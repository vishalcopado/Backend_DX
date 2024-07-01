public with sharing class PackageVersionCreateAction {
    private static final String MASK_SEQUENCE = '****';

    // PUBLIC

    @InvocableMethod(label='Create Package Version' category='Package Version Creation')
    public static List<Response> execute(List<Request> requests) {
        try {
            PackageInfo.Versions version = parseVersion(requests[0].packageVersionJson);

            DataJson parsedJSON = (DataJson) JSON.deserialize(requests[0].jsonInformation, DataJson.class);
            JsonInformation jsonInformation = (JsonInformation) JSON.deserialize(parsedJSON.jsonInformation, JsonInformation.class);
            copado__Artifact_Version__c result = createVersion(version, jsonInformation);

            if (!(Boolean) jsonInformation.installationkeybypass && String.isNotBlank((String) jsonInformation.installationkey)) {
                storeInstallationKey(result.Name, version.SubscriberPackageVersionId, jsonInformation);

                maskDataJson(parsedJSON, jsonInformation, requests[0].jobExecutionId);
            }
            return new List<Response>{ new Response(JSON.serialize(result, true).escapeJava()) };
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static void maskDataJson(DataJson parsedJSON, JsonInformation jsonInformation, Id jobExecutionId) {
        jsonInformation.installationkey = MASK_SEQUENCE;

        parsedJSON.jsonInformation = JSON.serialize(jsonInformation);

        copado__JobExecution__c jobExecution = new copado__JobExecution__c(Id = jobExecutionId, copado__DataJson__c = JSON.serialize(parsedJSON));
        Utilities.performDML(new List<copado__JobExecution__c>{ jobExecution }, 'update', AccessLevel.USER_MODE);
    }

    private static copado__Artifact_Version__c createVersion(PackageInfo.Versions version, JsonInformation parsedJSON) {
        copado__Artifact__c pkg = getpackage(version.Package2Id);

        copado__Artifact_Version__c result = new copado__Artifact_Version__c(Id = (Id) parsedJSON.versionId);
        result.copado__Package_Version_Id__c = version.Id;
        result.copado__Subscriber_Version_Id__c = version.SubscriberPackageVersionId;
        result.copado__Is_released__c = version.IsReleased;
        result.copado__Branch__c = version.Branch;
        result.copado__Version_Name__c = version.Name;
        result.copado__Tag__c = version.Tag;
        result.copado__Version_Description__c = version.Description;
        result.copado__Version_number__c = version.Version;
        result.copado__Data_JSON__c = getDataJSON(pkg, version);
        result.Has_Installation_Key__c = version.IsPasswordProtected;
        result.Ancestor_Id__c = version.AncestorId;
        result.Ancestor_Version__c = version.AncestorVersion;
        result.Skip_Validation__c = version.ValidationSkipped;
        result.Post_Install_URL__c = version.InstallUrl;
        result.Name = pkg.Name + ' - ' + version.Version;
        if (String.isBlank(result.Id)) {
            result.copado__Artifact__c = pkg.Id;
        }
        return result;
    }

    private static PackageInfo.Versions parseVersion(String versionJSON) {
        return (PackageInfo.Versions) System.JSON.deserialize(versionJSON, PackageInfo.Versions.class);
    }

    private static copado__Artifact__c getpackage(Id packageId) {
        return new PackagesSelector().byPackage2Ids(new Set<Id>{ packageId }).get(0);
    }

    private static String getDataJSON(copado__Artifact__c pkg, PackageInfo.Versions version) {
        return JSON.serialize(new Map<String, Object>{ 'codecoverage' => version.CodeCoverage });
    }

    private static void storeInstallationKey(String versionName, String subscriberVersionId, JsonInformation parsedJSON) {
        PackageVersionInstallationKey__c key = new PackageVersionInstallationKey__c();
        key.Name = versionName;
        key.PackageVersionId__c = subscriberVersionId;
        key.InstallationKey__c = (String) parsedJSON.installationkey;

        Utilities.performDML(new List<PackageVersionInstallationKey__c>{ key }, 'insert', AccessLevel.SYSTEM_MODE);
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Generated package version JSON info' required=true)
        public String packageVersionJson;

        @InvocableVariable(label='Package version additional JSON info')
        public String jsonInformation;

        @InvocableVariable(label='Job Execution ID')
        public String jobExecutionId;
    }

    @TestVisible
    private class DataJson {
        private String versionNumber;
        private String versionName;
        private String packageId;
        @TestVisible
        private String jsonInformation;
        private String description;
        private String actionCallback;
    }

    @TestVisible
    private class JsonInformation {
        private String apiversion;
        private String tag;
        private String postinstallscript;
        private Boolean skipvalidation;
        private String uninstallscript;
        private String postinstallurl;
        private String releasenotesurl;
        private String versiondescription;
        private Boolean installationkeybypass;
        @TestVisible
        private String installationkey;
        private Boolean codecoverage;
        private String definitionfile;
        private String branch;
        private String versionId;
    }

    public class Response {
        @InvocableVariable
        public String version;

        public Response(String version) {
            this.version = version;
        }
    }
}