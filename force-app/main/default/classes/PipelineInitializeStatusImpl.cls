public inherited sharing class PipelineInitializeStatusImpl {

    // PUBLIC
    public static PipelineInitializer.InitializeResult execute(Id jobId) {
        if(jobId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Job Execution Id'}));
        }

        copado.Jobs.StatusResult statusResult = copado.Jobs.Execution.status(jobId);

        return new PipelineInitializer.InitializeResult(statusResult.jobStatus, statusResult.steps);
    }
}