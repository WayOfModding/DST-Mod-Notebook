local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local STRINGS = GLOBAL.STRINGS
local TECH = GLOBAL.TECH
local ACTIONS = GLOBAL.ACTIONS
local State = GLOBAL.State
local FRAMES = GLOBAL.FRAMES
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local ActionHandler = GLOBAL.ActionHandler
local SpawnPrefab = GLOBAL.SpawnPrefab
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS

local NotebookMod = {}

PrefabFiles =
{
    "book_notebook",
    "notebook_classified",
}

-- Strings
STRINGS.NAMES.BOOK_NOTEBOOK = "Notebook"
STRINGS.RECIPE_DESC.BOOK_NOTEBOOK = "Better ink than memory!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_NOTEBOOK = "Should I take down some notes?"
STRINGS.NOTEBOOK =
{
    BOOKTITLELEFT = "\"",
    BOOKTITLERIGHT = "\"",
}

--[[
Ingredient:
    2x      papyrus
Tabs:
    Tools
Requirement:
    None
--]]
AddRecipe("book_notebook", { Ingredient("papyrus", 2) }, RECIPETABS.TOOLS, TECH.NONE, nil, nil, nil, nil, nil, "images/book_notebook.xml", nil, nil)

AddPrefabPostInit("book_notebook", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:AddComponent("nbreader")
    end
end)

AddPlayerPostInit(function(inst)
    inst:AddComponent("nbreader")
end)

local action_nbread = AddAction("NBREAD", "Read", function(act)
    local targ = act.target or act.invobject
    if targ == nil then
        return false, "Action.Read: 'targ' is nil"
    end
    if act.doer == nil then
        return false, "Action.Read: 'act.doer' is nil"
    end
    if act.doer.components.nbreader == nil then
        return false, "Action.Read: 'act.doer.components.nbreader' is nil"
    end
    return act.doer.components.nbreader:Read(targ)
end)
action_nbread.mount_valid = true

AddComponentAction("INVENTORY", "nbreader", function(inst, doer, actions)
    if inst:HasTag("nbreader") then
        table.insert(actions, ACTIONS.NBREAD)
    end
end)

AddReplicableComponent("notebook")

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

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.NBREAD, "notebook"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.NBREAD, "notebook"))

NotebookMod.RPC =
{
    NOTEBOOK =
    {
        SetPages =
        {
            fn = function(book, doer, pages)
                if not (checkentity(book))
                then
                    printinvalid("SetPages", doer)
                    return
                end
                if book.components.notebook then
                    book:SetPages(doer, pages)
                end
            end,
        },
    },
}

for namespace, nstable in pairs(NotebookMod.RPC) do
    for name, attr in pairs(nstable) do
        AddModRPCHandler(namespace, name, attr.fn)
    end
end