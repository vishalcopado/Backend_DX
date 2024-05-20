public with sharing class MetadataApiMetadataRetriever implements IMetadataRetriever {
    private static final String SESSION_ID = '{{SALESFORCE_SESSION_ID}}';

    protected String metadataTypeName;
    protected String searchTerm;

    protected String soapEnvelope;

    // PUBLIC

    public virtual IMetadataRetriever configure(String type, String searchTerm) {
        this.metadataTypeName = type;
        this.searchTerm = searchTerm;
        this.soapEnvelope = generateEnvelope(type);
        return this;
    }

    public virtual Object execute(String credentialId) {
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = Settings.METADATA_API_ENDPOINT;
        request.orgCredentialId = credentialId;
        request.logLabelIdentifier = 'Metadata Retriever - MetadataAPI';
        request.requestType = HttpMethod.GET.name();
        request.requestPayload = this.soapEnvelope;

        copado.GlobalAPI.ProxyOrgResponse response;
        if (!Test.isRunningTest()) {
            response = new copado.GlobalAPI().proxyOrgRequestSoap(request);
        } else {
            response = TestUtilities.getMockedResponse(new MetadataRetrieverMock().getResponseByType(this.metadataTypeName));
        }

        MetadataApiResult queryResult = processResponse(response);
        return queryResult;
    }

    public virtual List<MetadataSearchResult> handle(Object result) {
        MetadataApiResult metadataApiResult = (MetadataApiResult) result;
        List<MetadataSearchResult> searchResult = new List<MetadataSearchResult>();
        for (MetadataApiResult.MetadataRecord queryRow : metadataApiResult.records) {
            if (String.isBlank(this.searchTerm) || queryRow.fullName.contains(this.searchTerm)) {
                MetadataSearchResult tableRow = new MetadataSearchResult();
                tableRow.id = getId(queryRow.id);
                tableRow.type = this.metadataTypeName;
                tableRow.name = getName(queryRow.fullname);
                tableRow.lastModifiedBy = getLastModifiedBy(queryRow.lastModifiedByName);
                tableRow.lastModifiedDate = getLastModifiedDate(queryRow.lastModifiedDate);
                tableRow.createdDate = getCreatedDate(queryRow.createdDate);
                tableRow.createdBy = getCreatedBy(queryRow.createdByName);
                searchResult.add(tableRow);
            }
        }
        return searchResult;
    }

    // PRIVATE

    private String generateEnvelope(String type) {
        DOM.Document doc = new DOM.Document();

        DOM.XmlNode envelope = doc.createRootElement('soapenv:Envelope', null, null);
        envelope.setAttribute('xmlns:soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
        envelope.setAttribute('xmlns:met', 'http://soap.sforce.com/2006/04/metadata');

        DOM.XmlNode soapEnvHeader = envelope.addChildElement('soapenv:Header', null, null);
        soapEnvHeader.addChildElement('met:SessionHeader', null, null).addChildElement('met:sessionId', null, null).addTextNode(SESSION_ID);

        DOM.XmlNode soapEnvBody = envelope.addChildElement('soapenv:Body', null, null);
        soapEnvBody.addChildElement('met:listMetadata', null, null)
            .addChildElement('met:queries', null, null)
            .addChildElement('met:type', null, null)
            .addTextNode(type);

        return doc.toXmlString();
    }

    private MetadataApiResult processResponse(copado.GlobalAPI.ProxyOrgResponse response) {
        if (response.statusCode != 200) {
            String message = String.isNotBlank(response.errorMessage) ? response.errorMessage : 'Error searching metadata';
            throw new ApplicationException(message);
        }
        return MetadataApiResult.fromResponse(response.content);
    }

    private static String getId(String id) {
        return String.isNotBlank(id) ? id : '';
    }

    private static String getName(String fullname) {
        Boolean hasName = (fullname != null && String.isNotBlank(fullname));
        return hasName ? fullname : '';
    }

    private static String getLastModifiedBy(String lastModifiedByName) {
        Boolean hasLastModifiedBy = (lastModifiedByName != null && String.isNotBlank(lastModifiedByName));
        return hasLastModifiedBy ? lastModifiedByName : '';
    }

    private static String getLastModifiedDate(String lastModifiedDate) {
        return String.isNotBlank(lastModifiedDate) ? lastModifiedDate : '';
    }

    private static String getCreatedDate(String createdDate) {
        return String.isNotBlank(createdDate) ? createdDate : '';
    }

    private static String getCreatedBy(String createdByName) {
        Boolean hasCreatedBy = (createdByName != null && String.isNotBlank(createdByName));
        return hasCreatedBy ? createdByName : '';
    }
}