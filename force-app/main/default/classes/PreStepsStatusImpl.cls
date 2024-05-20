public inherited sharing class PreStepsStatusImpl {

    private copado__Deployment_Flow__c pipeline;
    private PipelineDescriptor pipelineDescriptor;

    private static final String TAKE_SNAPSHOT = 'TakeSnapshot';

    // CONSTRUCTOR

    public PreStepsStatusImpl(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.pipelineDescriptor = new PipelineDescriptor(pipelineId);
    }

    // PUBLIC STATIC

    public static PipelineInitializer.StatusResult execute(Id pipelineId) {
        if(pipelineId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}));
        }

        return new PreStepsStatusImpl(pipelineId).execute();
    }

    // PUBLIC

    public PipelineInitializer.StatusResult execute() {
        Id jobId = getSnapshotJobId();

        copado.Actions.StatusResult statusResult = new copado.Actions.StatusResult();
        if(jobId != null) {
            statusResult = copado.Actions.GitSnapshotService.status(jobId);
        }

        return new PipelineInitializer.StatusResult(statusResult.jobStatus, statusResult.steps, getInitializationStatus());
    }

    // PRIVATE

    private Id getSnapshotJobId() {
        Id result;

        copado__Environment__c finalEnvironment = pipelineDescriptor.findFinalEnvironment();
        Id mainCredentialId;

        if(finalEnvironment != null) {
            List<copado__Org__c> credentials = new CredentialsSelector().byEnvironmentIdAndValidationCheck(new Set<Id>{ finalEnvironment.Id });
            mainCredentialId = credentials.isEmpty() ? '' : credentials[0].Id;
        }

        List<copado__Git_Backup__c> snapshots = new GitSnapshotsSelector().byPipelineBranchRepoAndCredential(pipeline, mainCredentialId);

        if (!snapshots.isEmpty()) {
            List<copado__JobExecution__c> jobs = new JobExecutionsSelector().byPipelineActionAndSnapshot(pipeline.Id, TAKE_SNAPSHOT, snapshots[0].Id);
            result = jobs.isEmpty() ? '' : jobs[0].Id;
        }

        return result;
    }

    private String getInitializationStatus() {
        PipelineInitializationDetails initializationData;
        if (String.isNotBlank(pipeline?.Initialization_Data__c)) {
            initializationData = (PipelineInitializationDetails) JSON.deserialize(pipeline.Initialization_Data__c, PipelineInitializationDetails.class);
        }

        return initializationData?.status;
    }

}