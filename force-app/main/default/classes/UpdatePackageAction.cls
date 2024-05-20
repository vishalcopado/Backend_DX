public with sharing class UpdatePackageAction {
    // PUBLIC

    @InvocableMethod(label='Update Package')
    public static List<Response> execute(List<Request> requests) {
        List<Response> result = new List<Response>();
        try {
            PackageInfo pkgInfo = (PackageInfo) JSON.deserialize(requests[0].resultData, PackageInfo.class);
            copado__Artifact__c artifact = getPackage(requests[0].packageRecordId, pkgInfo);

            updatePackages(new List<copado__Artifact__c>{ artifact });
        } catch (Exception ex) {
            result.add(new Response(ex.getMessage()));
        }
        return result;
    }

    // PRIVATE

    private static void updatePackages(List<copado__Artifact__c> packages) {
        update Security.stripInaccessible(AccessType.UPDATABLE, packages).getRecords();
    }

    private static copado__Artifact__c getPackage(Id recordId, PackageInfo pkgInfo) {
        return new copado__Artifact__c(Id = recordId, copado__Package_Id__c = pkgInfo.packageId, copado__Package_Namespace__c = pkgInfo.namespace);
    }

    // INNER

    public class Request {
        @InvocableVariable(required=true)
        public String resultData;

        @InvocableVariable(required=true label='Package Id')
        public Id packageRecordId;
    }

    public class Response {
        @InvocableVariable(label='Response')
        public String message;

        public Response(String message) {
            this.message = message;
        }
    }

    private class PackageInfo {
        private String packageId;
        private String namespace;
    }
}