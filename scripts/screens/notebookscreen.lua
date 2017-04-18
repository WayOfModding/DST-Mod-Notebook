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
    print("KK-TEST> Function \"SetPages\" is invoked in notebookscreen.lua.")
    
    -- Filter pages that ain't modified
    print("----------- SetPages -----------")
    for page, mark in pairs(marks) do
        marks[page] = pages[page]
        print(page, pages[page])
    end
    print("--------------------------------")
    
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
end

local function onaccept(widget)
    print("Function \"onaccept\" is invoked in notebookscreen.lua.")
    if not widget.isopen then
        return
    end
    
    SetPages(widget.writeable, widget.pages, widget.marks)
    
    widget:Close()
end

local function onmiddle(widget)
    print("KK-TEST> Function \"onmiddle\" is invoked in notebookscreen.lua.")
    if not widget.isopen then
        return
    end
    
    widget:OverrideText("")
end

local function oncancel(widget)
    print("KK-TEST> Function \"oncancel\" is invoked in notebookscreen.lua.")
    if not widget.isopen then
        return
    end
    
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
local NotebookScreen = Class(Screen, function(self, owner, writeable)
    Screen._ctor(self, "NotebookScreen")

    self.owner = owner
    self.writeable = writeable

    self.isopen = false

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)
    
    self.scalingroot = self:AddChild(Widget("NotebookScreenScalingRoot"))
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

    self.root = self.scalingroot:AddChild(Widget("NotebookScreenRoot"))
    self.root:SetScale(.6, .6, .6)
    self.root:SetPosition(0, 150, 0)
    
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
    local buttons = {}
    -- Cancel
    table.insert(buttons, {
        text = config.cancelbtn.text,
        cb = function()
            print("KK-TEST> Button 'Cancel' is pressed.")
            oncancel(self)
        end,
        control = config.cancelbtn.control
    })
    -- Clear
    table.insert(buttons, {
        text = config.middlebtn.text,
        cb = function()
            print("KK-TEST> Button 'Clear' is pressed.")
            onmiddle(self)
            MarkCurrent(self)
        end,
        control = config.middlebtn.control
    })
    -- Accept
    table.insert(buttons, {
        text = config.acceptbtn.text,
        cb = function()
            print("KK-TEST> Button 'Accept' is pressed.")
            onaccept(self)
        end,
        control = config.acceptbtn.control
    })
    -- Last Page
    table.insert(buttons, {
        text = config.lastpagebtn.text,
        cb = function()
            print("KK-TEST> Button 'Last Page' is pressed.")
            LastPage(self)
        end,
        control = config.lastpagebtn.control
    })
    -- Next Page
    table.insert(buttons, {
        text = config.nextpagebtn.text,
        cb = function()
            print("KK-TEST> Button 'Next Page' is pressed.")
            NextPage(self)
        end,
        control = config.nextpagebtn.control
    })
    
    -- when you push a control with your mouse, the following seems
    -- kidna useless, there can only be one possible control value
    -- if there is a 'TextProcessorWidget'(@see FrontEnd:OnControl)
    -- which is "CONTROL_ACCEPT"
    -- unless you push such control through a keyboard or a controller
    -- pressing ESC grants you CONTROL_CANCEL
    for i, v in ipairs(buttons) do
        if v.control ~= nil then
            self.edit_text:SetPassControlToScreen(v.control, true)
        end
    end
    
    -- @see widgets/menu.lua
    local menuoffset = config.menuoffset or Vector3(0, 0, 0)
    if TheInput:ControllerAttached() then
        local spacing = 150
        self.menu = self.root:AddChild(Menu(buttons, spacing, true, "none"))
        self.menu:SetTextSize(40)
        local w = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    else
        local spacing = 110
        self.menu = self.root:AddChild(Menu(buttons, spacing, true, "small"))
        self.menu:SetTextSize(35)
        self.menu:SetPosition(menuoffset.x - .5 * spacing * (#buttons - 1), menuoffset.y, menuoffset.z)
    end
    
    assert(#self.menu.items == #buttons, "KK-TEST> Fail to create enough buttons.")
    for i, v in ipairs(self.menu.items) do
        -- weird game design
        v:SetControl(CONTROL_ACCEPT)
    end
    
    -------------------------------------------------------------------------------
    self.edit_text.OnTextInputted = function()
        --print("KK-TEST> OnTextInputted: "..self:GetText())
        MarkCurrent(self)
    end
    self.edit_text.OnGainFocus = function(self)
        print("KK-TEST> Widget 'edit_text' gains focus.")
    end
    self.edit_text.OnLoseFocus = function(self)
        print("KK-TEST> Widget 'edit_text' loses focus.")
    end
    --[[
    # TextEdit:OnTextEntered(self:GetString())
        # TextEdit:OnProcess()
            # TextEdit:OnControl(control, down)
            # TextEdit:OnRawKey(key, down)
    --]]
    self.edit_text.OnTextEntered = function(text)
        --self:OnControl(CONTROL_ACCEPT, false)
    end
    -- @invalid in DS
    self.edit_text:SetHelpTextApply("")
    -- @invalid in DS
    self.edit_text:SetHelpTextCancel("")
    -- @invalid in DS
    self.edit_text:SetHelpTextEdit("")
    -- @see widgets/screen
    self.default_focus = self.edit_text
    
    self:Show()
end)

function NotebookScreen:Show()
    NotebookScreen._base.Show(self)
    
    self.isopen = true
    if self.bgimage and self.bgimage.texture then
        self.bgimage:Show()
    end
    if self.edit_text then
        self.edit_text.inst.TextWidget:ShowEditCursor(false)
    end
end

function NotebookScreen:Close()
    print("KK-TEST> Function \"NotebookScreen:Close\" is invoked!")
    if self.isopen then
        self.edit_text:SetEditing(false)
        EndWriting(self.writeable)
        
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
Call stack 'NotebookScreen:OverrideText'
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
function NotebookScreen:OverrideText(text)
    print("KK-TEST> Function \"NotebookScreen:OverrideText\" is invoked!")
    if self.edit_text then
        self.edit_text:SetString(text)
    end
end

function NotebookScreen:GetText()
    return self.edit_text and self.edit_text:GetString() or ""
end

local function PushScreen(screen)
    if screen == nil then return end
    TheFrontEnd:PushScreen(screen)
end

function NotebookScreen:PushScreen()
    local screenstack = TheFrontEnd.screenstack
    local stackdepth = #screenstack
    for i = stackdepth, 1, -1 do
        if screenstack[i] == self then
            return false
        end
    end
    PushScreen(self)
    return true
end

local function PopScreen(screen)
    if screen == nil then return end
    local self = TheFrontEnd
    self.focus_locked = false
    self:SetForceProcessTextInput(false)
    TheInputProxy:FlushInput()
    screen:OnBecomeInactive()
    table.remove(self.screenstack, #self.screenstack)
    -- I don't want to destroy it yet
    --screen:OnDestroy()
    self.screenroot:RemoveChild(screen)
    if #self.screenstack > 0 and screen ~= self.screenstack[#self.screenstack] then
        self.screenstack[#self.screenstack]:SetFocus()
        self.screenstack[#self.screenstack]:OnBecomeActive()
        self:Update(0)
    end
end

function NotebookScreen:PopScreen()
    local screenstack = TheFrontEnd.screenstack
    local stackdepth = #screenstack
    if stackdepth > 0 and screenstack[stackdepth] == self then
        PopScreen(self)
        return true
    end
    return false
end
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
--[[
!!! BUGGY DUE TO KLEI !!!
@see FrontEnd:OnControl
[quote]
    -- map CONTROL_PRIMARY to CONTROL_ACCEPT for buttons
    -- while editing a text box and hovering over something else,
    -- consume the accept button
    -- (the raw key handlers will deal with it).
[/quote]
CONTROL_PRIMARY:    Mouse Left Button
CONTROL_SECONDARY:  Mouse Right Button
--]]
function NotebookScreen:OnControl(control, down)
    print(string.format(
        "KK-TEST> Function \"NotebookScreen:OnControl('%s', '%s')\" is invoked!",
        GetControlName(control), tostring(down)
    ))
    if NotebookScreen._base.OnControl(self, control, down) then
        --[[<Widget:OnControl(control, down)
        -- Pass control to its parent if not focused
        if not self.focus then return false end
        -- Traverse its children
        for k,v in pairs (self.children) do
            if v.focus and v:OnControl(control, down) then return true end
        end
        -- Handle scroll list
        if self.parent_scroll_list and (control == CONTROL_SCROLLBACK or control == CONTROL_SCROLLFWD) then
            return self.parent_scroll_list:OnControl(control, down, true)
        end
        -- Pass control to its parent
        return false
        --]]
        return true
    end
    
    if down then
        print("KK-TEST> Ignore KeyDown/ButtonDown event!")
        return false
        
    elseif control == CONTROL_TOGGLE_DEBUGRENDER
        or control == CONTROL_INSPECT_SELF
        -- push pause screen
        or control == CONTROL_PAUSE
        -- push new text input screen
        or control == CONTROL_TOGGLE_SAY
        or control == CONTROL_TOGGLE_WHISPER
        or control == CONTROL_TOGGLE_SLASH_COMMAND
    then
        -- consumes some controls
        return false
    -- this is removed because such condition is
    -- already handled by 'NotebookScreen._base.OnControl'
    
    end
    
    print("KK-TEST> No appropriate control is handled!")
    return false
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
    local screen = NotebookScreen(player, book)
    if screen == nil then
        return false, "Fail to make screen!"
    end
    playerhud:OpenScreenUnderPause(screen)
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
