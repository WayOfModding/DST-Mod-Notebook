local assets =
{
    Asset("ANIM", "anim/book_notebook.zip"),
    Asset("ATLAS", "images/book_notebook.xml"),
}

local prefabs =
{
    "book_fx",
}

local function onburnt(inst)
    inst:RemoveComponent("notebook")
    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("book_notebook")
    inst.AnimState:SetBuild("book_notebook")
    inst.AnimState:PlayAnimation("idle")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getspecialdescription = function(inst, reader)
        local notebook = inst.components.notebook
        
        if notebook then
            local title = notebook.pages[0]
            if title and title ~= "" then
                return STRINGS.NOTEBOOK.BOOKTITLELEFT .. title .. STRINGS.NOTEBOOK.BOOKTITLERIGHT
            end
        end
    end
    
    -- Writeable book --
    inst:AddComponent("notebook")
    --------------------

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/book_notebook.xml"
    
    -- Books are flammable
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)

    MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab("book_notebook", fn, assets, prefabs)