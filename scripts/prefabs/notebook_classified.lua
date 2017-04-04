return Prefab("notebook_classfied", function(Sim)
    local inst = CreateEntity()
    
    inst.entity:AddNetwork()
    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")
    
    inst.pages = {}
    
    if TheWorld.ismastersim then
        -- Server APIs
        self.persist = false
    else
        -- Client APIs
    end
    
    -- Common APIs
    
    return inst
end)