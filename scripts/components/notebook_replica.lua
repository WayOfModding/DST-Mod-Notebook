local makescreen = require("screens/notebookscreen")

local Notebook = Class(function(self, inst)
    self.inst = inst

    self.screen = nil
    self.opentask = nil

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("notebook_classified")
        self.classified.entity:SetParent(inst.entity)
    else
        if self.classified == nil and inst.notebook_classified ~= nil then
            self.classified = inst.notebook_classified
            inst.notebook_classified.OnRemoveEntity = nil
            inst.notebook_classified = nil
            self:AttachClassified(self.classified)
        end
    end
end)

--------------------------------------------------------------------------

function Notebook:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified:Remove()
            self.classified = nil
        else
            self.classified._parent = nil
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Notebook.OnRemoveEntity = Notebook.OnRemoveFromEntity

--------------------------------------------------------------------------
--Client triggers writing based on receiving access to classified data
--------------------------------------------------------------------------

local function BeginWriting(inst, self)
    self.opentask = nil
    self:BeginWriting(ThePlayer)
end

function Notebook:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    self.opentask = self.inst:DoTaskInTime(0, BeginWriting, self)
end

function Notebook:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    self:EndWriting()
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

function Notebook:BeginWriting(doer)
    if self.inst.components.notebook ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.notebook:BeginWriting(doer)
    elseif self.classified ~= nil
        and self.opentask == nil
        and doer ~= nil
        and doer == ThePlayer then

        if doer.HUD == nil then
            -- abort
        else -- if not busy...
            self.screen = makescreen(self.inst, doer)
        end
    end
end

local function SendRPCToServer(namespace, name, ...)
    local id_table = { namespace = namespace, id = MOD_RPC[namespace][name].id }
    SendModRPCToServer(id_table, ...)
end

function Notebook:SetTitle(doer, title)
    if doer and title then
        if self.inst.components.notebook ~= nil then
            self.inst.components.notebook:SetTitle(doer, title)
        elseif self.classified ~= nil and doer == ThePlayer
            and (title == nil or title:utf8len() <= MAX_WRITEABLE_LENGTH)
        then
            SendRPCToServer("NOTEBOOK", "SetTitle", self.inst, doer, title)
        end
    end
end

function Notebook:SetPage(doer, page, text)
    if doer and checknumber(page) then
        if self.inst.components.notebook ~= nil then
            self.inst.components.notebook:SetPage(doer, page, text)
        elseif self.classified ~= nil and doer == ThePlayer
            and (text == nil or text:utf8len() <= MAX_WRITEABLE_LENGTH)
        then
            SendRPCToServer("NOTEBOOK", "SetPage", self.inst, doer, page, text)
        end
    end
end

function Notebook:EndWriting()
    if self.opentask ~= nil then
        self.opentask:Cancel()
        self.opentask = nil
    end
    if self.inst.components.notebook ~= nil then
        self.inst.components.notebook:EndWriting()
    elseif self.screen ~= nil then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            if self.screen then
                self.screen:Close()
            end
        elseif self.screen.inst:IsValid() then
            --Should not have screen and no writer, but just in case...
            self.screen:Kill()
        end
        self.screen = nil
    end
end

function Notebook:SetWriter(writer)
    self.classified.Network:SetClassifiedTarget(writer or self.inst)
    if self.inst.components.notebook == nil then
        --Should only reach here during notebook construction
        assert(writer == nil)
    end
end

return Notebook
