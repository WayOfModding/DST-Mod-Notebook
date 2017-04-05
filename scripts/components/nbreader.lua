local NotebookReader = Class(function(self, inst)
    self.inst = inst
    
    inst:AddTag("nbreader")
end)

function NotebookReader:OnRemoveFromEntity()
    self.inst:RemoveTag("nbreader")
end

function NotebookReader:Read(book)
    if book == nil then
        return false, "NotebookReader:Read: 'book' is nil"
    end
    if book.components.notebook == nil then
        return false, "NotebookReader:Read: 'book.components.notebook' is nil"
    end
    
    local player = self.inst
    return book.components.notebook:BeginWriting(player)
end

return NotebookReader