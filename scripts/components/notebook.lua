local makescreen = require("screens/notebookscreen")

local function gettext(inst, reader)
    local that = inst.components.notebook
    
    if that then
        local title = that.pages[0]
        if title and title ~= "" then
            return STRINGS.NOTEBOOK.BOOKTITLELEFT .. title .. STRINGS.NOTEBOOK.BOOKTITLERIGHT
        end
    end
end

local Notebook = Class(function(self, inst)
    self.inst           = inst
    
    self.writer         = nil
    
    self.pages          = {}
    
    inst.components.inspectable.getspecialdescription = gettext
    inst:AddTag("notebook")

    self.onclosepopups = function(doer)
        self:EndWriting()
    end
end)

function Notebook:OnSave()
    local data = {}
    
    data.pages      = self.pages
    
    return data
end

function Notebook:OnLoad(data)
    self.pages      = data.pages
    -- Notify client
    if self.inst.replica.notebook.classified then
        self.inst.replica.notebook.classified.pages:set_local(self.pages)
        self.inst.replica.notebook.classified.pages:set(self.pages)
    end
end

function Notebook:SetWriter(writer)
    if self.writer == nil then
        self.writer = writer
    else
        print("KK-TEST> self.writer = ", self.writer)
    end
end

function Notebook:BeginWriting(doer)
    if self.writer == nil then
        -- Notify component update
        self.inst:StartUpdatingComponent(self)
        
        self.writer = doer
        -- Trigger when the pop-up window is closed
        self.inst:ListenForEvent("ms_closepopups", self.onclosepopups, doer)
        self.inst:ListenForEvent("onremove", self.onclosepopups, doer)
        
        -- Make pop-up window
        if doer.HUD == nil then
            return false, "Notebook:BeginWriting: 'doer.HUD' is nil"
        else
            local screen = makescreen(self.inst, doer)
            if screen == nil then
                return false, "Notebook:BeginWriting: Fail to make notebook screen!"
            else
                return true
            end
        end
    else
        return false, "Notebook:BeginWriting: Notebook is already being editing!"
    end
end

function Notebook:GetPage(page)
    return self.pages[page]
end

function Notebook:SetPages(doer, pages)
    if doer ~= nil and self.writer == doer then
        for page, text in pairs(pages) do
            self.pages[page] = text
        end
    else
        print(string.format("KK-TEST> Fail to execute Notebook:SetPages\n\tdoer=%s\n\tpages=%s\n\tself.writer=%s\n",
            doer, pages, self.writer))
    end
end

function Notebook:EndWriting()
    if self.writer ~= nil then
        self.inst:StopUpdatingComponent(self)
        
        self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, self.writer)
        self.inst:RemoveEventCallback("onremove", self.onclosepopups, self.writer)
        
        self.writer = nil
    end
end

function Notebook:Clear()
    self.pages = {}
end

-- Invoked when this component is removed from entity
function Notebook:OnRemoveFromEntity()
    self:EndWriting()
    self.inst:RemoveTag("notebook")
    
    self:Clear()
    
    if self.inst.components.inspectable ~= nil
            and self.inst.components.inspectable.getspecialdescription == gettext 
    then
        self.inst.components.inspectable.getspecialdescription = nil
    end
end

Notebook.OnRemoveEntity = Notebook.EndWriting

return Notebook