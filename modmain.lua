local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local STRINGS = GLOBAL.STRINGS
local TECH = GLOBAL.TECH

PrefabFiles = 
{
"book_notebook",
}

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
local recipe_nb = AddRecipe("book_notebook", { Ingredient("papyrus", 2) }, RECIPETABS.TOOLS, TECH.NONE)
recipe_nb.atlas = "images/inventoryimages/book_notebook.xml"
--[[
AddPlayerPostInit(function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:AddComponent("notebook_handler")
    end
end)

AddAction("READ_NOTEBOOK", "Read", function(act)
    local targ = act.target or act.invobject
    if targ ~= nil and
            act.doer ~= nil and
            targ.components.notebook_context ~= nil and
            act.doer.components.notebook_handler ~= nil then
        act.doer.components.notebook_handler:Read(targ)
        return true
    else
        return false
    end
end)

AddComponentAction("SCENE", "notebook_handler", function(inst, doer, actions, right)
    if right then
        if inst:HasTag("notebook") then
            table.insert(actions, GLOBAL.ACTIONS.READ_NOTEBOOK)
        end
    end
end)

local state_read_notebook = GLOBAL.State{
    name = "readn",
    tags = { "doing", "busy" },
    
}
--]]