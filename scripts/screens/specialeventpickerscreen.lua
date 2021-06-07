local Screen            = require "widgets/screen"
local Widget            = require "widgets/widget"
local Text              = require "widgets/text"
local ImageButton       = require "widgets/imagebutton"
local ScrollableList    = require "widgets/scrollablelist"
local TEMPLATES         = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"

local UserCommands      = require "usercommands"

local REFRESH_INTERVAL = 0.5

local MIN_HEIGHT = 20
local TITLE_HEIGHT = 46
local SUBTITLE_HEIGHT = 22
local BUTTON_HEIGHT = 37.5
local CANCEL_OFFSET = 0

local SpecialEventPickerScreen = Class(Screen, function(self, owner, targetuserid, onclosefn)
    Screen._ctor(self, "SpecialEventPickerScreen")

    self.owner = owner
    self.targetuserid = targetuserid
    self.onclosefn = onclosefn

    self.time_to_refresh = 0

    --darken everything behind the dialog
    self.black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
    self.black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black.image:SetTint(0, 0, 0, 0) -- invisible, but clickable!
    self.black:SetOnClick(function() TheFrontEnd:PopScreen() end)

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0, 0, 0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)


    local bg_root = self.proot:AddChild(Widget("bg_root"))
    bg_root:SetScale(1.0, 1.0) -- The pop-up window size
    
    local subtitle = self.targetuserid ~= nil and STRINGS.UI.SPECIAL_EVENT_PICKER.ERROR or STRINGS.UI.SPECIAL_EVENT_PICKER.SUBTITLE
    local subtitle_desc = ""
    self.bg = bg_root:AddChild(TEMPLATES.CurlyWindow(180, 340, subtitle, nil, nil, subtitle_desc))
    self.bg.title:SetPosition(0, -70)
    self.bg:SetPosition(0, -10)
    self.bg:SetSize(220, 360)
    self.bg.body:SetVAlign(ANCHOR_TOP)
    self.bg.body:SetSize(60, 90)

    if self.targetuserid ~= nil then
	    self.bg.body:Hide()

        local client = TheNet:GetClientTableForUser(self.targetuserid)
        local body = self.bg.title.parent:AddChild(Text(CHATFONT, 45, "", UICOLOURS.WHITE))
        local pos = self.bg.title:GetLocalPosition() + Vector3(0, -45, 0)
        body:SetTruncatedString(client ~= nil and client.name or "", 226, 50, true)
	    body:SetPosition(pos)
    end

    self:UpdateActions()

    local height = MIN_HEIGHT + SUBTITLE_HEIGHT + TITLE_HEIGHT
    local max_height = MIN_HEIGHT + SUBTITLE_HEIGHT + TITLE_HEIGHT
    local list_height = 0

    self.buttons = {}
    for i, action in ipairs(self.actions) do
        local text = action.prettyname

        local button = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_xlong_normal.tex", "button_carny_xlong_hover.tex", "button_carny_xlong_disabled.tex", "button_carny_xlong_down.tex"))
        button.image:SetScale(1, 1.1)
        button:SetFont(CHATFONT)
        button:SetTextSize(40)
        button:SetScale(0.5)
        button:SetText(button.text:GetString())
        button.text:SetColour(0,0,0,1)
        button.text:SetTruncatedString(text, 350, 58, true)
        button.text:SetRegionSize(370, 64) --Max out the region size for triggering the hover text

        button:SetOnClick(function() TheFrontEnd:PopScreen() self:RunAction(action.commandname) end)

        button.commandname = action.commandname

        table.insert(self.buttons, button)

        list_height = list_height + BUTTON_HEIGHT
    end

    local shown_buttons = 8
    local max_list_height = BUTTON_HEIGHT * shown_buttons
    list_height = math.min(list_height, max_list_height)

    height = height + list_height
    max_height = max_height + max_list_height

    self.scroll_list = self.proot:AddChild(ScrollableList(self.buttons, 210, list_height, BUTTON_HEIGHT, 0, nil, nil, #self.buttons > shown_buttons and 95 or 105, nil, nil, 8))
    self.default_focus = self.scroll_list

    if not TheInput:ControllerAttached() then
        self.cancelbutton = self.proot:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        self.cancelbutton.image:SetScale(.8)
        self.cancelbutton:SetFont(CHATFONT)
        self.cancelbutton.text:SetColour(0, 0, 0, 1)
        self.cancelbutton:SetTextSize(40)
        self.cancelbutton:SetText(STRINGS.UI.COMMANDSSCREEN.CANCEL)
        self.cancelbutton:SetScale(0.5)
        self.cancelbutton:SetOnClick(function() TheFrontEnd:PopScreen() end)
        height = height + BUTTON_HEIGHT + CANCEL_OFFSET
        max_height = max_height + BUTTON_HEIGHT + CANCEL_OFFSET
    end

    local top = (height/2 + max_height/2) / 2
    top = top - SUBTITLE_HEIGHT
    top = top - TITLE_HEIGHT

    self.scroll_list:SetPosition(#self.buttons > shown_buttons and 5 or 0, top - (list_height/2))
    top = top - list_height
    if self.cancelbutton then
        local bottom = (-max_height/2) + BUTTON_HEIGHT
        self.cancelbutton:SetPosition(0, bottom, 0) -- note: max_height, not max_top, to push it downwards
        top = top - CANCEL_OFFSET - BUTTON_HEIGHT
    end

    self.force_focus_button = nil
    self:RefreshButtons()
end)

function SpecialEventPickerScreen:OnDestroy()
    if self.onclosefn ~= nil then
        self.onclosefn()
    end
    self._base.OnDestroy(self)
end

function SpecialEventPickerScreen:UpdateActions()
    local actions = {}

    if SPECIAL_EVENTS.DEFAULT == nil then
        SPECIAL_EVENTS.DEFAULT = "default"
    end

    local orders = { NONE = 0, DEFAULT = 1, LAST = 2 }

    for tag, commandname in pairs(SPECIAL_EVENTS) do
        local order       = (orders[tag] or orders.LAST) .. tag
        local prettyname  = STRINGS.UI.SPECIAL_EVENT_PICKER[tag]       or 
                            STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS[tag] or 
                            commandname
        local exectype    = (commandname ~= WORLD_SPECIAL_EVENT) and 
                            COMMAND_RESULT.ALLOW                 or
                            COMMAND_RESULT.DISABLED

        table.insert(actions, {
            tag         = tag,
            order       = order,
            commandname = commandname,
            prettyname  = prettyname,
            exectype    = exectype
        })
        -- print(tag, eventCode, STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS[tag])
    end

    table.sort(actions, 
        function(a, b)
            if a.order ~= b.order then
                return a.order < b.order
            end
            return a.prettyname < b.prettyname 
        end)

    self.actions = actions
end

function SpecialEventPickerScreen:OnControl(control, down)
    if SpecialEventPickerScreen._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:PopScreen() 
        return true
    end
end

function SpecialEventPickerScreen:RefreshButtons()
	-- we only want to force the focus to be set the first time we find an active widget, not on every refresh
    local force_focus = false
    for _, button in ipairs(self.buttons) do
        local action = nil
        for _, act in ipairs(self.actions) do
            if act.commandname == button.commandname then
                action = act
                break
            end
        end

        if action ~= nil then
            if action.exectype == COMMAND_RESULT.DISABLED then
                -- we know canstart is false, but we want the reason
                local canstart, reason = UserCommands.CanUserStartCommand(action.commandname, self.owner, self.targetuserid)
                button:SetHoverText(reason ~= nil and STRINGS.UI.PLAYERSTATUSSCREEN.COMMANDCANNOTSTART[reason] or "")
                if TheInput:ControllerAttached() then
                    button:Disable()
                else
                    button:Select()
                end
            elseif action.exectype == COMMAND_RESULT.DENY then
                if TheInput:ControllerAttached() then
                    button:Disable()
                else
                    button:Select()
                end
            else
                button:ClearHoverText()
                if TheInput:ControllerAttached() then                    
                    button:Enable()
					-- this is the first active widget we've come across so set it as focus
                    if nil == self.force_focus_button then
                        self.force_focus_button = button
                        force_focus = true
                    end
                else
                    button:Unselect()
                end
            end
        end
    end

	-- force the focus if necessary
    if force_focus and nil ~= self.force_focus_button then
        self.force_focus_button:SetFocus()
    end
end

function SpecialEventPickerScreen:RunAction(name)
    if self.actions == nil then
        return
    end

    local action = nil
    for i, act in ipairs(self.actions) do
        if act.commandname == name then
            action = act
            break
        end
    end

    if action ~= nil then
        local cmd = "TheWorld.topology.overrides.specialevent=\"" .. action.commandname .. "\""
        cmd = cmd .. " ApplySpecialEvent(\"".. action.commandname .."\")"
        if action.commandname == "default" then
            cmd = "TheWorld.topology.overrides.specialevent=nil WORLD_SPECIAL_EVENT=\"default\""
            cmd = cmd .. " ApplySpecialEvent(\"none\")"
        end

        TheFrontEnd:PushScreen(
            PopupDialogScreen(STRINGS.UI.SPECIAL_EVENT_PICKER.TITLE_NEED_RESTART, 
                string.format(STRINGS.UI.SPECIAL_EVENT_PICKER.DESC_NEED_RESTART, action.prettyname), 
                {
                    {text = STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() 
                        TheFrontEnd:PopScreen() 
                        local announce_string = string.format(STRINGS.UI.SPECIAL_EVENT_PICKER.ANNOUNCE_STRING, action.prettyname)
                        if TheNet:GetIsClient() and TheNet:GetIsServerAdmin() then
                            TheNet:SendRemoteExecute(cmd)
                            TheNet:SendRemoteExecute("c_announce(\""..announce_string.."\")")
                            -- Merged on 4/2/2020
                            -- Thanks to @Iconer for the testing and making the PR.
                            TheNet:SendRemoteExecute("c_save()")
                            TheNet:SendRemoteExecute("TheWorld:DoTaskInTime(3.5, function() c_reset() end)")
                        else
                            ExecuteConsoleCommand(cmd)
                            ExecuteConsoleCommand("c_announce(\""..announce_string.."\")")
                            ExecuteConsoleCommand("c_save()")
                            ExecuteConsoleCommand("TheWorld:DoTaskInTime(3.5, function() c_reset() end)")
                        end
                        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_warningbell")
                    end},
                    {text = STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end } 
                })
        )
    end
end

function SpecialEventPickerScreen:OnUpdate(dt)
    if TheFrontEnd:GetFadeLevel() > 0 then
        TheFrontEnd:PopScreen(self)
        return
    elseif self.time_to_refresh > dt then
        self.time_to_refresh = self.time_to_refresh - dt
        return
    end

    self.time_to_refresh = REFRESH_INTERVAL
    self:UpdateActions()
    if #self.actions > 0 then
        self:RefreshButtons()
    else
        TheFrontEnd:PopScreen(self)
    end
end

function SpecialEventPickerScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end

return SpecialEventPickerScreen
