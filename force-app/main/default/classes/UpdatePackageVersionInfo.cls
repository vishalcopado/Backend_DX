public with sharing class UpdatePackageVersionInfo {
    private final static String JOB_TEMPLATE = 'SFDX Package Version Update_1';

    @InvocableMethod(label='Update Package Version Info')
    public static void execute(List<Request> requests) {
        try {
            PackageVersionUpdateJob.Version version = new PackageVersionUpdateJob.Version();
            version.packageVersion = new PackageVersionsSelector().byIds(new Set<Id>{ (Id) requests[0].versionId }).get(0);
            validatePackageVersionUpdate(version.packageVersion, requests[0]);

            version.packageVersion.copado__Version_Name__c = requests[0].versionName;
            version.packageVersion.copado__Version_Description__c = requests[0].description;
            version.packageVersion.copado__Tag__c = requests[0].tag;
            version.packageVersion.copado__Branch__c = requests[0].branch;
            version.apiVersion = getApiVersion(version.packageVersion);

            new PackageVersionUpdateJob(version, JOB_TEMPLATE).execute();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    // PRIVATE

    private static void validatePackageVersionUpdate(copado__Artifact_Version__c version, Request request) {
        if (String.isBlank(request.versionName) && String.isNotBlank(version.copado__Version_Name__c)) {
            throw new ApplicationException(Label.Package_Version_Name_Not_Blank);
        }
        if (String.isBlank(request.description) && String.isNotBlank(version.copado__Version_Description__c)) {
            throw new ApplicationException(Label.Package_Version_Description_Not_Blank);
        }
        if (String.isBlank(request.tag) && String.isNotBlank(version.copado__Tag__c)) {
            throw new ApplicationException(Label.Package_Version_Tag_Not_Blank);
        }
        if (String.isBlank(request.branch) && String.isNotBlank(version.copado__Branch__c)) {
            throw new ApplicationException(Label.Package_Version_Branch_Not_Blank);
        }
    }

    private static String getApiVersion(copado__Artifact_Version__c version) {
        return String.isNotBlank(version.Api_Version__c) ? version.Api_Version__c : version.copado__Artifact__r.Api_Version__c;
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Package Version Name')
        public String versionName;

        @InvocableVariable(label='Package Version Branch')
        public String branch;

        @InvocableVariable(label='Package Version Tag')
        public String tag;

        @InvocableVariable(label='Package Version Description')
        public String description;

        @InvocableVariable(label='Package Version Id' required=true)
        public String versionId;
    }
}