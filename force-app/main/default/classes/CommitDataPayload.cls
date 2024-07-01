public with sharing class CommitDataPayload {
    @AuraEnabled
    public Id userStoryId { get; set; }
    @AuraEnabled
    public Id dataTemplateId { get; set; }
    @AuraEnabled
    public Id dataSetId { get; set; }
    @AuraEnabled
    public String commitMessage { get; set; }
    @AuraEnabled
    public List<DataFilter> filters { get; set; }
    @AuraEnabled
    public String filterLogic { get; set; }
}