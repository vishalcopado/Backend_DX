public with sharing class JobStepCustomSettingHandler {
    @TestVisible
    private static copado.GlobalAPI.ProxyOrgResponse mockResponse;
    private static final String API_VERSION = 'v53.0';
    private static final String IS_SUCCESS = 'isSuccess';
    private static final String MESSAGE = 'message';
    private static final String PROFILE_SOBJECT = 'Profile';
    private static final String USER_SOBJECT = 'User';
    private static final String ORGANIZATION_SOBJECT = 'Organization';
    private static final String CUSTOM_SETTING_RECORD = 'customSetting';
    private static final String PROFILE_RECORD = 'profile';
    private static final String USER_RECORD = 'user';
    private static final String ORGANIZATION_RECORD = 'organization';
    private static final String OBJECT_KEY_PREFIX = 'objectKeyPrefix';
    private static final String LOG_LABEL_GET_CUSTOM_SETTING = 'Querying all custom settings, Tooling API Query.';
    private static final String LOG_LABEL_GET_CUSTOM_SETTING_RECORD = 'Querying all {0} custom setting record(s).';
    private static final String LOG_LABEL_GET_PROFILE_RECORD = 'Querying profile record(s).';
    private static final String LOG_LABEL_GET_USER_RECORD = 'Querying user record(s).';
    private static final String LOG_LABEL_GET_ORG_RECORD = 'Querying organization record(s).';

    // PUBLIC

    @AuraEnabled
    public static List<Object> getCustomSettings(String credentialId) {
        return executeQuery(
            'SELECT QualifiedApiName, DeveloperName FROM EntityDefinition WHERE IsCustomSetting = true',
            LOG_LABEL_GET_CUSTOM_SETTING,
            credentialId
        );
    }

    @AuraEnabled
    public static Map<String, Object> getRecords(String objectAPIName, String credentialId) {
        Map<String, Object> result = new Map<String, Object>{ IS_SUCCESS => false, MESSAGE => Label.NoCustomSettingRecords };
        Map<String, String> objectKeyPrefixes = getObjectKeyPrefix();
        try {
            List<Object> customSettingRecords = executeQuery(
                'SELECT Id, Name, SetupOwnerId, SetupOwner.Name FROM ' + objectAPIName,
                String.format(LOG_LABEL_GET_CUSTOM_SETTING_RECORD, new List<Object>{ objectAPIName }),
                credentialId
            );
            if (!customSettingRecords.isEmpty()) {
                result = getCustomSettingDependantRecords(customSettingRecords, objectKeyPrefixes, credentialId);
                result.put(IS_SUCCESS, true);
                result.put(OBJECT_KEY_PREFIX, objectKeyPrefixes);
                result.put(CUSTOM_SETTING_RECORD, customSettingRecords);
            }
        } catch (Exception error) {
            result.put(MESSAGE, error.getMessage());
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<copado__Function__c> getFunctionDetails(String apiName) {
        return new FunctionsSelector().byApiName(new Set<String>{ apiName });
    }

    //PRIVATE

    private static String getEndpoint(String api, String queryParam) {
        return api + '/query/?q=' + queryParam;
    }

    private static copado.GlobalAPI.ProxyOrgRequest createRequest(String endpoint, String logLabelIdentifier, String credentialId) {
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = endpoint;
        request.orgCredentialId = credentialId;
        request.logLabelIdentifier = logLabelIdentifier;
        request.requestType = HttpMethod.GET.name();

        return request;
    }

    private static copado.GlobalAPI.ProxyOrgResponse makeCallout(copado.GlobalAPI.ProxyOrgRequest request) {
        return Test.isRunningTest() ? mockResponse : new copado.GlobalAPI().proxyOrgRequest(request);
    }

    private static List<Object> processResponse(copado.GlobalAPI.ProxyOrgResponse response, String stepInformation) {
        if (response.statusCode == 200) {
            Map<String, Object> content = (Map<String, Object>) JSON.deserializeUntyped(response.content);
            return (List<Object>) content.get('records');
        } else {
            String message = String.isNotBlank(response.errorMessage) ? response.errorMessage : 'Error : ' + stepInformation;
            throw new ApplicationException(message);
        }
    }

    @TestVisible
    private static Map<String, Object> getCustomSettingDependantRecords(
        List<Object> customSettingRecords,
        Map<String, String> objectKeyPrefixes,
        String credentialId
    ) {
        Map<String, Object> result = new Map<String, Object>();
        Set<Id> profileIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> orgIds = new Set<Id>();

        for (Object data : customSettingRecords) {
            Map<String, Object> record = (Map<String, Object>) data;
            String setupOwnerId = (String) record.get('SetupOwnerId');
            String setupOwnerPrefix = setupOwnerId.substring(0, 3);
            if (objectKeyPrefixes.get(setupOwnerPrefix) == PROFILE_SOBJECT) {
                profileIds.add(setupOwnerId);
            } else if (objectKeyPrefixes.get(setupOwnerPrefix) == USER_SOBJECT) {
                userIds.add(setupOwnerId);
            } else if (objectKeyPrefixes.get(setupOwnerPrefix) == ORGANIZATION_SOBJECT) {
                orgIds.add(setupOwnerId);
            }
        }

        if (!profileIds.isEmpty()) {
            List<Object> profiles = executeQuery(
                'SELECT Id, Name FROM Profile WHERE Id IN (\'' +
                String.join(new List<Id>(profileIds), '\',\'') +
                '\')',
                LOG_LABEL_GET_PROFILE_RECORD,
                credentialId
            );
            result.put(PROFILE_RECORD, profiles);
        }

        if (!userIds.isEmpty()) {
            List<Object> users = executeQuery(
                'SELECT Id, Name, Profile.Name FROM User WHERE Id IN (\'' +
                String.join(new List<Id>(userIds), '\',\'') +
                '\')',
                LOG_LABEL_GET_USER_RECORD,
                credentialId
            );
            result.put(USER_RECORD, users);
        }

        if (!orgIds.isEmpty()) {
            List<Object> orgs = executeQuery(
                'SELECT Id, Name FROM Organization WHERE Id IN (\'' +
                String.join(new List<Id>(orgIds), '\',\'') +
                '\')',
                LOG_LABEL_GET_ORG_RECORD,
                credentialId
            );
            result.put(ORGANIZATION_RECORD, orgs);
        }

        return result;
    }

    private static List<Object> executeQuery(String query, String logLabelIdentifier, String credentialId) {
        String queryParam = EncodingUtil.urlEncode(query, 'UTF-8');
        String endpoint = getEndpoint('/services/data/' + API_VERSION, queryParam);
        copado.GlobalAPI.ProxyOrgResponse response = makeCallout(createRequest(endpoint, logLabelIdentifier, credentialId));
        return processResponse(response, logLabelIdentifier);
    }

    @TestVisible
    private static Map<String, String> getObjectKeyPrefix() {
        Map<String, String> result = new Map<String, String>();
        Set<String> sObjects = new Set<String>{ PROFILE_SOBJECT, USER_SOBJECT, ORGANIZATION_SOBJECT };
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String sObjectName : sObjects) {
            if (globalDescribe.containsKey(sObjectName)) {
                result.put(globalDescribe.get(sObjectName).getDescribe().getKeyPrefix(), sObjectName);
            }
        }
        return result;
    }
}