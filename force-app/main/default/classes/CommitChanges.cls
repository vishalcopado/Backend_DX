public with sharing class CommitChanges {

    private final static String APEX_CLASS_TYPE = 'ApexClass';
    private final static String APEX_TRIGGER_TYPE = 'ApexTrigger';
    private final static String COPADO_COMMIT_CHANGES = 'Copado Commit changes';
    private final static String ADD = 'Add';
    Id fileWithSelectedChanges;
    Id userStoryId;
    List<Change> changesList;
    List<copado__User_Story_Metadata__c> userStoryMetadata;

    // CTR

    public CommitChanges(Id fileWithSelectedChanges, Id userStoryId) {
        this.fileWithSelectedChanges = fileWithSelectedChanges;
        this.userStoryId = userStoryId;
    }

    // PUBLIC

    public List<Change> fromJson(String commitChangesJson) {
        return (List<Change>)JSON.deserialize(commitChangesJson, List<Change>.class);
    }

    public List<Change> getChangeList() {
        if (changesList == null) {
            String fileContent = getContentVersionData(fileWithSelectedChanges);
            changesList = fileContent == null ? new List<Change>() : fromJson(fileContent);
        }
        return changesList;
    }

    public List<Change> byTypeAndOperation(Set<String> type, Set<String> operation) {
        List<Change> result = new List<Change>();
        for(Change change :  getChangeList()) {
            if(operation.contains(change.a) && type.contains(change.t)) {
                result.add(change);
            }
        }
        return result;
    }

    public List<copado__User_Story_Metadata__c> toUserStoryMetadata(List<Change> changeList) {
        List<copado__User_Story_Metadata__c> result = new List<copado__User_Story_Metadata__c> ();
        for(Change change: changeList) {
            result.add(change.toUserStoryMetadata(userStoryId));
        }
        return result;
    }

    private static String getContentVersionData(Id contentVersionId) {
        List<ContentVersion> contentVersion = new ContentVersionsSelector()
            .byIdsAndTitles(new Set<Id>{ contentVersionId }, new Set<String>{ COPADO_COMMIT_CHANGES });
        return !contentVersion.isEmpty() ? contentVersion[0]?.VersionData?.toString() : null;
    }

    public class Change {
        public String t;
        public String n;
        public String m;
        public String c;
        public String a;
    
        // CTR

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Change(String type, String name, String module, String category, String action) {
            this.t = type;
            this.n = name;
            this.m = module;
            this.c = category;
            this.a = action;
        }
    
        // PUBLIC
        public copado__User_Story_Metadata__c toUserStoryMetadata(Id userStoryId) {
            String metadataApiName = this.t + '.' + this.n;
    
            return new copado__User_Story_Metadata__c(
                copado__Action__c = this.a,
                copado__Category__c = this.c,
                copado__ModuleDirectory__c = this.m,
                copado__Type__c = this.t,
                copado__User_Story__c = userStoryId,
                copado__Metadata_API_Name__c = this.n,
                Name = metadataApiName
            );
        }
    }
}