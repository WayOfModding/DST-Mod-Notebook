function IsDeveloper(inst)
    --assert(inst:HasTag("player"))
    -- Steam Name: KaiserKatze
    -- Klei user ID: KU_W6rIrzTu
    -- Offline user ID: OU_76561198051701765
    print(string.format("KK-TEST> User ID=%s, User Name=%s", inst.Network:GetUserID(), inst.Network:GetClientName()))
    return inst.userid == "KU_W6rIrzTu"
end