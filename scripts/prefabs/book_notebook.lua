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

--[[
Call stack 'ACTIONS.GIVE'
* Trader:AcceptGift(act.doer, act.invobject)
    * Inventory:GiveItem(item, nil, pos)            -- give item to the receiver
        * Inventory:IsItemEquipped(inst)            -- check if item is equipped
        * InventoryItem:RemoveFromOwner(true)       -- try to remove item from the giver's inventory/container
            > Inventory:RemoveItem(self.inst, true)
            > Container:RemoveItem(self.inst, true)
                * InventoryItem:OnRemoved()
                    > EntityScript:RemoveChild(self.inst)
                    * InventoryItem:ClearOwner()
                    * EntityScript:ReturnToScene()
        * InventoryItem:OnPickup(self.inst)         -- try to destroy item
        * Inventory:GetOverflowContainer()          -- get backpack
        * Inventory:GetNextAvailableSlot(inst)      -- find an empty slot to put item
            * Inventory:CanTakeItemInSlot(item, k)  -- check if item can go into container
        > InventoryItem:OnPutInInventory(self.inst) -- trigger a series of functions
            * InventoryItem:SetOwner(owner)
            * EntityScript:AddChild(self.inst)
            * EntityScript:RemoveFromScene()
--]]
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
    
    inst:AddTag("_notebook")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:RemoveTag("_notebook")
    
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
    
    return inst
end

return Prefab("book_notebook", fn, assets, prefabs)