public with sharing class SelectiveCommitSetupPayload {
    @AuraEnabled
    public Id userStoryId { get; set; }
    @AuraEnabled
    public String featureBranch { get; set; }
    @AuraEnabled
    public String baseBranch { get; set; }
    @AuraEnabled
    public String destinationBranch { get; set; }
    @AuraEnabled
    public String metadataTypeAndName { get; set; }
    @AuraEnabled
    public String filePrefix { get; set; }
}