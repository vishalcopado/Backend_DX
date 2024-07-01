public with sharing class RefreshOrgMetadataCache {
    private Id credentialId;
    private Set<String> ignoredType;
    private Set<String> typeFilter;

    @TestVisible
    private static final String SFDX_REFRESH_METADATA_TEMPLATE = 'SFDX Refresh Metadata_1';

    // CONSTRUCTOR

    public RefreshOrgMetadataCache(Id credentialId) {
        this(credentialId, null, null);
    }

    public RefreshOrgMetadataCache(Id credentialId, Set<String> ignoredType, Set<String> typeFilter) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
        this.credentialId = credentialId;
        this.ignoredType = (ignoredType == null ? new Set<String>() : ignoredType);
        this.typeFilter = (typeFilter == null ? new Set<String>() : typeFilter);
    }

    // PUBLIC

    public copado__JobExecution__c execute() {
        copado__JobExecution__c result;
        try {
            copado__Org__c credential = getCredential();
            result = getInProgressRefreshMetadataJob(credential.copado__Environment__c);
            if (result == null) {
                List<copado.CreateExecution.Request> executionRequests = new List<copado.CreateExecution.Request>();
                executionRequests.add(createExecutionRequest(credential.copado__Environment__c, getMetadataFileId()));
                result = copado.CreateExecution.execute(executionRequests)[0];
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        return result;
    }

    // PRIVATE

    private copado__Org__c getCredential() {
        List<copado__Org__c> credentials = new CredentialsSelector().byIds(new List<String>{ this.credentialId });
        if (credentials.isEmpty()) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
        return credentials[0];
    }

    private Id getMetadataFileId() {
        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ this.credentialId }, new Set<String>{ 'MetaData' });
        return !contentDocumentLinks.isEmpty() ? contentDocumentLinks[0].ContentDocument?.LatestPublishedVersionId : null;
    }

    private copado__JobExecution__c getInProgressRefreshMetadataJob(Id environmentId) {
        copado__JobExecution__c result;
        for (
            copado__JobExecution__c jobExecution : new JobExecutionsSelector()
                .bySourceTemplateAndStatus(
                    new Set<Id>{ environmentId },
                    new Set<String>{ SFDX_REFRESH_METADATA_TEMPLATE },
                    new Set<String>{ 'In Progress' }
                )
        ) {
            if (String.isNotBlank(jobExecution.copado__DataJson__c)) {
                DataJson dataJson = (DataJson) JSON.deserialize(jobExecution.copado__DataJson__c, DataJson.class);
                if (dataJson.credentialId == this.credentialId) {
                    result = jobExecution;
                    break;
                }
            }
        }
        return result;
    }

    private copado.CreateExecution.Request createExecutionRequest(Id environment, Id metadataFileId) {
        copado.CreateExecution.Request request = new copado.CreateExecution.Request();
        request.templateName = SFDX_REFRESH_METADATA_TEMPLATE;
        request.sourceId = environment;
        request.dataJson = new DataJson(this.credentialId, metadataFileId, this.ignoredType, this.typeFilter).stringify();
        request.runAfterInstantiation = true;
        return request;
    }

    // INNER

    private class DataJson {
        private Id credentialId;
        private String metadataFileId;
        private Set<String> ignoredType;
        private Set<String> typeFilter;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        private DataJson(Id credentialId, String metadataFileId, Set<String> ignoredType, Set<String> typeFilter) {
            this.credentialId = credentialId;
            this.metadataFileId = metadataFileId;
            this.ignoredType = ignoredType;
            this.typeFilter = typeFilter;
        }

        private String stringify() {
            return JSON.serialize(this);
        }
    }
}