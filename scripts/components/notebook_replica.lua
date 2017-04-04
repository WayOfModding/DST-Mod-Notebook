local makescreen = require("screens/notebookscreen")
local json = require("json")

local function SendRPC(namespace, name, ...)
    print("KK-TEST> SendRPC:", ...)
    local id_table =
    {
        namespace = namespace,
        id = MOD_RPC[namespace][name].id
    }
    SendModRPCToServer(id_table, ...)
end

local function setpages(self, pages)
    print("KK-TEST> Function 'setpages' is invoked.")
    -- Master Sim stores notebook data in 'notebook' COMPONENT instead REPLICA
    for page, text in pairs(pages) do
        self.pages[page] = text
    end
end

local Notebook = Class(function(self, inst)
    self.inst = inst
    
    -- @see netvars.lua
    self.newpages = net_string(inst.GUID, "notebook.newpages", "pagedirty")
    
    -- Only declare these two fields on client side
    if not TheWorld.ismastersim then
        self.pages = {}
        
        self.OnPagesDirty = function()
            local newpages = self.newpages:value()
            if newpages == nil or newpages == "" or newpages == "{}" or newpages == "[]" then
                return false
            end
            newpages = json.decode(newpages)
            assert(type(newpages) == "table", "KK-TEST> Invalid 'newpages' type: " .. type(newpages))
            -- update local data structure
            setpages(self, newpages)
            return true
        end
        self.OnRemoveFromEntity = function(self)
            self:RemoveEventCallback("pagedirty", self.OnPagesDirty)
        end
        
        inst:ListenForEvent("pagedirty", self.OnPagesDirty)
    end
end)

function Notebook:GetDebugString()
    return "Notebook(replica)" .. json.encode(self:GetPages())
end

function Notebook:SetPages(pages)
    print("KK-TEST> Function 'Notebook(replica):SetPages' is invoked.")
    if self.inst.components.notebook ~= nil then
        -- Host client
        self.inst.components.notebook:SetPages(pages)
    else
        -- Update pages locally
        setpages(self, pages)
        -- Send new pages to server with RPC
        pages = json.encode(pages)
        assert(type(pages) == "string", "Error occurred while encoding json string!")
        SendRPC("NOTEBOOK", "SetPages", self.inst, pages)
    end
end

function Notebook:GetPages()
    print("KK-TEST> Function Notebook(replica):SetPages() is invoked.")
    local res = nil
    if self.inst.components.notebook ~= nil then
        --print("KK-TEST> self.inst.components.notebook is found.")
        res = self.inst.components.notebook.pages
    else
        --print("KK-TEST> self.inst.components.notebook is NOT found.")
        res = self.pages
    end
    assert(res ~= nil, "KK-TEST> An empty book is retrieved!")
    return res
end

function Notebook:GetPage(page)
    return self:GetPages()[page] or ""
end

function Notebook:GetTitle()
    return self:GetPage(0)
end


function Notebook:BeginWriting(doer)
    if self.inst.components.notebook ~= nil then
        return self.inst.components.notebook:BeginWriting(doer)
    elseif doer ~= nil and doer == ThePlayer then
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
    if self.inst.components.notebook ~= nil then
        return self.inst.components.notebook:EndWriting(doer)
    end
end

return Notebook