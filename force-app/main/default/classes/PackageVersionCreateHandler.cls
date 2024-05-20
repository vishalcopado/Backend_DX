public with sharing class PackageVersionCreateHandler {
    @AuraEnabled
    public static void startCreate(String recordId, String installationKey) {
        copado__Artifact_Version__c version = getVersion(recordId);
        Copado.PackageVersionCreateAction.Request request = createRequest(version, installationKey);

        List<Copado.PackageVersionCreateAction.Response> response = Copado.PackageVersionCreateAction.create(
            new List<Copado.PackageVersionCreateAction.Request>{ request }
        );

        updateJobId(version, response[0]?.job?.Id);
    }

    private static Copado.PackageVersionCreateAction.Request createRequest(copado__Artifact_Version__c version, String installationKey) {
        Copado.PackageVersionCreateAction.Request request = new Copado.PackageVersionCreateAction.Request(
            version.copado__Artifact__c,
            createJSON(version, installationKey)
        );

        request.versionName = version.copado__Version_Name__c;
        request.versionNumber = version.copado__Version_number__c;
        request.description = String.isNotBlank(version.copado__Version_Description__c) ? version.copado__Version_Description__c : '';

        return request;
    }

    private static String createJSON(copado__Artifact_Version__c version, String installationKey) {
        Map<String, Object> data = getDataJSON(version.copado__Data_JSON__c);

        Map<String, Object> jsonInformation = new Map<String, Object>{
            'versionId' => version.Id,
            'branch' => version.copado__Branch__c,
            'definitionfile' => version.copado__DefinitionFile__c,
            'codecoverage' => getBooleanValue(version.Code_Coverage__c, data.get('codecoverage')),
            'installationkey' => installationKey,
            'installationkeybypass' => getBooleanValue(String.isBlank(installationKey), data.get('installationkeybypass')),
            'versiondescription' => version.copado__Version_Description__c,
            'releasenotesurl' => getStringValue(version.Release_Notes_URL__c, data.get('releasenotesurl')),
            'postinstallurl' => getStringValue(version.Post_Install_URL__c, data.get('postinstallurl')),
            'uninstallscript' => getStringValue(version.Uninstall_Script__c, data.get('uninstallscript')),
            'skipvalidation' => getBooleanValue(version.Skip_Validation__c, data.get('skipvalidation')),
            'postinstallscript' => getStringValue(version.Post_Install_Script__c, data.get('postinstallscript')),
            'tag' => getStringValue(version.copado__Tag__c, data.get('tag')),
            'apiversion' => getApiVersion(version)
        };

        return JSON.serialize(jsonInformation);
    }

    private static Map<String, Object> getDataJSON(String dataJSON) {
        Map<String, Object> result = String.isNotBlank(dataJSON)
            ? (Map<String, Object>) JSON.deserializeUntyped(dataJSON)
            : new Map<String, Object>();

        return result;
    }

    private static String getStringValue(String recordValue, Object jsonValue) {
        return String.isNotBlank(recordValue) ? recordValue : (String) jsonValue;
    }

    private static Boolean getBooleanValue(Boolean recordValue, Object jsonValue) {
        return (recordValue ? recordValue : (jsonValue != null ? true : false));
    }

    private static void updateJobId(copado__Artifact_Version__c version, Id jobId) {
        version.copado__LastJobExecutionId__c = jobId;
        update Security.stripInaccessible(AccessType.UPDATABLE, new List<copado__Artifact_Version__c>{ version }).getRecords();
    }

    private static copado__Artifact_Version__c getVersion(Id recordId) {
        return new PackageVersionsSelector().byIds(new Set<Id>{ recordId }).get(0);
    }

    private static String getApiVersion(copado__Artifact_Version__c version) {
        return String.isNotBlank(version.Api_Version__c) ? version.Api_Version__c : version.copado__Artifact__r.Api_Version__c;
    }
}