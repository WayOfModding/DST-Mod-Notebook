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

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/book_notebook.xml"
    
    -- Writeable book --
    inst:AddComponent("notebook")
    --------------------
    
    -- Books are flammable
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL
    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)

    MakeHauntableLaunch(inst)
    
    inst.IsNotebook = function(self)
        return self and self.components.notebook
    end
    inst.GetTitle = function(self)
        return self.components.notebook.title
    end
    inst.GetWriters = function(self)
        return self.components.notebook.writers
    end
    inst.GetText = function(self)
        return self.components.notebook.text
    end
    inst.Write = function(self, doer, title, text)
        self.components.notebook:Write(doer, title, text)
    end
    inst.EndWriting = function(self)
        self.components.notebook:EndWriting()
    end
    
    return inst
end

return Prefab("book_notebook", fn, assets, prefabs)