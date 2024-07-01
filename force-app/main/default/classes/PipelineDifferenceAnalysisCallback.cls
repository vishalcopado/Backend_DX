@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PipelineDifferenceAnalysisCallback implements copado.JobExecutionCallback {

    private static final String ERROR = 'Error';
    private static final String SUCCESS = 'Success';
    private static final String COMPLETE = 'Complete';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String CANCELLED = 'Cancelled';
    private static final String DIFFERENCE_METADATA = 'DifferenceMetadata';
    private static final Map<String, String> STATUS_VALUE_BY_JOB_STATUS = new Map<String,String>{ 'Successful' => SUCCESS, ERROR => ERROR, 'Canceled' => CANCELLED };

    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global PipelineDifferenceAnalysisCallback() {
        // Empty constructor needed so callback function can be called
    }

    // Execution callback
    global void execute(copado__JobExecution__c job, String status) {
        try {
            copado__Deployment_Flow__c pipeline = new PipelinesSelector().byId(new Set<Id>{ job?.copado__Pipeline__c })[0];
            PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(pipeline);
            String latestInitializationData = getLatestInitializationData(currentInitializationData, status);

            switch on status {
                when 'Successful' {
                    deleteOldFile(job.Id, job?.copado__Pipeline__c);

                    Set<Id> environmentIds = getRequiredEnvironmentIds(pipeline);
                    if (isDifferenceFilePresentOnEachEnvironment(environmentIds, pipeline.Id)) {
                        updateInitializationData(job.copado__Pipeline__c, latestInitializationData);
                        notifyViaEmail(null, 'Branches_Difference_Analysis_Success', pipeline.Name);
                    }
                }
                when 'Error', 'Canceled' {
                    updateInitializationData(job.copado__Pipeline__c, latestInitializationData);
                    notifyViaEmail(job, 'Branches_Difference_Analysis_Failure', pipeline.Name);
                }
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private PipelineInitializationDetails getCurrentInitializationData(copado__Deployment_Flow__c pipeline) {
        if (String.isBlank(pipeline?.Initialization_Data__c)) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }));
        }

        return (PipelineInitializationDetails) JSON.deserialize(pipeline.Initialization_Data__c, PipelineInitializationDetails.class);
    }

    private Set<Id> getRequiredEnvironmentIds(copado__Deployment_Flow__c pipeline) {
        PipelineDescriptor pipelineDescriptor = new PipelineDescriptor(pipeline.Id, pipeline.copado__Main_Branch__c);
        List<copado__Deployment_Flow_Step__c> pipelineConnections = pipelineDescriptor.getOrderedPipelineConnections();
        Map<Id, Id> destinationEnvironmentsBySourceEnvironments = pipelineDescriptor.getDestinationEnvironmentsByIntermediateEnvironments(pipelineConnections);

        return destinationEnvironmentsBySourceEnvironments.keySet();
    }

    private Boolean isDifferenceFilePresentOnEachEnvironment(Set<Id> environmentIds, Id pipelineId) {
        Set<String> fileNames = new Set<String>();
        for (Id environmentId : environmentIds) {
            fileNames.add(pipelineId + '_' + environmentId + '_' + DIFFERENCE_METADATA);
        }

        Set<String> contentDocumentTitles = new Set<String>();
        for (ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(environmentIds, fileNames)) {
            contentDocumentTitles.add(contentDocumentLink.ContentDocument.Title);
        }

        return contentDocumentTitles.containsAll(fileNames);
    }

    private void notifyViaEmail(copado__JobExecution__c job, String notificationName, String pipelineName) {
        copado.CopadoNotifications.SendRequest request = new copado.CopadoNotifications.SendRequest();

        request.name = notificationName;
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = new Map<String, String>{
            'PipelineName' => pipelineName,
            'JobExecutionLink' => job == null ? '' : URL.getOrgDomainUrl().toExternalForm() + '/' + job.Id,
            'UserName' => UserInfo.getName()
        };

        copado.CopadoNotifications.send(request);
    }

    private String getLatestInitializationData(PipelineInitializationDetails currentInitializationData, String status) {
        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        } else {
            for (PipelineInitializationDetails.ActivityLog log : currentInitializationData.activityLog) {
                if (String.isNotBlank(log.title) && log.title.equalsIgnoreCase(Label.CalculatingDifferences) && log.status.equalsIgnoreCase(IN_PROGRESS)) {
                    log.status = STATUS_VALUE_BY_JOB_STATUS.get(status);
                    break;
                }
            }
        }

        if (status == 'Successful') {
            currentInitializationData.diffAnalysisStatus = COMPLETE;
            currentInitializationData.lastDiffAnalysis = System.now().getTime();
        } else {
            currentInitializationData.diffAnalysisStatus = ERROR;
        }

        return JSON.serializePretty(currentInitializationData);
    }

    private void updateInitializationData(Id pipelineId, String latestInitializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = latestInitializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private static void deleteOldFile(Id jobId, Id pipelineId) {
        List<copado__JobExecution__c> jobs = new JobExecutionsSelector().byIds(new Set<Id>{ jobId });
        if (jobs.isEmpty()) {
            throw new ApplicationException(Label.JobNotFound);
        }

        Id environmentId = jobs[0]?.copado__Source__c;

        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitlesAscending(new Set<Id>{ environmentId }, new Set<String>{ pipelineId + '_' + environmentId + '_' + DIFFERENCE_METADATA });

        if (!contentDocumentLinks.isEmpty() && contentDocumentLinks.size() > 1) {
            List<ContentDocument> contentDocumentsToBeDeleted = new List<ContentDocument>{ new ContentDocument(Id = contentDocumentLinks[0].ContentDocumentId) };
            new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
        }
    }
}