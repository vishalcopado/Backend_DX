@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PipelineInitializeProjectCallback implements copado.JobExecutionCallback {

    private static final String IN_PROGRESS = 'In Progress';
    private static final String SUCCESS = 'Success';
    private static final String ERROR = 'Error';
    private static final String CANCELLED = 'Cancelled';

    private String snapshotErrorMessage;

    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global PipelineInitializeProjectCallback() {
        // Empty constructor needed so callback function can be called
    }

    // Execution callback
    global void execute(copado__JobExecution__c job, String status) {
        try {
            copado__Deployment_Flow__c pipeline = getPipeline(job?.copado__Pipeline__c);

            if (String.isBlank(pipeline.Initialization_Data__c)) {
                throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }));
            }

            if (status == 'Successful' || (status == 'Error' && isProjectInitialized(job.Id))) {
                Id snapshotJobId = configureAndTakeSnapshot(pipeline.Id);

                String initializationData;
                if (snapshotJobId == null) {
                    initializationData = getInitializationDataByStatus('Snapshot record failure', pipeline.Initialization_Data__c, null);
                } else {
                    initializationData = getInitializationDataByStatus('Successful', pipeline.Initialization_Data__c, snapshotJobId);
                }
                updateInitializationData(pipeline, initializationData);
            } else {
                String initializationData = getInitializationDataByStatus(status, pipeline.Initialization_Data__c, null);
                updateInitializationData(pipeline, initializationData);
                notifyViaEmail(job);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private void updateInitializationData(copado__Deployment_Flow__c pipeline, String initializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipeline.Id,
            Initialization_Data__c = initializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getInitializationDataByStatus(String status, String initializationData, Id jobId) {
        String result;

        switch on status {
            when 'Successful' {
                result = getInitializationDataForSuccess(initializationData, jobId);
            }
            when 'Error' {
                result = getInitializationDataForFailure(initializationData, status);
            }
            when 'Snapshot record failure' {
                result = getInitializationDataForSnapshotFailure(initializationData);
            }
            when 'Canceled' {
                result = getInitializationDataForFailure(initializationData, status);
            }
        }

        return result;
    }

    private String getInitializationDataForSuccess(String initializationData, Id jobId) {
        PipelineInitializationDetails currentInitializationData = (PipelineInitializationDetails) JSON.deserialize(initializationData, PipelineInitializationDetails.class);

        currentInitializationData.latestJobExecutionId = jobId;

        PipelineInitializationDetails.ActivityLog logEntryForProject = new PipelineInitializationDetails.ActivityLog();
        logEntryForProject.status = SUCCESS;
        logEntryForProject.timestamp = System.now().getTime();
        logEntryForProject.title = Label.ProjectInitialized;

        PipelineInitializationDetails.ActivityLog logEntryForSnapshot = new PipelineInitializationDetails.ActivityLog();
        logEntryForSnapshot.status = IN_PROGRESS;
        logEntryForSnapshot.timestamp = System.now().getTime();
        logEntryForSnapshot.title = Label.SnapshotMessage;

        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        } else {
            PipelineInitializationDetails.ActivityLog lastLogEntry = currentInitializationData.activityLog.get(currentInitializationData.activityLog.size() - 1);
            lastLogEntry.status = SUCCESS;
        }

        currentInitializationData.activityLog.add(logEntryForProject);
        currentInitializationData.activityLog.add(logEntryForSnapshot);

        return JSON.serializePretty(currentInitializationData);
    }

    private String getInitializationDataForFailure(String initializationData, String status) {
        PipelineInitializationDetails currentInitializationData = (PipelineInitializationDetails) JSON.deserialize(initializationData, PipelineInitializationDetails.class);

        if (!currentInitializationData.activityLog.isEmpty()) {
            PipelineInitializationDetails.ActivityLog lastLogEntry = currentInitializationData.activityLog.get(currentInitializationData.activityLog.size() - 1);
            lastLogEntry.status = status == ERROR ? ERROR : CANCELLED;
        }

        return JSON.serializePretty(currentInitializationData);
    }

    private String getInitializationDataForSnapshotFailure(String initializationData) {
        PipelineInitializationDetails currentInitializationData = (PipelineInitializationDetails) JSON.deserialize(initializationData, PipelineInitializationDetails.class);

        PipelineInitializationDetails.ActivityLog logEntryForSnapshot = new PipelineInitializationDetails.ActivityLog();
        logEntryForSnapshot.status = ERROR;
        logEntryForSnapshot.timestamp = System.now().getTime();
        logEntryForSnapshot.title = Label.SnapshotCreationError;

        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        } else {
            PipelineInitializationDetails.ActivityLog lastLogEntry = currentInitializationData.activityLog.get(currentInitializationData.activityLog.size() - 1);
            lastLogEntry.status = SUCCESS;
        }

        currentInitializationData.activityLog.add(logEntryForSnapshot);
        currentInitializationData.message = snapshotErrorMessage;

        return JSON.serializePretty(currentInitializationData);
    }

    private Id configureAndTakeSnapshot(Id pipelineId) {
        Id mainCredentialId;
        String finalEnvironmentName;

        copado__Deployment_Flow__c pipeline = getPipeline(pipelineId);
        copado__Environment__c finalEnvironment = new PipelineDescriptor(pipelineId).findFinalEnvironment();

        if(finalEnvironment != null) {
            List<copado__Org__c> credentials = new CredentialsSelector().byEnvironmentIdAndValidationCheck(new Set<Id>{ finalEnvironment.Id });
            finalEnvironmentName = finalEnvironment.Name;
            mainCredentialId = credentials.isEmpty() ? '' : credentials[0].Id;
        }

        copado.Actions.TakeGitSnapshotResult result;
        try {
            copado.Actions.ConfigureGitSnapshotRequest configureSnapshotRequest = new copado.Actions.ConfigureGitSnapshotRequest();
            configureSnapshotRequest.name = String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> {finalEnvironmentName});
            configureSnapshotRequest.branch = pipeline?.copado__Main_Branch__c;
            configureSnapshotRequest.credentialId = mainCredentialId;
            configureSnapshotRequest.repositoryId = pipeline?.copado__Git_Repository__c;
            configureSnapshotRequest.pipelineId = pipeline?.Id;
            configureSnapshotRequest.scope = new DefaultSnapshotScopeConfiguration(pipeline?.Id).generate();
            copado__Git_Backup__c snapshot = copado.Actions.GitSnapshotService.configure(configureSnapshotRequest).snapshot;

            copado.Actions.TakeGitSnapshotRequest request = new copado.Actions.TakeGitSnapshotRequest();
            request.snapshotId = snapshot.Id;
            request.message = String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> {System.now().format('yyyy-MM-dd')});
            request.actionCallback = PipelineInitializeMainCallback.class.getName();
            result = copado.Actions.GitSnapshotService.takeSnapshot(request);
        } catch (Exception ex) {
            snapshotErrorMessage = ex.getMessage();
            return null;
        }

        return result.jobExecution.Id;
    }

    private Boolean isProjectInitialized(Id jobId) {
        Boolean result = false;

        List<copado__Result__c> jobStepResults = new ResultsSelector().byJobExecutionId(jobId);

        if(!jobStepResults.isEmpty() && String.isNotBlank(jobStepResults[0].copado__Result_Data__c)) {
            ResultData resultData = (ResultData) JSON.deserialize(jobStepResults[0].copado__Result_Data__c, ResultData.class);
            result = resultData.projectInitialized;
        }

        return result;
    }

    private copado__Deployment_Flow__c getPipeline(Id pipelineId) {
        return new PipelinesSelector().byId(new Set<Id>{ pipelineId })[0];
    }

    private void notifyViaEmail(copado__JobExecution__c job) {
        copado.CopadoNotifications.SendRequest request = new copado.CopadoNotifications.SendRequest();

        request.name = 'Failed_Git_Initialization';
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = new Map<String, String>{
            'JobExecutionName' => job.Name,
            'JobExecutionLink' => getExternalLink(job.Id),
            'UserName' => UserInfo.getName()
        };

        copado.CopadoNotifications.send(request);
    }

    private String getExternalLink(Id recordId) {
        return URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
    }

    // INNER

    private class ResultData {
        Boolean projectInitialized;
    }
}