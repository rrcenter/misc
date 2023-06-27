--[[
    UI编辑器配置对应的显示视图
]]
local constant_uieditor = g_constant_conf['constant_uieditor']
local constant_uisystem = g_constant_conf['constant_uisystem']
local UIControlItem = import('uieditor.uieditor_control_item').UIControlItem

-- 貌似复制太快马上再获取剪切板的内容会获得空
Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_config_view')

function Panel:_initMainPanel()
    -- view size
    local resolutionSize = g_native_conf['editor_design_resolution_size']
    local w, h = resolutionSize.width, resolutionSize.height
    self.layerDevice:SetContentSize(w, h)
    self.layerDevice.rectBorder:SetContentSize(w, h)
    self.nodeSelFrames:SetContentSize(w, h)

    -- drag & drop list object
    self.listObjects:EnableDragAndDrop(function(btn)
        if btn.uicontrol_item:IsSelected() then
            local spt = g_uisystem.load_template_create('editor/uieditor/items/uieditor_list_object_template')
            spt.text:SetString(btn.text:GetString())
            spt.chVisible:SetCheck(btn.chVisible:GetCheck())
            return spt
        end
    end)

    self.listObjects.OnDragAndDrop = function(pt, srcItem, destItem)
        if destItem then
            self:OPMoveItem(destItem.uicontrol_item)
        end
    end

    -- search function
    self.editSearchItem.OnEditReturn = function(text)
        local selItems = {}

        if #text > 0 and self.root_item then
            self.root_item:ForEachItem(function(item)
                if string.find(item:GetCfg()['name'], text) then
                    table.insert(selItems, item)
                end
            end)
        end

        self:ShowTips('搜到%d个结果', #selItems)
        self:SelectControlItems(selItems)
        self:_editRefreshCurselData()
    end

    --单选多选处理, 选中， 移动
    self.layerTouch:HandleMouseEvent()

    self.layerTouch.OnMouseWheel = function(scrollValue)
        if scrollValue > 0 then
            self:OPSetPanelScale(self.layerDevice:getScale() * (1.2 ^ scrollValue))
        else
            self:OPSetPanelScale(self.layerDevice:getScale() * (0.8 ^ (-scrollValue)))
        end
    end

    -- 圈选 移动
    local beginPos
    local selectRect = nil
    self.layerTouch.OnMouseDown = function(mouseBtn, pos)
        if selectRect then
            selectRect:removeFromParent(true)
            selectRect = nil
            beginPos = nil
        end

        if mouseBtn ~= constant_uisystem.MouseButton.BUTTON_RIGHT then
            return
        end

        beginPos = pos
        if g_ui_event_mgr.is_ctrl_down() then
            selectRect = cc.CCRectangle:Create(1, 0x0000ff)
            self:get_layer():addChild(selectRect)
            selectRect:SetContentSize(0,0)
            selectRect:setAnchorPoint(ccp(0.5,0.5))
        end        
    end

    self.layerTouch.OnMouseUp = function(mouseBtn, pos)
        if mouseBtn ~= constant_uisystem.MouseButton.BUTTON_RIGHT then
            if selectRect then
                selectRect:removeFromParent(true)
                selectRect = nil
                beginPos = nil
            end
            return
        end

        if selectRect then
            selectRect:removeFromParent(true)
            selectRect = nil
            
            --圈点多选
            if self.root_item then
                local items = {}
                self.root_item:ItemInRect(
                    math.min(pos.x, beginPos.x),
                    math.max(pos.y, beginPos.y),
                    math.max(pos.x, beginPos.x),
                    math.min(pos.y, beginPos.y),
                    items
                )
                self:SelectControlItems(items)
                self:_editRefreshCurselData()
            end
        end
        beginPos = nil
    end

    self.layerTouch.OnMouseMove = function(bMoveInside, pos, bFirstMove)
        if beginPos and pos then
            if selectRect then
                --多选
                selectRect:SetPosition((beginPos.x + pos.x) / 2, (beginPos.y + pos.y) / 2)
                selectRect:SetContentSize(math.abs(beginPos.x - pos.x), math.abs(beginPos.y - pos.y))
            else
                --移动 layerDevice
                local x, y = self.layerDevice:getPosition()
                self.layerDevice:SetPosition(x + pos.x - beginPos.x, y + pos.y - beginPos.y)
                self.nodeSelFrames:SetPosition(x + pos.x - beginPos.x, y + pos.y - beginPos.y)

                beginPos = pos
            end
        end
    end

    self.layerTouch.OnClick = function(pos)
        local bCtrlDown = g_ui_event_mgr.is_ctrl_down()

        local item = self.root_item and self.root_item:ItemForTouch(pos)
        if item then
            if bCtrlDown then
                self:CtrlSelectControlItem(item)  -- 多选
            else
                self:SelectControlItem(item)  -- 单选
            end
        elseif not bCtrlDown then
            -- ctrl + 左键 为多选 不应该选空控件
            self:SelectControlItem(nil)
        end
        self:_editRefreshCurselData()
    end

    self.layerTouch.OnDropFile = function(filePaths, position)
        self:_on_drop_file(filePaths, position)
    end

    -- 节点折叠
    self:set_panel_swallow_key_event(false)
    self.listObjects:EnableAutoKeyWrapByLevel(self)

    -- ani edit
    local function _selectAni(aniName)
        self._curAniName = aniName
        self:RefreshSelItemAniPropertyConf(true)

        self.root_item:ForEachItem(function(v)
            v:_updateListViewItem()
        end)
    end

    local function _updateAni()
        self._curAniName = nil
        local defAniName = nil
        self.comboAni:SetItems({})
        if self.root_item then
            local aniNames = {}
            self.root_item:ForEachItem(function(v)
                for aniName, v in pairs(v:GetAniData()) do
                    if not table.is_empty(v) then
                        aniNames[aniName] = true
                        if defAniName == nil then
                            defAniName = aniName
                        end
                    end
                end
            end)

            for aniName, _ in pairs(aniNames) do
                self.comboAni:AddMenuItem(aniName, function()
                    _selectAni(aniName)
                end)
            end

            _selectAni(defAniName)
        end
    end
    self.layerActionAni:setVisible(self.checkShowAni:GetCheck())
    self.checkShowAni.OnChecked = function(bcheck)
        self.layerActionAni:setVisible(bcheck)

        if bcheck then
            _updateAni()
        else
            if self.layerShowAni:isVisible() then
                self.btnPlayAni.OnClick()
            end
        end

        self:RefreshSelItemAniPropertyConf()
    end

    self.btnPlayAni.OnClick = function()
        local bShowAni = not self.layerShowAni:isVisible()

        if bShowAni then
            if is_valid_str(self._curAniName) then
                self.layerShowAni:setVisible(true)
                self.layerDevice:setVisible(false)
                self.nodeSelFrames:setVisible(false)
                self.layerShowAni:SetPosition(self.layerDevice:GetPosition())
                self.layerShowAni:setScale(self.layerDevice:getScale())
                self.layerShowAni:SetContentSize(self.layerDevice:GetContentSize())
                self.layerShowAni:removeAllChildren()

                self.btnPlayAni:SetString('关闭')
                local baseNode = g_uisystem.create_item(self.root_item:DumpItemCfg(), self.layerShowAni)
                baseNode:PlayAnimation(self._curAniName)
            else
                message('动画无效')
                return
            end
        else
            g_audio_mgr.stopMusic(true)
            g_audio_mgr.stopAllSounds()
            self.btnPlayAni:SetString('播放')
            self.layerShowAni:setVisible(false)
            self.layerDevice:setVisible(true)
            self.nodeSelFrames:setVisible(true)
        end
    end

    self.btnDelAni.OnClick = function()
        if self._curAniName == nil then
            message('请选择指定的动画再执行删除')
            return
        end

        local delCount = 0
        self.root_item:ForEachItem(function(v)
            local aniData = v:GetAniData()
            if aniData and aniData[self._curAniName] ~= nil then
                aniData[self._curAniName] = nil
                delCount = delCount + 1

                v:_updateListViewItem()
            end
        end)

        self._curAniName = nil

        self:EditPush()
        message('成功删除{1}个节点动画', delCount)
        self:RefreshSelItemAniPropertyConf()
    end
end

-- 拖拽件
function Panel:_on_drop_file(filePaths, position)
    local project_res_path = g_logic_editor:get_project_res_path()
    local function _addDropFile(filePath)
        local releative_path = string.match(filePath, string.format('^%s(.+)$', project_res_path))
        if releative_path == nil then
            message('请选择当前项目res目录资源')
            return
        end

        local suffix_str = string.match(releative_path, '^.+%.(.+)$')
        if not suffix_str then
            return
        end

        local file_suffix_to_node_conf = constant_uieditor.file_suffix_to_node[suffix_str]
        if not file_suffix_to_node_conf then
            -- message('没有找到文件类型配置，请选择有效的文件')
            return
        end

        local check_sub_type_policy = file_suffix_to_node_conf.check_sub_type_policy
        if check_sub_type_policy then
            local is_valid, sub_type = check_sub_type_policy(releative_path)
            if is_valid then
                if sub_type ~= suffix_str then
                    file_suffix_to_node_conf = file_suffix_to_node_conf[sub_type]
                end
            else
                message('请选择有效的文件格式')
                return
            end
        end

        if file_suffix_to_node_conf then
            return self:drag_generate_ui_node(releative_path, file_suffix_to_node_conf)
        end
    end

    local listConf = {}
    for _, filePath in ipairs(filePaths) do
        local cfg = _addDropFile(filePath)
        if cfg then
            table.insert(listConf, cfg)
        end
    end

    if table.is_empty(listConf) then
        return
    end

    local parentItem = self:GetSelectedControlItem() or self.root_item
    local startIndex = nil
    local addItem = {}
    if parentItem then
        if g_ui_event_mgr.is_ctrl_down() or g_ui_event_mgr.is_alt_down() then
            local p = parentItem:GetParentItem()
            if p then
                parentItem = p
                if g_ui_event_mgr.is_ctrl_down() then
                    startIndex = parentItem:GetParentItemIndex() + 1
                else
                    startIndex = parentItem:GetParentItemIndex()
                end
            end
        end
    else
        local conf = table.remove(listConf, 1)
        conf['pos'] = position
        parentItem = self:_addConf(conf)
        table.insert(addItem, parentItem)
    end

    local localPosition = parentItem:GetCtrl():convertToNodeSpace(position)
    localPosition.x = math.round_number(localPosition.x)
    localPosition.y = math.round_number(localPosition.y)

    for i, conf in ipairs(listConf) do
        conf['pos'] = localPosition
        table.insert(addItem, self:_addConf(conf, parentItem, startIndex and startIndex + i -1))
    end
    self:EditPush()

    self:SelectControlItems(addItem)
end

--生成节点
function Panel:drag_generate_ui_node(releative_path, conf)
    local defConf = conf.defConf or {}
    defConf.type_name = conf.type_name

    for _, param in ipairs(conf.params or {}) do
        local cur_conf = defConf
        local file_key_path = param.file_key_path
        local keys = string.split(file_key_path, ".")
    
        for index, key in ipairs(keys or {}) do
            if index ~= #keys then
                local sub_conf = defConf[key] or {}
                defConf[key] = sub_conf
                cur_conf = sub_conf
            else
                local change_param = param.change_param
                if change_param then
                    releative_path = change_param(releative_path)
                end
                cur_conf[key] = releative_path
            end
        end
    end

    return defConf
end

-- override
function Panel:init_panel(templateName)
    self.eventHandler = g_event_mgr.new_event_handler()

    self._templateName = nil  -- 模板名称(未保存模板名为空)
    self.root_item = nil  -- 根节点
    self._selItems = {}  -- 选中的item列表

    -- 编辑操作
    self._editData = {}
    self._editCurIndex = 0
    self._editCurSaveIndex = 0
    self._editOPCount = 0

    -- panel resolution

    -- panel test show animation
    self._curAniName = nil

    -- init
    self:_initMainPanel()

    -- 加载配置
    if templateName then
        if self:_addConf(templateName) then
            --cur panel template name
            self.editPanelName:SetText(templateName)

            self._templateName = templateName
            self:EditPush()
            self:EditOnSave()
        end
    end
end

function Panel:GetCurSelAniName()
    return self._curAniName
end

-- 当前面板的模板名称
function Panel:GetTemplateName()
    return self._templateName
end

-- 面板的内容可否保存
function Panel:CanSave()
    return self.root_item ~= nil
end

-- 判断当前面板的状态是否需要保存
function Panel:NeedSave()
    return self:CanSave() and (self:GetTemplateName() == nil or self:IsEditChanged())
end

-- 保存 panel 对应的配置
function Panel:SaveConfig(templateName)
    local tmpName = string.match(templateName, '(.+)%.json')
    if tmpName then
        templateName = tmpName
    end

    self._templateName = templateName

    g_multi_doc_manager.save_template_conf(self)

    self:EditOnSave()

    self.editPanelName:SetText(self:GetTemplateName() or '')
end

-- 判断当前 文档是否有修改过
function Panel:IsEditChanged()
    return self._editCurIndex ~= self._editCurSaveIndex
end

function Panel:EditOnSave()
    while #self._editData > self._editCurIndex do
        table.remove(self._editData)
    end
    self._editCurSaveIndex = self._editCurIndex
end

function Panel:EditOperateBegin()
    self._editOPCount = self._editOPCount + 1
end

function Panel:EditOperateEnd()
    assert(self._editOPCount > 0)
    self._editOPCount = self._editOPCount - 1
end

function Panel:EditOperatePush()
    self:EditOperateEnd()
    self:EditPush()
end

function Panel:EditPush()
    if self._editOPCount > 0 or self.root_item == nil then
        return
    end

    while #self._editData > self._editCurIndex do
        table.remove(self._editData)
    end

    if self._editCurSaveIndex > self._editCurIndex then
        self._editCurSaveIndex = 0
    end

    --1： cfg 、 2:sel index list
    local list = {}
    self.root_item:GetSelectedIndexList(list)
    table.insert(self._editData, {self.root_item:DumpItemCfg(), list})
    self._editCurIndex = self._editCurIndex + 1

    print('edit push ##################')
end

-- 刷新当前编辑数据的选中数据
function Panel:_editRefreshCurselData()
    if self.root_item == nil then
        return
    end

    if self._editCurIndex > 0 then
        local list = {}
        self.root_item:GetSelectedIndexList(list)
        self._editData[self._editCurIndex][2] = list
    end
end

function Panel:_editUpdateData()
    if self._editCurIndex > 0 then
        local data = self._editData[self._editCurIndex]
        self:_clearRootItem()
        assert(self:_addConf(data[1]))
        self:SelectControlItemsByIndexList(data[2])
    end
end

-- 控制当前文档的可见性
function Panel:ShowConfigView(bShow)
    self:get_layer():setVisible(bShow)
end

-- 获取该配置文件的保存路径
function Panel:GetSaveFilePath()
    if self._templateName then
        return g_logic_editor.get_ui_template_file_path(self._templateName)
    end
end


-- items op
function Panel:_addConf(conf, parentItem, pos)
    if is_string(conf) then
        conf = g_uisystem.load_template(conf)
    end

    if not g_uisystem.is_template_valid(conf) then
        printf('conf not valid:%s', str(conf))
        return
    end

    local item = UIControlItem:New(conf, parentItem or self.root_item, pos, self)
    if self.root_item == nil then
        self.root_item = item
    end

    return item
end

function Panel:_clearRootItem()
    if self.root_item then
        self.root_item:RemoveSelf()
        self.root_item = nil
        assert(table.is_empty(self._selItems))
        return true
    end
end

function Panel:_copyControlItems(items)
    if #items == 0 then
        return
    end

    local config = {listPos = {}, listCtrl = {}}
    for i, v in ipairs(items) do
        config.listCtrl[i] = v:DumpItemCfg()

        local ctrl = v:GetCtrl()
        config.listPos[i] = ctrl:getParent():convertToWorldSpace(ccp(ctrl:getPosition()))
    end

    win_copy_data2clipboard(repr(config))

    return config
end

function Panel:_cutControlItems(items)
    if #items == 0 then
        return
    end

    local ret = self:_copyControlItems(items)
    for _, v in ipairs(items) do
        v:RemoveSelf()
        if v == self.root_item then
            self.root_item = nil
        end
    end

    return ret
end

function Panel:_pasteAsChildItem(destItem, index, conf)
    local selItems = {}
    for i, config in ipairs(conf.listCtrl) do
        local item = self:_addConf(config, destItem, index and index + i - 1)
        if item then
            --确保 cut item 的世界坐标在past之后保持不变
            local ctrl = item:GetCtrl()
            ctrl:setPosition(ctrl:getParent():convertToNodeSpace(conf.listPos[i]))
            item:RefreshItemConfig()

            table.insert(selItems, item)
        end
    end

    if destItem and destItem:GetCfg()['lock'] and not table.is_empty(selItems) then
        destItem:GetBtnInListView().chLock:SetCheck(false, true)
    end

    --选中粘贴之后的控件
    self:SelectControlItems(selItems)

    return selItems
end

function Panel:_pasteAsFrontItem(destItem, conf)
    local parentItem = destItem and destItem:GetParentItem()
    if parentItem then
        local pos = table.find_v(parentItem:GetChildList(), destItem)
        return self:_pasteAsChildItem(parentItem, pos, conf)
    else
        return self:_pasteAsChildItem(nil, nil, conf)
    end
end

function Panel:_pasteAsBackItem(destItem, conf)
    local parentItem = destItem and destItem:GetParentItem()
    if parentItem then
        local pos = table.find_v(parentItem:GetChildList(), destItem) + 1
        return self:_pasteAsChildItem(parentItem, pos, conf)
    else
        return self:_pasteAsChildItem(nil, nil, conf)
    end
end

function Panel:_doReload()
    self:_clearRootItem()
    g_uisystem.reload_template(self._templateName)
    self:_addConf(self._templateName)
end

function Panel:RefreshSelItemAniPropertyConf(bScrollToTop)
    self.listAniProperty:DeleteAllSubItem()
    self.btnAddAni.OnClick = nil

    self.comboAni:SetString(self._curAniName or '')
    self.editAddAni:SetString(self._curAniName or '')

    local bShowAni = #self._selItems == 1
    self.nodeAddAni:setVisible(bShowAni)
    if not bShowAni then
        return
    end

    local item = self:GetSelectedControlItem()
    item:_updateListViewItem()

    -- refresh cur ani property edit
    local curEditAniConf
    self.btnAddAni.OnClick = function()
        local addAni = self.editAddAni:GetString()
        if not is_valid_str(addAni) then
            message('请输入有效的动画名称')
            return
        end

        if self._curAniName == addAni and curEditAniConf then
            table.insert(curEditAniConf, constant_uisystem.default_ani_template_name)
            item:GetAniData()[addAni] = curEditAniConf
            message('成功为动画[{1}]增加一个子动画', addAni)
            self:RefreshSelItemAniPropertyConf()
        elseif item:GetAniData()[addAni] == nil then
            item:GetAniData()[addAni] = {constant_uisystem.default_ani_template_name}
            message('成功增加动画:{1}', addAni)

            self._curAniName = addAni

            self.root_item:ForEachItem(function(v)
                v:_updateListViewItem()
            end)

            self:RefreshSelItemAniPropertyConf()
        else
            message('请将当前的动画切换到 [{1}] 在执行添加动画', addAni)
        end
    end

    if is_valid_str(self._curAniName) then
        curEditAniConf = item:GetAniData()[self._curAniName]
        
        if is_array(curEditAniConf) then
            local offset = self.listAniProperty:getContentOffset()
            curEditAniConf = table.from_arr_trans_fun(curEditAniConf, function(_, v)
                if g_uisystem.load_ani_template(v) then
                    return v
                end
            end)

            -- print('curEditAniConf', curEditAniConf)
            for i, v in ipairs(curEditAniConf) do
                -- add head
                self.listAniProperty:AddTemplateItem().btnDelete.OnClick = function()
                    table.remove(curEditAniConf, i)
                    item:GetAniData()[self._curAniName] = curEditAniConf
                    self:EditPush()
                    self:RefreshSelItemAniPropertyConf()
                end

                local ctrl = editor_utils_create_edit_ctrls('edit_type_select_action_ani', v, {name='动画'}, nil, function(value)
                    curEditAniConf[i] = value
                    item:GetAniData()[self._curAniName] = curEditAniConf
                    self:EditPush()
                    self:RefreshSelItemAniPropertyConf()
                end):GetCtrl()

                self.listAniProperty:AddControl(ctrl)
            end

            self.listAniProperty:setContentOffset(offset)
        else
            curEditAniConf = nil
        end
    end

    if bScrollToTop then
        self.listAniProperty:ScrollToTop()
    else
        self.listAniProperty:ResetContentOffset()
    end
end

--[[刷新一下选中按钮的属性列表]]
function Panel:RefreshSelItemPropertyConf(bScrollToTop)
    self.listProperty:DeleteAllSubItem()


    if #self._selItems ~= 1 then
        return
    end

    local item = self:GetSelectedControlItem()

    -- basic property edit
    local offset = self.listProperty:getContentOffset()
    g_uisystem.get_control_config(item:GetCfg()['type_name']):GenEditControls(self.listProperty, item, self)
    self.listProperty:setContentOffset(offset)


    if bScrollToTop then
        self.listProperty:ScrollToTop()
    else
        self.listProperty:ResetContentOffset()
    end
end

local _delayShowTips
function Panel:ShowTips(...)
    local tips = string.format(...)
    assert(is_valid_str(tips))
    self.lTips:SetString(tips)

    if _delayShowTips then
        _delayShowTips('cancel')
    end

    _delayShowTips = self._layer:DelayCall(1, function()
        self.lTips:SetString('')
    end)
end


------------------------------------------ OP
function Panel:OPEditUndo()
    if self._editCurIndex > 1 then
        self._editCurIndex = self._editCurIndex - 1
        self:_editUpdateData()
        return true
    else
        return false
    end
end

function Panel:OPEditRedo()
    if self._editCurIndex < #self._editData then
        self._editCurIndex = self._editCurIndex + 1
        self:_editUpdateData()
        return true
    else
        return false
    end
end

-- rectBorder显示
function Panel:OPShowBoarder()
    self.layerDevice.rectBorder:setVisible(not self.layerDevice.rectBorder:isVisible())
end

function Panel:OPShowCenterView()
    self.nodeSelFrames:SetPosition('50%', '50%')
    self.layerDevice:SetPosition('50%', '50%')
end

function Panel:OPGenDlgCode()
    local dirPath = g_logic_editor.get_project_script_dialog_path()
    if not dirPath then
        message('脚本代码不存在')
        return
    end

    if not is_valid_str(self._templateName) then
        message('请先保存模板')
        return
    end

    local filePath = win_save_file('lua脚本代码', dirPath)

    if is_valid_str(filePath) then
        if string.sub(filePath, -4) ~= '.lua' then
            filePath = filePath .. '.lua'
        end

        filePath = dirPath .. filePath

        if not g_fileUtils:isFileExist(filePath) then
            local content = string.gsub(constant_uieditor.editor_template_code, '__TEMPLATE__', self._templateName)
            content = string.format(content, os.date('%Y-%m-%d %H:%M', os.time()))
            g_fileUtils:writeStringToFile(content, filePath)
            win_explorer(filePath)
        end
    end
end

function Panel:OPReloadFile()
    local savePath = self:GetSaveFilePath()
    if savePath == nil or not g_fileUtils:isFileExist(savePath) then
        message('当前文档未曾保存过,无法刷新成本地配置')
        return
    end

    if self:IsEditChanged() then
        win_confirm_yes_no(nil, "当前的工作未保存，是否重新加载？", function()
            self:_doReload()
            self:EditPush()
            self:EditOnSave()
        end)
    else
        self:_doReload()
        self:EditPush()
        self:EditOnSave()
    end
end

--[[
    panel 对UI控件的单选操作(执行多选直接调用对应 item 的 SelectControlItem 方法即可)
    if item == nil then unselect all
]]
function Panel:SelectControlItem(item)
    assert(item == nil or isinstance(item, UIControlItem))
    if not self.root_item then
        return
    end

    self._selItems = item and {item} or {}
    self.root_item:SelectUniqueItem(item)

    --刷新选中属性
    self:RefreshSelItemPropertyConf(true)
    self:RefreshSelItemAniPropertyConf(true)
end

--如果已经有选中的item则该item默认添加进来
function Panel:SelectControlItems(items)
    for _, v in ipairs(items) do
        assert(isinstance(v, UIControlItem))
    end

    if not self.root_item then
        return
    end

    if #items == 0 then
        return self:SelectControlItem(nil)
    end

    self._selItems = items

    self.root_item:SelectUniqueItems(table.to_value_set(items))

    --刷新选中属性
    self:RefreshSelItemPropertyConf(true)
    self:RefreshSelItemAniPropertyConf(true)
end

function Panel:SelectControlItemsByIndexList(list)
    if not self.root_item then
        return
    end

    local selItems = {}
    for _, index in ipairs(list) do
        table.insert(selItems, self.root_item:GetItemByIndexList(index))
    end
    return self:SelectControlItems(selItems)
end

--[[将指定控件加入跟随列表中,如果已经在列表中则从列表中移除]]
function Panel:CtrlSelectControlItem(item)
    assert(item == nil or isinstance(item, UIControlItem))

    if table.arr_remove_v(self._selItems, item) then
        assert(item:IsSelected())
        item:SelectControlItem(false)
    else
        assert(not item:IsSelected())
        table.insert(self._selItems, 1, item)
        item:SelectControlItem(true)
    end
    self:RefreshSelItemPropertyConf(true)
    self:RefreshSelItemAniPropertyConf(true)
end

function Panel:GetSelectedControlItem()
    return self._selItems[1]
end

function Panel:GetSeletedList()
    return self._selItems
end




--[[在选中的控件的子列表中添加一个新的控件]]
function Panel:AddUIControlItem(typeName, defCfg)
    local conf = table.merge({type_name = typeName}, defCfg)

    local item = self:GetSelectedControlItem() or self.root_item
    local addItem
    if item == self.root_item then
        addItem = self:_addConf(conf, item)
    else
        local defPos = defCfg.pos or ccp(0, 0)
        if g_ui_event_mgr.is_ctrl_down() then
            addItem = self:_pasteAsBackItem(item, {listCtrl = {conf}, listPos = {defPos}})[1]
        elseif g_ui_event_mgr.is_alt_down() then
            addItem = self:_pasteAsFrontItem(item, {listCtrl = {conf}, listPos = {defPos}})[1]
        else
            addItem = self:_addConf(conf, item)
        end
    end

    if addItem then
        local pos = addItem:GetCtrl():getParent():ConvertToNodeSpace('50%', '50%')
        addItem:GetCtrl():setPosition(pos)
        addItem:RefreshItemConfig()
        --选中新建的控件
        self:SelectControlItem(addItem)
        self:EditPush()
    end
end

--复制当前选中的items
function Panel:CopySelItem()
    self:_copyControlItems(self.root_item:GetNoSelParentSelItems())
end

--剪切当前选中的items
function Panel:CutSelItem()
    self:_cutControlItems(self.root_item:GetNoSelParentSelItems())
    self:EditPush()
end

function Panel:PasteAsBackItem()
    local selItem = self:GetSelectedControlItem()
    if not selItem then 
        return
    end

    if selItem == self.root_item then
        return
    end

    local copyConf = eval(win_get_data_from_clipboard())
    if #self:_pasteAsBackItem(selItem, copyConf) > 0 then
        self:EditPush()
    end
end

function Panel:PasteAsFrontItem()
    local selItem = self:GetSelectedControlItem()
    if not selItem then
        return 
    end

    if selItem == self.root_item then
        return
    end

    local copyConf = eval(win_get_data_from_clipboard())
    if #self:_pasteAsFrontItem(selItem, copyConf) > 0 then
        self:EditPush()
    end
end

--拷贝为选中项的子项
function Panel:PasteAsChildItem()
    local copyConf = eval(win_get_data_from_clipboard())
    if not copyConf then
        return
    end
    if #self:_pasteAsChildItem(self:GetSelectedControlItem(), nil, copyConf) > 0 then
        self:EditPush()
    end
end

--将选中的节点移到指定节点下
function Panel:OPMoveItem(destItem)
    local srcItems = self:GetSeletedList()
    -- 如果目标节点是拖动节点的子节点则忽略
    for _, srcItem in ipairs(srcItems) do
        if srcItem:IsAncestor(destItem) then
            return
        end
    end

    local bCtrlDown = g_ui_event_mgr.is_ctrl_down()
    local bAltDown  = g_ui_event_mgr.is_alt_down()

    if (bAltDown or bCtrlDown) and destItem == self.root_item then
        return
    end

    --OP
    local copyConf = self:_cutControlItems(srcItems)
    if bCtrlDown then
        self:_pasteAsBackItem(destItem, copyConf)
    elseif bAltDown then
        self:_pasteAsFrontItem(destItem, copyConf)
    else
        self:_pasteAsChildItem(destItem, nil, copyConf)
    end
    self:EditPush()
end

-- 删除选中的所有节点
function Panel:DeleteSelItem()
    if not self:GetSelectedControlItem() then
        return
    end

    if self.root_item:IsSelected() then
        self:_clearRootItem()
    else
        for _, v in ipairs(self.root_item:GetNoSelParentSelItems()) do
            v:RemoveSelf()
        end
    end
    self:EditPush()
end

local function _alignH_EQUIDISTANCE(sortedList)
    local parentItem = sortedList[1]:GetParentItem()
    for _, item in ipairs(sortedList) do
        if parentItem ~= item:GetParentItem() then
            message('该操作需要在同一个节点层级进行')
        end
    end

    local alignList = table.copy(sortedList)

    -- left -> right
    table.arr_bubble_sort(alignList, function(obj1, obj2)
        local pos1 = obj1:GetCtrl():convertToWorldSpace(ccp(0, 0))
        local pos2 = obj2:GetCtrl():convertToWorldSpace(ccp(0, 0))
        return pos1.x < pos2.x
    end)

    local objBox = {}
    local allLen = 0
    for i, v in ipairs(alignList) do
        objBox[i] = v:GetCtrl():GetBoundingBox()
        allLen = allLen + objBox[i].width
    end

    local lastObjB = objBox[#objBox]
    local obj_interval = ((lastObjB.x + lastObjB.width - objBox[1].x)  - allLen) / (#alignList - 1)

    --按照父子顺序设置坐标
    local curX = objBox[1].x
    for i, v in ipairs(alignList) do
        v:GetCtrl():SetLeftPosition(curX)
        v:RefreshItemConfig()

        curX = curX + objBox[i].width + obj_interval
    end
end

local function _alignV_EQUIDISTANCE(sortedList)
    local parentItem = sortedList[1]:GetParentItem()
    for _, item in ipairs(sortedList) do
        if parentItem ~= item:GetParentItem() then
            message('该操作需要在同一个节点层级进行')
        end
    end

    local alignList = table.copy(sortedList)

    -- bottom -> top
    table.arr_bubble_sort(alignList, function(obj1, obj2)
        local pos1 = obj1:GetCtrl():convertToWorldSpace(ccp(0, 0))
        local pos2 = obj2:GetCtrl():convertToWorldSpace(ccp(0, 0))
        return pos1.y < pos2.y
    end)

    local objBox = {}
    local allLen = 0

    for i, v in ipairs(alignList) do
        objBox[i] = v:GetCtrl():GetBoundingBox()
        allLen = allLen + objBox[i].height
    end

    local lastObjB = objBox[#objBox]
    local obj_interval = ((lastObjB.y + lastObjB.height - objBox[1].y) - allLen) / (#alignList - 1)

    local curY = objBox[1].y
    for i, v in ipairs(alignList) do
        v:GetCtrl():SetBottomPosition(curY)
        v:RefreshItemConfig()

        curY = curY + objBox[i].height + obj_interval
    end
end

local function _alignH_ADD_SPACE(sortedList, space)
    local alignList = table.copy(sortedList)

    table.arr_bubble_sort(alignList, function(obj1, obj2)
        local pos1 = obj1:GetCtrl():convertToWorldSpace(ccp(0, 0))
        local pos2 = obj2:GetCtrl():convertToWorldSpace(ccp(0, 0))
        return pos1.x <= pos2.x
    end)

    local posList = {}
    for i, v in ipairs(alignList) do
        table.insert(posList, v:GetCtrl():convertToWorldSpace(ccp(0, 0)).x)
    end

    local wPoX = {}
    for i, v in ipairs(alignList) do
        wPoX[v] = posList[i] +  (i - 1) * space
    end

    --按照父子顺序设置坐标
    for i, v in ipairs(sortedList) do
        v:GetCtrl():SetLeftPosition(v:GetCtrl():getParent():convertToNodeSpace(ccp(wPoX[v], 0)).x)
        v:RefreshItemConfig()
    end
end

local function _alignV_ADD_SPACE(sortedList, space)
    local alignList = table.copy(sortedList)

    table.arr_bubble_sort(alignList, function(obj1, obj2)
        local pos1 = obj1:GetCtrl():convertToWorldSpace(ccp(0, 0))
        local pos2 = obj2:GetCtrl():convertToWorldSpace(ccp(0, 0))
        return pos1.y <= pos2.y
    end)

    local posList = {}
    for i, v in ipairs(alignList) do
        table.insert(posList, v:GetCtrl():convertToWorldSpace(ccp(0, 0)).y)
    end

    local wPoY = {}
    for i, v in ipairs(alignList) do
        wPoY[v] = posList[i] +  (i - 1) * space
    end

    --按照父子顺序设置坐标
    for i, v in ipairs(sortedList) do
        v:GetCtrl():SetBottomPosition(v:GetCtrl():getParent():convertToNodeSpace(ccp(0, wPoY[v])).y)
        v:RefreshItemConfig()
    end
end

local function _alignSyncSize(sortedList, itemW, itemH)
    for _, item in ipairs(sortedList) do
        local width, height = item:GetCtrl():GetContentSize()
        item:GetCtrl():SetContentSize(itemW or width, itemH or height)
        item:RefreshItemConfig(true, true)
    end
end

local function _alignSyncPosition(selectedItem, sortedList, alignType)
    local ALIGN_TYPE = constant_uieditor.ALIGN_TYPE

    --根据选中的 item 进行对齐
    local ctrl = selectedItem:GetCtrl()
    local wPosMin = ctrl:convertToWorldSpace(ccp(0, 0))
    local wPosMax = ctrl:convertToWorldSpace(ccp(ctrl:GetContentSize()))

    if alignType == ALIGN_TYPE.TOP then
        -- 向上对齐
        for _, v in ipairs(sortedList) do
            if v ~= selectedItem then
                local pos = v:GetCtrl():getParent():convertToNodeSpace(wPosMax)
                v:GetCtrl():SetTopPosition(pos.y)
                v:RefreshItemConfig()
            end
        end
    elseif alignType == ALIGN_TYPE.BOTTOM then
        -- 向下对齐
        for i, v in ipairs(sortedList) do
            if v ~= selectedItem then
                local pos = v:GetCtrl():getParent():convertToNodeSpace(wPosMin)
                v:GetCtrl():SetBottomPosition(pos.y)
                v:RefreshItemConfig()
            end
        end
    elseif alignType == ALIGN_TYPE.LEFT then
        --左对齐
        for i, v in ipairs(sortedList) do
            if v ~= selectedItem then
                local pos = v:GetCtrl():getParent():convertToNodeSpace(wPosMin)
                v:GetCtrl():SetLeftPosition(pos.x)
                v:RefreshItemConfig()
            end
        end
    elseif alignType == ALIGN_TYPE.RIGHT then
        -- 右对齐
        for i, v in ipairs(sortedList) do
            if v ~= selectedItem then
                local pos = v:GetCtrl():getParent():convertToNodeSpace(wPosMax)
                v:GetCtrl():SetRightPosition(pos.x)
                v:RefreshItemConfig()
            end
        end
    elseif alignType == ALIGN_TYPE.VCENTER then
        -- 垂直居中对齐
        for i, v in ipairs(sortedList) do
            if v ~= selectedItem then
                local posMin = v:GetCtrl():getParent():convertToNodeSpace(wPosMin)
                local posMax = v:GetCtrl():getParent():convertToNodeSpace(wPosMax)
                v:GetCtrl():SetXCenterPosition((posMax.x + posMin.x)/2)
                v:RefreshItemConfig()
            end
        end
    elseif alignType == ALIGN_TYPE.HCENTER then
        --水平对齐
        for i, v in ipairs(sortedList) do
            if v ~= selectedItem then
                local posMin = v:GetCtrl():getParent():convertToNodeSpace(wPosMin)
                local posMax = v:GetCtrl():getParent():convertToNodeSpace(wPosMax)
                v:GetCtrl():SetYCenterPosition((posMax.y + posMin.y)/2)
                v:RefreshItemConfig()
            end
        end
    else
        assert(false, alignType)
    end
end

-- 对齐选中对象列表
function Panel:AlignSelect(alignType)
    if self.root_item == nil then
        return
    end

    local selectList = self.root_item:GetBFSSelItems()
    if #selectList == 0 then
        return
    end

    local ALIGN_TYPE = constant_uieditor.ALIGN_TYPE
    assert(table.find_v(ALIGN_TYPE, alignType))

    if alignType >= ALIGN_TYPE.H_EQUIDISTANCE and alignType <= ALIGN_TYPE.V_SUB_SPACE and #selectList < 3 then
        message('此操作请选中3个以上节点')
        return
    end

    if #selectList == 1 then
        self:_alignParent(alignType)
    else
        local curSelectedItem = self:GetSelectedControlItem()
        if alignType == ALIGN_TYPE.H_EQUIDISTANCE then
            _alignH_EQUIDISTANCE(selectList)
        elseif alignType == ALIGN_TYPE.V_EQUIDISTANCE then
            _alignV_EQUIDISTANCE(selectList)
        elseif alignType >= ALIGN_TYPE.H_ADD_SPACE and alignType <= ALIGN_TYPE.V_SUB_SPACE then
            local space
            if g_ui_event_mgr.is_ctrl_down() then
                space = constant_uieditor.align_ctrl_move_len
            elseif g_ui_event_mgr.is_alt_down() then
                space = constant_uieditor.align_alt_move_len
            elseif g_ui_event_mgr.is_shift_down() then
                space = constant_uieditor.align_shift_move_len
            else
                space = 1
            end

            if alignType == ALIGN_TYPE.H_ADD_SPACE then
                _alignH_ADD_SPACE(selectList, space)
            elseif alignType == ALIGN_TYPE.H_SUB_SPACE then
                _alignH_ADD_SPACE(selectList, -space)
            elseif alignType == ALIGN_TYPE.V_ADD_SPACE then
                _alignV_ADD_SPACE(selectList, space)
            elseif alignType == ALIGN_TYPE.V_SUB_SPACE then
                _alignV_ADD_SPACE(selectList, -space)
            end
        elseif alignType == ALIGN_TYPE.SAME_WIDTH then
            local w, h = curSelectedItem:GetCtrl():GetContentSize()
            _alignSyncSize(selectList, w, nil)
        elseif alignType == ALIGN_TYPE.SAME_HEIGHT then
            local w, h = curSelectedItem:GetCtrl():GetContentSize()
            _alignSyncSize(selectList, nil, h)
        elseif alignType == ALIGN_TYPE.SAME_SIZE then
            _alignSyncSize(selectList, curSelectedItem:GetCtrl():GetContentSize())
        else
            _alignSyncPosition(curSelectedItem, selectList, alignType)
        end
    end

    self:RefreshSelItemPropertyConf()
    self:EditPush()
end

function Panel:_alignParent(alignType)
    if self.root_item == nil then
        return
    end

    local selItem = self:GetSelectedControlItem()
    if selItem == nil then
        return
    end

    local ALIGN_TYPE = constant_uieditor.ALIGN_TYPE
    assert(table.find_v(ALIGN_TYPE, alignType))
    local sortedList = self.root_item:GetBFSSelItems()

    if alignType == ALIGN_TYPE.TOP then
        -- 向上对齐
        for _, v in ipairs(sortedList) do
            local cfg = v:GetCfg()
            cfg['anchor']['y'] = 1
            cfg['pos']['y'] = 'i0'
            v:RefreshItemControl()
        end
    elseif alignType == ALIGN_TYPE.BOTTOM then
        -- 向下对齐
        for i, v in ipairs(sortedList) do
            local cfg = v:GetCfg()
            cfg['anchor']['y'] = 0
            cfg['pos']['y'] = 0
            v:RefreshItemControl()
        end
    elseif alignType == ALIGN_TYPE.VCENTER then
        -- 向下对齐
        for i, v in ipairs(sortedList) do
            local cfg = v:GetCfg()
            cfg['anchor']['x'] = 0.5
            cfg['pos']['x'] = '50%'
            v:RefreshItemControl()
        end
    elseif alignType == ALIGN_TYPE.LEFT then
        --左对齐
        for i, v in ipairs(sortedList) do
            local cfg = v:GetCfg()
            cfg['anchor']['x'] = 0
            cfg['pos']['x'] = 0
            v:RefreshItemControl()
        end
    elseif alignType == ALIGN_TYPE.RIGHT then
        -- 右对齐
        for i, v in ipairs(sortedList) do
            local cfg = v:GetCfg()
            cfg['anchor']['x'] = 1
            cfg['pos']['x'] = 'i0'
            v:RefreshItemControl()
        end
    elseif alignType == ALIGN_TYPE.HCENTER then
        --水平对齐
        for i, v in ipairs(sortedList) do
            local cfg = v:GetCfg()
            cfg['anchor']['y'] = 0.5
            cfg['pos']['y'] = '50%'
            v:RefreshItemControl()
        end
    else
        local w, h = selItem:GetCtrl():getParent():GetContentSize()
        if alignType == ALIGN_TYPE.SAME_WIDTH then
            _alignSyncSize({selItem}, w, nil)
        elseif alignType == ALIGN_TYPE.SAME_HEIGHT then
            _alignSyncSize({selItem}, nil, h)
        elseif alignType == ALIGN_TYPE.SAME_SIZE then
            _alignSyncSize({selItem}, w, h)
        else
            print('not support align type', alignType)
        end
    end
end

function Panel:OPSetPanelScale(scale)
    local wPos = win_get_cursor_pos()
    local cursorInDevicePos = self.layerDevice:convertToNodeSpace(wPos)
    local preDevicePos = self.layerDevice:getParent():convertToNodeSpace(wPos)

    scale = math.clamp(scale, 0.1, 20)
    self.layerDevice:setScale(scale)
    self.nodeSelFrames:setScale(scale)

    -- local sPos = mat4_transformVector(self.layerDevice:getNodeToParentTransform(), cursorInDevicePos)
    local sPos = self.layerDevice:getParent():convertToNodeSpace(self.layerDevice:convertToWorldSpace(cursorInDevicePos))
    local curPosX, curPosY = self.layerDevice:getPosition()

    local pos = ccp(curPosX + preDevicePos.x - sPos.x, curPosY + preDevicePos.y - sPos.y)
    self.layerDevice:setPosition(pos)
    self.nodeSelFrames:setPosition(pos)

    self:ShowTips('缩放%d%%', math.round_number(scale * 100))
    

    if table.is_empty(self._selItems) then
        return
    end

    if self._delayFixSelFrameTransform == nil then
        self._delayFixSelFrameTransform = self._layer:DelayCall(0.1, function()
            for _, item in ipairs(self._selItems) do
                item:_updateSelFrameTransform()
            end
            self._delayFixSelFrameTransform = nil
        end)
    end
end

function Panel:MoveSelectedCtrl(offsetx, offsety)
    local sortedSelList = self.root_item:GetBFSSelItems()
    local singleSel = table.to_value_set(self.root_item:GetNoSelParentSelItems())
    table.arr_remove_if(sortedSelList, function(i, v)
        if not singleSel[v] then
            return i, true
        end
    end)

    if #sortedSelList == 0 then
        return
    end

    self:EditOperateBegin()

    for _, v in ipairs(sortedSelList) do
        local x, y = v:GetCtrl():GetPosition()
        v:GetCtrl():SetPosition(x + offsetx, y + offsety)
        v:RefreshItemConfig()
    end

    self:EditOperatePush()
    self:RefreshSelItemPropertyConf()
end

--将拖拽的配置拖动到指定的选中节点下(为选中则拖动到根节点下)
function Panel:AddDragConfig(config, pt)
    if is_string(config) then
        config = table.deepcopy(g_uisystem.load_template(config))
    end
    config['lock'] = true

    local selItem = self:GetSelectedControlItem()
    local copyConf = {listPos = {pt}, listCtrl = {config}}
    if g_ui_event_mgr.is_ctrl_down() then
        if #self:_pasteAsBackItem(selItem, copyConf) > 0 then
            self:EditPush()
        end
    elseif g_ui_event_mgr.is_alt_down() then
        if #self:_pasteAsFrontItem(selItem, copyConf) > 0 then
            self:EditPush()
        end
    else
        if #self:_pasteAsChildItem(selItem, nil, copyConf) > 0 then
            self:EditPush()
        end
    end
end

--打开配置文件所在文件夹
function Panel:OpenContainFolder()
    local path = self:GetSaveFilePath()
    if g_fileUtils:isFileExist(path) then
        os.execute('explorer /select, ' .. string.gsub(path, '/', '\\'))
    else
        message('文件夹不存在')
    end
end

function Panel:OPChangeNodePosFormat(osx, osy)
    for _, item in ipairs(self.root_item:GetBFSSelItems()) do
        item:ConvertPos(osx, osy)
    end

    self:RefreshSelItemPropertyConf()
end

function Panel:OPChangeNodeSizeFormat(osx, osy)
    for _, item in ipairs(self.root_item:GetBFSSelItems()) do
        item:ConvertSize(osx, osy)
    end

    self:RefreshSelItemPropertyConf()
end

function Panel:OPPreviewPanel()
    if not self.root_item then
        message('空节点不能预览')
        return
    end

    if self:NeedSave() then
        message('需要保存后才能预览')
        return
    end

    local appDir = win_get_exe_dir()
    local workdir = win_startup_conf['workdir']
    local templateName = self:GetTemplateName()
    local projResPath = g_logic_editor.get_project_res_path()
    local lang = g_native_conf['cur_multilang_index']
    local designSize = g_native_conf['editor_design_resolution_size']
    local appName = self._curAniName and string.format('template[%s]-ani-name[%s]', templateName, self._curAniName) or string.format('template[%s]', templateName)
    local cmd =string.format('start %s -workdir %s -preview_template %s -preview_res_path %s -preview_lang %s -preview_design_size %dX%d -preview_ani_name %s -app_name %s -id preview',
        appDir, workdir, templateName, projResPath, lang, designSize.width, designSize.height, tostring(self._curAniName), appName)

    printf('cmd:%s', cmd)
    os.execute(cmd)
end

function Panel:OPSelectAllItems()
    local items = {}
    self.root_item:ForEachItem(function(item)
        table.insert(items, item)
    end)
    self:SelectControlItems(items)
end
