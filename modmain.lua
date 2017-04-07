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
local checkentity = GLOBAL.checkentity
local checkstring = GLOBAL.checkstring
local assert = GLOBAL.assert

local DEBUG = true

PrefabFiles =
{
    "book_notebook",
}

-- Strings
STRINGS.NAMES.BOOK_NOTEBOOK = "Notebook"
STRINGS.RECIPE_DESC.BOOK_NOTEBOOK = "Better ink than memory!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_NOTEBOOK = "Should I take down some notes?"
STRINGS.NOTEBOOK =
{
    BOOKTITLELEFT   = "\"",
    BOOKTITLERIGHT  = "\"",
    BUTTON_CANCEL   = "Cancel",
    BUTTON_CLEAR    = "Clear",
    BUTTON_ACCEPT   = "Accept",
    BUTTON_LASTPAGE = "Last Page",
    BUTTON_NEXTPAGE = "Next Page",
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

AddPlayerPostInit(function(inst)
    -- Global variable 'TheWorld' is not yet initialized before getting into the game,
    -- caching it would cause a null pointer exception.
    
    -- Replicable components should only be added on server side!
    -- If a component is added on client side will cause duplicate replica exception!
    inst:AddComponent("nbreader")
    
    -- Spawn a book item in tester's inventory
    if DEBUG and inst.components.inventory then
        local item = SpawnPrefab("book_notebook")
        inst.components.inventory:GiveItem(item)
    end
end)

local action_nbread = AddAction("NBREAD", "Read", function(act)
    print("KK-TEST> Action 'Read' is made.")
    local targ = act.target or act.invobject
    local result = false
    local reason = nil
    if targ == nil then
        reason = "Action.Read: 'targ' is nil"
    elseif targ.replica.notebook == nil then
        reason = "Action.Read: 'targ.replica.notebook' is nil"
    elseif act.doer == nil then
        reason = "Action.Read: 'act.doer' is nil"
    elseif act.doer.components.nbreader == nil then
        reason = "Action.Read: 'act.doer.components.nbreader' is nil"
    else
        result, reason = act.doer.components.nbreader:Read(targ)
    end
    
    if not result then
        print("KK-TEST> Action failed: " .. reason)
    end
    return result, reason
end)
action_nbread.mount_valid = true

--[[
All possible component action categories: SCENE, USEITEM, POINT, EQUIPPED, INVENTORY, ISVALID
--]]
AddComponentAction("INVENTORY", "notebook", function(inst, doer, actions)
    if inst:HasTag("notebook") then
        table.insert(actions, ACTIONS.NBREAD)
    end
end)

-- This loads notebook_replica into book_notebook
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

local function printinvalid(rpcname, player)
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))

    --This event is for MODs that want to handle players sending invalid rpcs
    TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })
end

--[[
All available validation functions in networkclientrpc.lua
function checkbool(val)
function checknumber(val)
function checkuint(val)
function checkstring(val)
function checkentity(val)
optbool = checkbool
function optnumber(val)
function optuint(val)
function optstring(val)
function optentity(val)
--]]
local RPC_HANDLERS =
{
    NOTEBOOK =
    {
        -- Parameters:
        --  * book:     instance of prefab 'book_notebook'
        --  * pages:    string of pages table serialized by json
        SetPages = function(player, book, pages)
            print("KK-TEST> RPC handler 'SetPages' is invoked.")
            if not (checkentity(book)
                and checkstring(pages))
            then
                printinvalid("SetPages", player)
                return false, "Invalid RPC"
            end
            assert(book.components.notebook ~= nil, "KK-TEST> 'book.components.notebook' not found on server side!")
            return book.components.notebook:SetPages(pages)
        end,
    },
}

for namespace, nstable in pairs(RPC_HANDLERS) do
    for name, func in pairs(nstable) do
        AddModRPCHandler(namespace, name, func)
    end
end