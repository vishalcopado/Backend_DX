public with sharing class ApexTestInfo {
    public Boolean removeExistingSelection;
    public Id fileWithSelectedChanges;

    public ApexTestInfo() {
        this.removeExistingSelection = false;
        this.fileWithSelectedChanges = null;
    }

    public ApexTestInfo(Boolean removeExistingSelection, Id fileWithSelectedChanges) {
        this.removeExistingSelection = removeExistingSelection;
        this.fileWithSelectedChanges = fileWithSelectedChanges;
    }
}