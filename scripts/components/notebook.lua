local function gettext(inst, reader)
    local that = inst.components.notebook
    
    if that and that.title then
        local text = "\"" .. that.title .. "\""
        if that.writers then
            text = text .. " by " .. that.writers[1]
            if #that.writers / 2 > 1 then
                text = text .. ", etc"
            end
        end
        
        return text
    end
end

local Notebook = Class(function(self, inst)
    self.inst           = inst
    
    self.screen         = nil
    self.writer         = nil
    
    self.title          = nil
    self.writers        = nil
    self.text           = nil
    
    inst.components.inspectable.getspecialdescription = gettext
    inst:AddTag("notebook")
end)

local function onclosepopups(doer)
    self:EndWriting()
end

function Notebook:OnSave()
    local data = {}
    
    data.title      = self.title
    data.writers    = self.writers
    data.text       = self.text
    
    return data
end

function Notebook:OnLoad(data)
    self.title      = data.title
    self.writers    = data.writers
    self.text       = data.text
end

function Notebook:OnRead(doer)
    self:BeginWriting(doer)
    return true
end

function Notebook:BeginWriting(doer)
    if self.writer == nil then
        -- Notify component update
        self.inst:StartUpdatingComponent(self)
        
        self.writer = doer
        -- Trigger when the pop-up window is closed
        self.inst:ListenForEvent("ms_closepopups", onclosepopups, doer)
        self.inst:ListenForEvent("onremove", onclosepopups, doer)
        
        -- Make pop-up window
        if doer.HUD ~= nil then
            self.screen = NotebookMod.makescreen(self.inst, doer) -- ?
        end
    end
end

function Notebook:Write(doer, title, text)
    if doer ~= nil and self.writer == doer then
        self.title = title
        self.text = text
        self:EndWriting()
    end
end

local function GetPlayerName(player)
    return player.Network:GetClientName() --, player.Network:GetUserID()
end

function Notebook:EndWriting()
    if self.writer ~= nil then
        self.inst:StopUpdatingComponent(self)
        
        if self.screen ~= nil then
            self.writer.HUD:CloseWriteableWidget()
            self.screen = nil
        end
        
        self.inst:RemoveEventCallback("ms_closepopups", onclosepopups, self.writer)
        self.inst:RemoveEventCallback("onremove", onclosepopups, self.writer)
        
        if self.writers == nil then
            self.writers = {}
        end
        local player_name = GetPlayerName(self.writer)
        if self.writers[player_name] == nil then
            -- set
            self.writers[player_name] = true
            -- list
            table.insert(self.writers, player_name)
        end
        
        self.writer = nil
    elseif self.screen ~= nil then
        if self.screen.inst:IsValid() then
            self.screen:Kill()
        end
        self.screen = nil
    end
end

function Notebook:Clear()
    self.title = nil
    self.writers = nil
    self.text = nil
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