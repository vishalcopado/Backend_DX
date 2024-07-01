public with sharing class PipelineInitializerJobInformation {

    private static final String RETRIED = 'Retried';
    private static final String COMMIT_ACTION = 'Commit';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String TAKE_SNAPSHOT = 'TakeSnapshot';
    private static final String DIRECT_BRANCH_CREATION = 'Direct Branch Creation';
    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization_1';
    private static final String SFDX_INITIALIZE_BRANCHES_ONLY = 'SFDX_Initialize_Pipeline_Branches_Only_1';
    private static final String SFDX_INITIALIZE_PIPELINE_WITH_CHANGES = 'SFDX_Initialize_Pipeline_with_Changes_1';

    private static final Set<String> INITIALIZATION_TYPES = new Set<String> { 'WIP Full', 'WIP Diff' };
    private static final Set<String> INITIALIZATION_STATUS = new Set<String> { 'Initializing main', 'Error initializing main' };

    // PUBLIC

    @AuraEnabled
    public static String getJobExecutionErrorMessage(Id jobExecutionId) {
        try {
            List<copado__JobExecution__c> jobExecutions = new JobExecutionsSelector().byIds(new Set<Id>{ jobExecutionId });
            if (jobExecutions.isEmpty()) {
                throw new ApplicationException(Label.JobNotFound);
            }
            return jobExecutions[0].copado__ErrorMessage__c;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static void retryJob(Id jobExecutionId, Id pipelineId) {
        try {
            copado__Deployment_Flow__c pipeline = getPipeline(pipelineId);
            copado__JobExecution__c job = getJobExecution(jobExecutionId);

            PipelineInitializationDetails initializationData = (PipelineInitializationDetails) JSON.deserialize(pipeline?.Initialization_Data__c, PipelineInitializationDetails.class);
            if (isMainBranchInitializationJob(initializationData?.status, job, pipelineId)) {
                PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
                request.pipelineId = pipelineId;
                request.initializationType = initializationData?.initializationType;

                PipelineInitializer.PreSteps.initializeMainBranch(request);
            } else if (isBranchCreationJob(initializationData?.status, job)) {
                String latestInitializationData = getLatestInitializationData(pipelineId, initializationData, RETRIED);
                updateInitializationData(pipelineId, latestInitializationData);
                PipelineInitializer.Initialize.execute(pipelineId);
            } else if (isCommitJob(pipelineId, initializationData, job)) {
                copado.Jobs.Execution.execute( new copado.Jobs.ExecutionRequest (jobExecutionId));
                String latestInitializationData = getLatestInitializationData(pipelineId, initializationData, IN_PROGRESS);
                updateInitializationData(pipelineId, latestInitializationData);
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static copado__Deployment_Flow__c getPipeline(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        return pipelines[0];
    }

    private static copado__JobExecution__c getJobExecution(Id jobExecutionId) {
        List<copado__JobExecution__c> jobs = new JobExecutionsSelector().byIds(new Set<Id>{ jobExecutionId });
        if (jobs.isEmpty()) {
            throw new ApplicationException(Label.JobNotFound);
        }

        return jobs[0];
    }

    private static Boolean isMainBranchInitializationJob(String status, copado__JobExecution__c job, Id pipelineId) {
        String snapshotTemplateApiName = new ActionTemplate(TAKE_SNAPSHOT, pipelineId).getApiName();
        Set<String> templateNames = new Set<String> { SFDX_GIT_INITIALIZATION, snapshotTemplateApiName };

        return INITIALIZATION_STATUS.contains(status) && templateNames.contains(job?.copado__Template__r?.copado__ApiName__c);
    }

    private static Boolean isBranchCreationJob(String status, copado__JobExecution__c job) {
        Set<String> templateNames = new Set<String> { SFDX_INITIALIZE_BRANCHES_ONLY, SFDX_INITIALIZE_PIPELINE_WITH_CHANGES };

        return status == Label.CreatingBranches && templateNames.contains(job?.copado__Template__r?.copado__ApiName__c);
    }

    private static Boolean isCommitJob(Id pipelineId, PipelineInitializationDetails initializationData, copado__JobExecution__c job) {
        String commitTemplateApiName = new ActionTemplate(COMMIT_ACTION, pipelineId).getApiName();

        return initializationData?.status == Label.CreatingBranches &&
            INITIALIZATION_TYPES.contains(initializationData?.initializationType) &&
            job?.copado__Template__r?.copado__ApiName__c == commitTemplateApiName;
    }

    private static String getLatestInitializationData(Id pipelineId, PipelineInitializationDetails initializationData, String status) {
        if (initializationData.activityLog != null && !initializationData.activityLog.isEmpty()) {
            PipelineInitializationDetails.ActivityLog lastLogEntry = initializationData.activityLog.get(initializationData.activityLog.size() - 1);
            lastLogEntry.status = RETRIED;
        }

        return JSON.serializePretty(initializationData);
    }

    private static void updateInitializationData(Id pipelineId, String latestInitializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = latestInitializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }
}