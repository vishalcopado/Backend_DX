public with sharing class PackageVersionIds {
    private static final String MASK_SEQUENCE = '****';

    public with sharing class Request {
        @InvocableVariable(label='Subscriber ID')
        public String subscriberId;

        @InvocableVariable(label='Job Execution ID')
        public String jobExecutionId;

        @InvocableVariable(label='Job Execution Data Json')
        public String dataJson;
    }

    public with sharing class Result {
        @InvocableVariable(label='Package Versions')
        public List<copado__Artifact_Version__c> versions = new List<copado__Artifact_Version__c>();
    }

    @InvocableMethod(label='Retrieve Package Version Ids' description='Return Package Version Ids' category='Apex Action')
    public static List<Result> packageVersionsBydId(List<Request> requests) {
        try {
            List<copado__Artifact_Version__c> versions = getInstalledPackages(requests);
            Result result = new Result();
            result.versions.addAll(versions);

            maskDataJson(requests[0].dataJson, requests[0].jobExecutionId);

            return new List<Result>{ result };
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    public static void maskDataJson(String dataJson, Id jobExecutionId) {
        DataJson data = (DataJson) JSON.deserialize(dataJson, DataJson.class);
        if (String.isNotBlank(data.installationKey)) {
            data.installationKey = MASK_SEQUENCE;

            copado__JobExecution__c execution = new copado__JobExecution__c(Id = jobExecutionId, copado__DataJson__c = JSON.serialize(data));
            update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ execution }).getRecords();
        }
    }

    private static List<copado__Artifact_Version__c> getInstalledPackages(List<Request> requests) {
        Set<Id> versionIds = new Set<Id>();
        List<PackageStatus> versions = (List<PackageStatus>) JSON.deserialize(requests[0].subscriberId, List<PackageStatus>.class);

        for (PackageStatus pkgstatus : versions) {
            if (pkgstatus.status == 'success') {
                versionIds.add(pkgstatus.versionId);
            }
        }
        return new PackageVersionsSelector().bySubscriberIds(versionIds);
    }

    private class PackageStatus {
        public Id versionId;
        public String status;
    }

    @TestVisible
    private class DataJson {
        @TestVisible
        private String subscriberId;
        @TestVisible
        private String installSecurityType;
        @TestVisible
        private String installationKey;
        @TestVisible
        private String deploymentJobId;
        @TestVisible
        private String apiVersion;
    }
}