@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global inherited sharing class InitializeWithSelectedMetadataCallback implements copado.JobExecutionCallback {

    private static final String ERROR = 'Error';
    private static final String SUCCESS = 'Success';
    private static final String CANCELLED = 'Cancelled';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String SELECTED_METADATA = 'Selected Metadata';

    private static final Map<String, String> STATUS_VALUE_BY_JOB_STATUS = new Map<String,String>{ 'Successful' => SUCCESS, ERROR => ERROR, 'Canceled' => CANCELLED };

    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global InitializeWithSelectedMetadataCallback() {
        // Empty constructor needed so callback function can be called
    }

    // GLOBAL - EXECUTION CALLBACK
    global void execute(copado__JobExecution__c job, String status) {
        try {
            copado__Deployment_Flow__c pipeline = getPipeline(job.copado__Pipeline__c);
            PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(pipeline?.Initialization_Data__c);

            if (status == 'Successful') {
                processNextGroup(job, pipeline, currentInitializationData);
            } else {
                updateInitializationData(currentInitializationData, status, job);
                notifyViaEmail(job, 'Branch_Creation_Failed', pipeline.Name);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PUBLIC

    public void processMetadataGroup(PipelineInitializer.MetadataGroup metadataGroup, copado__Deployment_Flow__c pipeline, Id environmentId) {
        copado__User_Story__c userStory = createUserStory(metadataGroup, pipeline, environmentId);
        CommitChangesResult commitResult = commitChanges(userStory, metadataGroup, environmentId, pipeline.Id);
        updateInitializationDataWithCommitJob(commitResult, pipeline.Id);
    }

    // PRIVATE

    private void processNextGroup(copado__JobExecution__c job, copado__Deployment_Flow__c pipeline, PipelineInitializationDetails currentInitializationData) {
        // NOTE - Check if the current environment has metadataFile to process
        PipelineInitializer.MetadataGroup metadataGroup = getMetadataGroupFromFile(job?.copado__Pipeline__c, currentInitializationData?.currentEnvironmentId);

        if (metadataGroup != null) {
            updateInitializationData(currentInitializationData, 'Successful', job);
            copado__User_Story__c userStory = createUserStory(metadataGroup, pipeline, currentInitializationData.currentEnvironmentId);
            CommitChangesResult commitResult = commitChanges(userStory, metadataGroup, currentInitializationData.currentEnvironmentId, pipeline.Id);
            updateInitializationDataWithCommitJob(commitResult, pipeline.Id);
        } else {
            // NOTE - File not found, update currentEnvironmentId
            updateInitializationDataWithNextEnvironment(currentInitializationData, job, pipeline);
            new PipelineInitializeWithSelectedMetadata().createBranches(pipeline);
        }
    }

    private void updateInitializationDataWithCommitJob(CommitChangesResult commitResult, Id pipelineId) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = getLatestInitializationData(commitResult, pipelineId)
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getLatestInitializationData(CommitChangesResult commitResult, Id pipelineId) {
        copado__Deployment_Flow__c pipeline = getPipeline(pipelineId);
        PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(pipeline?.Initialization_Data__c);

        currentInitializationData.latestJobExecutionId = commitResult.jobId;

        PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
        logEntry.status = IN_PROGRESS;
        logEntry.timestamp = System.now().getTime();
        logEntry.title = String.format(Label.CommittingChanges, new List<Object> { commitResult.userStoryName });

        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        }
        currentInitializationData.activityLog.add(logEntry);

        return JSON.serializePretty(currentInitializationData);
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

    private PipelineInitializer.MetadataGroup getMetadataGroupFromFile(Id pipelineId, Id environmentId) {
        PipelineInitializer.MetadataGroup result;

        String fileName = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;
        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ environmentId }, new Set<String>{ fileName });

        if (!contentDocumentLinks.isEmpty()) {
            MetadataGroups metadataGroups = getMetadataGroupsFromFile(contentDocumentLinks[0].contentDocumentId);
            result = getNextUnprocessedGroup(metadataGroups);
        }

        return result;
    }

    private MetadataGroups getMetadataGroupsFromFile(Id contentDocumentId) {
        MetadataGroups result;

        String fileContent = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ contentDocumentId })[0].VersionData.toString();
        if (String.isNotBlank(fileContent)) {
            result = (MetadataGroups) JSON.deserialize(fileContent, MetadataGroups.class);
        }

        return result;
    }

    private PipelineInitializer.MetadataGroup getNextUnprocessedGroup(MetadataGroups metadataGroups) {
        PipelineInitializer.MetadataGroup result;

        if (metadataGroups != null) {
            for (PipelineInitializer.MetadataGroup metadataGroup : metadataGroups.metadataGroups) {
                result = !metadataGroup.isProcessed ? metadataGroup : null;
            }
        }

        return result;
    }

    private copado__User_Story__c createUserStory(PipelineInitializer.MetadataGroup metadataGroup, copado__Deployment_Flow__c pipeline, Id environmentId) {
        copado__User_Story__c userStory = new copado__User_Story__c();

        userStory.copado__User_Story_Title__c = metadataGroup.groupName.length() > 255 ? metadataGroup.groupName.substring(0, 255) : metadataGroup.groupName;
        userStory.copado__Functional_Specifications__c = metadataGroup.groupDescription;
        userStory.RecordTypeId = Schema.SObjectType.copado__User_Story__c.getRecordTypeInfosByDeveloperName().get('User_Story').getRecordTypeId();
        userStory.copado__Project__c = getPipelineProject(pipeline);
        userStory.copado__Org_Credential__c = getDefaultAuthenticatedCredential(environmentId);

        Utilities.performDML(new List<copado__User_Story__c>{ userStory }, 'insert', AccessLevel.USER_MODE);
        return userStory;
    }

    private Id getPipelineProject(copado__Deployment_Flow__c pipeline) {
        Id result;

        String projectName = String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> { pipeline.Name });

        List<copado__Project__c> projects = new ProjectsSelector().byActivePipelineIdsAndName(new Set<Id>{ pipeline.Id }, new Set<String>{ projectName });
        if (projects.isEmpty()) {
            result = createNewProject(pipeline.Id, projectName);
        } else {
            result = projects[0].Id;
        }

        return result;
    }

    private Id createNewProject(Id pipelineId, String projectName) {
        copado__Project__c project = new copado__Project__c();

        project.copado__Deployment_Flow__c = pipelineId;
        project.Name = projectName;
        project.copado__Description__c = Label.NewProjectDescription;

        Utilities.performDML(new List<copado__Project__c>{ project }, 'insert', AccessLevel.USER_MODE);
        return project.Id;
    }

    private Id getDefaultAuthenticatedCredential(Id environmentId) {
        Id result;

        List<copado__Org__c> credentials = new CredentialsSelector().byEnvironmentIdAndValidationCheck(new Set<Id>{ environmentId });
        if (!credentials.isEmpty()) {
            result = credentials[0].Id;
        }

        return result;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private CommitChangesResult commitChanges(copado__User_Story__c userStory, PipelineInitializer.MetadataGroup metadataGroup, Id environmentId, Id pipelineId) {
        copado.Actions.CommitRequest request = new copado.Actions.CommitRequest();

        request.changes = metadataGroup.selectedMetadata;
        request.otherInformation = JSON.serialize(new CommitOtherInformation(metadataGroup.groupName, environmentId, pipelineId));
        request.message = metadataGroup.groupName;
        request.userStoryId = userStory.Id;
        request.actionCallback = PipelineInitializeWithSelectedMetadata.class.getName();

        copado.Actions.CommitResult commitResult = copado.Actions.CommitService.execute(request);

        String userStoryName = new UserStoriesSelector().byIds(new Set<Id> { userStory.Id })[0].Name;
        return new CommitChangesResult(commitResult.jobExecution.Id, userStory.Id, userStoryName);
    }

    private void updateInitializationData(PipelineInitializationDetails currentInitializationData, String status, copado__JobExecution__c job) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = job.copado__Pipeline__c,
            Initialization_Data__c = getInitializationData(currentInitializationData, status, job)
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getInitializationData(PipelineInitializationDetails currentInitializationData, String status, copado__JobExecution__c job) {
        String branchName = getBranchName(job.copado__DataJson__c);

        PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
        logEntry.status = STATUS_VALUE_BY_JOB_STATUS.get(status);
        logEntry.timestamp = System.now().getTime();
        logEntry.title = String.format(Label.NamedBranchCreated, new List<Object> { branchName });

        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        }
        currentInitializationData.activityLog.add(logEntry);

        return JSON.serializePretty(currentInitializationData);
    }

    private String getBranchName(String jobDataJson) {
        JobData jobData = (JobData) JSON.deserialize(jobDataJson, JobData.class);
        return jobData.branches.source;
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

    private void updateInitializationDataWithNextEnvironment(PipelineInitializationDetails currentInitializationData, copado__JobExecution__c job, copado__Deployment_Flow__c pipeline) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipeline.Id,
            Initialization_Data__c = getInitializationDataWithNextEnvironment(currentInitializationData, job, pipeline)
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getInitializationDataWithNextEnvironment(PipelineInitializationDetails currentInitializationData, copado__JobExecution__c job, copado__Deployment_Flow__c pipeline) {
        String initializationData = getInitializationData(currentInitializationData, 'Successful', job);
        PipelineInitializationDetails updatedInitializationDetails = (PipelineInitializationDetails) JSON.deserialize(initializationData, PipelineInitializationDetails.class);

        if (!updatedInitializationDetails.pendingEnvironmentIds.isEmpty()) {
            updatedInitializationDetails.pendingEnvironmentIds.remove(0);
            updatedInitializationDetails.currentEnvironmentId = !updatedInitializationDetails.pendingEnvironmentIds.isEmpty() ? updatedInitializationDetails.pendingEnvironmentIds[0] : null;
        }
        // Note - Need to check with updated currentInitializationData.pendingEnvironmentIds
        if (updatedInitializationDetails.pendingEnvironmentIds.isEmpty()) {
            updatedInitializationDetails.status = Label.BranchesCreated;
            updatedInitializationDetails.completedDate = System.now().toString();
            notifyViaEmail(job, 'Branch_Creation_Success', pipeline.Name);
        }

        return JSON.serializePretty(updatedInitializationDetails);
    }

    // INNER

    @TestVisible
    private class MetadataGroups {
        public List<PipelineInitializer.MetadataGroup> metadataGroups;
    }

    @TestVisible
    private class Branches {
        public String source;
        public String destination;
    }

    @TestVisible
    private class JobData {
        public Branches branches;

        public JobData(Branches branches) {
            this.branches = branches;
        }
    }

    private class CommitOtherInformation {
        public String metadataGroupName;
        public Id environmentId;
        public Id pipelineId;

        public CommitOtherInformation(String metadataGroupName, Id environmentId, Id pipelineId) {
            this.metadataGroupName = metadataGroupName;
            this.environmentId = environmentId;
            this.pipelineId = pipelineId;
        }
    }

    private class CommitChangesResult {
        public String jobId;
        public String userStoryId;
        public String userStoryName;

        public CommitChangesResult(String jobId, String userStoryId, String userStoryName) {
            this.jobId = jobId;
            this.userStoryId = userStoryId;
            this.userStoryName = userStoryName;
        }
    }
}