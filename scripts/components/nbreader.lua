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
            return book.components.notebook:OnRead(self.inst)
        end
    end
end

return NotebookReader