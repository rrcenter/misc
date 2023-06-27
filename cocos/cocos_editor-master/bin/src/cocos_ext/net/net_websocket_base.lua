--[[
    websocket
]]

local encrypt_utils = direct_import('cocos_ext.common.encrypt_utils')

-- 发送心跳的间隔时间
local config_heart_beat_interval = 6
local config_heart_beat_close_delay = 30


local function encrypt_send_string(sendString, index)
    -- print('encrypt_send_string', sendString, index)
    local content = string.char(index)..sendString
    -- print('content_bin', str2binary(content))
    -- print('content_md5', utils_get_md5_from_string(content))
    local chunk = encrypt_utils.xor_cipher(content)
    -- print('chunk', str2binary(chunk))
    local checkBit = encrypt_utils.hash_str(content)
    -- print('checkBit', str2binary(checkBit))
    return str2binary(checkBit, chunk)
end


GameNet = CreateClass()

-- override
function GameNet:__init__()
    self._conn = nil
    self._heart_beat_interal = config_heart_beat_interval
    self._netHandler = g_event_mgr.new_event_handler()

    self._proto = {
        CMD_COMMON_REMOTE_LOGIN_PUSH = 1000000, -- 远程登录挤掉线
        CMD_COMMON_HEART_BEAT_REQ = 1000001, -- 心跳返回
        CMD_COMMON_HEART_BEAT_RSP = 1000002,
        CMD_COMPRESS_REQ = 1000003,  -- 申请协议压缩
        CMD_COMPRESS_RSP = 1000004,
    }

    self._protosName = 'no_protos_name'
    self._protoIDNameMap = table.reverse_key_value(self._proto)

    self._log = nil

    self.heartBeatDelay = nil          -- 发心跳的 delay
    self._lastSendHeartBeatTime = {} -- 上一次发送心跳协议的时间
    self.lastReceiveHeartBeat = nil

    self._bSendEncryptedMsg = false
    self._sendEncryptedIndex = 0

    -- 自带事件
    self._netHandler:RegisterEvent('on_net_open')
    self._netHandler:RegisterEvent('on_net_close')
    self._netHandler:RegisterEvent('on_net_logic_error')

    self._netHandler:RegisterEvent('on_net_do_open')
    self._netHandler:RegisterEvent('on_net_do_close')
    self._netHandler:RegisterEvent('on_net_heartbeat_time_delay')
end

function GameNet:SetSendEncryptedMsg(bEnable)
    self._bSendEncryptedMsg = bEnable
end

-- override
function GameNet:on_proto_registered()
    -- 上一次收到心跳的时间
    self:RegisterNetEvent('on_net_open', function()
        if self._bSendEncryptedMsg then
            self._sendEncryptedIndex = 0
        end

        self:_closeSchedule()

        self.heartBeatDelay = delay_call(0, function()
            local lastSendTime = self._lastSendHeartBeatTime[1]
            if self:IsConnected() then
                local curTime = utils_get_tick()
                -- 心跳断网检测
                if lastSendTime and curTime - lastSendTime >= config_heart_beat_close_delay or 
                    self.lastReceiveHeartBeat and curTime - self.lastReceiveHeartBeat >= config_heart_beat_close_delay then
                    self.heartBeatDelay = nil
                    self:Close(true)
                else
                    self:Send(self._proto.CMD_COMMON_HEART_BEAT_REQ)
                    table.insert(self._lastSendHeartBeatTime, curTime)
                    return self._heart_beat_interal
                end
            else
                self.heartBeatDelay = nil
            end
        end)

        self:Send(self._proto.CMD_COMPRESS_REQ, {
            enable = utils_is_game_cpp_interface_available('support_wss'),
            ver = self._bSendEncryptedMsg and 2 or 0,
        })
    end)

    self:RegisterNetEvent('CMD_COMMON_HEART_BEAT_RSP', function(data)
        -- 设置服务端和客户端时间差距
        local curTime = utils_get_tick()
        self.lastReceiveHeartBeat = curTime
        local lastSendTime = table.remove(self._lastSendHeartBeatTime, 1)
        if lastSendTime == nil then
            utils_test_upload_log2server('websocket_error', string.format('lastSendTime is nil, net[%s]', self._protosName))
        else
            self._netHandler:Trigger('on_net_heartbeat_time_delay', curTime, lastSendTime, data.stamp)
        end
    end)

    self:RegisterNetEvent('on_net_logic_error', function(msgBody)
        printf('[%s] on_net_logic_error:%s', self._protosName, str(msgBody))
        local errors = g_conf_mgr.get_conf('errors')
        if errors[msgBody.code - 1] then
            message(errors[msgBody.code - 1]['lang'])
        else
            message(errors[0]['lang']..'code:'..(msgBody.code - 1))
        end
    end)
end

function GameNet:Open(ADDR)
    if self.isDestroy then
        return
    end
    assert(self:IsClosed())

    self._log:Printf('Open [%s]', ADDR)

    if string.sub(ADDR, 1, 3) == 'ws:' then
        self._conn = cc.WebSocket:create(ADDR)
    elseif string.sub(ADDR, 1, 3) == 'wss' then
        self._conn = cc.WebSocket:create(ADDR, {}, 'config/cacert.pem')
    else
        error_msg('ADDR [%s] not valid', ADDR)
    end

    local function onopen()
        if self.isDestroy then
            return
        end
        self._log:Print('on_net_open')
        -- 这里真机可能不会触发这样的报错
        if self:IsConnected() then
            self._netHandler:Trigger('on_net_open')
        else
            self:Close(true)
        end
    end

    local function onclose(evt)
        if self.isDestroy then
            return
        end
        self._log:Print('on_net_close')
        self:Close(true)
    end

    local function onerror(evt)
        if self.isDestroy then
            return
        end
        self._log:Printf('onerror [%s]', str(evt))
        self:Close(true)
    end

    local function onmessage(msgId, body, rawStr)
        if self.isDestroy then
            return
        end
        if not is_number(msgId) then
            if is_table(msgId) then
                local msg = msgId
                msgId = msg['MsgId']
                body = msg['Body']
            elseif is_string(msgId) then
                local msg = string.format('error:[%s] [%s] received unexpected buffer:%s', self._protosName, str(body), str_binary(msgId))
                utils_test_upload_log2server('error_websocket_unexpected_buffer', msg)
                return
            end
        end


        -- 网络原因会触发这个
        if not self:IsConnected() then
            self:Close(true)
            return
        end

        if body == nil then
            self._log:Printf('message body【%s】not valid', rawStr)
            return
        end

        if msgId < 0 then
            if msgId == -1 then
                local evalBody = eval(body)
                if evalBody == nil then
                    __G__TRACKBACK__(string.format("[%s] msgbody error:%s", self._protosName, str(body)))
                    self._netHandler:Trigger('on_net_logic_error', {code = 0, origin_body = str(body)})
                else
                    self._netHandler:Trigger('on_net_logic_error', evalBody)
                end
            elseif msgId == -2 then
                message(T('数据异常'))
            else
                self._log:Printf('net msgId [%s] not valid [%s]', str(msgId), str(body))
            end
            return
        end

        if not self._protoIDNameMap[msgId] then
            local errorMsg = string.format('net [%s] receive message id[%d] not valid, body is [%s], uid=[%d]', self._protosName, msgId, (eval(body) or str(body)), g_user_info.get_user_info().uid)
            utils_test_upload_log2server('error_websocket_unexpected_msg_id', errorMsg)
            return
        end

        if g_native_conf.debug_control.bPrintNetLog then
            local curTime = utils_get_tick()
            self._log:PrintProto(self._protoIDNameMap[msgId], str(body))
            -- self._writeLogCostTime = self._writeLogCostTime or 0
            -- self._writeLogCostTime = self._writeLogCostTime + utils_get_tick() - curTime
            -- print('debug write log time', self._writeLogCostTime)
        else
            printf('LOG_PROTO[%s][%s]', self._protosName, str(self._protoIDNameMap[msgId]))
        end

        xpcall(function()
            self._netHandler:Trigger(msgId, body)
        end, function(msg)
            __G__TRACKBACK__(msg)
            self._log:Printf('error in receiving proto ID:[%s][%s]', str(self._protoIDNameMap[msgId]), str(msgId))
        end)
    end

    self._conn:registerScriptHandler(onopen, cc.WEBSOCKET_OPEN)
    self._conn:registerScriptHandler(onmessage, cc.WEBSOCKET_MESSAGE)
    self._conn:registerScriptHandler(onclose, cc.WEBSOCKET_CLOSE)
    self._conn:registerScriptHandler(onerror, cc.WEBSOCKET_ERROR)

    self._netHandler:Trigger('on_net_do_open')

    return true
end

function GameNet:Close(bTriggerEvent)
    if self.isDestroy then
        return
    end
    self._log:Printf('Close %s %s', str(bTriggerEvent), str(self._conn))
    self:_closeSchedule()

    if self._conn then
        self._conn:unregisterScriptHandler(cc.WEBSOCKET_OPEN)
        self._conn:unregisterScriptHandler(cc.WEBSOCKET_MESSAGE)
        self._conn:unregisterScriptHandler(cc.WEBSOCKET_CLOSE)
        self._conn:unregisterScriptHandler(cc.WEBSOCKET_ERROR)
        self._conn:close()
        self._conn = nil
        self._lastSendHeartBeatTime = {} -- 上一次发送心跳协议的时间
        self.lastReceiveHeartBeat = nil
        if bTriggerEvent then
            self._netHandler:Trigger('on_net_close')
        end
    end

    self._netHandler:Trigger('on_net_do_close')
end

function GameNet:Send(msgId, body)
    if self.isDestroy then
        return
    end

    body = body or {}

    if is_string(msgId) then
        msgId = self._proto[msgId]
        assert(msgId)
    end

    if not self._protoIDNameMap[msgId] then
        error_msg('net send message id [%d] not valid', msgId)
    end

    if not self:IsConnected() then
        self._log:Printf('send but not connected [%s]', self._protoIDNameMap[msgId])

        -- 网络奇葩的时候连着的突然就断了然后会发生连接不了的情况
        self:Close(true)
        g_game_mgr.CheckReconnect()
        return
    end

    if table.is_empty(body) then
        body['empty'] = true
    end

    self._log:PrintProto(self._protoIDNameMap[msgId], str(body))

    local ss = luaext_json_encode({
        MsgId = msgId,
        Body = luaext_json_encode(body),
    })

    if msgId ~= self._proto.CMD_COMPRESS_REQ and self._bSendEncryptedMsg then
        -- 跟服务器约定第一个压缩协议不加密
        ss = encrypt_send_string(ss, self._sendEncryptedIndex)
        self._sendEncryptedIndex = self._sendEncryptedIndex + 1
        if self._sendEncryptedIndex > 255 then
            self._sendEncryptedIndex = 0
        end
    end
    self._conn:sendString(ss)
end

function GameNet:RegisterNetEvent(id, callback, nPriority, bCallbackOnce, bindObject)
    if self.isDestroy then
        return
    end

    if is_string(id) and self._proto[id] ~= nil then
        id = self._proto[id]
    end
    self._netHandler:AddCallback(id, callback, nPriority, bCallbackOnce, bindObject)
end

function GameNet:RemoveCallbackByBindObj(bindObject)
    if self.isDestroy then
        return
    end
    if self._netHandler then
        self._netHandler:RemoveCallbackByBindObj(bindObject)
    end
end

function GameNet:_closeSchedule()
    if self.heartBeatDelay then
        self.heartBeatDelay('cancel')
        self.heartBeatDelay = nil
    end
end

function GameNet:DestroyNet()
    self:Close()

    if self._log then
        g_log_mgr.close_log(self._log)
        self._log = nil
    end
    self.isDestroy = true
end

function GameNet:RegProtos(proto, protosName)
    if self.isDestroy then
        return
    end
    if is_table(protosName) then
        proto, protosName = protosName, proto
    end

    table.merge(self._proto, proto)
    self._protosName = protosName
    self._protoIDNameMap = table.reverse_key_value(self._proto)

    assert(self._log == nil)
    self._log = g_log_mgr.create_log(protosName)
    -- self._log:AddProtoLogFilter('CMD_COMMON_HEART_BEAT_REQ')
    -- self._log:AddProtoLogFilter('CMD_COMMON_HEART_BEAT_RSP')

    for protoName, protoID in pairs(self._proto) do
        -- 强制限制收的协议要这么命名
        if protoName:sub(-3, -1) == 'RSP' or protoName:sub(-4, -1) == 'PUSH' then
            self._netHandler:RegisterEvent(protoID)
        end
    end

    self:on_proto_registered()
end

function GameNet:EnableNetLog(bEnable)
    if self.isDestroy then
        return
    end
    self._log:EnableLog(bEnable)
end

function GameNet:IsConnected()
    return self._conn and self._conn:getReadyState() == cc.EXT_CONNECT_STATUS.OPEN
end

function GameNet:IsClosed()
    return not self._conn or self._conn:getReadyState() == cc.EXT_CONNECT_STATUS.CLOSED
end

------------------------------------------------- utilities
function GameNet:SendGameLoginRequest(protoID)
    if self.isDestroy then
        return
    end
    local session_key = g_user_info.get_user_info().session_key
    assert(session_key ~= nil)

    local req = {
        session_key = session_key,
        lang = g_native_conf.cur_multilang_index,
        channel_name = platform_get_app_channel_name(),
    }

    self:Send(protoID, req)
end
