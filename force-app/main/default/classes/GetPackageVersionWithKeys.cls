/*
TODO: We are not using the corresponsing flow anymore, this class needs to be removed from the package.
*/
public with sharing class GetPackageVersionWithKeys {
    private Id subscriberVersionId;
    private Map<Id, PackageVersion> versionsMap = new Map<Id, PackageVersion>();

    // CTOR

    public GetPackageVersionWithKeys(Id subscriberVersionId, Set<Id> dependenciesIds) {
        this.subscriberVersionId = subscriberVersionId;
        for (Id dependency : dependenciesIds) {
            this.versionsMap.put(dependency, new PackageVersion(dependency, null));
        }
    }

    // PUBLIC

    @InvocableMethod(label='Get Package Version With Key' category='Copado Package Version')
    public static List<Response> execute(List<Request> request) {
        try {
            VersionDetails details = (VersionDetails) JSON.deserialize(request[0].versionDetails, VersionDetails.class);

            GetPackageVersionWithKeys versionObj = new GetPackageVersionWithKeys(request[0].subscriberVersionId, new Set<Id>(details.dependencies));
            versionObj.getVersionDetails(details);

            return new List<Response>{ new Response(versionObj.versionsMap.values()) };
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private void getVersionDetails(VersionDetails details) {
        Set<Id> dependenciesIds = versionsMap.keySet();
        if (!dependenciesIds.isEmpty()) {
            addDependenciesWithKeys();
        }
        addPackageVersion(details);
    }

    private void addDependenciesWithKeys() {
        Set<Id> dependenciesIds = versionsMap.keySet();
        for (PackageVersionInstallationKey__c key : new PackageVersionInstallationKeySelector().byPackageVersionId(dependenciesIds)) {
            versionsMap.put(key.PackageVersionId__c, new PackageVersion(key.PackageVersionId__c, key.InstallationKey__c));
        }
    }

    private void addPackageVersion(VersionDetails details) {
        List<PackageVersionInstallationKey__c> versionKey = new PackageVersionInstallationKeySelector()
            .byPackageVersionId(new Set<Id>{ subscriberVersionId });

        String key = versionKey.isEmpty() ? null : versionKey[0].InstallationKey__c;
        versionsMap.put(
            subscriberVersionId,
            new PackageVersion(subscriberVersionId, key, (String) details.subscriberPackageId, (String) details.versionNumber)
        );
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Subscriber Package Version Id' required=true)
        public String subscriberVersionId;
        @InvocableVariable(label='Subscriber Package Version Id Details')
        public String versionDetails;
    }

    public class Response {
        @InvocableVariable(label='Package Versions with Key')
        public String versions;

        public Response(List<PackageVersion> versions) {
            this.versions = JSON.serialize(versions).escapeEcmaScript();
        }
    }

    @TestVisible
    private class PackageVersion {
        public String id;
        public String key;
        public String subscriberPackageId;
        public String versionNumber;

        public PackageVersion(String id, String key) {
            this.id = id;
            this.key = key;
        }

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public PackageVersion(String id, String key, String subscriberPackageId, String versionNumber) {
            this.id = id;
            this.key = key;
            this.versionNumber = versionNumber;
            this.subscriberPackageId = subscriberPackageId;
        }
    }

    @TestVisible
    private class VersionDetails {
        public String subscriberVersionId;
        public List<Id> dependencies;
        public String versionNumber;
        public String subscriberPackageId;
    }
}