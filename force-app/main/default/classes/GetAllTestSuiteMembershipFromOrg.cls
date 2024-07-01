public with sharing class GetAllTestSuiteMembershipFromOrg {
    private final static String LOG_LABEL_APEX_TEST_SUITE = 'Test Suite - Retriever';
    private final static String LOG_LABEL_TEST_SUITE_MEMBERSHIP = 'Test Suite Membership - Retriever';
    private final static String SOQL_ENPOINT_PREFIX = Settings.TOOLING_API_ENDPOINT + '/query/?q=';
    private final static String TEST_SUITE_RETRIEVAL_ERROR = 'Error retrieving Apex Test Suite';
    private final static String TEST_SUITE_MEMBERSHIP_RETRIEVAL_ERROR = 'Error retrieving Test Suite Membership';

    @TestVisible
    private static String testSuiteMockResponse;
    @TestVisible
    private static String testSuiteMembershipMockResponse;

    private Id orgCredentialId;
    private Set<String> testSuites;

    // CTR

    public GetAllTestSuiteMembershipFromOrg(Id orgCredentialId) {
        this.orgCredentialId = orgCredentialId;
        this.testSuites = new Set<String>();
    }

    public GetAllTestSuiteMembershipFromOrg(Id orgCredentialId, Set<String> testSuites) {
        this.orgCredentialId = orgCredentialId;
        this.testSuites = testSuites != null ? testSuites : new Set<String>();
    }

    // PUBLIC

    public List<TestSuiteMembership> execute() {
        List<TestSuiteMembership> result = new List<TestSuiteMembership>();
        copado.GlobalAPI.ProxyOrgResponse apexTestSuiteResponse = getQueryResponse(
            getApexTestSuiteQuery(),
            LOG_LABEL_APEX_TEST_SUITE,
            TEST_SUITE_RETRIEVAL_ERROR
        );
        List<ApexTestSuite> apexTestSuites = deserializeToApexTestSuites(apexTestSuiteResponse.content);
        if (!apexTestSuites.isEmpty()) {
            copado.GlobalAPI.ProxyOrgResponse testSuiteMembershipResponse = getQueryResponse(
                getTestSuiteMembershipQuery(apexTestSuites),
                LOG_LABEL_TEST_SUITE_MEMBERSHIP,
                TEST_SUITE_MEMBERSHIP_RETRIEVAL_ERROR
            );
            result = deserializeToTestSuiteMemberships(testSuiteMembershipResponse.content);
        }
        return result;
    }

    // PRIVATE

    private copado.GlobalAPI.ProxyOrgResponse getQueryResponse(String query, String logLabel, String errorMessage) {
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = getEndpoint(query);
        request.orgCredentialId = this.orgCredentialId;
        request.logLabelIdentifier = logLabel;
        request.requestType = HttpMethod.GET.name();
        copado.GlobalAPI.ProxyOrgResponse result;

        result = !Test.isRunningTest()
            ? new copado.GlobalAPI().proxyOrgRequest(request)
            : TestUtilities.getMockedResponse(getMockedResponse(errorMessage == TEST_SUITE_RETRIEVAL_ERROR));
        if (result.statusCode != 200) {
            String message = String.isNotBlank(result.errorMessage) ? result.errorMessage : errorMessage;
            throw new ApplicationException(message);
        }
        return result;
    }

    private String getEndpoint(String query) {
        return (SOQL_ENPOINT_PREFIX + getUrlEncoded(query, 'UTF-8'));
    }

    private String getUrlEncoded(String query, String encoding) {
        return (EncodingUtil.urlEncode(query, encoding));
    }

    private String getTestSuiteMembershipQuery(List<ApexTestSuite> apexTestSuites) {
        Map<Id, ApexTestSuite> apexTestSuitesById = new Map<Id, ApexTestSuite>(apexTestSuites);
        Set<String> fieldsToQuery = new Set<String>{
            'Id',
            'ApexClass.Name',
            'ApexClass.NamespacePrefix',
            'ApexClass.LastModifiedDate',
            'ApexClass.LastModifiedBy.Name',
            'ApexTestSuite.TestSuiteName',
            'ApexTestSuite.LastModifiedDate',
            'ApexTestSuite.LastModifiedBy.Name'
        };
        String result =
            'SELECT ' +
            getFormattedValue(fieldsToQuery, ',') +
            ' FROM TestSuiteMembership WHERE ApexTestSuiteId IN (\'' +
            getFormattedValue(apexTestSuitesById.keySet(), '\',\'') +
            '\')';
        return result;
    }

    private String getApexTestSuiteQuery() {
        return this.testSuites.isEmpty()
            ? 'SELECT Id FROM ApexTestSuite'
            : 'SELECT Id FROM ApexTestSuite WHERE TestSuiteName IN (\'' + getFormattedValue(testSuites, '\',\'') + '\')';
    }

    private List<ApexTestSuite> deserializeToApexTestSuites(String data) {
        String serializedRecords = getSerializedRecords(data);
        return String.isNotBlank(serializedRecords)
            ? (List<ApexTestSuite>) JSON.deserialize(serializedRecords, List<ApexTestSuite>.class)
            : new List<ApexTestSuite>();
    }

    private List<TestSuiteMembership> deserializeToTestSuiteMemberships(String data) {
        String serializedRecords = getSerializedRecords(data);
        return String.isNotBlank(serializedRecords)
            ? (List<TestSuiteMembership>) JSON.deserialize(serializedRecords, List<TestSuiteMembership>.class)
            : new List<TestSuiteMembership>();
    }

    private static String getSerializedRecords(String data) {
        String result;
        Map<String, Object> deserializedResponse = (Map<String, Object>) JSON.deserializeUntyped(data);
        if ((Integer) deserializedResponse.get('totalSize') > 0) {
            result = JSON.serialize(deserializedResponse.get('records'));
        }
        return result;
    }

    private static String getMockedResponse(Boolean isTestSuiteRequest) {
        return isTestSuiteRequest ? testSuiteMockResponse : testSuiteMembershipMockResponse;
    }

    private static String getFormattedValue(Set<String> data, String seperator) {
        return String.join(new List<String>(data), seperator);
    }

    private static String getFormattedValue(Set<Id> data, String seperator) {
        return String.join(new List<Id>(data), seperator);
    }
}