local assets=
{
    Asset("IMAGE", "images/inventoryimages/book_notebook.tex"),
    Asset("ATLAS", "images/inventoryimages/book_notebook.xml"),
}

local function onread(inst, reader)
    reader.components.talker:Say("Cthulhu Fhatgn!", 2)
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("books")
    inst.AnimState:SetBuild("books")
    inst.AnimState:PlayAnimation("idle")  
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/book_notebook.xml"
    
    -- Writeable book --
    --inst:AddComponent("writeable")
    --inst:AddComponent("book")
    --inst.components.book.onread = onread
    --inst:AddComponent("notebook_context")
    --------------------
    
    -- Books are flammable 
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab( "common/inventory/book_notebook", fn, assets) 
