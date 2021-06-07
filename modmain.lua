local _G = GLOBAL
local TheNet = _G.TheNet
local require = _G.require
local STRINGS = _G.STRINGS
local ImageButton = require "widgets/imagebutton"
local PlayerStatusScreen = require "screens/playerstatusscreen"
local SpecialEventPickerScreen = require "screens/specialeventpickerscreen"

Assets = {
	Asset("IMAGE", "images/event_picker.tex"), 
	Asset("ATLAS", "images/event_picker.xml"), 
}

local old_DoInit = PlayerStatusScreen.DoInit
function PlayerStatusScreen:DoInit(ClientObjs, ...)
	old_DoInit(self, ClientObjs, ...)

    ------ Localization ------
    local SPECIAL_EVENT_PICKER_FALLBACK_LOCALIZATION = {}
    SPECIAL_EVENT_PICKER_FALLBACK_LOCALIZATION["english"] = 
    {
        NONE                 = "None",
        DEFAULT              = "Default",
        DEFAULT_NEED_RESTART = "Default (need restart)",
        BUTTON_TITLE         = "Switch Event",
        ERROR                = "Error",
        SUBTITLE             = "Special Event Picker",
        ANNOUNCE_STRING      = "Server world event is set to \"%s\"",
        TITLE_NEED_RESTART   = "Need Restart",
        DESC_NEED_RESTART    = "Server will save and restart in order to apply the event setting:\n\n\"%s\""
    }
    
    SPECIAL_EVENT_PICKER_FALLBACK_LOCALIZATION["tchinese"] = 
    {
        NONE                 = "無",
        DEFAULT              = "預設",
        DEFAULT_NEED_RESTART = "預設（需要重啟）",
        BUTTON_TITLE         = "切換活動",
        ERROR                = "錯誤",
        SUBTITLE             = "選擇套用特別活動",
        ANNOUNCE_STRING      = "伺服器特別活動已設定為「%s」",
        TITLE_NEED_RESTART   = "需要重啟",
        DESC_NEED_RESTART    = "將會存檔並且重新啟動伺服器，以套用活動設定：\n\n%s"
    }

    if TheNet:GetLanguageCode() == "tchinese" or GLOBAL.LanguageTranslator.defaultlang == "cht" then
        STRINGS.UI.SPECIAL_EVENT_PICKER = SPECIAL_EVENT_PICKER_FALLBACK_LOCALIZATION["tchinese"]
    else
        STRINGS.UI.SPECIAL_EVENT_PICKER = SPECIAL_EVENT_PICKER_FALLBACK_LOCALIZATION["english"]
    end

	local admin = self.owner.Network:IsServerAdmin()
	if not admin then return end
	
	if self.event_picker_button == nil then
		self.event_picker_button = self.root:AddChild(ImageButton("images/event_picker.xml", "event_picker_icon.tex", nil, nil, nil, nil, { .4, .4 }, { 0, 0 }))
		self.event_picker_button:SetNormalScale({.4, .4})
		self.event_picker_button:SetFocusScale({.4*1.2, .4*1.2})
		self.event_picker_button:SetOnClick(function()
			TheFrontEnd:PopScreen()
			self:OpenSpecialEventPickerScreen(nil)
		end)
		self.event_picker_button:SetHoverText(STRINGS.UI.SPECIAL_EVENT_PICKER.BUTTON_TITLE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 48, colour = WHITE})

		local servermenux = -329
		-- local servermenubtnoffs = 24
		-- local servermenunumbtns = 1

		-- if self.viewgroup_button ~= nil then
		-- 	servermenunumbtns = servermenunumbtns + 1
		-- end
		-- if self.serveractions_button ~= nil then
		-- 	servermenunumbtns = servermenunumbtns + 1
		-- end

		-- self.event_picker_button:SetPosition(servermenux + (servermenunumbtns > 1 and (servermenunumbtns) * servermenubtnoffs or 0), 200)
		self.event_picker_button:SetPosition(-servermenux+65, 210)
	end
end

function PlayerStatusScreen:OpenSpecialEventPickerScreen(targetuserid)
    if self.specialeventpickerscreen == nil then
        self.specialeventpickerscreen = SpecialEventPickerScreen(self.owner, targetuserid, function() self.specialeventpickerscreen = nil end)
        TheFrontEnd:PushScreen(self.specialeventpickerscreen)
    end
end
