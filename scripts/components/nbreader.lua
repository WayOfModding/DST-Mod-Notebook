local NotebookReader = Class(function(self, inst)
    self.inst = inst
    
    inst:AddTag("nbreader")
end)

function NotebookReader:OnRemoveFromEntity()
    self.inst:RemoveTag("nbreader")
end

function NotebookReader:Read(book)
    if not book then return end
    if TheWorld.ismastersim then
        notebook = book.components.notebook
    else
        notebook = book.replica.notebook
    end
    return notebook:BeginWriting(self.inst)
end

return NotebookReader