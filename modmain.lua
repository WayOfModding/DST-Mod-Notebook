local require = GLOBAL.require
local assert = GLOBAL.assert

local NotebookMod = {}

PrefabFiles =
{
    "book_notebook",
}

------------------------------------------------------------------------
local STRINGS = GLOBAL.STRINGS
-- Strings
STRINGS.NAMES.BOOK_NOTEBOOK = "Notebook"
STRINGS.RECIPE_DESC.BOOK_NOTEBOOK = "Better ink than memory!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_NOTEBOOK = "Should I take down some notes?"
STRINGS.NOTEBOOK =
{
    BOOKTITLELEFT = "\"",
    BOOKTITLERIGHT = "\"",
}
------------------------------------------------------------------------
local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH

local recipe_notebook = Recipe("book_notebook", { Ingredient("papyrus", 2) }, RECIPETABS.TOOLS, TECH.NONE)

local resolvefilepath = GLOBAL.resolvefilepath
recipe_notebook.atlas = resolvefilepath("images/book_notebook.xml")

AddPlayerPostInit(function(inst)
    inst:AddComponent("nbreader")
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
    if targ == nil then
        local reason = "Action.Read: 'targ' is nil"
        print("KK-TEST> Action failed: " .. reason)
        return false, reason
    end
    if targ.components.notebook == nil then
        local reason = "Action.Read: 'targ.components.notebook' is nil"
        print("KK-TEST> Action failed: " .. reason)
        return false, reason
    end
    if act.doer == nil then
        local reason = "Action.Read: 'act.doer' is nil"
        print("KK-TEST> Action failed: " .. reason)
        return false, reason
    end
    if act.doer.components.nbreader == nil then
        local reason = "Action.Read: 'act.doer.components.nbreader' is nil"
        print("KK-TEST> Action failed: " .. reason)
        return false, reason
    end
    local result, reason = act.doer.components.nbreader:Read(targ)
    if result then
        return true
    else
        print("KK-TEST> Action failed: " .. reason)
        return false, reason
    end
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
        inst.AnimState:PlayAnimation("action_uniqueitem_pre")
        inst.AnimState:PushAnimation("book", false)
        inst.AnimState:Show("ARM_normal")
        if inst.components.inventory then
            inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and (inst.bufferedaction.target or inst.bufferedaction.invobject) or nil)
        end
    end,

    timeline =
    {
        TimeEvent(0, function(inst)
            local fxtoplay = inst.components.rider ~= nil and inst.components.rider:IsRiding() and "book_fx_mount" or "book_fx"
            local fx = SpawnPrefab(fxtoplay)
            fx.entity:SetParent(inst.entity)
            fx.Transform:SetPosition(0, 0.2, 0)
            inst.sg.statemem.book_fx = fx
        end),

        TimeEvent(28 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
        end),

        TimeEvent(54 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
        end),

        TimeEvent(58 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
            inst:PerformBufferedAction()
            inst.sg.statemem.book_fx = nil
        end),
    },

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        if inst.components.inventory
            and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        then
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
AddStategraphState("wilson_client", state_notebook)
------------------------------------------------------------------------
local ActionHandler = GLOBAL.ActionHandler
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.NBREAD, "notebook"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.NBREAD, "notebook"))
