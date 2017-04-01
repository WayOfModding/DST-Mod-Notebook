local makescreen = require("screens/notebookscreen")

local function gettext(inst, reader)
    local that = inst.components.notebook
    
    if that and that.title and that.title ~= "" then
        return STRINGS.NOTEBOOK.BOOKTITLELEFT .. that.title .. STRINGS.NOTEBOOK.BOOKTITLERIGHT
    end
end

local Notebook = Class(function(self, inst)
    self.inst           = inst
    
    self.writer         = nil
    
    self.title          = nil
    self.pages          = {}
    
    inst.components.inspectable.getspecialdescription = gettext
    inst:AddTag("notebook")

    self.onclosepopups = function(doer)
        self:EndWriting()
    end
end)

function Notebook:OnSave()
    local data = {}
    
    data.title      = self.title
    data.pages      = self.pages
    
    return data
end

function Notebook:OnLoad(data)
    self.title      = data.title
    self.pages      = data.pages
    -- Notify client
    self.inst.replica.classified.title:set_local(self.title)
    self.inst.replica.classified.title:set(self.title)
    self.inst.replica.classified.pages:set_local(self.pages)
    self.inst.replica.classified.pages:set(self.pages)
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
        if doer.HUD ~= nil then
            makescreen(self.inst, doer)
        end
    end
end

function Notebook:GetTitle()
    return self.title
end

function Notebook:GetPage(page)
    return self.pages[page]
end

function Notebook:SetTitle(doer, title)
    if doer ~= nil and self.writer == doer then
        self.title = title
    end
end

function Notebook:SetPages(doer, pages)
    if doer ~= nil and self.writer == doer then
        for page, text in pairs(pages)
            self.pages[page] = text
        end
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
    self.title = nil
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