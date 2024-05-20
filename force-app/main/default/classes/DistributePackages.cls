public with sharing class DistributePackages {
    private static final String PACKAGE_VERSION_PUBLISHED_STATUS = 'Published';
    private static final String PACKAGE_VERSION_PRERELEASE_STATUS = 'Pre-Release';
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<copado__Artifact_Version__c> fetchPkgVersionsFor(Id packageId) {
        List<copado__Artifact_Version__c> result = new PackageVersionsSelector()
            .byStatusAndIds(new Set<Id>{ packageId }, new Set<String>{ PACKAGE_VERSION_PUBLISHED_STATUS, PACKAGE_VERSION_PRERELEASE_STATUS });
        if (result.isEmpty()) {
            throw new ApplicationException(Label.No_Generated_Package_Versions);
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<copado__Org__c> getCredentials(List<String> credentialIds) {
        if (credentialIds.isEmpty()) {
            List<copado__Org__c> credentials = new CredentialsSelector().byActiveEnvAndPlatform(new Set<String>{ 'SFDX','Salesforce'});
            if (credentials.isEmpty()) {
                throw new ApplicationException(Label.No_SFDX_Platform_Environment);
            }
            return credentials;
        } else {
            return new CredentialsSelector().byIds(credentialIds);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<copado__Project__c> getProjects() {
        return new ProjectsSelector().byActivePipelineRepoAndPlatform(new Set<String>{'SFDX', 'Salesforce'});
    }

    @AuraEnabled
    public static List<copado__JobExecution__c> initiateDistributionFor(String pkgVersionId, List<String> credentialIds, String pkgSecurityType) {
        return new DeployPackages(pkgVersionId, credentialIds, pkgSecurityType).execute();
    }
}