public with sharing class ListAllSobjectsInOrg {
    private String orgId;

    // CTOR

    public ListAllSobjectsInOrg(String orgId) {
        this.orgId = orgId;
    }

    // PUBLIC

    public List<SobjectItem> execute() {
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = getEndpoint();
        request.orgCredentialId = orgId;
        request.logLabelIdentifier = 'List all sobjects Tooling API Query';
        request.requestType = HttpMethod.GET.name();

        copado.GlobalAPI.ProxyOrgResponse response;
        if (!Test.isRunningTest()) {
            response = new copado.GlobalAPI().proxyOrgRequest(request);
        } else {
            response = mockResponse();
        }

        return processResponse(response);
    }

    // PRIVATE

    private String getEndpoint() {
        return Settings.TOOLING_API_ENDPOINT + '/sobjects';
    }

    private List<SobjectItem> processResponse(copado.GlobalAPI.ProxyOrgResponse response) {
        if (response.statusCode == 200) {
            ListAllSobjectsResult content = (ListAllSobjectsResult) JSON.deserialize(response.content, ListAllSobjectsResult.class);
            return content.sobjects;
        } else {
            String message = String.isNotBlank(response.errorMessage) ? response.errorMessage : Label.ListSobjectsErrorMessage;
            throw new ApplicationException(message);
        }
    }

    // INNER

    private with sharing class ListAllSobjectsResult {
        private List<SobjectItem> sobjects;
    }

    @TestVisible
    private static copado.GlobalAPI.ProxyOrgResponse mockResponse() {
        return TestUtilities.getMockedResponse(
            JSON.serialize(new Map<String, Object>{ 'statusCode' => 200, 'content' => '{"sobjects":[{"Name":"ApexClass"}]}' })
        );
    }
}