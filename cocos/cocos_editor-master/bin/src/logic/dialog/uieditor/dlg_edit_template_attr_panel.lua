--[[
    编辑模板动态属性
]]
local constant_uieditor = g_constant_conf['constant_uieditor']

Panel = g_panel_mgr.new_panel_class('editor/edit/uieditor_edit_template_attr')

-- overwrite
function Panel:init_panel(templateName, data, btn, callback)
    self:add_key_event_callback('KEY_ESCAPE', function()
        self:close_panel()
    end)

    self._layer.OnClick = function()
        self:close_panel()
    end

    self._data = table.deepcopy(data)
    self._callback = callback

    self._conf = g_uisystem.load_template(templateName)
    self._rootNodeConf = g_uisystem.gen_root_node_conf(templateName)

    self._curSelNodeName = nil

    self:_updateData()

    local wpos = btn:convertToWorldSpace(ccp(0,0))
    self.bg:SetPosition(wpos.x, 25)
end

function Panel:_updateData()
    self.comboName:SetItems({})
    self.comboProperty:SetItems({})
    for nodeName, nodeConf in sorted_pairs(self._rootNodeConf) do
        local function _onSelMenu()
            self._curSelNodeName = nodeName

            self.comboName:SetString(nodeName)
            self.comboProperty:SetItems({})

            local attr_list = self._data[nodeName]
            local uiConfig = g_uisystem.get_control_config(attr_list and attr_list['type_name'] or nodeConf['type_name'])

            for attrName, _ in sorted_pairs(uiConfig:GetEditInfo()) do
                if attr_list == nil or attr_list[attrName] == nil and constant_uieditor['dynamic_template_ignor_attrs'][attrName] == nil then
                    self.comboProperty:AddMenuItem(attrName, function()
                        self._data[nodeName] = self._data[nodeName] or {}
                        self._data[nodeName][attrName] = nodeConf[attrName] or uiConfig:GetDefConf()[attrName]
                        self:_updateData()
                        self._callback(self._data)
                    end)
                end
            end
        end
        self.comboName:AddMenuItem(nodeName, function()
            if self._curSelNodeName ~= nodeName then
                _onSelMenu()
            end
        end)
        if self._curSelNodeName == nodeName then
            _onSelMenu()
        end
    end

    self.listAttr:SetInitCount(0)

    -- print('template attr panel _updateData', self._data)
    local bExistInvalidNode = false
    for nodeName, nodeAttr in sorted_pairs(self._data) do
        local nodeConf = self._rootNodeConf[nodeName]
        if nodeConf then
            local genAttrs = {}
            for _, conf in ipairs(g_uisystem.get_control_config(nodeAttr['type_name'] or nodeConf['type_name']):GenEditAttrs()) do
                local attr = conf['attr']
                local attrValue = nodeAttr[attr]
                if attrValue ~= nil then
                    genAttrs[attr] = true

                    -- add head
                    local item = self.listAttr:AddTemplateItem(nil, true)
                    item.name:SetString('#c00ff00{1}#n[#cff0000{2}#n]', nodeName, attr)
                    item.btnDelete.OnClick = function()
                        self._data[nodeName][attr] = nil
                        self:_updateData()
                        self._callback(self._data)
                    end

                    local ctrl = editor_utils_create_edit_ctrls(conf['tp'], attrValue, conf['parm'], nodeConf, function(value)
                        self._data[nodeName][attr] = value
                        self:_updateData()
                        self._callback(self._data)
                    end):GetCtrl()

                    self.listAttr:AddControl(ctrl, nil, true)
                end
            end

            -- del unused node attr due to different type_name
            for attr, v in pairs(nodeAttr) do
                if not genAttrs[attr] then
                    nodeAttr[attr] = nil
                end
            end
        else
            self._data[nodeName] = nil
            bExistInvalidNode = true
        end
    end

    if bExistInvalidNode then
        self:_updateData()
        self._callback(self._data)
    end

    self.listAttr:_refreshContainer()
end
