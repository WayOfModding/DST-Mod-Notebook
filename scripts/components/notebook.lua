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

local Notebook = Class(function(self, inst)
    self.inst = inst
    --print("KK-TEST(notebook)>", dumptable(self.inst))
    print("KK-TEST> ClientName:", self.inst.Network:GetClientName())
    print("KK-TEST> UserID:",self.inst.Network:GetUserID())
    
    self.pages = {}
    
    self.onclosepopups = function(doer)
        self:EndWriting(doer)
    end
    
    inst:AddTag("notebook")
    --inst:DoTaskInTime(0, RegisterNetListeners)
end)

------------------------------------------------------------
-- Common APIs
------------------------------------------------------------
function Notebook:OnSave()
    return { pages = self.pages }
end

function Notebook:OnLoad(data, newents)
    print("KK-TEST> Function Notebook:OnLoad is invoked on " .. (TheWorld.ismastersim and "server-side" or "client-side"))
    self.pages = data.pages
end

function Notebook:GetPage(page)
    return self.pages and self.pages[page] or ""
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

if TheWorld.ismastersim then
------------------------------------------------------------
-- Server APIs
------------------------------------------------------------
    function Notebook:SetPages(pages)
        if type(pages) == "string" then
            pages = json.decode(pages)
            assert(type(pages) == "table", "Error occurred while decoding json string!")
        elseif type(pages) ~= "table" then
            return false, "Invalid parameter type 'pages': " .. type(pages)
        end
        for page, text in pairs(pages) do
            self.pages[page] = text
        end
        self.inst:PushEvent("server.notebook.setpages", { newpages = pages })
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
else
------------------------------------------------------------
-- Client APIs
------------------------------------------------------------
    function Notebook:SetPages(pages)
        self.inst:PushEvent("client.notebook.setpages", { newpages = pages })
        pages = json.encode(pages)
        assert(type(pages) == "string", "Error occurred while encoding json string!")
        SendRPC("NOTEBOOK", "SetPages", self.inst, pages)
    end
end

return Notebook