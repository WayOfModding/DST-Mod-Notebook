local makescreen = require("screens/notebookscreen")

local Notebook = Class(function(self, inst)
    self.inst = inst

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
    self:BeginWriting(ThePlayer)
end

function Notebook:GetTitle()
    return self.classified.title:value()
end

function Notebook:GetPage(page)
    return self.classified.pages:value()[page]
end

function Notebook:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    self.inst:DoTaskInTime(0, BeginWriting, self)
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
        self.inst.components.notebook:BeginWriting(doer)
    elseif self.classified ~= nil
        and doer ~= nil
        and doer == ThePlayer then

        if doer.HUD == nil then
            -- abort
        else -- if not busy...
            makescreen(self.inst, doer)
        end
    end
end

function Notebook:EndWriting()
    if self.inst.components.notebook ~= nil then
        self.inst.components.notebook:EndWriting()
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
