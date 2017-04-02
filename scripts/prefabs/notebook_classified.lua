--------------------------------------------------------------------------
--Server interface
--------------------------------------------------------------------------

local function OnTitleChanged(parent, data)
    local notebook = parent.components.notebook
    notebook.title = data.newtitle
end

local function OnPagesChanged(parent, data)
    local notebook = parent.components.notebook
    for page, text in pairs(data.newpages) do
        notebook.pages[page] = text
    end
end

--------------------------------------------------------------------------
--Client interface
--------------------------------------------------------------------------

local function OnRemoveEntity(inst)
    if inst._parent ~= nil then
        inst._parent.notebook_classified = nil
    end
end

local function OnEntityReplicated(inst)
    inst._parent = inst.entity:GetParent()
    if inst._parent == nil then
        print("Unable to initialize classified data for notebook")
    elseif inst._parent.replica.notebook ~= nil then
        inst._parent.replica.notebook:AttachClassified(inst)
    else
        inst._parent.notebook_classified = inst
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

local function OnTitleDirty(inst)
    if inst._parent ~= nil then
        local title = inst.title:value()
        local data =
        {
            newtitle = title,
        }
        inst._parent:PushEvent("titlechanged", data)
    end
end

local function OnPagesDirty(inst)
    if inst._parent ~= nil then
        local pages = inst.pages:value()
        local data =
        {
            newpages = pages,
        }
        inst._parent:PushEvent("pageschanged", data)
    end
end

local function SendRPC(namespace, name, ...)
    local id_table = { namespace = namespace, id = MOD_RPC[namespace][name].id }
    SendModRPCToServer(id_table, ...)
end

local function SetTitle(inst, doer, title)
    SendRPC("NOTEBOOK", "SetTitle", inst._parent, doer, title)
end

local function SetPages(inst, doer, pages)
    SendRPC("NOTEBOOK", "SetPages", inst._parent, doer, pages)
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------


--------------------------------------------------------------------------

local function RegisterNetListeners(inst)
    if TheWorld.ismastersim then
        -- server
        inst._parent = inst.entity:GetParent()
        inst:ListenForEvent("titlechanged", OnTitleChanged, inst._parent)
        inst:ListenForEvent("pageschanged", OnPagesChanged, inst._parent)
    else
        -- client
        inst:ListenForEvent("titledirty", OnTitleDirty)
        inst:ListenForEvent("pagesdirty", OnPagesDirty)
    end
    -- common
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddNetwork()
    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")
    
    --Net variables
    inst.title = net_string(inst.GUID, "notebook.title", "titledirty")
    inst.pages = net_entity(inst.GUID, "notebook.pages", "pagesdirty")
    
    --Delay net listeners until after initial values are deserialized
    inst:DoTaskInTime(0, RegisterNetListeners)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        --Client interface
        inst.OnEntityReplicated = OnEntityReplicated
        inst.SetTitle = SetTitle
        inst.SetPages = SetPages

        return inst
    end

    --Server interface
    
    inst.persists = false

    return inst
end

return Prefab("notebook_classified", fn)
