public with sharing class GetAllTestClassesFromOrg {
    private final static String LOG_LABEL_APEX_CLASS = 'Apex Test Class - Retriever';
    private final static String SOSL_ENPOINT_PREFIX = '/services/data/v54.0/tooling/search/?q=';
    private String orgCredentialId;
    private Set<String> searchTerms;
    @TestVisible
    private static String mockResponse;

    // PUBLIC

    public GetAllTestClassesFromOrg(String orgCredentialId) {
        this.orgCredentialId = orgCredentialId;
    }

    public GetAllTestClassesFromOrg(String orgCredentialId, Set<String> searchTerms) {
        this.orgCredentialId = orgCredentialId;
        this.searchTerms = searchTerms;
    }

    public copado.GlobalAPI.ProxyOrgResponse execute() {
        String query = getSOSLQuery(this.searchTerms);
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = getEndpoint(query);
        request.orgCredentialId = this.orgCredentialId;
        request.logLabelIdentifier = LOG_LABEL_APEX_CLASS;
        request.requestType = HttpMethod.GET.name();
        copado.GlobalAPI.ProxyOrgResponse result;

        result = !Test.isRunningTest() ? new copado.GlobalAPI().proxyOrgRequest(request) : TestUtilities.getMockedResponse(mockResponse);
        if (result.statusCode != 200) {
            String message = String.isNotBlank(result.errorMessage) ? result.errorMessage : Label.Error_Finding_Test_Classes_From_Org;
            throw new ApplicationException(message);
        }

        return result;
    }

    // PRIVATE

    private static String getEndpoint(String query) {
        return (SOSL_ENPOINT_PREFIX + getUrlEncoded(query, 'UTF-8'));
    }

    private static String getUrlEncoded(String query, String encoding) {
        return (EncodingUtil.urlEncode(query, encoding));
    }

    @TestVisible
    private static String getSOSLQuery(Set<String> searchTerms) {
        String searchTermForSOSL = searchTerms != null && !searchTerms.isEmpty() ? String.join(new List<String>(searchTerms), '" OR "') : '';
        String result =
            'FIND {(@IsTest OR "testMethod void")' +
            (String.isNotBlank(searchTermForSOSL) ? ' AND ("' + searchTermForSOSL + '")' : '') +
            '} IN ALL FIELDS RETURNING ApexClass(Name, NamespacePrefix, LastModifiedDate, LastModifiedBy.Name WHERE Status = \'Active\' ORDER BY LastModifiedDate DESC)';
        return result;
    }
}