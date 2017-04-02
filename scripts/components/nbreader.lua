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
    
    local notebook = nil
    if TheWorld.ismastersim then
        notebook = book.components.notebook
        if notebook == nil then
            return false, "NotebookReader:Read: 'notebook' is nil(TheWorld.ismastersim == true)"
        end
    else
        notebook = book.replica.notebook
        if notebook == nil then
            return false, "NotebookReader:Read: 'notebook' is nil(TheWorld.ismastersim == false)"
        end
    end
    
    return notebook:BeginWriting(self.inst)
end

return NotebookReader