local require = GLOBAL.require
local assert = GLOBAL.assert

local DEBUG = true
------------------------------------------------------------------
PrefabFiles =
{
    "book_notebook",
}

Assets =
{
    Asset("ANIM", "anim/book_notebook.zip"),
    
    Asset("IMAGE", "images/book_notebook.tex"),
    Asset("ATLAS", "images/book_notebook.xml"),
    
    Asset("IMAGE", "images/scoreboard.tex"),
    Asset("ATLAS", "images/scoreboard.xml"),
}

------------------------------------------------------------------------
local STRINGS = GLOBAL.STRINGS
-- Strings
STRINGS.NAMES.BOOK_NOTEBOOK = "Notebook"
STRINGS.RECIPE_DESC.BOOK_NOTEBOOK = "Better ink than memory!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_NOTEBOOK = "Should I take down some notes?"
STRINGS.NOTEBOOK    =
{
    BOOKTITLELEFT   = "\"",
    BOOKTITLERIGHT  = "\"",
    BUTTON_CANCEL   = "Cancel",
    BUTTON_CLEAR    = "Clear",
    BUTTON_ACCEPT   = "Accept",
    BUTTON_LASTPAGE = "Last Page",
    BUTTON_NEXTPAGE = "Next Page",
}
------------------------------------------------------------------------
local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH

local recipe_notebook = Recipe("book_notebook", { Ingredient("papyrus", 2) }, RECIPETABS.TOOLS, TECH.NONE)

local resolvefilepath = GLOBAL.resolvefilepath
recipe_notebook.atlas = resolvefilepath("images/book_notebook.xml")
------------------------------------------------------------------------
local SpawnPrefab = GLOBAL.SpawnPrefab

local function IsNotebook(inst)
    return inst.prefab == "book_notebook"
end

AddPlayerPostInit(function(inst)
    inst:AddComponent("nbreader")
    
    -- Spawn a book item in tester's inventory
    if DEBUG and inst.components.inventory
        and inst.components.inventory:FindItem(IsNotebook) == nil
    then
        local item = SpawnPrefab("book_notebook")
        inst.components.inventory:GiveItem(item)
    end
end)
------------------------------------------------------------------------
local ACTIONS = GLOBAL.ACTIONS
local Action = GLOBAL.Action

local action_nbread = Action()
action_nbread.id    = "NBREAD"
action_nbread.str   = "Read"
action_nbread.fn    = function(act)
    print("KK-TEST> Action 'Read' is made.")
    local targ = act.target or act.invobject
    local result = false
    local reason = nil
    if targ == nil then
        reason = "Action.Read: 'targ' is nil"
    elseif targ.components.notebook == nil then
        reason = "Action.Read: 'targ.components.notebook' is nil"
    elseif act.doer == nil then
        reason = "Action.Read: 'act.doer' is nil"
    elseif act.doer.components.nbreader == nil then
        reason = "Action.Read: 'act.doer.components.nbreader' is nil"
    else
        result, reason = act.doer.components.nbreader:Read(targ)
    end
    reason = reason or "Unknown"
    if not result then
        print("KK-TEST> Action 'Read' failed due to:\n\t" .. reason)
    end
    return result, reason
end
AddAction(action_nbread)
------------------------------------------------------------------------
local State = GLOBAL.State
local FRAMES = GLOBAL.FRAMES
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local SpawnPrefab = GLOBAL.SpawnPrefab
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS

local state_notebook = State{
    name = "notebook",
    tags = { "doing" },
    -- get code from State{"book"} from SGwilson.lua
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("book")
        inst.AnimState:OverrideSymbol("book_open", "player_actions_uniqueitem", "book_open")
        inst.AnimState:OverrideSymbol("book_closed", "player_actions_uniqueitem", "book_closed")
        inst.AnimState:OverrideSymbol("book_open_pages", "player_actions_uniqueitem", "book_open_pages")
        inst.AnimState:Show("ARM_normal")
        if inst.components.inventory.activeitem and inst.components.inventory.activeitem.components.book then
            inst.components.inventory:ReturnActiveItem()
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/use_book")
    end,
    
    timeline=
    {
        TimeEvent(0, function(inst)
            local fxtoplay = "book_fx"
            if inst.prefab == "waxwell" then
                fxtoplay = "waxwell_book_fx" 
            end       
            local fx = SpawnPrefab(fxtoplay)
            local pos = inst:GetPosition()
            fx.Transform:SetRotation(inst.Transform:GetRotation())
            fx.Transform:SetPosition( pos.x, pos.y - .2, pos.z ) 
            inst.sg.statemem.book_fx = fx
        end),

        TimeEvent(28*FRAMES, function(inst) 
            if inst.prefab == "waxwell" then
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_dark")
            else
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
            end
        end),

        TimeEvent(58*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
            inst:PerformBufferedAction()
            inst.sg.statemem.book_fx = nil
        end),

        TimeEvent(62*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
        end),
    },
    
    events=
    {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
    
    onexit = function(inst)
        if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
            inst.AnimState:Show("ARM_carry") 
            inst.AnimState:Hide("ARM_normal")
        end
        if inst.sg.statemem.book_fx then
            inst.sg.statemem.book_fx:Remove()
            inst.sg.statemem.book_fx = nil
        end
    end,
}

AddStategraphState("wilson", state_notebook)
------------------------------------------------------------------------
local ActionHandler = GLOBAL.ActionHandler
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.NBREAD, "notebook"))
