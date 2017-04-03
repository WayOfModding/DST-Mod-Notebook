local json = require("json")

local Notebook = Class(function(self, inst)
    self.inst = inst
    
    -- @see netvars.lua
    self.pages = net_entity(inst.GUID, "notebook.pages", "pagedirty")
end)

function Notebook:SetPages(newpages)
    print("KK-TEST> Function Notebook(replica):SetPages(" .. json.encode(newpages) .. ").")
    self.pages:set(newpages)
end

function Notebook:GetPages()
    print("KK-TEST> Function Notebook(replica):SetPages() is invoked.")
    if self.inst.components.notebook ~= nil then
        print("KK-TEST> self.inst.components.notebook is found.")
        return self.inst.components.notebook.pages
    else
        print("KK-TEST> self.inst.components.notebook is NOT found.")
        return self.pages:value()
    end
end

return Notebook