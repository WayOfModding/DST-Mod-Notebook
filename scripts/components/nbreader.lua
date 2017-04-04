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
    if book.replica.notebook == nil then
        return false, "NotebookReader:Read: 'book.replica.notebook' is nil"
    end
    
    local player = self.inst
    return book.replica.notebook:BeginWriting(player)
end

return NotebookReader