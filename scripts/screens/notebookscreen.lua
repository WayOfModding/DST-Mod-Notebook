local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"
local json = require "json"

local function SetPages(book, pages, marks)
    print("KK-TEST> Function 'SetPages'(@notebookscreen) is invoked.")
    
    -- Filter pages that ain't modified
    for page, mark in pairs(marks) do
        marks[page] = pages[page]
    end
    
    book.replica.notebook:SetPages(marks)
end

local function EndWriting(book, player)
    book.replica.notebook:EndWriting(player)
end

local function GetPage(self, page)
    local res = self.pages[page] or ""
    print("KK-TEST> Function Screen:GetPage() returns \"" .. res .. "\".")
    return res
end
local function GetTitle(self)
    local res = GetPage(self, 0)
    print("KK-TEST> Function Screen:GetTitle() returns \"" .. res .. "\".")
    return res
end
local function OnPageUpdated(self, page)
    print("KK-TEST> Function Screen:OnPageUpdated() is invoked.")
    local res = GetPage(self, page) or ""
    if page == 0 then
        self.edit_text:SetHAlign(ANCHOR_MIDDLE)
    else
        self.edit_text:SetHAlign(ANCHOR_LEFT)
    end
    self.edit_text:SetString(res)
end
local function MarkPage(self, page)
    print("KK-TEST> Function Screen:MarkPage() is invoked.")
    local text = self.edit_text:GetString() or ""
    self.pages[page] = text
    self.marks[page] = true
end
local function MarkCurrent(self)
    print("KK-TEST> Function Screen:MarkCurrent() is invoked.")
    MarkPage(self, self.page)
end
local function UpdatePage(self, page)
    print("KK-TEST> Function Screen:UpdatePage() is invoked.")
    self.page = page
    OnPageUpdated(self, page)
end
local function LastPage(self)
    print("KK-TEST> Function Screen:LastPage() is invoked.")
    local oldpage = self.page
    local newpage = oldpage - 1
    if newpage < 0 then newpage = 0 end
    if newpage < oldpage then
        UpdatePage(self, newpage)
    end
    self.edit_text:SetEditing(true)
end
local function NextPage(self)
    print("KK-TEST> Function Screen:NextPage() is invoked.")
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

local function onclose(widget)
    print("KK-TEST> dumptable(pages):")
    dumptable(widget.pages)
    print("KK-TEST> dumptable(marks):")
    dumptable(widget.marks)
end

local function onaccept(inst, doer, widget)
    if not widget.isopen then
        return
    end
    
    SetPages(inst, widget.pages, widget.marks)

    if widget.config.acceptbtn.cb ~= nil then
        widget.config.acceptbtn.cb(inst, doer, widget)
    end

    widget.edit_text:SetEditing(false)
    EndWriting(inst, doer)
    widget:Close()
end

local function onmiddle(inst, doer, widget)
    if not widget.isopen then
        return
    end
    
    widget.edit_text:SetString("")
    widget.edit_text:SetEditing(true)
end

local function oncancel(inst, doer, widget)
    if not widget.isopen then
        return
    end
    
    EndWriting(inst, doer)

    if widget.config.cancelbtn.cb ~= nil then
        widget.config.cancelbtn.cb(inst, doer, widget)
    end

    widget:Close()
end

local config =
{
    prompt = "Notebook",
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -250, 0),

    cancelbtn = { text = "Cancel", cb = nil, control = CONTROL_CANCEL },
    middlebtn = { text = "Clear", cb = nil, control = CONTROL_MENU_MISC_2 },
    acceptbtn = { text = "Accept", cb = nil, control = CONTROL_ACCEPT },
    
    lastpagebtn = { text = "Last Page", cb = nil, control = CONTROL_ZOOM_IN },
    nextpagebtn = { text = "Next Page", cb = nil, control = CONTROL_ZOOM_OUT },
}

local WriteableWidget = Class(Screen, function(self, owner, writeable)
    Screen._ctor(self, "SignWriter")

    self.owner = owner
    self.writeable = writeable
    self.config = config

    self.isopen = false

    self._scrnw, self._scrnh = TheSim:GetScreenSize()

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.scalingroot = self:AddChild(Widget("writeablewidgetscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
    self.inst:ListenForEvent("continuefrompause", function()
        if self.isopen then
            self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
        end
    end, TheWorld)
    self.inst:ListenForEvent("refreshhudsize", function(hud, scale)
        if self.isopen then
            self.scalingroot:SetScale(scale)
        end
    end, owner.HUD.inst)

    self.root = self.scalingroot:AddChild(Widget("writeablewidgetroot"))
    self.root:SetScale(.6, .6, .6)

    -- Click on the screen will quit Notebook
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function() oncancel(self.writeable, self.owner, self) end

    self.bganim = self.root:AddChild(UIAnim())
    self.bganim:SetScale(1, 1, 1)
    -- Frame
    --self.bgimage = self.root:AddChild(Image("images/nbpanel.xml", "nbpanel.tex"))
    self.bgimage = self.root:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
    self.bganim:SetScale(1, 1, 1)

    --self.title = self.root:AddChild(Text(BUTTONFONT, 50))
    --self.title:SetPosition(0, 70, 0)
    --self.title:SetColour(0, 0, 0, 1)
    --self.title:SetString(self.config.prompt)

    --self.edit_text_bg = self.root:AddChild(Image("images/textboxes.xml", "textbox_long.tex"))
    --self.edit_text_bg:SetPosition(0, 5, 0)
    --self.edit_text_bg:ScaleToSize(480, 50)

    self.edit_text = self.root:AddChild(TextEdit(CODEFONT, 50, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    self.edit_text:SetForceEdit(true)
    self.edit_text:SetPosition(0, 200, 0)
    self.edit_text:SetRegionSize(800, 60)
    self.edit_text:SetHAlign(ANCHOR_MIDDLE)
    self.edit_text:SetVAlign(ANCHOR_TOP)
    --self.edit_text:SetFocusedImage(self.edit_text_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex")
    self.edit_text:SetTextLengthLimit(32)
    self.edit_text:EnableWordWrap(true)
    self.edit_text:EnableWhitespaceWrap(true)
    self.edit_text:EnableRegionSizeLimit(true)
    self.edit_text:EnableScrollEditWindow(false)

    -------------------------------------------------------------------------------
    -- Pages
    -------------------------------------------------------------------------------
    self.page = 0
    -- Load all pages into this widget
    self.pages = writeable.replica.notebook:GetPages()
    print("KK-TEST> @notebookscreen.lua self.pages=" .. json.encode(self.pages) .. "\ndumptable(self.pages):")
    dumptable(self.pages)
    self.marks = {}
    
    -- Initialize text area
    local title = GetTitle(self)
    self.edit_text:SetString(title)
    self.edit_text:SetFocus()
    print("KK-TEST> Text area is initialized: \"" .. title .. "\", \"" .. self.edit_text:GetString() .. "\"")
    
    -------------------------------------------------------------------------------
    -- Buttons
    -------------------------------------------------------------------------------
    self.buttons = {}
    -- Cancel
    table.insert(self.buttons, { text = config.cancelbtn.text, cb = function()
        print("KK-TEST> Button 'Cancel' is pressed.")
        oncancel(self.writeable, self.owner, self)
    end, control = config.cancelbtn.control })
    -- Clear
    table.insert(self.buttons, { text = config.middlebtn.text, cb = function()
        print("KK-TEST> Button 'Clear' is pressed.")
        MarkCurrent(self)
        onmiddle(self.writeable, self.owner, self)
    end, control = config.middlebtn.control })
    -- Accept
    table.insert(self.buttons, { text = config.acceptbtn.text, cb = function()
        print("KK-TEST> Button 'Accept' is pressed.")
        onaccept(self.writeable, self.owner, self)
    end, control = config.acceptbtn.control })
    -- Last Page
    table.insert(self.buttons, { text = config.lastpagebtn.text, cb = function()
        print("KK-TEST> Button 'Last Page' is pressed.")
        LastPage(self)
    end, control = config.lastpagebtn.control })
    -- Next Page
    table.insert(self.buttons, { text = config.nextpagebtn.text, cb = function()
        print("KK-TEST> Button 'Next Page' is pressed.")
        NextPage(self)
    end, control = config.nextpagebtn.control })

    for i, v in ipairs(self.buttons) do
        if v.control ~= nil then
            self.edit_text:SetPassControlToScreen(v.control, true)
        end
    end
    -------------------------------------------------------------------------------

    local menuoffset = config.menuoffset or Vector3(0, 0, 0)
    if TheInput:ControllerAttached() then
        local spacing = 150
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "none"))
        self.menu:SetTextSize(40)
        local w = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    else
        local spacing = 110
        self.menu = self.root:AddChild(Menu(self.buttons, spacing, true, "small"))
        self.menu:SetTextSize(35)
        self.menu:SetPosition(menuoffset.x - .5 * spacing * (#self.buttons - 1), menuoffset.y, menuoffset.z)
    end

    self.edit_text:OnControl(CONTROL_ACCEPT, false)
    self.edit_text.OnTextInputted = function()
        --print("KK-TEST> OnTextInputted: "..self:GetText())
        MarkCurrent(self)
    end
    self.edit_text.OnTextEntered = function()
        self:OnControl(CONTROL_ACCEPT, false)
    end
    self.edit_text:SetHelpTextApply("")
    self.edit_text:SetHelpTextCancel("")
    self.edit_text:SetHelpTextEdit("")
    self.default_focus = self.edit_text

    if config.bgatlas ~= nil and config.bgimage ~= nil then
        self.bgimage:SetTexture(config.bgatlas, config.bgimage)
    end

    if config.animbank ~= nil then
        self.bganim:GetAnimState():SetBank(config.animbank)
    end

    if config.animbuild ~= nil then
        self.bganim:GetAnimState():SetBuild(config.animbuild)
    end

    if config.pos ~= nil then
        self.root:SetPosition(config.pos)
    else
        self.root:SetPosition(0, 150, 0)
    end

    --if config.buttoninfo ~= nil then
        --if doer ~= nil and doer.components.playeractionpicker ~= nil then
            --doer.components.playeractionpicker:RegisterContainer(container)
        --end
    --end

    self.isopen = true
    self:Show()

    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end
end)

function WriteableWidget:OnBecomeActive()
    self._base.OnBecomeActive(self)
    self.edit_text:SetFocus()
    self.edit_text:SetEditing(true)
end

function WriteableWidget:Close()
    if self.isopen then
        onclose(self)
        --if self.container ~= nil then
            --if self.owner ~= nil and self.owner.components.playeractionpicker ~= nil then
                --self.owner.components.playeractionpicker:UnregisterContainer(self.container)
            --end
        --end

        self.writeable = nil

        if self.bgimage.texture then
            self.bgimage:Hide()
        else
            self.bganim:GetAnimState():PlayAnimation("close")
        end

        self.black:Kill()
        --self.title:Kill()
        self.edit_text:SetEditing(false)
        self.edit_text:Kill()
        --self.edit_text_bg:Kill()
        self.menu:Kill()

        self.isopen = false

        self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
    end
end

function WriteableWidget:OverrideText(text)
    self.edit_text:SetString(text)
    self.edit_text:SetFocus()
end

function WriteableWidget:GetText()
    return self.edit_text:GetString()
end

function WriteableWidget:SetValidChars(chars)
    self.edit_text:SetCharacterFilter(chars)
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
    if not down then
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

local function ShowWriteableWidget(player, playerhud, writeable)
    assert(player == playerhud.owner, "KK-TEST> player != playerhud.owner")
    local screen = WriteableWidget(playerhud.owner, writeable)
    playerhud:OpenScreenUnderPause(screen)
    if TheFrontEnd:GetActiveScreen() == screen then
        -- Have to set editing AFTER pushscreen finishes.
        screen.edit_text:SetEditing(true)
    end
    return screen
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
