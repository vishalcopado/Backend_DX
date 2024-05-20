public with sharing class PromotionsSelector extends fflib_SObjectSelector {
    private Boolean enforceFLS;
    private Boolean enforceCRUD;

    // CONSTRUCTOR

    public PromotionsSelector() {
        this(true, true);
    }

    public PromotionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
        this.enforceFLS = enforceFLS;
        this.enforceCRUD = enforceCRUD;
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Promotion__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Promotion__c.Name,
            copado__Promotion__c.Validate_Deploy_Request_Id__c,
            copado__Promotion__c.Apex_Test_Level__c,
            copado__Promotion__c.copado__Status__c,
            copado__Promotion__c.copado__Destination_Environment__c,
            copado__Promotion__c.copado__Source_Environment__c,
            copado__Promotion__c.Rollback_Status__c,
            copado__Promotion__c.Rolled_Back_Date__c
        };
    }

    public List<copado__Promotion__c> byIdsAndActivePromotedStories(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('copado__Destination_Environment__r.Apex_Test_Level__c')
            .setCondition(
                'copado__Platform__c = \'SFDX\' AND Id IN (SELECT copado__Promotion__c from copado__Promoted_User_Story__c WHERE copado__Promotion__c IN :ids AND copado__Status__c = \'Active\')'
            );

        new PromotedUserStoriesSelector(enforceCRUD, enforceFLS)
            .addQueryFactorySubselect(query)
            .selectField('copado__User_Story__r.Apex_Test_Level__c')
            .setCondition('copado__Status__c = \'Active\'');

        return Database.query(query.toSOQL());
    }

    public List<copado__Promotion__c> byDestinationIds(Set<Id> destinationIds) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Destination_Environment__c')
                .setCondition(
                    'copado__Platform__c = \'SFDX\' AND copado__Destination_Environment__c IN :destinationIds AND Validate_Deploy_Request_Id__c != null'
                )
                .toSOQL()
        );
    }

    public List<copado__Promotion__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'copado__Back_Promotion__c', 'copado__Project__r.copado__Deployment_Flow__c', 'copado__Destination_Org_Credential__c' })
                .setCondition('copado__Platform__c = \'SFDX\' AND Id IN :ids')
                .toSOQL()
        );
    }

    public List<copado__Promotion__c> fetchRepositoryInfoByIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Destination_Environment__c')
                .selectField('copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__Pull_Request_Base_URL__c')
                .selectField('copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__c')
                .selectField('copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__Git_Provider__c')
                .selectField('copado__Release__r.copado__Project__r.copado__Deployment_Flow__c')
                .selectField('copado__Project__r.copado__Deployment_Flow__r.Name')
                .selectField(
                    'copado__Release__r.copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__Pull_Request_Base_URL__c'
                )
                .selectField('copado__Release__r.copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__c')
                .selectField('copado__Release__r.copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__Git_Provider__c')
                .setCondition('copado__Platform__c = \'SFDX\' AND Id IN :ids')
                .toSOQL()
        );
    }

    public List<copado__Promotion__c> byIdsAndNotNullValidationIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory().setCondition('copado__Platform__c = \'SFDX\' AND Id IN :ids AND Validate_Deploy_Request_Id__c != null').toSOQL()
        );
    }
}