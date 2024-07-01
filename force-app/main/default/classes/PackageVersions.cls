public with sharing class PackageVersions extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public PackageVersions(List<copado__Artifact_Version__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        new UpdatePackageVersionRecord(getChangedRecords(new Set<String>{ 'copado__Is_released__c', 'copado__Subscriber_Version_Id__c' }), false)
            .execute();
    }

    public override void onBeforeInsert() {
        new UpdatePackageVersionRecord(records, true).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new PackageVersions(records);
        }
    }
}