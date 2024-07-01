public with sharing class UpdatePackageVersionRecord {
    private List<copado__Artifact_Version__c> records;
    private Boolean isInsert;
    private final static String STATUS_PUBLISHED = 'Published';
    private final static String STATUS_PRE_RELEASED = 'Pre-Release';
    private final static String STATUS_DRAFT = 'Draft';
    private final static String SALESFORCE_PACKAGE_RECORD_TYPE = 'Package_Artifact';

    // CONSTRUCTOR

    public UpdatePackageVersionRecord(List<copado__Artifact_Version__c> records, Boolean isInsert) {
        this.records = records;
        this.isInsert = isInsert;
    }

    // PUBLIC

    public void execute() {
        Map<Id, copado__Artifact__c> packagesById = getPackagesById();
        for (copado__Artifact_Version__c newVersion : records) {
            copado__Artifact__c artifact = packagesById.get(newVersion.copado__Artifact__c);
            if (artifact != null) {
                if (isInsert) {
                    updateVersionBranch(newVersion, artifact);
                }
                updateVersionStatus(newVersion);
            }
        }
    }

    //PRIVATE

    private Map<Id, copado__Artifact__c> getPackagesById() {
        Set<Id> packageIds = getPackageIds();

        Map<Id, copado__Artifact__c> result = new Map<Id, copado__Artifact__c>(
            new PackagesSelector().byRecordType(new Set<String>{ SALESFORCE_PACKAGE_RECORD_TYPE }, packageIds)
        );
        return result;
    }

    private Set<Id> getPackageIds() {
        Set<Id> result = new Set<Id>();
        for (copado__Artifact_Version__c version : records) {
            result.add(version.copado__Artifact__c);
        }
        return result;
    }

    private void updateVersionStatus(copado__Artifact_Version__c newVersion) {
        if (newVersion.copado__Is_released__c) {
            newVersion.copado__Status__c = STATUS_PUBLISHED;
        } else if (!newVersion.copado__Is_released__c && String.isNotBlank(newVersion.copado__Subscriber_Version_Id__c)) {
            newVersion.copado__Status__c = STATUS_PRE_RELEASED;
        } else if (String.isBlank(newVersion.copado__Subscriber_Version_Id__c)) {
            newVersion.copado__Status__c = STATUS_DRAFT;
        }
    }

    private void updateVersionBranch(copado__Artifact_Version__c newVersion, copado__Artifact__c pkg) {
        newVersion.copado__Branch__c = String.isNotBlank(newVersion.copado__Branch__c) ? newVersion.copado__Branch__c : pkg?.copado__DefaultBranch__c;
    }
}