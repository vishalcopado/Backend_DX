public inherited sharing class PipelineInitializeBranchesImpl {

    private copado__Deployment_Flow__c pipeline;

    private static final String SUCCESS = 'Success';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String BRANCHES_ONLY = 'Direct Branch Creation';
    private static final String MAIN_INITIALIZED = 'Main Initialized';
    private static final String SFDX_INITIALIZE_BRANCHES_ONLY = 'SFDX_Initialize_Pipeline_Branches_Only_1';
    private static final Set<String> VALID_STATUSES = new Set<String>{MAIN_INITIALIZED, Label.CreatingBranches};
    private static final Set<String> WIP_MODES = new Set<String>{'WIP Full', 'WIP Diff'};

    // CONSTRUCTOR

    public PipelineInitializeBranchesImpl(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
    }

    // PUBLIC STATIC

    public static PipelineInitializer.ExecuteResult execute(Id pipelineId) {
        if(pipelineId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}));
        }

        return new PipelineInitializeBranchesImpl(pipelineId).execute();
    }

    // PUBLIC

    public PipelineInitializer.ExecuteResult execute() {
        if (pipeline.copado__Platform__c != 'SFDX') {
            throw new ApplicationException(Label.PipelineUnavailableForInitializationMessage);
        }

        PipelineInitializer.ExecuteResult result;

        PipelineInitializationDetails initializationData = getInitializationData();
        if (initializationData?.initializationType == BRANCHES_ONLY && VALID_STATUSES.contains(initializationData?.status)) {
            result = initializeWithBranchesOnly();

            String latestInitializationData = getLatestInitializationData(initializationData, result?.jobExecution?.Id);
            updateInitializationData(latestInitializationData);
        } else if (WIP_MODES.contains(initializationData?.initializationType) && VALID_STATUSES.contains(initializationData?.status) && initializationData?.areChangesSelected) {
            result = new PipelineInitializeWithSelectedMetadata().createBranches(pipeline);
        }

        return result;
    }

    // PRIVATE

    private PipelineInitializationDetails getInitializationData() {
        if (String.isBlank(pipeline?.Initialization_Data__c)) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }));
        }

        return (PipelineInitializationDetails) JSON.deserialize(pipeline.Initialization_Data__c, PipelineInitializationDetails.class);
    }

    private void updateInitializationData(String latestInitializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipeline.Id,
            Initialization_Data__c = latestInitializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getLatestInitializationData(PipelineInitializationDetails currentInitializationData, Id jobId) {
        PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
        logEntry.status = IN_PROGRESS;
        logEntry.timestamp = System.now().getTime();
        logEntry.title = Label.CreatingBranches;

        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        } else {
            for (PipelineInitializationDetails.ActivityLog log : currentInitializationData.activityLog) {
                if (String.isNotBlank(log.title) && log.title.equalsIgnoreCase(Label.SnapshotComplete)) {
                    log.status = SUCCESS;
                    break;
                }
            }
        }
        currentInitializationData.activityLog.add(logEntry);
        currentInitializationData.latestJobExecutionId = jobId;
        currentInitializationData.status = Label.CreatingBranches;

        return JSON.serializePretty(currentInitializationData);
    }

    private PipelineInitializer.ExecuteResult initializeWithBranchesOnly() {
        PipelineInitializer.ExecuteResult result = new PipelineInitializer.ExecuteResult();

        copado.Jobs.ExecutionCreateFromTemplateRequest initializeRequest = new copado.Jobs.ExecutionCreateFromTemplateRequest();
        initializeRequest.templateAPIName = SFDX_INITIALIZE_BRANCHES_ONLY;
        initializeRequest.pipelineId = pipeline?.Id;
        initializeRequest.dataJson = getDataJson(new PipelineDescriptor(pipeline?.Id).getDestinationBranchesBySourceBranches());
        copado__JobExecution__c initializeJob = copado.Jobs.Execution.createFromTemplate(initializeRequest).jobExecution;

        copado.Jobs.ExecutionResult executionResult = copado.Jobs.Execution.execute(new copado.Jobs.ExecutionRequest(initializeJob.Id));
        result.jobExecution = executionResult.jobExecution;

        return result;
    }

    private String getDataJson(Map<String, String> destinationBranchesBySourceBranches) {
        List<Branch> branches = new List<Branch>();

        for (String sourceBranch : destinationBranchesBySourceBranches.keySet()) {
            branches.add(new Branch(sourceBranch, destinationBranchesBySourceBranches.get(sourceBranch)));
        }

        JobData jobData = new JobData(branches);
        return JSON.serialize(jobData);
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

    private class JobData {
        public List<Branch> branches;

        public JobData(List<Branch> branches) {
            this.branches = branches;
        }
    }
}