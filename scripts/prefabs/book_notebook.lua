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
    inst.GetPage = function(self, page)
        return self.components.notebook.pages[page]
    end
    inst.SetTitle = function(self, doer, title)
        print(string.format("KK-TEST> book_notebook:SetTitle(%s, %s)",
            tostring(doer), tostring(title)))
        print("self.components.notebook=\t"..tostring(self.components.notebook))
        print("self.replica.notebook=\t"..tostring(self.replica.notebook))
        if self.components.notebook then
            self.components.notebook:SetTitle(doer, title)
        end
        if self.replica.notebook then
            self.replica.notebook:SetTitle(doer, title)
        end
    end
    inst.SetPage = function(self, doer, page, text)
        print(string.format("KK-TEST> book_notebook:SetPage(%s, %s, %s)",
            tostring(doer), tostring(page), tostring(text)))
        if self.components.notebook then
            self.components.notebook:SetPage(doer, page, text)
        end
        if self.replica.notebook then
            self.replica.notebook:SetPage(doer, page, text)
        end
    end
    inst.EndWriting = function(self)
        if self.components.notebook then
            self.components.notebook:EndWriting()
        end
        if self.replica.notebook then
            self.replica.notebook:EndWriting()
        end
    end
    
    return inst
end

return Prefab("book_notebook", fn, assets, prefabs)