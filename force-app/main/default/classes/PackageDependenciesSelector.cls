public with sharing class PackageDependenciesSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PackageDependenciesSelector() {
        this(true, true);
    }

    public PackageDependenciesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Artifact_Dependency__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Artifact_Dependency__c.copado__Depends_on_the_latest_version__c
        };
    }

    public List<copado__Artifact_Dependency__c> byDependentPackageIds(Set<Id> packageIds) {
        return Database.query(
            newQueryFactory()
                .selectFields(dependingFields())
                .setCondition(copado__Artifact_Dependency__c.copado__Dependent_Artifact__c + ' IN :packageIds')
                .toSOQL()
        );
    }

    // PRIVATE

    private Set<String> dependingFields() {
        return new Set<String>{
            'copado__Depending_Artifact_Version__r.copado__Subscriber_Version_Id__c',
            'copado__Depending_Artifact__r.copado__Artifact_Version__r.copado__Subscriber_Version_Id__c'
        };
    }
}