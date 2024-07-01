public with sharing class UpdateInstallationKey {
    private final static String JOB_TEMPLATE = 'SFDX Package Version Update_1';

    @AuraEnabled
    public static String fetchInstallationKey(Id subscriberVersionId) {
        List<PackageVersionInstallationKey__c> keys = new PackageVersionInstallationKeySelector()
            .byPackageVersionId(new Set<Id>{ subscriberVersionId });
        return keys.isEmpty() ? null : keys[0]?.InstallationKey__c;
    }

    @AuraEnabled
    public static void executeJob(Id subscriberVersionId, String installationKey) {
        if (String.isBlank(subscriberVersionId)) {
            throw new ApplicationException(Label.Empty_Subscriber_Version_Id);
        }
        try {
            PackageVersionUpdateJob.Version version = new PackageVersionUpdateJob.Version();
            version.installationKey = installationKey;
            version.packageVersion = getVersion(subscriberVersionId);
            version.apiVersion = getApiVersion(version.packageVersion);

            new PackageVersionUpdateJob(version, JOB_TEMPLATE).execute();
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    private static copado__Artifact_Version__c getVersion(Id subscriberVersionId) {
        List<copado__Artifact_Version__c> result = new PackageVersionsSelector().bySubscriberIds(new Set<Id>{ subscriberVersionId });
        if (result.isEmpty()) {
            throw new ApplicationException(Label.Invalid_Subscriber_Version_Id);
        }

        String devHub = result[0]?.copado__Artifact__r?.copado__Target_Dev_Hub_Org__c;
        if (String.isBlank(devHub)) {
            throw new ApplicationException(Label.PopulateTargetDevHub);
        }
        return result[0];
    }

    private static String getApiVersion(copado__Artifact_Version__c version) {
        return String.isNotBlank(version.Api_Version__c) ? version.Api_Version__c : version.copado__Artifact__r.Api_Version__c;
    }
}