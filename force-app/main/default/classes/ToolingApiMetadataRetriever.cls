@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
// This apex class is used for 'RetrieveMetadata' section of the commit page, since
// we only use 'ListMetaData' now on the commit page, hence we will review
// all the apex classes used for 'RetrieveMetadata' operation and will discuss what
// needs to be done for them. 
public with sharing class ToolingApiMetadataRetriever implements IMetadataRetriever {
    protected String metadataTypeName;
    protected String toolingTypeName;
    protected String searchTerm;

    protected String queryParam;

    // PUBLIC

    public virtual IMetadataRetriever configure(String type, String searchTerm) {
        this.metadataTypeName = type;
        this.toolingTypeName = convertType(type);
        this.searchTerm = getEncoded(searchTerm, '');
        this.queryParam = generateQuery();
        return this;
    }

    public virtual Object execute(String credentialId) {
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = getEndpoint();
        request.orgCredentialId = credentialId;
        request.logLabelIdentifier = 'Metadata Retriever - ToolingAPI';
        request.requestType = HttpMethod.GET.name();

        copado.GlobalAPI.ProxyOrgResponse response;
        if (!Test.isRunningTest()) {
            response = new copado.GlobalAPI().proxyOrgRequest(request);
        } else {
            response = TestUtilities.getMockedResponse(new MetadataRetrieverMock().getResponseByType(this.metadataTypeName));
        }

        ToolingApiResult queryResult = processResponse(response);
        return queryResult;
    }

    public virtual List<MetadataSearchResult> handle(Object result) {
        ToolingApiResult toolingApiResult = (ToolingApiResult) result;
        List<MetadataSearchResult> searchResult = new List<MetadataSearchResult>();
        for (ToolingApiResult.MetadataRecord queryRow : toolingApiResult.records) {
            MetadataSearchResult tableRow = new MetadataSearchResult();
            tableRow.id = getId(queryRow.id);
            tableRow.type = this.metadataTypeName;
            tableRow.name = getName(queryRow, this.toolingTypeName);
            tableRow.lastModifiedBy = getLastModifiedBy(queryRow.lastModifiedBy);
            tableRow.lastModifiedDate = getLastModifiedDate(queryRow.lastModifiedDate);
            tableRow.createdDate = getCreatedDate(queryRow.createdDate);
            tableRow.createdBy = getCreatedBy(queryRow.createdBy);
            searchResult.add(tableRow);
        }
        return searchResult;
    }

    // PRIVATE

    private String convertType(String type) {
        return ToolingApiConstants.TOOLING_API_TYPES_BY_METADATA_API_TYPE.containsKey(type)
            ? ToolingApiConstants.TOOLING_API_TYPES_BY_METADATA_API_TYPE.get(type)
            : type;
    }

    private String generateQuery() {
        List<String> fields = getFields();
        String searchKey = getSearchKey();
        if (ToolingApiConstants.CONDITIONAL_QUERY_TYPES.contains(this.toolingTypeName)) {
            return String.format(
                ToolingApiConstants.CONDITIONAL_QUERY_TEMPLATE,
                new List<Object>{ String.join(fields, ','), this.toolingTypeName, searchKey, this.searchTerm, getAdditionalCondition() }
            );
        }
        return String.format(
            ToolingApiConstants.DEFAULT_QUERY_TEMPLATE,
            new List<Object>{ String.join(fields, ','), this.toolingTypeName, searchKey, this.searchTerm }
        );
    }

    private String getEndpoint() {
        String toolingApiPath = Settings.TOOLING_API_ENDPOINT;
        String queryPath = '/query/?q=';
        return toolingApiPath + queryPath + this.queryParam;
    }

    private ToolingApiResult processResponse(copado.GlobalAPI.ProxyOrgResponse response) {
        if (response.statusCode != 200) {
            String message = String.isNotBlank(response.errorMessage) ? response.errorMessage : 'Error searching metadata';
            throw new ApplicationException(message);
        }
        return (ToolingApiResult) JSON.deserialize(response.content, ToolingApiResult.class);
    }

    private static String getId(String id) {
        return String.isNotBlank(id) ? id : '';
    }

    private static String getName(ToolingApiResult.MetadataRecord record, String metadataType) {
        return getFullName(record, metadataType);
    }

    private static String getLastModifiedBy(ToolingApiResult.LastModifiedBy lastModifiedBy) {
        Boolean hasLastModifiedBy = (lastModifiedBy != null && String.isNotBlank(lastModifiedBy.name));
        return hasLastModifiedBy ? lastModifiedBy.name : '';
    }

    private static String getLastModifiedDate(String lastModifiedDate) {
        return String.isNotBlank(lastModifiedDate) ? lastModifiedDate : '';
    }

    private static String getCreatedDate(String createdDate) {
        return String.isNotBlank(createdDate) ? createdDate : '';
    }

    private static String getCreatedBy(ToolingApiResult.CreatedBy createdBy) {
        Boolean hasCreatedBy = (createdBy != null && String.isNotBlank(createdBy.name));
        return hasCreatedBy ? createdBy.name : '';
    }

    private List<String> getFields() {
        List<String> result = new List<String>();

        if (ToolingApiConstants.NO_NAMESPACE_FIELD_TYPES.contains(this.toolingTypeName)) {
            result.addAll(ToolingApiConstants.DEFAULT_FIELDS_NO_NAMESPACE);
        } else if (ToolingApiConstants.NO_CREATED_FIELDS_TYPES.contains(this.toolingTypeName)) {
            result.addAll(ToolingApiConstants.DEFAULT_FIELDS_NO_CREATED_FIELDS);
        } else if (ToolingApiConstants.NO_OWNER_TYPES.contains(this.toolingTypeName)) {
            result.addAll(ToolingApiConstants.DEFAULT_FIELDS_NO_OWNER);
        } else if (ToolingApiConstants.NO_DEFAULT_FIELDS_TYPES.contains(this.toolingTypeName)) {
            result.addAll(ToolingApiConstants.NO_DEFAULT_FIELDS);
        } else {
            result.addAll(ToolingApiConstants.DEFAULT_FIELDS);
        }

        if (ToolingApiConstants.ENTITY_FIELD_TYPES.contains(this.toolingTypeName)) {
            result.addAll(ToolingApiConstants.ENTITY_FIELDS);
        }

        if (ToolingApiConstants.FULL_NAME_FIELD_TYPES.contains(this.toolingTypeName)) {
            result.add(ToolingApiConstants.FIELD_FULL_NAME);
        }

        if (ToolingApiConstants.DEFINITION_FIELD_TYPES.contains(this.toolingTypeName)) {
            result.addAll(ToolingApiConstants.DEFINITION_FIELDS);
        }

        result.add(getSearchKey());

        return result;
    }

    private String getSearchKey() {
        String result = ToolingApiConstants.FIELD_DEVELOPER_NAME;
        if (ToolingApiConstants.NAME_FIELD_TYPES.contains(this.toolingTypeName)) {
            result = ToolingApiConstants.FIELD_NAME;
        } else if (this.toolingTypeName == ToolingApiConstants.TYPE_VALIDATION_RULE) {
            result = ToolingApiConstants.FIELD_VALIDATION_NAME;
        } else if (this.toolingTypeName == ToolingApiConstants.TYPE_FLOW) {
            result = ToolingApiConstants.FIELD_DEFINITION_DEVELOPER_NAME;
        } else if (ToolingApiConstants.MASTER_LABEL_FIELD_TYPES.contains(this.toolingTypeName)) {
            result = ToolingApiConstants.FIELD_MASTER_LABEL;
        }
        return result;
    }

    private String getAdditionalCondition() {
        String result = '';
        if (this.toolingTypeName == ToolingApiConstants.TYPE_FLOW) {
            result = ToolingApiConstants.ADDITIONAL_CONDITION_TYPE_FLOW;
        } else if (this.toolingTypeName == ToolingApiConstants.TYPE_PERMISSION_SET) {
            result = ToolingApiConstants.ADDITIONAL_CONDITION_TYPE_PERMISSION_SET;
        }
        return result;
    }

    private static String getFullName(ToolingApiResult.MetadataRecord record, String metadataType) {
        if (String.isNotBlank(record.fullName)) {
            return record.fullName;
        }
        String result = addEntityName(record, metadataType);
        result += addDefinitionName(record, metadataType);
        result += addNamespacePrefix(record.namespacePrefix);
        result += addName(record, metadataType);
        return checkIsCustom(result, record, metadataType);
    }

    private static String addEntityName(ToolingApiResult.MetadataRecord record, String metadataType) {
        Boolean hasEntityDefinition = (record.entityDefinition != null);
        String namespacePrefix = (hasEntityDefinition && String.isNotBlank(record.entityDefinition.namespacePrefix))
            ? record.entityDefinition.namespacePrefix + ToolingApiConstants.NAMESPACE_SEPARATOR
            : '';
        String developerName = (hasEntityDefinition && String.isNotBlank(record.entityDefinition.developerName))
            ? record.entityDefinition.developerName
            : '';
        Boolean isCustom = hasEntityDefinition && String.isNotBlank(record.entityDefinition.lastModifiedDate);
        developerName += isCustom ? ToolingApiConstants.CUSTOM_SUFFIX : '';
        developerName += metadataType.equals(ToolingApiConstants.TYPE_LAYOUT)
            ? ToolingApiConstants.LAYOUT_SEPARATOR
            : ToolingApiConstants.ENTITY_SEPARATOR;
        return hasEntityDefinition ? namespacePrefix + developerName : '';
    }

    private static String addDefinitionName(ToolingApiResult.MetadataRecord record, String metadataType) {
        Boolean hasDefinition = (record.definition != null);
        String namespacePrefix = (hasDefinition && String.isNotBlank(record.definition.namespacePrefix))
            ? record.definition.namespacePrefix + ToolingApiConstants.NAMESPACE_SEPARATOR
            : '';
        String developerName = (hasDefinition && String.isNotBlank(record.definition.developerName)) ? record.definition.developerName : '';

        return hasDefinition ? namespacePrefix + developerName : '';
    }

    private static String addNamespacePrefix(String namespacePrefix) {
        return String.isNotBlank(namespacePrefix) ? namespacePrefix + ToolingApiConstants.NAMESPACE_SEPARATOR : '';
    }

    private static String addName(ToolingApiResult.MetadataRecord record, String metadataType) {
        String result = '';
        if (String.isNotBlank(record.name)) {
            result += record.name;
        } else if (String.isNotBlank(record.developerName)) {
            result += record.developerName;
        } else if (String.isNotBlank(record.validationName)) {
            result += record.validationName;
        } else if (String.isNotBlank(record.masterLabel)) {
            result += record.masterLabel;
        }
        return getEncoded(result, metadataType);
    }

    private static String checkIsCustom(String name, ToolingApiResult.MetadataRecord record, String metadataType) {
        if (String.isNotBlank(name)) {
            Boolean hasLastModifiedBy = (record.lastModifiedBy != null && String.isNotBlank(record.lastModifiedBy.name));
            Boolean isCustomField = ((hasLastModifiedBy && metadataType.equalsIgnoreCase(ToolingApiConstants.TYPE_FIELD_DEFINITION)) ||
            metadataType.equalsIgnoreCase(ToolingApiConstants.TYPE_CUSTOM_FIELD));
            Boolean isCustomObject = ((hasLastModifiedBy && metadataType.equalsIgnoreCase(ToolingApiConstants.TYPE_ENTITY_DEFINITION)) ||
            metadataType.equalsIgnoreCase(ToolingApiConstants.TYPE_CUSTOM_OBJECT));
            Boolean isCustom = isCustomField || isCustomObject;
            name += isCustom ? ToolingApiConstants.CUSTOM_SUFFIX : '';
        }
        return name;
    }

    private static String getEncoded(String inputString, String metadataType) {
        String result = inputString;
        if (String.isBlank(metadataType)) {
            result = String.escapeSingleQuotes(inputString);
            result = EncodingUtil.urlEncode(result, 'UTF-8');
            result = result.replace('.', '%2E');
        } else if (ToolingApiConstants.TYPE_WORKFLOW_RULE != metadataType) {
            result = EncodingUtil.urlEncode(inputString, 'UTF-8');
            result = result.replace('+', ' ');
            result = result.replace('.', '%2E');
        }
        return result;
    }
}