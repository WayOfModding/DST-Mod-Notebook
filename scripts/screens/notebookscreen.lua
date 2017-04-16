local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"
local json = require "json"

require("util/debug")

-- Constants
local TITLE_LENGTH_LIMIT    = 16
local TEXT_LENGTH_LIMIT     = 256

local function SetPages(book, pages, marks)
    --print("KK-TEST> Function 'SetPages'(@notebookscreen) is invoked.")
    
    -- Filter pages that ain't modified
    for page, mark in pairs(marks) do
        marks[page] = pages[page]
    end
    
    book.replica.notebook:SetPages(marks)
end

local function EndWriting(book)
    book.replica.notebook:EndWriting()
end

local function GetPage(self, page)
    local res = self.pages[page]
    --print("KK-TEST> Function Screen:GetPage(" .. tostring(page) .. ") returns \"" .. res .. "\".")
    return res or ""
end
local function GetTitle(self)
    local res = GetPage(self, 0)
    --print("KK-TEST> Function Screen:GetTitle() returns \"" .. res .. "\".")
    return res
end
local function MarkPage(self, page)
    --print("KK-TEST> Function Screen:MarkPage(" .. tostring(page) .. ") is invoked.")
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
    self.page = page
    
    local res = GetPage(self, page)
    if page == 0 then
        self.edit_text:SetHAlign(ANCHOR_MIDDLE)
        self.edit_text:SetVAlign(ANCHOR_MIDDLE)
        self.edit_text:SetTextLengthLimit(TITLE_LENGTH_LIMIT)
    else
        self.edit_text:SetHAlign(ANCHOR_LEFT)
        self.edit_text:SetVAlign(ANCHOR_TOP)
        self.edit_text:SetTextLengthLimit(TEXT_LENGTH_LIMIT)
    end
    self:OverrideText(res)
end
local function LastPage(self)
    --print("KK-TEST> Function Screen:LastPage() is invoked.")
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
    print("Function 'onaccept' is invoked in notebookscreen.lua.")
    if not widget.isopen then
        return
    end
    
    SetPages(inst, widget.pages, widget.marks)

    widget.edit_text:SetEditing(false)
    EndWriting(inst)
    widget:Close()
end

local function onmiddle(inst, doer, widget)
    print("Function 'onmiddle' is invoked in notebookscreen.lua.")
    if not widget.isopen then
        return
    end
    
    widget:OverrideText("")
    widget.edit_text:SetEditing(true)
end

local function oncancel(inst, doer, widget)
    print("Function 'oncancel' is invoked in notebookscreen.lua.")
    if not widget.isopen then
        return
    end
    
    widget.edit_text:SetEditing(false)
    EndWriting(inst)
    widget:Close()
end

local config =
{
    menuoffset = Vector3(6, -250, 0),
    
    cancelbtn   = { text = STRINGS.NOTEBOOK.BUTTON_CANCEL,      control = CONTROL_CANCEL        },
    middlebtn   = { text = STRINGS.NOTEBOOK.BUTTON_CLEAR,       control = CONTROL_MENU_MISC_1   },
    acceptbtn   = { text = STRINGS.NOTEBOOK.BUTTON_ACCEPT,      control = CONTROL_ACCEPT        },
    lastpagebtn = { text = STRINGS.NOTEBOOK.BUTTON_LASTPAGE,    control = CONTROL_ZOOM_IN       },
    nextpagebtn = { text = STRINGS.NOTEBOOK.BUTTON_NEXTPAGE,    control = CONTROL_ZOOM_OUT      },
}

--[[
@see FrontEnd:OnMouseButton
--]]
local WriteableWidget = Class(Screen, function(self, owner, writeable)
    Screen._ctor(self, "SignWriter")

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
    
    --self.bgimage = self.root:AddChild(Image("images/nbpanel.xml", "nbpanel.tex"))
    self.bgimage = self.root:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
    
    -- TextEdit.ctor(font, size, text, colour)
    self.edit_text = self.root:AddChild(TextEdit(CODEFONT, 50, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    -- @invalid in DS
    self.edit_text:SetForceEdit(true)
    self.edit_text:SetPosition(0, 0, 0)
    self.edit_text:SetRegionSize(800, 480)
    self.edit_text:SetHAlign(ANCHOR_MIDDLE)
    self.edit_text:SetVAlign(ANCHOR_MIDDLE)
    self.edit_text:SetTextLengthLimit(TITLE_LENGTH_LIMIT)
    -- @invalid in DS
    self.edit_text:EnableWordWrap(true)
    -- @invalid in DS
    self.edit_text:EnableWhitespaceWrap(true)
    -- @invalid in DS
    self.edit_text:EnableRegionSizeLimit(true)
    -- @invalid in DS
    self.edit_text:EnableScrollEditWindow(false)
    -- @invalid in DS
    self.edit_text:SetAllowNewline(true)

    -------------------------------------------------------------------------------
    -- Pages
    -------------------------------------------------------------------------------
    self.page = 0
    -- Load all pages into this widget
    self.pages = writeable.replica.notebook:GetPages()
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
    
    -- @see widgets/menu.lua
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
    -------------------------------------------------------------------------------
    self.edit_text:OnControl(CONTROL_ACCEPT, false)
    self.edit_text.OnTextInputted = function()
        --print("KK-TEST> OnTextInputted: "..self:GetText())
        MarkCurrent(self)
    end
    -- @invalid in DS
    self.edit_text:SetHelpTextApply("")
    -- @invalid in DS
    self.edit_text:SetHelpTextCancel("")
    -- @invalid in DS
    self.edit_text:SetHelpTextEdit("")
    -- WHAT?
    self.default_focus = self.edit_text

    --if config.buttoninfo ~= nil then
        --if doer ~= nil and doer.components.playeractionpicker ~= nil then
            --doer.components.playeractionpicker:RegisterContainer(container)
        --end
    --end

    self.isopen = true
    self:Show()

    if self.bgimage then
        if self.bgimage.texture then
            self.bgimage:Show()
        end
    end
end)

function WriteableWidget:OnBecomeActive()
    print("KK-TEST> Function 'WriteableWidget:OnBecomeActive' is invoked!")
    self._base.OnBecomeActive(self)
    if self.edit_text then
        self.edit_text:SetEditing(true)
    end
end

function WriteableWidget:Close()
    if self.isopen then
        self.writeable = nil

        if self.bgimage then
            if self.bgimage.texture then
                self.bgimage:Hide()
            end
        end
        
        if self.menu then
            self.menu:Clear()
        end
        self.root:KillAllChildren()
        self.root:Kill()
        self.scalingroot:Kill()
        
        self.isopen = false
        
        self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
    end
end

--[[
Call stack 'WriteableWidget:OverrideText'
* TextEdit:SetString(str=text)
    * TextEdit:FormatString(str)
    * TextEditWidget:SetString(str)             -- native call
* TextEdit:SetEditing(editing=true)
    * TextEdit:SetFocus()
    * TextEdit:DoSelectedImage()
    * TheInput:EnableDebugToggle(false)
    * FrontEnd:SetForceProcessTextInput(true, self)
        -- @see <mod>/scripts/screens/notebookscreen.lua
        -- self.edit_text:SetForceEdit(true)
    * TextEdit:SetAllowNewline(true)
        -- @see widgets/textedit
        -- self.enable_accept_control = false
    * TextWidget:ShowEditCursor(self.editing)   -- native call
--]]
function WriteableWidget:OverrideText(text)
    if self.edit_text then
        self.edit_text:SetString(text)
        self.edit_text:SetEditing(true)
    end
end

function WriteableWidget:GetText()
    return self.edit_text and self.edit_text:GetString() or ""
end

--[[
# TextEdit:OnTextEntered(self:GetString())
    # TextEdit:OnProcess()
        # TextEdit:OnControl(control, down)
        # TextEdit:OnRawKey(key, down)
--]]
--[[
@see Widget:OnControl(control, down)
When a widget's OnControl is invoked,
    1) it returns false immediately,
    if it is not focused;
    2) it will pass control state to each
    of its children that is focused;
    3) it pass valid control state to its
    parent_scroll_list
    4) return false;
--]]
--[[
@see Widget:SetFocus
@see Widget:SetFocusFromChild
# Focus Chain
    When a widget is set focused, it will set
    its parent focused, and defocus all of
    its focused siblings.
    This procedure goes on and on until
    it reaches the root widget.
# Focus Path
    A widget will be set focused when:
    1) its 'SetFocus' is invoked directly;
    2) it is configured as 'focus_forward'
    of another widget whose 'SetFocus' gets
    invoked just now;
--]]
function WriteableWidget:OnControl(control, down)
    print(string.format(
        "KK-TEST> Function \"WriteableWidget:OnControl('%s', '%s')\" is invoked!",
        GetControlName(control), tostring(down)
    ))
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

--[[
@see screens/playerhud.lua
--]]
--[[
Call stack
* PlayerHud:OpenScreenUnderPause(screen)
    * FrontEnd:PushScreen(screen)
        * FrontEnd:SetForceProcessTextInput(false)
        * table.insert(self.screenstack, screen)
--]]
local function ShowWriteableWidget(player, playerhud, book)
    local screen = WriteableWidget(playerhud.owner, book)
    if screen == nil then
        return false, "Fail to make screen!"
    end
    playerhud:OpenScreenUnderPause(screen)
    -- TODO is this necessary? @see WriteableWidget:OnBecomeActive
    if TheFrontEnd:GetActiveScreen() == screen and screen.edit_text then
        -- Have to set editing AFTER pushscreen finishes.
        screen.edit_text:SetEditing(true)
    end
    return true, "NotebookScreen is created successfully!"
end

--[[
@see prefabs/player_common.lua
--]]
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
