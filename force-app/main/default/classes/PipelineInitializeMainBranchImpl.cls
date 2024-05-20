public inherited sharing class PipelineInitializeMainBranchImpl {

    private copado__Deployment_Flow__c pipeline;
    private PipelineDescriptor pipelineDescriptor;
    private String initializationType;

    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization_1';
    private static final String INITIALIZING_MAIN = 'Initializing main';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String WIP_FULL = 'WIP Full';

    private static final Set<String> INITIALIZATION_STATUS = new Set<String> { INITIALIZING_MAIN, 'Error initializing main' };

    // CONSTRUCTOR

    public PipelineInitializeMainBranchImpl(PipelineInitializer.InitializeMainBranchRequest request) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ request.pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.initializationType = request.initializationType;
        this.pipelineDescriptor = new PipelineDescriptor(request.pipelineId, pipelines[0].copado__Main_Branch__c);
    }

    // PUBLIC STATIC

    public static PipelineInitializer.InitializeMainBranchResult execute(PipelineInitializer.InitializeMainBranchRequest request) {
        if(request.pipelineId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}));
        }

        return new PipelineInitializeMainBranchImpl(request).execute();
    }

    // PUBLIC

    public PipelineInitializer.InitializeMainBranchResult execute() {
        if (pipeline.copado__Platform__c != 'SFDX') {
            throw new ApplicationException(Label.PipelineUnavailableForInitializationMessage);
        }
        PipelineInitializer.InitializeMainBranchResult result;

        String status = getPipelineInitializationStatus();
        if (INITIALIZATION_STATUS.contains(status)) {
            result = initializeSalesforceProject();
            String latestInitializationData = getInitializationData(result.jobExecution.Id);
            updateInitializationData(latestInitializationData);
        }

        return result;
    }

    // PRIVATE

    private String getPipelineInitializationStatus() {
        String result;

        if (String.isBlank(pipeline?.Initialization_Data__c)) {
            result = INITIALIZING_MAIN;
        } else {
            PipelineInitializationDetails initializationData = (PipelineInitializationDetails) JSON.deserialize(pipeline.Initialization_Data__c, PipelineInitializationDetails.class);
            result = initializationData?.status;
        }

        return result;
    }

    private void updateInitializationData(String latestInitializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipeline.Id,
            Initialization_Data__c = latestInitializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private String getInitializationData(Id jobId) {
        PipelineInitializationDetails details;
        if (String.isBlank(pipeline?.Initialization_Data__c)) {
            details = new PipelineInitializationDetails();
        } else {
            details = (PipelineInitializationDetails) JSON.deserialize(pipeline.Initialization_Data__c, PipelineInitializationDetails.class);
        }

        details.initializationType = initializationType;
        details.status = INITIALIZING_MAIN;
        details.pendingEnvironmentIds = getPipelineEnvironmentIds();
        details.latestJobExecutionId = jobId;
        details.currentEnvironmentId = details.pendingEnvironmentIds.isEmpty() ? null : details.pendingEnvironmentIds[0];

        PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
        logEntry.status = IN_PROGRESS;
        logEntry.timestamp = System.now().getTime();
        logEntry.title = Label.InitializeProject;

        details.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };

        return JSON.serializePretty(details);
    }

    private List<Id> getPipelineEnvironmentIds() {
        List<Id> result = new List<Id>();

        try {
            List<copado__Deployment_Flow_Step__c> orderedConnections = pipelineDescriptor.getOrderedPipelineConnections();
            for (copado__Deployment_Flow_Step__c connection : orderedConnections) {
                result.add(connection.copado__Source_Environment__c);
            }
        } catch (Exception ex) {
            throw new ApplicationException(Label.VisitPipelineManager);
        }

        return result;
    }

    private PipelineInitializer.InitializeMainBranchResult initializeSalesforceProject() {
        PipelineInitializer.InitializeMainBranchResult result = new PipelineInitializer.InitializeMainBranchResult();

        ProjectInitializationDetails initializationDetails = new ProjectInitializationDetails();
        initializationDetails.gitRepositoryId = pipeline?.copado__Git_Repository__c;
        initializationDetails.defaultDirectory = 'force-app';
        initializationDetails.branch = pipeline?.copado__Main_Branch__c;
        initializationDetails.projectName = pipeline?.Name;
        initializationDetails.recreateProject = false;
        initializationDetails.template = 'standard';
        initializationDetails.gitRepositoryURI = pipeline?.copado__Git_Repository__r?.copado__URI__c;
        initializationDetails.forceBranchCreation = true;

        copado.Jobs.ExecutionCreateFromTemplateRequest projectInitializeRequest = new copado.Jobs.ExecutionCreateFromTemplateRequest();
        projectInitializeRequest.templateAPIName = SFDX_GIT_INITIALIZATION;
        projectInitializeRequest.pipelineId = pipeline?.Id;
        projectInitializeRequest.dataJson = JSON.serializePretty(initializationDetails);
        projectInitializeRequest.callback = PipelineInitializeProjectCallback.class.getName();
        copado__JobExecution__c projectInitializeJob = copado.Jobs.Execution.createFromTemplate(projectInitializeRequest).jobExecution;

        copado.Jobs.ExecutionResult executionResult = copado.Jobs.Execution.execute(new copado.Jobs.ExecutionRequest(projectInitializeJob.Id));
        result.jobExecution = executionResult.jobExecution;
        return result;
    }

    // INNER

    @TestVisible
    private class ProjectInitializationDetails {
        public Id gitRepositoryId;
        public String defaultDirectory;
        public String branch;
        public String projectName;
        public Boolean recreateProject;
        public String template;
        public String gitRepositoryURI;
        public Boolean forceBranchCreation;
    }
}