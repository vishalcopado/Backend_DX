public with sharing class SourceMember {
    private Id orgCredentialId;
    private final static String SOQL_ENPOINT_PREFIX = Settings.TOOLING_API_ENDPOINT + '/query/?q=';
    private final static String LOG_LABEL_APEX_CLASS = 'SourceMember - Query';
    private static final Set<String> INVALID_TYPES = new Set<String>{ 'AuraDefinition', 'LightningComponentResource', 'ExperienceResource' };
    private static final Set<String> NOT_TO_BE_FORMATTED_TYPES = new Set<String>{ 'Dashboard', 'Report', 'WorkflowRule', 'EmailTemplate' };

    @TestVisible
    private static String mockResponse;

    // PUBLIC

    public SourceMember(Id orgCredentialId) {
        this.orgCredentialId = orgCredentialId;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled(cacheable=true)
    public static List<SourceMemberResult> getItems(
        Id orgCredentialId,
        String memberName,
        String memberType,
        String changedDateTimeFilter,
        String changedBy
    ) {
        try {
            List<String> memberTypes = String.isNotBlank(memberType) ? new List<String>{ memberType } : new List<String>();
            copado.GlobalAPI.ProxyOrgResponse response = new SourceMember(orgCredentialId)
                .query(memberName, memberTypes, changedDateTimeFilter, changedBy, 2000, null, null, null);
            List<SourceMemberResult> sourceMembers = processResponse(response);
            List<SourceMemberResult> validSourceMembers = filterInvalidTypes(sourceMembers);
            List<SourceMemberResult> encodedSourceMembers = encodeNames(validSourceMembers);
            return encodedSourceMembers;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static List<SourceMemberResult> getDeletedItems(Id credentialId) {
        try {
            copado.GlobalAPI.ProxyOrgResponse response = new SourceMember(credentialId)
                .query(null, null, null, null, 1000, 'true', 'LastModifiedDate', 'DESC');
            List<SourceMemberResult> sourceMembers = processResponse(response);
            List<SourceMemberResult> validSourceMembers = filterInvalidTypes(sourceMembers);
            List<SourceMemberResult> encodedSourceMembers = encodeNames(validSourceMembers);
            return encodedSourceMembers;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private copado.GlobalAPI.ProxyOrgResponse query(
        String memberName,
        List<String> memberTypes,
        String lastModifiedDate,
        String changedBy,
        Integer numberOfRecords,
        String isNameObsolete,
        String orderBy,
        String orderDirection
    ) {
        String query = buildSOQLQuery(memberName, memberTypes, lastModifiedDate, changedBy, numberOfRecords, isNameObsolete, orderBy, orderDirection);
        copado.GlobalAPI.ProxyOrgRequest request = getProxyOrgRequest(query);
        request.requestType = HttpMethod.GET.name();
        copado.GlobalAPI.ProxyOrgResponse result;

        result = !Test.isRunningTest() ? new copado.GlobalAPI().proxyOrgRequest(request) : TestUtilities.getMockedResponse(mockResponse);
        if (result.statusCode != 200) {
            String message = String.isNotBlank(result.errorMessage) ? result.errorMessage : Label.Source_Member_Query_Error;
            throw new ApplicationException(message);
        }
        return result;
    }

    private static List<SourceMemberResult> processResponse(copado.GlobalAPI.ProxyOrgResponse response) {
        SourceMemberQueryResult content = (SourceMemberQueryResult) JSON.deserialize(response.content, SourceMemberQueryResult.class);
        return content.records;
    }

    private static List<SourceMemberResult> filterInvalidTypes(List<SourceMemberResult> sourceMembers) {
        List<SourceMemberResult> result = new List<SourceMemberResult>();
        for (SourceMemberResult sourceMember : sourceMembers) {
            if (!INVALID_TYPES.contains(sourceMember.MemberType)) {
                result.add(sourceMember);
            }
        }
        return result;
    }

    private copado.GlobalAPI.ProxyOrgRequest getProxyOrgRequest(String query) {
        copado.GlobalAPI.ProxyOrgRequest request = new copado.GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = getEndpoint(query);
        request.orgCredentialId = this.orgCredentialId;
        request.logLabelIdentifier = LOG_LABEL_APEX_CLASS;
        request.requestType = HttpMethod.GET.name();
        return request;
    }

    private static List<SourceMemberResult> encodeNames(List<SourceMemberResult> sourceMembers) {
        List<SourceMemberResult> result = new List<SourceMemberResult>();
        for (SourceMemberResult sourceMember : sourceMembers) {
            sourceMember.MemberName = getEncoded(sourceMember.MemberName, sourceMember.MemberType);
            result.add(sourceMember);
        }
        return result;
    }

    private static String getEncoded(String metadataName, String metadataType) {
        String result = metadataName;
        if (!NOT_TO_BE_FORMATTED_TYPES.contains(metadataType)) {
            String[] stringCharacters = metadataName.split('');
            for (Integer i = 0; i < stringCharacters?.size(); i++) {
                String character = stringCharacters[i];
                if (!character?.isAlphanumericSpace()) {
                    character = EncodingUtil.urlEncode(character, 'UTF-8');
                    stringCharacters[i] = character;
                }
            }
            result = String.join(stringCharacters, '');
            result = result.contains('.') ? result.substringBefore('.') + '.' + result.substringAfter('.').replace('.', '%2E') : result;
        }
        return result;
    }

    private String getEndpoint(String query) {
        return (SOQL_ENPOINT_PREFIX + getUrlEncoded(query, 'UTF-8'));
    }

    private String getUrlEncoded(String query, String encoding) {
        return (EncodingUtil.urlEncode(query, encoding));
    }

    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.CyclomaticComplexity')
    private String buildSOQLQuery(
        String memberName,
        List<String> memberTypes,
        String lastModifiedDate,
        String changedBy,
        Integer numberOfRecords,
        String isNameObsolete,
        String orderBy,
        String orderDirection
    ) {
        String query = 'SELECT {0} FROM SourceMember {1} LIMIT {2}';
        List<String> whereClause = new List<String>();
        String sortingDetails;

        if (String.isNotBlank(memberName)) {
            whereClause.add('MemberName LIKE \'%' + String.escapeSingleQuotes(memberName) + '%\'');
        }
        if (memberTypes != null && !memberTypes?.isEmpty()) {
            whereClause.add('MemberType IN (\'' + String.join(memberTypes, '\' , \'') + '\')');
        }
        if (String.isNotBlank(lastModifiedDate)) {
            whereClause.add('LastModifiedDate >= ' + lastModifiedDate);
        }
        if (String.isNotBlank(changedBy)) {
            whereClause.add('LastModifiedBy.Name LIKE \'%' + String.escapeSingleQuotes(changedBy) + '%\'');
        }
        if (String.isNotBlank(isNameObsolete)) {
            whereClause.add('IsNameObsolete = ' + String.escapeSingleQuotes(isNameObsolete));
        }
        if (String.isNotBlank(orderBy) && String.isNotEmpty(orderDirection)) {
            sortingDetails = 'ORDER BY ' + String.escapeSingleQuotes(orderBy) + ' ' + String.escapeSingleQuotes(orderDirection);
        }
        String whereParam = whereClause?.size() > 0 ? 'WHERE ' + String.join(whereClause, ' AND ') : '';
        return String.format(
            query,
            new List<String>{
                getFields(),
                String.isNotBlank(sortingDetails) ? whereParam + ' ' + sortingDetails : whereParam,
                String.valueOf(numberOfRecords)
            }
        );
    }

    private String getFields() {
        List<String> fields = new List<String>{ 'LastModifiedBy.Name', 'LastModifiedDate', 'IsNameObsolete', 'MemberName', 'MemberType' };
        return String.join(fields, ',');
    }

    @TestVisible
    private with sharing class SourceMemberQueryResult {
        @TestVisible
        private List<SourceMemberResult> records;
    }
}