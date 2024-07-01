public with sharing class DeploymentJobSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public DeploymentJobSelector() {
        this(true, true);
    }

    public DeploymentJobSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Deployment_Job__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Deployment_Job__c.copado__Last_Result__c };
    }

    public List<copado__Deployment_Job__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'copado__Last_Result__c', 'copado__Status__c' })
                .setCondition(copado__Deployment_Job__c.Id + ' IN :ids')
                .toSOQL()
        );
    }
}