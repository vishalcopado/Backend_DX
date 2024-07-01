public with sharing class CredentialListView {
    @TestVisible
    private static String mockResponse;

    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<ListView> getSobjectListviews(String sobjectType) {
        try {
            return new ListViewSelector().bySobject(sobjectType);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String query) {
        try {
            return Database.query(query);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getListViewRecords(String listViewId) {
        String sobjectApiPath = '/services/data/v60.0/sobjects/';

        try {
            copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();

            request.endPointUrlService = sobjectApiPath + 'copado__Org__c/listviews/'+ listViewId + '/describe';
            request.orgCredentialId =  getCredential().Id;
            request.logLabelIdentifier = Label.Credential_List_View_Fetching;
            request.requestType = HttpMethod.GET.name();

            copado.GlobalAPI.ProxyOrgResponse proxyRequest = !Test.isRunningTest() ? new copado.GlobalAPI().proxyOrgRequest(request) : TestUtilities.getMockedResponse(mockResponse);
            return processResponse(proxyRequest, request.logLabelIdentifier);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static String processResponse(copado.GlobalAPI.ProxyOrgResponse response, String stepInformation) {
        if (response.statusCode == 200) {
            return response.content;
        } else {
            String message = String.isNotBlank(response.errorMessage) ? response.errorMessage : Label.Error + ': ' + stepInformation;
            throw new ApplicationException(message);
        }
    }

    private static copado__Org__c getCredential() {
        List<copado__Org__c> result = new CredentialsSelector().bySFDCOrgId(new Set<String>{  UserInfo.getOrganizationId() + '_' + UserInfo.getUserId() });
        if (result.isEmpty()) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }

        validateOrg(result[0].Id);
        return result[0];
    }

    private static void validateOrg(String orgId) {
        copado.ValidateOrgAction.Request request = new copado.ValidateOrgAction.Request();
        request.orgId = orgId;

        List<copado.ValidateOrgAction.Result> result = copado.ValidateOrgAction.execute(new List<copado.ValidateOrgAction.Request>{ request });
        Boolean isValid = !result.isEmpty() ? result.get(0).isValidOrg : false;

        if(!isValid) {
            throw new ApplicationException(Label.Org_Is_Not_Valid);
        }
    }
}