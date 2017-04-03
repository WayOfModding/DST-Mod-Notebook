local makescreen = require("screens/notebookscreen")
local json = require("json")

local function setpages(self, pages)
    print("KK-TEST> Function 'setpages' is invoked.")
    local count = 0
    for page, text in pairs(pages) do
        self.pages[page] = text
        count = count + 1
    end
    print("KK-TEST> Pages changed: " .. tostring(count))
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
end,
nil,
{
    pages = function(self, newpages)
        print("KK-TEST> Setter of 'pages' is invoked.")
        if self.inst.replica.notebook then
            self.inst.replica.notebook:SetPages(newpages)
        end
    end
})

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

function Notebook:SetPages(pages)
    print("KK-TEST> Function 'Notebook:SetPages' is invoked.")
    if pages == nil then
        return false, "Nil parameter 'pages'"
    end
    if type(pages) == "string" then
        pages = json.decode(pages)
        assert(type(pages) == "table", "Error occurred while decoding json string!")
    elseif type(pages) ~= "table" then
        return false, "Invalid parameter type 'pages': " .. type(pages)
    end
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

return Notebook