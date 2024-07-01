public with sharing class MetadataRefreshDetails {
    private final static String METADATA = 'MetaData';

    @AuraEnabled
    public String name { get; set; }

    @AuraEnabled
    public List<String> selectedMetadata { get; set; }

    @AuraEnabled
    public Boolean isMetadataSavedToFile { get; set; }

    public MetadataRefreshDetails() {
        this.name = METADATA;
        this.selectedMetadata = new List<String>();
        this.isMetadataSavedToFile = false;
    }

    public MetadataRefreshDetails(String name, List<String> selectedMetadata, Boolean isMetadataSavedToFile) {
        this.name = name;
        this.selectedMetadata = selectedMetadata;
        this.isMetadataSavedToFile = isMetadataSavedToFile;
    }
}