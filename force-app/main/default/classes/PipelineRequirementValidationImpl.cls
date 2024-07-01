public inherited sharing class PipelineRequirementValidationImpl {

    private copado__Deployment_Flow__c pipeline;
    private PipelineDescriptor pipelineDescriptor;

    // CONSTRUCTOR

    public PipelineRequirementValidationImpl(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        this.pipeline = pipelines[0];
        this.pipelineDescriptor = new PipelineDescriptor(pipelineId);
    }

    // PUBLIC STATIC

    public static void execute(Id pipelineId) {
        if(pipelineId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}));
        }

        new PipelineRequirementValidationImpl(pipelineId).execute();
    }

    // PUBLIC

    public void execute() {
        validatePipeline();
        validateIfPipelineHasConnections();
        validateCredentialsAuthentication();
    }

    private void validatePipeline() {
        if (!pipeline.copado__Active__c) {
            throw new ApplicationException(Label.InactivePipelineError);
        }

        if (String.isBlank(pipeline.copado__Main_Branch__c)) {
            throw new ApplicationException(Label.MainBranchMissingError);
        }

        if (pipeline.copado__Git_Repository__c == null) {
            throw new ApplicationException(Label.GitRepoMissingError);
        }
    }

    private void validateIfPipelineHasConnections() {
        List<copado__Deployment_Flow_Step__c> pipelineConnections = new PipelineConnectionsSelector().byPipelineId(pipeline.Id);
        if(pipelineConnections.isEmpty()) {
            throw new ApplicationException(Label.PipelineConnectionsMissingError);
        }
    }

    private void validateCredentialsAuthentication() {
        Set<Id> environmentIds = pipelineDescriptor.getEnvironments().keySet();
        Boolean areCredentialsAuthenticated = pipelineDescriptor.areCredentialsAuthenticated(environmentIds);
        if (!areCredentialsAuthenticated) {
            throw new ApplicationException(Label.MissingAuthenticatedDefaultCredentials);
        }
    }
}