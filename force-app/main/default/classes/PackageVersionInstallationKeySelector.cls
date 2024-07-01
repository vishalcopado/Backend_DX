public with sharing class PackageVersionInstallationKeySelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PackageVersionInstallationKeySelector() {
        this(true, true);
    }

    public PackageVersionInstallationKeySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return PackageVersionInstallationKey__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            PackageVersionInstallationKey__c.Name,
            PackageVersionInstallationKey__c.InstallationKey__c,
            PackageVersionInstallationKey__c.PackageVersionId__c
        };
    }

    public List<PackageVersionInstallationKey__c> byPackageVersionId(Set<Id> ids) {
        return Database.query(
            newQueryFactory().setCondition(PackageVersionInstallationKey__c.PackageVersionId__c + ' IN :ids').toSOQL()
        );
    }
}