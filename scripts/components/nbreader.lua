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
    elseif book.components.notebook == nil then
        return false, "NotebookReader:Read: 'book.components.notebook' is nil"
    else
        local player = self.inst
        return book.components.notebook:BeginWriting(player)
    end
end

return NotebookReader