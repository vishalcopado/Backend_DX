@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global inherited sharing class PipelineInitializeWithSelectedMetadata implements copado.JobExecutionCallback {

    private static final String ERROR = 'Error';
    private static final String SUCCESS = 'Success';
    private static final String CANCELLED = 'Cancelled';
    private static final String SELECTED_METADATA = 'Selected Metadata';
    private static final String SFDX_INITIALIZE_PIPELINE_WITH_CHANGES = 'SFDX_Initialize_Pipeline_with_Changes_1';

    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global PipelineInitializeWithSelectedMetadata() {
        // Empty constructor needed so callback function can be called
    }

    // GLOBAL - EXECUTION CALLBACK
    global void execute(copado__JobExecution__c job, String status) {
        try {
            JsonInformation jobDataJson = (JsonInformation) JSON.deserialize(job?.copado__DataJson__c, JsonInformation.class);
            CommitOtherInformation commitJobJson = (CommitOtherInformation) JSON.deserialize(jobDataJson.jsonInformation, CommitOtherInformation.class);
            copado__Deployment_Flow__c pipeline = getPipeline(commitJobJson?.pipelineId);
            PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(pipeline?.Initialization_Data__c);

            if (status == 'Successful') {
                proceedWithNextGroup(job, pipeline, currentInitializationData);
            } else {
                // Note - Stop the process
                updateInitializationDataWithError(pipeline, currentInitializationData, status);
                notifyViaEmail(job, 'Branch_Creation_Failed', pipeline.Name);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PUBLIC
    public PipelineInitializer.ExecuteResult createBranches(copado__Deployment_Flow__c pipeline) {
        PipelineInitializer.ExecuteResult result;

        // Note - Query is required to get updated initialization data at all times, as this method is being called from multiple places
        copado__Deployment_Flow__c pipelineRecord = getPipeline(pipeline.Id);
        PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(pipelineRecord?.Initialization_Data__c);

        if (currentInitializationData.currentEnvironmentId != null) {
            result = createJobForBranchCreation(pipelineRecord, currentInitializationData.currentEnvironmentId);
            updateInitializationDataWithJobId(currentInitializationData, result?.jobExecution?.Id, pipelineRecord.Id);
        }

        return result;
    }

    // PRIVATE

    private void proceedWithNextGroup(copado__JobExecution__c job, copado__Deployment_Flow__c pipeline, PipelineInitializationDetails currentInitializationData) {
        Id metadataGroupFileId = getMetadataGroupFileId(pipeline.Id, currentInitializationData.currentEnvironmentId);

        if (metadataGroupFileId != null) {
            // Note - Process next group
            MetadataGroups metadataGroupsInFile = getMetadataGroups(metadataGroupFileId);
            updateProcessedMetadataGroup(job, metadataGroupsInFile, metadataGroupFileId);

            PipelineInitializer.MetadataGroup nextGroupToProcess = getNextGroupToProcess(pipeline.Id, currentInitializationData.currentEnvironmentId);

            if (nextGroupToProcess != null) {
                new InitializeWithSelectedMetadataCallback().processMetadataGroup(nextGroupToProcess, pipeline, currentInitializationData.currentEnvironmentId);
            } else {
                processNextEnvironmentForBranchCreation(currentInitializationData, job, pipeline);
            }
        } else {
            // Note - There is no file on the environment, thus process next environment
            processNextEnvironmentForBranchCreation(currentInitializationData, job, pipeline);
        }
    }

    private PipelineInitializer.ExecuteResult createJobForBranchCreation(copado__Deployment_Flow__c pipeline, Id currentEnvironmentId) {
        PipelineInitializer.ExecuteResult result = new PipelineInitializer.ExecuteResult();

        copado.Jobs.ExecutionCreateFromTemplateRequest initializeRequest = new copado.Jobs.ExecutionCreateFromTemplateRequest();
        initializeRequest.templateAPIName = SFDX_INITIALIZE_PIPELINE_WITH_CHANGES;
        initializeRequest.pipelineId = pipeline?.Id;
        initializeRequest.dataJson = getBranchesJson(pipeline?.Id, currentEnvironmentId);
        initializeRequest.callback = InitializeWithSelectedMetadataCallback.class.getName();
        copado__JobExecution__c initializeJob = copado.Jobs.Execution.createFromTemplate(initializeRequest).jobExecution;

        copado.Jobs.ExecutionResult executionResult = copado.Jobs.Execution.execute(new copado.Jobs.ExecutionRequest(initializeJob.Id));
        result.jobExecution = executionResult.jobExecution;

        return result;
    }

    private String getBranchesJson(Id pipelineId, Id environmentId) {
        List<copado__Deployment_Flow_Step__c> pipelineConnectionsForGivenSourceEnvironment = new PipelineConnectionsSelector().byPipelineAndSourceEnvironment(new Set<Id>{ pipelineId }, new Set<Id>{ environmentId });
        Branch branches;

        for (copado__Deployment_Flow_Step__c pipelineConnection : pipelineConnectionsForGivenSourceEnvironment) {
            branches = new Branch(pipelineConnection.copado__Branch__c, pipelineConnection.copado__Destination_Branch__c);
        }

        JobData jobData = new JobData(branches);
        return JSON.serialize(jobData);
    }

    private copado__Deployment_Flow__c getPipeline(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        return pipelines[0];
    }

    private PipelineInitializationDetails getCurrentInitializationData(String initializationData) {
        if (String.isBlank(initializationData)) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }));
        }

        return (PipelineInitializationDetails) JSON.deserialize(initializationData, PipelineInitializationDetails.class);
    }

    private Id getMetadataGroupFileId(Id pipelineId, Id environmentId) {
        Id result;

        String fileName = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;
        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ environmentId }, new Set<String>{ fileName });

        if (!contentDocumentLinks.isEmpty()) {
            result = contentDocumentLinks[0].contentDocumentId;
        }

        return result;
    }

    private MetadataGroups getMetadataGroups(Id metadataGroupFileId) {
        String fileContent = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ metadataGroupFileId })[0].VersionData.toString();

        return (MetadataGroups) JSON.deserialize(fileContent, MetadataGroups.class);
    }

    private void updateProcessedMetadataGroup(copado__JobExecution__c job, MetadataGroups metadataGroupsInFile, Id metadataGroupFileId) {
        JsonInformation jobDataJson = (JsonInformation) JSON.deserialize(job?.copado__DataJson__c, JsonInformation.class);
        CommitOtherInformation commitJobJson = (CommitOtherInformation) JSON.deserialize(jobDataJson.jsonInformation, CommitOtherInformation.class);

        String processedGroupName = commitJobJson.metadataGroupName;
        String fileName = commitJobJson.pipelineId + '_' + commitJobJson.environmentId + '_' + SELECTED_METADATA;

        for (PipelineInitializer.MetadataGroup metadataGroup : metadataGroupsInFile.metadataGroups) {
            if (metadataGroup.groupName == processedGroupName) {
                metadataGroup.isProcessed = true;
            }
        }

        createSelectedMetadataFile(metadataGroupsInFile, fileName, commitJobJson.environmentId);
        deleteExistingFile(metadataGroupFileId);
    }

    private void deleteExistingFile(Id contentDocumentId) {
        List<ContentDocument> contentDocumentsToBeDeleted = new List<ContentDocument>{ new ContentDocument(Id = contentDocumentId) };
        new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
    }

    private void createSelectedMetadataFile(MetadataGroups metadataGroups, String fileName, Id environmentId) {
        ContentVersion contentVersion = new ContentVersion();

        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = fileName + '.json';
        contentVersion.Title = fileName;
        contentVersion.VersionData = Blob.valueOf(JSON.serializePretty(metadataGroups));
        contentVersion.FirstPublishLocationId = environmentId;

        Utilities.performDML(new List<ContentVersion>{ contentVersion }, 'insert', AccessLevel.USER_MODE);
    }

    private PipelineInitializer.MetadataGroup getNextGroupToProcess(Id pipelineId, Id environmentId) {
        PipelineInitializer.MetadataGroup result;

        String fileName = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;

        // NOTE - Query is required because previous file is deleted and updated
        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ environmentId }, new Set<String>{ fileName });

        if (!contentDocumentLinks.isEmpty()) {
            String fileContent = new ContentVersionsSelector()
                    .byContentDocumentIdWithLatest(new Set<Id>{ contentDocumentLinks[0].contentDocumentId })[0].VersionData.toString();
    
            MetadataGroups metadataGroups = (MetadataGroups) JSON.deserialize(fileContent, MetadataGroups.class);
    
            for (PipelineInitializer.MetadataGroup metadataGroup : metadataGroups.metadataGroups) {
                if (!metadataGroup.isProcessed) {
                    result = metadataGroup;
                }
            }
        }

        return result;
    }

    private void updateInitializationDataWithNextEnvironment(PipelineInitializationDetails currentInitializationData, copado__JobExecution__c job, copado__Deployment_Flow__c pipeline) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipeline.Id,
            Initialization_Data__c = getInitializationData(currentInitializationData, job, pipeline)
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getInitializationData(PipelineInitializationDetails currentInitializationData, copado__JobExecution__c job, copado__Deployment_Flow__c pipeline) {
        if (currentInitializationData.activityLog != null && !currentInitializationData.activityLog.isEmpty()) {
            PipelineInitializationDetails.ActivityLog lastLogEntry = currentInitializationData.activityLog.get(currentInitializationData.activityLog.size() - 1);
            lastLogEntry.status = lastLogEntry.status != SUCCESS ? SUCCESS : lastLogEntry.status;
        }

        if (!currentInitializationData.pendingEnvironmentIds.isEmpty()) {
            currentInitializationData.pendingEnvironmentIds.remove(0);
            currentInitializationData.currentEnvironmentId = !currentInitializationData.pendingEnvironmentIds.isEmpty() ? currentInitializationData.pendingEnvironmentIds[0] : null;
        }
        if (currentInitializationData.pendingEnvironmentIds.isEmpty()) {
            currentInitializationData.status = Label.BranchesCreated;
            currentInitializationData.completedDate = System.now().toString();
            notifyViaEmail(job, 'Branch_Creation_Success', pipeline.Name);
        }

        return JSON.serializePretty(currentInitializationData);
    }

    private void updateInitializationDataWithError(copado__Deployment_Flow__c pipeline, PipelineInitializationDetails currentInitializationData, String status) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipeline.Id,
            Initialization_Data__c = getInitializationData(currentInitializationData, pipeline, status)
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getInitializationData(PipelineInitializationDetails currentInitializationData, copado__Deployment_Flow__c pipeline, String status) {
        if (!currentInitializationData.activityLog.isEmpty()) {
            PipelineInitializationDetails.ActivityLog lastLogEntry = currentInitializationData.activityLog.get(currentInitializationData.activityLog.size() - 1);
            lastLogEntry.status = status == ERROR ? ERROR : CANCELLED;
        }

        return JSON.serializePretty(currentInitializationData);
    }

    private void updateInitializationDataWithJobId(PipelineInitializationDetails currentInitializationData, Id jobId, Id pipelineId) {
        currentInitializationData.latestJobExecutionId = jobId;
        currentInitializationData.status = Label.CreatingBranches;

        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = JSON.serializePretty(currentInitializationData)
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private void notifyViaEmail(copado__JobExecution__c job, String notificationName, String pipelineName) {
        copado.CopadoNotifications.SendRequest request = new copado.CopadoNotifications.SendRequest();

        request.name = notificationName;
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = new Map<String, String>{
            'PipelineName' => pipelineName,
            'JobExecutionLink' => URL.getOrgDomainUrl().toExternalForm() + '/' + job.Id,
            'UserName' => UserInfo.getName()
        };

        copado.CopadoNotifications.send(request);
    }

    private void processNextEnvironmentForBranchCreation(PipelineInitializationDetails currentInitializationData, copado__JobExecution__c job, copado__Deployment_Flow__c pipeline) {
        updateInitializationDataWithNextEnvironment(currentInitializationData, job, pipeline);
        createBranches(pipeline);
    }

    // INNER

    @TestVisible
    private class Branch {
        public String source;
        public String destination;

        public Branch(String source, String destination) {
            this.source = source;
            this.destination = destination;
        }
    }

    @TestVisible
    private class JobData {
        public Branch branches;

        public JobData(Branch branch) {
            this.branches = branch;
        }
    }

    @TestVisible
    private class MetadataGroups {
        public List<PipelineInitializer.MetadataGroup> metadataGroups;
    }

    @TestVisible
    private class CommitOtherInformation {
        public String metadataGroupName;
        public Id environmentId;
        public Id pipelineId;
    }

    @TestVisible
    private class JsonInformation {
        public String jsonInformation;
    }
}