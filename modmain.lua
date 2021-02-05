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
    if STRINGS.UI.SPECIAL_EVENT_PICKER == nil then STRINGS.UI.SPECIAL_EVENT_PICKER = {} end
    STRINGS.UI.SPECIAL_EVENT_PICKER.HALLOWED_NIGHTS = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.HALLOWED_NIGHTS
    STRINGS.UI.SPECIAL_EVENT_PICKER.WINTERS_FEAST = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.WINTERS_FEAST
    STRINGS.UI.SPECIAL_EVENT_PICKER.YOTG = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.YOTG
    STRINGS.UI.SPECIAL_EVENT_PICKER.YOTV = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.YOTV
    STRINGS.UI.SPECIAL_EVENT_PICKER.YOTP = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.YOTP
    STRINGS.UI.SPECIAL_EVENT_PICKER.YOTC = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.YOTC
    STRINGS.UI.SPECIAL_EVENT_PICKER.YOTB = STRINGS.UI.SANDBOXMENU.SPECIAL_EVENTS.YOTB
    STRINGS.UI.SPECIAL_EVENT_PICKER.NONE = STRINGS.UI.SPECIAL_EVENT_PICKER.NONE or "None"
    STRINGS.UI.SPECIAL_EVENT_PICKER.DEFAULT = STRINGS.UI.SPECIAL_EVENT_PICKER.DEFAULT or "Default"
    STRINGS.UI.SPECIAL_EVENT_PICKER.DEFAULT_NEED_RESTART = STRINGS.UI.SPECIAL_EVENT_PICKER.DEFAULT_NEED_RESTART or "Default (need restart)"
    STRINGS.UI.SPECIAL_EVENT_PICKER.BUTTON_TITLE = STRINGS.UI.SPECIAL_EVENT_PICKER.BUTTON_TITLE or "Switch Event"
    STRINGS.UI.SPECIAL_EVENT_PICKER.ERROR = STRINGS.UI.SPECIAL_EVENT_PICKER.ERROR or "Error"
    STRINGS.UI.SPECIAL_EVENT_PICKER.SUBTITLE = STRINGS.UI.SPECIAL_EVENT_PICKER.SUBTITLE or "Special Event Picker"
    STRINGS.UI.SPECIAL_EVENT_PICKER.ANNOUNCE_STRING = STRINGS.UI.SPECIAL_EVENT_PICKER.ANNOUNCE_STRING or "Server world event is set to \"%s\""
    STRINGS.UI.SPECIAL_EVENT_PICKER.TITLE_NEED_RESTART = STRINGS.UI.SPECIAL_EVENT_PICKER.TITLE_NEED_RESTART or "Need Restart"
    STRINGS.UI.SPECIAL_EVENT_PICKER.DESC_NEED_RESTART = STRINGS.UI.SPECIAL_EVENT_PICKER.DESC_NEED_RESTART or "Server will save and restart in order to apply the event setting:\n\n\"%s\""

    local lang_code = TheNet:GetLanguageCode()
    if lang_code == "tchinese" then
        STRINGS.UI.SPECIAL_EVENT_PICKER.NONE = "無"
        STRINGS.UI.SPECIAL_EVENT_PICKER.DEFAULT = "預設"
        STRINGS.UI.SPECIAL_EVENT_PICKER.DEFAULT_NEED_RESTART = "預設（需要重啟）"
		STRINGS.UI.SPECIAL_EVENT_PICKER.BUTTON_TITLE = "切換活動"
		STRINGS.UI.SPECIAL_EVENT_PICKER.ERROR = "錯誤"
		STRINGS.UI.SPECIAL_EVENT_PICKER.SUBTITLE = "選擇套用特別活動"
        STRINGS.UI.SPECIAL_EVENT_PICKER.ANNOUNCE_STRING = "伺服器特別活動已設定為「%s」"
        STRINGS.UI.SPECIAL_EVENT_PICKER.TITLE_NEED_RESTART = "需要重啟"
        STRINGS.UI.SPECIAL_EVENT_PICKER.DESC_NEED_RESTART = "將會存檔並且重新啟動伺服器，以套用活動設定：\n\n%s"
    end
    --------------------------

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
