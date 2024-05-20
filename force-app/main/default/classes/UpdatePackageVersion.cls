public with sharing class UpdatePackageVersion {
    private static PackageVersionUpdateJob.Version version;
    private static final String MASK_SEQUENCE = '****';

    // PUBLIC

    @InvocableMethod(label='Update Package Version')
    public static void updateRecords(List<Request> requests) {
        try {
            List<copado__Result__c> res = new ResultsSelector().byIds(new Set<Id>{ requests[0].prevResultId });

            version = (PackageVersionUpdateJob.Version) JSON.deserialize(res[0].copado__Result_Data__c, PackageVersionUpdateJob.Version.class);

            if (String.isNotBlank(requests[0].installationKey)) {
                updateInstallationKey(requests[0].installationKey);
                version.packageVersion.Has_Installation_Key__c = true;
                maskDataJson(
                    res[0].copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c,
                    res[0].copado__JobStep__r.copado__JobExecution__c
                );
            }
            updatePackageVersionRecord();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static void maskDataJson(String dataJson, Id jobExecutionId) {
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(dataJson);
        if (data.get('installationKey') != null) {
            data.put('installationKey', MASK_SEQUENCE);
            copado__JobExecution__c execution = new copado__JobExecution__c(Id = jobExecutionId, copado__DataJson__c = JSON.serialize(data));
            update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ execution }).getRecords();
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void updateInstallationKey(String key) {
        List<PackageVersionInstallationKey__c> keys = new PackageVersionInstallationKeySelector()
            .byPackageVersionId(new Set<Id>{ version.packageVersion.copado__Subscriber_Version_Id__c });

        PackageVersionInstallationKey__c newKey = new PackageVersionInstallationKey__c(
            Id = keys.isEmpty() ? null : keys[0].Id,
            InstallationKey__c = key,
            PackageVersionId__c = version.packageVersion.copado__Subscriber_Version_Id__c,
            Name = version.packageVersion.Name
        );

        //Note: Protected Custom Settings DML
        upsert newKey;
    }

    private static void updatePackageVersionRecord() {
        update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ version.packageVersion }).getRecords();
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Previous Result Id' required=true)
        public String prevResultId;

        @InvocableVariable(label='Installation Key' required=false)
        public String installationKey;
    }
}