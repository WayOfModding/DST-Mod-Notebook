local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local AbsTextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"
local json = require "json"

-- Constants
local CONTROL_MENU_MISC_1   = 68
local TITLE_LENGTH_LIMIT    = 16
local MAX_HUD_SCALE         = 1.25
local MAX_WRITEABLE_LENGTH  = 200

local function SetPages(book, pages, marks)
    if book == nil
        or pages == nil
        or marks == nil
        or book.components.notebook == nil
    then
        return
    end
    -- Filter pages that ain't modified
    for page, mark in pairs(marks) do
        marks[page] = pages[page]
    end
    
    book.components.notebook:SetPages(marks)
end

local function EndWriting(book, player)
    if book and player and book.components.notebook then
        book.components.notebook:EndWriting(player)
    end
end

local function GetPage(self, page)
    local res = nil
    if self and page and self.pages then
        res = self.pages[page]
    end
    --print("KK-TEST> Function Screen:GetPage(" .. tostring(page) .. ") returns \"" .. res .. "\".")
    return res or ""
end
local function GetTitle(self)
    local res = GetPage(self, 0)
    --print("KK-TEST> Function Screen:GetTitle() returns \"" .. res .. "\".")
    return res
end
local function OnPageUpdated(self, page)
    --print("KK-TEST> Function Screen:OnPageUpdated(" .. tostring(page) .. ") is invoked.")
    if self == nil
        or page == nil
        or self.edit_text == nil
    then
        return
    end
    local res = GetPage(self, page) or ""
    if page == 0 then
        self.edit_text:SetHAlign(ANCHOR_MIDDLE)
        self.edit_text:SetVAlign(ANCHOR_MIDDLE)
        self.edit_text:SetTextLengthLimit(TITLE_LENGTH_LIMIT)
    else
        self.edit_text:SetHAlign(ANCHOR_LEFT)
        self.edit_text:SetVAlign(ANCHOR_TOP)
        self.edit_text:SetTextLengthLimit(MAX_WRITEABLE_LENGTH)
    end
    self:OverrideText(res)
end
local function MarkPage(self, page)
    --print("KK-TEST> Function Screen:MarkPage(" .. tostring(page) .. ") is invoked.")
    if self == nil
        or page == nil
        or self.pages == nil
        or self.marks == nil
    then
        return
    end
    local text = self.edit_text:GetString() or ""
    self.pages[page] = text
    self.marks[page] = true
end
local function MarkCurrent(self)
    --print("KK-TEST> Function Screen:MarkCurrent() is invoked.")
    MarkPage(self, self.page)
end
local function UpdatePage(self, page)
    --print("KK-TEST> Function Screen:UpdatePage(" .. tostring(page) .. ") is invoked.")
    if self == nil
        or page == nil
        or self.page == nil
    then
        return
    end
    self.page = page
    OnPageUpdated(self, page)
end
local function LastPage(self)
    --print("KK-TEST> Function Screen:LastPage() is invoked.")
    if self == nil
        or self.page == nil
        or self.edit_text == nil
    then
        return
    end
    local oldpage = self.page
    local newpage = oldpage - 1
    if newpage < 0 then newpage = 0 end
    if newpage < oldpage then
        UpdatePage(self, newpage)
    end
    self.edit_text:SetEditing(true)
end
local function NextPage(self)
    --print("KK-TEST> Function Screen:NextPage() is invoked.")
    if self == nil
        or self.page == nil
        or self.pages == nil
        or self.edit_text == nil
    then
        return
    end
    local oldpage = self.page
    local newpage = oldpage + 1
    local limit = #self.pages + 1
    -- Prevent abusing 'Next Page'
    if newpage > limit then
        newpage = limit
    end
    if newpage > oldpage then
        UpdatePage(self, newpage)
    end
    self.edit_text:SetEditing(true)
end

local function onaccept(inst, doer, widget)
    if not widget.isopen then
        return
    end
    
    SetPages(inst, widget.pages, widget.marks)

    widget.edit_text:SetEditing(false)
    EndWriting(inst, doer)
    widget:Close()
end

local function onmiddle(inst, doer, widget)
    if not widget.isopen then
        return
    end
    
    widget:OverrideText("")
    widget.edit_text:SetEditing(true)
end

local function oncancel(inst, doer, widget)
    if not widget.isopen then
        return
    end
    
    EndWriting(inst, doer)
    
    widget:Close()
end

local config =
{
    menuoffset = Vector3(6, -250, 0),

    cancelbtn   = { text = "Cancel",    control = CONTROL_CANCEL, },
    middlebtn   = { text = "Clear",     control = CONTROL_MENU_MISC_1, },
    acceptbtn   = { text = "Accept",    control = CONTROL_ACCEPT, },
    lastpagebtn = { text = "Last Page", control = CONTROL_ZOOM_IN, },
    nextpagebtn = { text = "Next Page", control = CONTROL_ZOOM_OUT, },
}

local TextEdit = Class(AbsTextEdit, function(self, font, size, text)
    AbsTextEdit._ctor(self, font, size, text)
    
    self.pass_controls_to_screen = {}
end)

function TextEdit:SetPassControlToScreen(control, pass)
    self.pass_controls_to_screen[control] = pass or nil
end

function TextEdit:OnControl(control, down)
    if AbsTextEdit._base._base.OnControl(self, control, down) then return true end

    --gobble up extra controls
    if self.editing and (control ~= CONTROL_CANCEL and control ~= CONTROL_OPEN_DEBUG_CONSOLE and control ~= CONTROL_ACCEPT) then
        return not self.pass_controls_to_screen[control]
    end

    if self.editing and not down and control == CONTROL_CANCEL then
        self:SetEditing(false)
        TheInput:EnableDebugToggle(true)
        return not self.pass_controls_to_screen[control]
    end
    --[[
    if self.enable_accept_control and not down and control == CONTROL_ACCEPT then
        if not self.editing then
            self:SetEditing(true)
            return not self.pass_controls_to_screen[control]
        else
            -- Previously this was being done only in the OnRawKey, but that doesnt handle controllers very well, this does.
            self:OnProcess()
            return not self.pass_controls_to_screen[control]
        end
    end
    --]]
    if not down and control == CONTROL_ACCEPT then
        self:SetEditing(true)
        return not self.pass_controls_to_screen[control]
    end
end

--[[
SCALEMODE_NONE = 0
SCALEMODE_FILLSCREEN = 1
SCALEMODE_PROPORTIONAL = 2
SCALEMODE_FIXEDPROPORTIONAL = 3
SCALEMODE_FIXEDSCREEN_NONDYNAMIC = 4
--]]
local WriteableWidget = Class(Screen, function(self, owner, writeable)
    Screen._ctor(self, "NotebookScreen")

    self.owner = owner
    self.writeable = writeable

    self.isopen = false

    self._scrnw, self._scrnh = TheSim:GetScreenSize()

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)
    
    self.scalingroot = self:AddChild(Widget("writeablewidgetscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())

    self.root = self.scalingroot:AddChild(Widget("writeablewidgetroot"))
    self.root:SetScale(.6, .6, .6)
    self.root:SetPosition(0, 150, 0)

    -- Click on the screen will quit Notebook
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function()
        print("KK-TEST> Widget 'black' is busted.")
        oncancel(self.writeable, self.owner, self)
    end
    
    self.bgimage = self.root:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
    
    --[[
    Built-in fonts in Don't Starve:
    DEFAULTFONT, DIALOGFONT, TITLEFONT, UIFONT, BUTTONFONT,
    NUMBERFONT, TALKINGFONT, TALKINGFONT_WATHGRITHR,
    SMALLNUMBERFONT, BODYTEXTFONT,
    --]]
    self.edit_text = self.root:AddChild(TextEdit(DEFAULTFONT, 50, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    self.edit_text:SetPosition(0, 0, 0)
    self.edit_text:SetRegionSize(800, 480)
    self.edit_text:SetHAlign(ANCHOR_MIDDLE)
    self.edit_text:SetVAlign(ANCHOR_MIDDLE)
    self.edit_text:SetTextLengthLimit(TITLE_LENGTH_LIMIT)
    
    self.edit_text:OnControl(CONTROL_ACCEPT, false)
    self.edit_text.OnTextInputted = function()
        MarkCurrent(self)
    end
    self.edit_text.OnTextEntered = function()
        self:OnControl(CONTROL_ACCEPT, false)
    end
    self.default_focus = self.edit_text
    -------------------------------------------------------------------------------
    -- Pages
    -------------------------------------------------------------------------------
    self.page = 0
    -- Load all pages into this widget
    self.pages = writeable.components.notebook:GetPages()
    self.marks = {}
    -- Initialize text area
    self:OverrideText(GetTitle(self))
    -------------------------------------------------------------------------------
    -- Buttons
    -------------------------------------------------------------------------------
    self.buttons = {}
    -- Cancel
    table.insert(self.buttons, {
        text = config.cancelbtn.text,
        cb = function()
            print("KK-TEST> Button 'Cancel' is pressed.")
            oncancel(self.writeable, self.owner, self)
        end,
        control = config.cancelbtn.control
    })
    -- Clear
    table.insert(self.buttons, {
        text = config.middlebtn.text,
        cb = function()
            print("KK-TEST> Button 'Clear' is pressed.")
            onmiddle(self.writeable, self.owner, self)
            MarkCurrent(self)
        end,
        control = config.middlebtn.control
    })
    -- Accept
    table.insert(self.buttons, {
        text = config.acceptbtn.text,
        cb = function()
            print("KK-TEST> Button 'Accept' is pressed.")
            onaccept(self.writeable, self.owner, self)
        end,
        control = config.acceptbtn.control
    })
    -- Last Page
    table.insert(self.buttons, {
        text = config.lastpagebtn.text,
        cb = function()
            print("KK-TEST> Button 'Last Page' is pressed.")
            LastPage(self)
        end,
        control = config.lastpagebtn.control
    })
    -- Next Page
    table.insert(self.buttons, {
        text = config.nextpagebtn.text,
        cb = function()
            print("KK-TEST> Button 'Next Page' is pressed.")
            NextPage(self)
        end,
        control = config.nextpagebtn.control
    })
    
    for i, v in ipairs(self.buttons) do
        if v.control ~= nil then
            self.edit_text:SetPassControlToScreen(v.control, true)
        end
    end
    
    local menuoffset = config.menuoffset or Vector3(0, 0, 0)
    if TheInput:ControllerAttached() then
        local spacing = 200
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "none"))
        self.menu:SetTextSize(40)
        local w = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    else
        local spacing = 160
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "small"))
        self.menu:SetTextSize(35)
        self.menu:SetPosition(menuoffset.x - .5 * spacing * (#self.buttons - 1), menuoffset.y, menuoffset.z)
    end
    -------------------------------------------------------------------------------
    
    self.isopen = true
    self:Show()

    if self.bgimage then
        if self.bgimage.texture then
            self.bgimage:Show()
        end
    end
end)

function WriteableWidget:OnBecomeActive()
    self._base.OnBecomeActive(self)
    if self.edit_text then
        self.edit_text:SetFocus()
        self.edit_text:SetEditing(true)
    end
end

function WriteableWidget:Close()
    if self.isopen then
        --if self.container ~= nil then
            --if self.owner ~= nil and self.owner.components.playeractionpicker ~= nil then
                --self.owner.components.playeractionpicker:UnregisterContainer(self.container)
            --end
        --end

        self.writeable = nil

        if self.bgimage then
            if self.bgimage.texture then
                self.bgimage:Hide()
            end
        end

        if self.black then
            self.black:Kill()
        end
        if self.edit_text then
            self.edit_text:Kill()
        end
        if self.menu then
            self.menu:Kill()
        end
        if self.bgimage then
            self.bgimage:Kill()
        end

        self.isopen = false

        self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
    end
end

function WriteableWidget:OverrideText(text)
    if self.edit_text then
        self.edit_text:SetString(text)
        self.edit_text:SetFocus()
    end
end

function WriteableWidget:GetText()
    return self.edit_text and self.edit_text:GetString() or ""
end

function WriteableWidget:OnControl(control, down)
    if WriteableWidget._base.OnControl(self,control, down) then return true end

    -- gjans: This makes it so that if the text box loses focus and you click
    -- on the bg, it presses accept. Kind of weird behaviour. I'm guessing
    -- something like it is needed for controllers, but it's not exaaaactly
    -- this.
    --if control == CONTROL_ACCEPT and not down then
        --if #self.buttons >= 1 and self.buttons[#self.buttons] then
            --self.buttons[#self.buttons].cb()
            --return true
        --end
    --end
    if not down and self.buttons then
        for i, v in ipairs(self.buttons) do
            if control == v.control and v.cb ~= nil then
                v.cb()
                return true
            end
        end
        if control == CONTROL_OPEN_DEBUG_CONSOLE then
            return true
        end
    end
end

local function ShowWriteableWidget(player, playerhud, book)
    local screen = WriteableWidget(playerhud.owner, book)
    if screen == nil then
        return false, "Fail to make screen!"
    end
    TheFrontEnd:PushScreen(screen)
    -- TODO is this necessary? @see WriteableWidget:OnBecomeActive
    if TheFrontEnd:GetActiveScreen() == screen and screen.edit_text then
        -- Have to set editing AFTER pushscreen finishes.
        screen.edit_text:SetEditing(true)
    end
    return true, "NotebookScreen is created successfully!"
end

local function MakeWriteableWidget(inst, doer)
    if inst and inst.prefab == "book_notebook" then
        if doer and doer.HUD then
            return ShowWriteableWidget(doer, doer.HUD, inst)
        end
        return false, "Invalid player"
    else
        return false, "Invalid prefab making NotebookScreen!"
    end
end

return MakeWriteableWidget