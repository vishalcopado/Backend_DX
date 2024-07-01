public with sharing class GetApexCodeCoverageFromOrg {
    private Set<String> metadataNames;
    private Id credentialId;

    @TestVisible
    private static String mockNonCoveredItemsResponse;

    // CONSTRUCTOR

    public GetApexCodeCoverageFromOrg(Set<String> metadataNames, Id credentialId) {
        this.metadataNames = metadataNames;
        this.credentialId = credentialId;
    }

    // PUBLIC

    public SoqlApiResponse execute() {
        SoqlApiResponse result;
        if (!this.metadataNames?.isEmpty()) {
            String query =
                'SELECT+ApexClassOrTrigger.Name,NumLinesCovered,NumLinesUncovered+FROM+ApexCodeCoverageAggregate+WHERE+ApexClassOrTrigger.Name+IN+(' +
                getFormattedMetadataNames() +
                ')';
            copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
            request.endPointUrlService = '/services/data/v54.0/tooling/query/?q=' + query;
            request.orgCredentialId = this.credentialId;
            request.logLabelIdentifier = 'Apex Tests Service - Retrieving non covered metadata items';
            request.requestType = HttpMethod.GET.name();
            copado.GlobalAPI.ProxyOrgResponse response = getCodeCoverageResponse(request);
            result = (SoqlApiResponse) JSON.deserialize(response.content, SoqlApiResponse.class);
        }
        return result;
    }

    // PRIVATE

    private copado.GlobalAPI.ProxyOrgResponse getCodeCoverageResponse(copado.GlobalAPI.ProxyOrgRequest request) {
        copado.GlobalAPI.ProxyOrgResponse result;
        if (!Test.isRunningTest()) {
            result = new copado.GlobalAPI().proxyOrgRequest(request);
            if (result.statusCode != 200) {
                String message = String.isNotBlank(result.errorMessage) ? result.errorMessage : 'Error searching metadata';
                throw new ApplicationException(message);
            }
        } else {
            result = TestUtilities.getMockedResponse(mockNonCoveredItemsResponse);
        }
        return result;
    }

    private String getFormattedMetadataNames() {
        return '\'' + String.join(new List<String>(this.metadataNames), '\',\'') + '\'';
    }

    // INNER

    public class SoqlApiResponse {
        public List<MetadataCoverage> records;
    }

    public class MetadataCoverage {
        @SuppressWarnings('PMD.FieldNamingConventions')
        // The naming conventions warning is suppressed to match the response data
        public MetadataItem ApexClassOrTrigger;
        public Integer numLinesCovered;
        public Integer numLinesUncovered;
    }

    public class MetadataItem {
        @SuppressWarnings('PMD.FieldNamingConventions')
        // The naming conventions warning is suppressed to match the response data
        public String Name;
    }
}