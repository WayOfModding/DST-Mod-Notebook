local NotebookReader = Class(function(self, inst)
    self.inst = inst
    
    inst:AddTag("nbreader")
end)

function NotebookReader:OnRemoveFromEntity()
    self.inst:RemoveTag("nbreader")
end

function NotebookReader:Read(book)
    if book then
        if book.components.notebook then
            if book.components.notebook:OnRead(self.inst) then
                return true
            end
        end
    end
end

return NotebookReader