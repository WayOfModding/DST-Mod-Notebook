local makescreen = require("screens/notebookscreen")
local json = require("json")

local function setpages(self, pages)
    print("KK-TEST> Function 'setpages' is invoked.")
    for page, text in pairs(pages) do
        self.pages[page] = text
    end
end

local Notebook = Class(function(self, inst)
    self.inst = inst
    --print("KK-TEST(notebook)>", dumptable(self.inst))
    
    self.pages = {}
    
    self.onclosepopups = function(doer)
        self:EndWriting(doer)
    end
    
    inst:AddTag("notebook")
    --inst:DoTaskInTime(0, RegisterNetListeners)
    
    inst.components.inspectable.getspecialdescription = function(inst, reader)
        local title = inst.components.notebook:GetTitle()
        if title and title ~= "" then
            return STRINGS.NOTEBOOK.BOOKTITLELEFT .. title .. STRINGS.NOTEBOOK.BOOKTITLERIGHT
        else
            print("KK-TEST> Inspectable component retrieves empty book title!")
            return nil
        end
    end
end)

function Notebook:OnSave()
    return { pages = self.pages }
end

function Notebook:OnLoad(data, newents)
    print("KK-TEST> Function Notebook:OnLoad(" .. json.encode(data) .. ") is invoked.")
    self.pages = data.pages
end

function Notebook:GetDebugString()
    return "Notebook" .. json.encode(self.pages)
end

function Notebook:Clear()
    self.pages = {}
end

function Notebook:BeginWriting(doer)
    -- Notify component update
    self.inst:StartUpdatingComponent(self)
    
    -- Trigger when the pop-up window is closed
    self.inst:ListenForEvent("ms_closepopups", self.onclosepopups, doer)
    self.inst:ListenForEvent("onremove", self.onclosepopups, doer)
    
    -- Make pop-up window
    if doer ~= nil and doer == ThePlayer then
        if doer.HUD == nil then
            return false, "Notebook:BeginWriting: 'doer.HUD' is nil"
        else
            return makescreen(self.inst, doer)
        end
    else
        return false, "KK-TEST> Invalid doer!"
    end
end

function Notebook:EndWriting(doer)
    self.inst:StopUpdatingComponent(self)
    
    self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, doer)
    self.inst:RemoveEventCallback("onremove", self.onclosepopups, doer)
end

function Notebook:GetPages()
    print("KK-TEST> Function Notebook:SetPages() is invoked.")
    return self.pages
end

function Notebook:GetPage(page)
    print("KK-TEST> Function Notebook:GetPage() is invoked.")
    return self:GetPages()[page] or ""
end

function Notebook:GetTitle()
    print("KK-TEST> Function Notebook:GetTitle() is invoked.")
    return self:GetPage(0)
end

function Notebook:SetPages(pages)
    print("KK-TEST> Function 'Notebook:SetPages' is invoked.")
    if pages == nil then
        return false, "Nil parameter 'pages'"
    end
    assert(type(pages) ~= "table", "Parameter 'pages' has invalid type!")
    setpages(self, pages)
    return true
end

-- Invoked when this component is removed from entity
function Notebook:OnRemoveFromEntity()
    self:EndWriting(self.inst.components.inventoryitem
        and self.inst.components.inventoryitem.owner
        or ThePlayer)
    self.inst:RemoveTag("notebook")
    self:Clear()
end

Notebook.OnRemoveEntity = Notebook.EndWriting

function Notebook:CanDoAction(action)
    return action == ACTIONS.NBREAD
end

-- @see playeractionpicker.lua
--      * CollectSceneActions(inst, actions, right)
--      * CollectUseActions(inst, target, actions, right)
--      * CollectPointActions(inst, pos, actions, right)
--      * CollectEquippedActions(inst, target, actions, right)
--      * CollectInventoryActions(inst, actions, right)
function Notebook:CollectInventoryActions(doer, actions)
    if doer.components.nbreader then
        table.insert(actions, ACTIONS.NBREAD)
    end
end

return Notebook