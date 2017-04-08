local makescreen = require("screens/notebookscreen")
local json = require("json")

local NotebookManager = Class(function(self)
    self.books = {}
    
    self.UpdateBook = function(self, notebook)
        self.books[notebook.inst.GUID] = notebook.pages
    end
    self.RemoveBook = function(self, notebook)
        self.books[notebook.inst.GUID] = nil
    end
    self.GetBook = function(self, notebook)
        self:RemoveBook(notebook)
        return self.books[notebook.inst.GUID] or {}
    end
end)()

local function setpages(self, pages)
    print("KK-TEST> Function 'setpages' is invoked.")
    for page, text in pairs(pages) do
        self.pages[page] = text
    end
end

-- Notify client that a change is made to 'self.pages' in 'notebook' COMPONENT
local function notify(self)
    print("KK-TEST> Function 'notify' is invoked.")
    local notebook = self.inst.replica.notebook
    assert(notebook ~= nil, "KK-TEST> Field 'inst.replica.notebook' not found!")
    local pages = json.encode(self.pages)
    print("KK-TEST> Pushing newpages to clients: \"" .. pages .. "\"")
    notebook.newpages:set_local(pages)
    notebook.newpages:set(pages)
    NotebookManager:UpdateBook(self)
end

local Notebook = Class(function(self, inst)
    self.inst = inst
    --print("KK-TEST(notebook)>", dumptable(self.inst))
    
    self.pages = {}
    
    self.onclosepopups = function(doer)
        self:EndWriting(doer)
    end
    -- test
    local function test()
        print("========================= Notebook Information =========================\nGUID="..tostring(inst.GUID))
        dumptable(self.pages)
        print("========================= Notebook Manager Info =========================")
        dumptable(NotebookManager.books)
        print()
    end
    -- invoked by 'EntityScript:RemoveFromScene'
    self.onenterlimbo = function()
        print("KK-TEST> Function 'onenterlimbo' is invoked! Item 'Notebook' is moved into inventory.")
        test()
    end
    -- invoked by 'EntityScript:ReturnToScene'
    self.onexitlimbo = function()
        print("KK-TEST> Function 'onexitlimbo' is invoked! Item 'Notebook' is moved out of inventory.")
        test()
    end
    
    inst:AddTag("notebook")
    --inst:DoTaskInTime(0, RegisterNetListeners)
    
    inst.components.inspectable.getspecialdescription = function(inst, reader)
        local title = inst.replica.notebook:GetTitle()
        if title and title ~= "" then
            return STRINGS.NOTEBOOK.BOOKTITLELEFT .. title .. STRINGS.NOTEBOOK.BOOKTITLERIGHT
        else
            print("KK-TEST> Inspectable component retrieves empty book title!")
            return nil
        end
    end
    
    inst:ListenForEvent("enterlimbo", self.onenterlimbo)
    inst:ListenForEvent("exitlimbo", self.onexitlimbo)
end)

function Notebook:OnSave()
    return { pages = self.pages }
end

function Notebook:OnLoad(data, newents)
    print("KK-TEST> Function Notebook:OnLoad(" .. json.encode(data) .. ") is invoked.")
    self.pages = data.pages
    notify(self)
end

function Notebook:GetDebugString()
    return "Notebook" .. json.encode(self.pages)
end

local function Clear(self)
    self.pages = {}
    notify(self)
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
        print("KK-TEST> Decoding RPC string: \"" .. pages .. "\"")
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
    
    self.inst:RemoveEventCallback("enterlimbo", self.onenterlimbo)
    self.inst:RemoveEventCallback("exitlimbo", self.onexitlimbo)
end

Notebook.OnRemoveEntity = Notebook.EndWriting

function Notebook:Destroy()
    NotebookManager:RemoveBook(self)
end

return Notebook