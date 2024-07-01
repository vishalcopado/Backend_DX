public with sharing class UserStoriesSelector extends FflibExtension {
    // CONSTRUCTOR

    public UserStoriesSelector() {
        this(true, true);
    }

    public UserStoriesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__User_Story__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__User_Story__c.Name,
            copado__User_Story__c.copado__User_Story_Title__c,
            copado__User_Story__c.copado__Org_Credential__c,
            copado__User_Story__c.copado__Project__c,
            copado__User_Story__c.copado__Release__c,
            copado__User_Story__c.copado__Metadata_Types_in_Selection__c,
            copado__User_Story__c.copado__Has_Apex_Code__c,
            copado__User_Story__c.copado__Minimum_Apex_Code_Coverage__c,
            copado__User_Story__c.copado__Platform__c,
            copado__User_Story__c.copado__Promotion_Test_Level__c
        };
    }

    public Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap() {
        return new Map<String, List<Schema.SObjectField>>{
            'copado__Org_Credential__r' => new List<Schema.SObjectField>{ copado__Org__c.Name, copado__Org__c.copado__Environment__c, copado__Org__c.copado__Validated_Date__c },
        'copado__Project__r' => new List<Schema.SObjectField>{ copado__Project__c.copado__Deployment_Flow__c },
        'copado__Release__r.copado__Project__c' => new List<Schema.SObjectField>{ copado__Project__c.copado__Deployment_Flow__c }
        }; 
    }

    public List<copado__User_Story__c> byIds(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setCondition(copado__User_Story__c.Id + ' IN :ids').selectFields(new Set<String> {'copado__Environment__c'});
        setLookupFields(query, 'copado__Org_Credential__r');
        setLookupFields(query, 'copado__Project__r');
        setLookupFields(query, 'copado__Release__r.copado__Project__c');

        return Database.query(query.toSOQL());
    }

    public List<copado__User_Story__c> byIdsAndPlatforms(Set<Id> ids, Set<String> platforms) {
        return Database.query(
            newQueryFactory()
                .setCondition(copado__User_Story__c.Id + ' IN :ids AND ' + copado__User_Story__c.copado__Platform__c + ' IN :platforms')
                .toSOQL()
        );
    }

    public List<copado__User_Story__c> byIdsWithUserStoryMetadataTypes(Set<Id> ids, Set<String> types, Set<String> actions) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(
                new Set<String>{
                    'copado__Apex_Code_Coverage__c',
                    'copado__Classes_Without_Coverage__c',
                    'copado__Triggers_Without_Coverage__c',
                    'copado__Failing_Methods__c'
                }
            )
            .setCondition(copado__User_Story__c.Id + ' IN :ids');
        new UserStoryMetadataSelector()
            .addQueryFactorySubselect(query)
            .selectFields(new Set<String>{ 'copado__Type__c', 'copado__Metadata_API_Name__c', 'copado__User_Story__c' })
            .setCondition('copado__Type__c IN :types AND copado__Action__c IN :actions');
        return Database.query(query.toSOQL());
    }
}