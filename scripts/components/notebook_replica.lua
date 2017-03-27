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
            self.screen = writeables.makescreen(self.inst, doer)
        end
    end
end

function Notebook:Write(doer, text)
    --NOTE: text may be network data, so enforcing length is
    --      NOT redundant in order for rendering to be safe.
    if self.inst.components.notebook ~= nil then
        self.inst.components.notebook:Write(doer, text)
    elseif self.classified ~= nil and doer == ThePlayer
        and (text == nil or text:utf8len() <= MAX_WRITEABLE_LENGTH) then
        SendRPCToServer(RPC.SetWriteableText, self.inst, text)
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
            ThePlayer.HUD:CloseWriteableWidget()
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
