public with sharing class ConfigureVersionFromGitController {
    private final static String JOB_TEMPLATE = 'SFDX Package Version Git Configure_1';

    @AuraEnabled
    public static void getGitConfig(Id recordId) {
        try {
            PackageVersionUpdateJob.Version version = new PackageVersionUpdateJob.Version();
            version.packageVersion = getVersion(recordId);
            new PackageVersionUpdateJob(version, JOB_TEMPLATE).execute();
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    private static copado__Artifact_Version__c getVersion(Id recordId) {
        copado__Artifact_Version__c result = new PackageVersionsSelector().byIds(new Set<Id>{ recordId }).get(0);
        return result;
    }
}