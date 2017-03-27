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

local NotebookMod =
{
    DEBUG = true,
}

PrefabFiles =
{
    "book_notebook",
    "notebook_classified",
}

-- Strings
STRINGS.NAMES.BOOK_NOTEBOOK = "Notebook"
STRINGS.RECIPE_DESC.BOOK_NOTEBOOK = "Better ink than memory!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_NOTEBOOK = "Should I take down some notes?"

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
    if GLOBAL.TheWorld.ismastersim then
        inst:AddComponent("nbreader")
    end
end)

local action_nbread = AddAction("NBREAD", "Read", function(act)
    local targ = act.target or act.invobject
    if targ ~= nil
            and act.doer ~= nil
            and targ.components.notebook ~= nil
            and act.doer.components.nbreader ~= nil
    then
        return act.doer.components.nbreader:Read(targ)
    end
end)
action_nbread.mount_valid = true

AddComponentAction("INVENTORY", "nbreader", function(inst, doer, actions)
    if inst:HasTag("nbreader") then
        table.insert(actions, ACTIONS.NBREAD)
    end
end)

local state_notebook = State{
    name = "notebook",
    tags = { "doing" },
    -- get code from State{"book"} from SGwilson.lua
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("action_uniqueitem_pre")
        inst.AnimState:PushAnimation("book", false)
        inst.AnimState:Show("ARM_normal")
        inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and (inst.bufferedaction.target or inst.bufferedaction.invobject) or nil)
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
AddStategraphState("wilson_client", state_notebook)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.NBREAD, "notebook"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.NBREAD, "notebook"))

-- TODO: customize notebook widget
local Vector3 = GLOBAL.Vector3
local CONTROL_CANCEL = GLOBAL.CONTROL_CANCEL
local CONTROL_MENU_MISC_2 = GLOBAL.CONTROL_MENU_MISC_2
local CONTROL_ACCEPT = GLOBAL.CONTROL_ACCEPT
local notebook_config =
{
    prompt = "Notebook",
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -70, 0),

    cancelbtn = { text = "Cancel", cb = function(inst, doer, widget)
        if inst.components.notebook ~= nil then
            inst.components.notebook:EndWriting()
        end
    end, control = CONTROL_CANCEL },
    middlebtn = { text = "Clear", cb = function(inst, doer, widget)
        widget:OverrideText("")
    end, control = CONTROL_MENU_MISC_2 },
    acceptbtn = { text = "Accept", cb = function(inst, doer, widget)
        if inst.components.notebook ~= nil then
            inst.components.notebook.title = widget:GetText()
            inst.components.notebook:EndWriting()
        end
    end, control = CONTROL_ACCEPT },
}
NotebookMod.makescreen = function(inst, doer)
    if inst.prefab == "book_notebook" then
        print("KK-TEST:Function 'NotebookMod.makescreen' invoked.")
        if doer and doer.HUD then
            local screen = doer.HUD:ShowWriteableWidget(inst, notebook_config)
            screen:OverrideText(inst.components.notebook.title)
            return screen
        end
    end
end

GLOBAL.NotebookMod = NotebookMod

-- DEBUG
if NotebookMod and NotebookMod.DEBUG then
    local function IsNotebook(item)
        return item.prefab == "book_notebook"
    end
    
    local function DebugSimInit(inst)
        if inst and inst.components.inventory then
            if inst.components.inventory:FindItem(IsNotebook) then
                return
            end
            inst.components.inventory:GiveItem(SpawnPrefab("book_notebook"))
        end
    end

    AddSimPostInit(DebugSimInit)
end