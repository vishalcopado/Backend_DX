public with sharing class UserStoryMetadataTrigger extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public UserStoryMetadataTrigger(List<copado__User_Story_Metadata__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onAfterInsert() {
        setMetadataInSelection();
    }

    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        setMetadataInSelection();
    }

    public override void onAfterDelete() {
        setMetadataInSelection();
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void setMetadataInSelection() {
        List<copado__User_Story__c> storiesToUpdate = new List<copado__User_Story__c>();

        Set<Id> storyIds = getStoryIds();
        Map<Id, Set<String>> typesByStory = getTypesByStory(new UserStoryMetadataSelector().byStoryIdsAndActionAddOrFull(storyIds));

        List<copado__User_Story__c> stories = new UserStoriesSelector().byIdsAndPlatforms(storyIds, new Set<String>{ 'SFDX' });
        for (copado__User_Story__c record : stories) {
            String types = formatTypes(typesByStory.get(record.Id));

            Boolean hasApex = hasApex(types);
            if (record.copado__Metadata_Types_in_Selection__c != types || hasApex != record.copado__Has_Apex_Code__c) {
                record.copado__Metadata_Types_in_Selection__c = types;
                record.copado__Has_Apex_Code__c = hasApex;
                storiesToUpdate.add(record);
            }
        }

        // Executed in trigger context
        update storiesToUpdate;
    }

    private Set<Id> getStoryIds() {
        Set<Id> result = new Set<Id>();

        for (copado__User_Story_Metadata__c metadata : (List<copado__User_Story_Metadata__c>) records) {
            result.add(metadata.copado__User_Story__c);
        }

        return result;
    }

    private Map<Id, Set<String>> getTypesByStory(List<copado__User_Story_Metadata__c> records) {
        Map<Id, Set<String>> result = new Map<Id, Set<String>>();

        for (copado__User_Story_Metadata__c metadata : records) {
            if (!result.containsKey(metadata.copado__User_Story__c)) {
                result.put(metadata.copado__User_Story__c, new Set<String>());
            }

            result.get(metadata.copado__User_Story__c).add(metadata.copado__Type__c);
        }

        return result;
    }

    private String formatTypes(Set<String> types) {
        return String.join(new List<String>(types), ';');
    }

    private Boolean hasApex(String types) {
        Set<String> result = new Set<String>(new List<String>(types?.split(';')));
        return result.contains('ApexClass') || result.contains('ApexTrigger');
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new UserStoryMetadataTrigger(records);
        }
    }
}