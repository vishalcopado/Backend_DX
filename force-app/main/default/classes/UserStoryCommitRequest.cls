public with sharing class UserStoryCommitRequest {
    @AuraEnabled
    public Id userStoryId { get; set; }
    @AuraEnabled
    public List<MetadataItem> changes { get; set; }
    @AuraEnabled
    public Boolean recreateFeatureBranch { get; set; }
    @AuraEnabled
    public Boolean executeCommit { get; set; }
    @AuraEnabled
    public String baseBranch { get; set; }
    @AuraEnabled
    public String message { get; set; }

    public copado.CommitAction.Request parse() {
        copado.CommitAction.Request result = new copado.CommitAction.Request();
        result.userStoryId = userStoryId;
        result.changes = parseChanges();
        result.recreateFeatureBranch = recreateFeatureBranch;
        result.executeCommit = executeCommit;
        result.baseBranch = baseBranch;
        result.message = message;
        return result;
    }

    private List<copado.CommitAction.Change> parseChanges() {
        List<copado.CommitAction.Change> result = new List<copado.CommitAction.Change>();
        for (MetadataItem change : changes) {
            result.add(change.parseCommitRequest());
        }
        return result;
    }
}