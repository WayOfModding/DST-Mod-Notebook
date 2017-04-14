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
        local res = self.books[notebook.inst.GUID]
        self:RemoveBook(notebook)
        return res or {}
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
end

local Notebook = Class(function(self, inst)
    self.inst = inst
    --print("KK-TEST(notebook)>", dumptable(self.inst))
    
    self.pages = {}
    self.writer = nil
    
    self.onclosepopups = function(doer)
        if doer == self.writer then
            self:EndWriting()
        end
    end
    -- test
    -- To remove item from inventory will trigger 'exitlimbo'
    -- To hold item in hand will trigger 'enterlimbo'
    -- To drop item on the ground will trigger 'exitlimbo'
    local function test()
        print("------------------------- Notebook Information -------------------------",
            "\n\t\tGUID="..tostring(inst.GUID),
            "\n\t\tpages="..tostring(json.encode(self.pages)))
        print("------------------------- Notebook Manager Info ------------------------",
            "\n\t\tNotebookManager.books="..tostring(json.encode(NotebookManager.books)))
    end
    -- invoked by 'EntityScript:RemoveFromScene'
    self.onenterlimbo = function()
        print("========================================================================")
        print("KK-TEST> Function 'onenterlimbo' is invoked!\n\t\tItem 'Notebook' is moved into inventory.")
        --test()
        print("========================================================================")
        --self.pages = NotebookManager:GetBook(self)
    end
    -- invoked by 'EntityScript:ReturnToScene'
    self.onexitlimbo = function()
        print("========================================================================")
        print("KK-TEST> Function 'onexitlimbo' is invoked!\n\t\tItem 'Notebook' is moved out of inventory.")
        --test()
        print("========================================================================")
        --NotebookManager:UpdateBook(self)
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
    print("KK-TEST> Function Notebook:OnSave() is invoked.")
    return { pages = self.pages }
end

function Notebook:OnLoad(data, newents)
    print("KK-TEST> Function Notebook:OnLoad() is invoked.")
    self.pages = data.pages or {}
    notify(self)
end

function Notebook:GetDebugString()
    --print("KK-TEST> Function 'Notebook:GetDebugString' is invoked.")
    return "Notebook" .. json.encode(self.pages)
end

local function Clear(self)
    self.pages = {}
    notify(self)
end

function Notebook:BeginWriting(doer)
    print("KK-TEST> Function 'Notebook:BeginWriting' is invoked.")
    if self.writer ~= nil then
        print("KK-TEST> Already writing!")
        return
    end
    -- Notify component update
    self.inst:StartUpdatingComponent(self)
    self.writer = doer
    
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

function Notebook:EndWriting()
    print("KK-TEST> Function 'Notebook:EndWriting' is invoked.")
    if self.writer == nil then
        print("KK-TEST> Already NOT writing!")
        return
    end
    self.inst:StopUpdatingComponent(self)
    
    self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, self.writer)
    self.inst:RemoveEventCallback("onremove", self.onclosepopups, self.writer)
    
    self.writer = nil
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

--------------------------------------------------------------------------
--Check for auto-closing conditions
--------------------------------------------------------------------------

function Writeable:OnUpdate(dt)
    if self.writer == nil then
        self.inst:StopUpdatingComponent(self)
    elseif (self.writer.components.rider ~= nil
            and self.writer.components.rider:IsRiding())
        or not (self.writer:IsNear(self.inst, 3)
            and CanEntitySeeTarget(self.writer, self.inst))
    then
        self:EndWriting()
    end
end

--------------------------------------------------------------------------

-- Invoked when this component is removed from entity
function Notebook:OnRemoveFromEntity()
    print("KK-TEST> Function 'Notebook:OnRemoveFromEntity' is invoked.")
    self:EndWriting()
    self.inst:RemoveTag("notebook")
    self:Clear()
    
    self.inst:RemoveEventCallback("enterlimbo", self.onenterlimbo)
    self.inst:RemoveEventCallback("exitlimbo", self.onexitlimbo)
end

-- Invoked when entity book is removed from the world
-- for example, when the book owner quits the game
function Notebook:OnRemoveEntity()
    print("KK-TEST> Function 'Notebook:OnRemoveEntity' is invoked.")
    self:EndWriting()
end

function Notebook:Destroy()
    print("KK-TEST> Function 'Notebook:Destroy' is invoked.")
    --NotebookManager:RemoveBook(self)
end

return Notebook