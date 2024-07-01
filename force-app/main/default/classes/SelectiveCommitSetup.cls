public with sharing class SelectiveCommitSetup {
    private static final String SFDX_SELECTIVE_COMMIT_SETUP = 'SFDX_Selective_Commit_Setup_1';

    // PUBLIC

    @AuraEnabled
    public static Id execute(SelectiveCommitSetupPayload payload, Id pipelineId, Id sourceId) {
        try {
            List<copado__JobExecution__c> jobExecutions = getJobExecutionsWithSameRequestInProgress(
                SFDX_SELECTIVE_COMMIT_SETUP,
                pipelineId,
                sourceId,
                payload
            );
            if (jobExecutions?.size() != 0) {
                return jobExecutions[0].Id;
            }
            CmcSfJobExecution jobExecution = new CmcSfJobExecution()
                .templateName(SFDX_SELECTIVE_COMMIT_SETUP)
                .pipelineId(pipelineId)
                .sourceId(sourceId)
                .dataJson(JSON.serializePretty(payload))
                .run();
            return jobExecution.recordId;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<copado__JobExecution__c> getJobExecutionsWithSameRequestInProgress(
        String templateName,
        Id pipelineId,
        Id sourceId,
        SelectiveCommitSetupPayload payload
    ) {
        List<copado__JobExecution__c> result = new List<copado__JobExecution__c>();
        List<copado__JobExecution__c> jobExecutions = new JobExecutionsSelector()
            .byTemplateAndPipelineAndSourceAndStatus(templateName, pipelineId, sourceId, 'In Progress');
        for (copado__JobExecution__c jobExecution : jobExecutions) {
            if (hasSamePayload(payload, jobExecution.copado__DataJson__c)) {
                result.add(jobExecution);
            }
        }
        return result;
    }

    private static Boolean hasSamePayload(SelectiveCommitSetupPayload requestPayload, String inProgressJobExecutionPayload) {
        SelectiveCommitSetupPayload jobExecutionPayload = (SelectiveCommitSetupPayload) JSON.deserialize(
            inProgressJobExecutionPayload,
            SelectiveCommitSetupPayload.class
        );
        return (jobExecutionPayload.baseBranch?.equals(requestPayload.baseBranch) &&
        jobExecutionPayload.destinationBranch?.equals(requestPayload.destinationBranch) &&
        jobExecutionPayload.metadataTypeAndName?.equals(requestPayload.metadataTypeAndName) &&
        jobExecutionPayload.baseBranch?.equals(requestPayload.baseBranch) &&
        jobExecutionPayload.userStoryId?.equals(requestPayload.userStoryId));
    }

    @AuraEnabled(cacheable=true)
    public static String getDestinationBranchForUserStory(Id pipelineId, Id sourceEnvironmentId) {
        try {
            List<copado__Deployment_Flow_Step__c> pipelineConnections = new PipelineConnectionsSelector()
                .byPipelineAndSourceEnvironment(new Set<Id>{ pipelineId }, new Set<Id>{ sourceEnvironmentId });
            if (pipelineConnections.isEmpty() || String.isBlank(pipelineConnections[0].copado__Destination_Branch__c)) {
                throw new ApplicationException(Label.Pipeline_Connection_does_not_exists_or_Destination_Branch_is_empty);
            }
            return pipelineConnections[0].copado__Destination_Branch__c;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static JobExecutionDetails getJobExecutionDetails(Id jobExecutionId) {
        try {
            List<copado__JobExecution__c> jobExecutions = new JobExecutionsSelector().byIds(new Set<Id>{ jobExecutionId });
            return new JobExecutionDetails(jobExecutions[0].Name, jobExecutions[0].copado__Status__c, jobExecutions[0].Id);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static List<Id> getEditorContentVersionIds(Id userStoryId, List<String> titles) {
        try {
            List<ContentDocumentLink> metadataLinksOnUserStory = new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ userStoryId }, new Set<String>(titles));

            List<ContentDocumentLink> latestMetadataLinksOnUserStory = getLatestMetadataLinksOnUserStory(metadataLinksOnUserStory);
            Set<Id> metadataDocumentIdsOnUserStory = new Set<Id>();
            for (ContentDocumentLink metadataLinkOnUserStory : latestMetadataLinksOnUserStory) {
                metadataDocumentIdsOnUserStory.add(metadataLinkOnUserStory.ContentDocumentId);
            }
            Map<Id, ContentVersion> metadataContentVersionsOnUSByIds = new Map<Id, ContentVersion>(
                new ContentVersionsSelector().byContentDocumentIdWithLatest(metadataDocumentIdsOnUserStory)
            );
            return new List<Id>(metadataContentVersionsOnUSByIds.keySet());
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    private static List<ContentDocumentLink> getLatestMetadataLinksOnUserStory(List<ContentDocumentLink> metadataLinksOnUserStory) {
        Map<String, ContentDocumentLink> latestMetadataLinksOnUserStoryByTitle = new Map<String, ContentDocumentLink>();
        for (ContentDocumentLink metadataLinkOnUserStory : metadataLinksOnUserStory) {
            if (!latestMetadataLinksOnUserStoryByTitle.containsKey(metadataLinkOnUserStory.ContentDocument.Title)) {
                latestMetadataLinksOnUserStoryByTitle.put(metadataLinkOnUserStory.ContentDocument.Title, metadataLinkOnUserStory);
            }
        }
        return latestMetadataLinksOnUserStoryByTitle.values();
    }

    public class JobExecutionDetails {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Id recordId;

        public JobExecutionDetails(String name, String status, Id recordId) {
            this.name = name;
            this.status = status;
            this.recordId = recordId;
        }
    }
}