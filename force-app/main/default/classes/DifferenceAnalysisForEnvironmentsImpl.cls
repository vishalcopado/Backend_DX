@SuppressWarnings('PMD.OperationWithLimitsInLoop')
public inherited sharing class DifferenceAnalysisForEnvironmentsImpl implements Queueable, Finalizer {

    private static final String IN_PROGRESS = 'In Progress';
    private static final String SFDX_DIFFERENCE_ANALYSIS = 'SFDX_Difference_Analysis_1';

    List<Request> requests;

    // CONSTRUCTOR


    public DifferenceAnalysisForEnvironmentsImpl(List<Request> requests) {
        this.requests = requests;
    }


    // PUBLIC

    public void execute() {
        Integer loopLimit = Math.min(requests.size(), 25);

        // NOTE: SF Limitation for only upto 50 Queueable jobs in a transaction
        for (Integer i = 0; i < loopLimit; i++) {
            Request request = requests.remove(0);
            if(Test.isRunningTest() || requests.size() == 1) {
                request.execute();
            } else {
                System.enqueueJob(new DifferenceAnalysisForEnvironmentsImpl(new List<Request> {request}));
            }
        }

        if (!requests.isEmpty()) {
            System.enqueueJob(this);
        }
    }


    public void execute(QueueableContext context) {
        if (requests.isEmpty()) {
            return;
        }

        Request request = requests.remove(0);
        // NOTE - Pipeline record needs to be refreshed
        request.pipeline = new PipelinesSelector().byId(new Set<Id>{ request.pipeline.Id })[0];
        request.execute();

        if(!requests.isEmpty()) {
            System.attachFinalizer(this);
        }
    }


    public void execute(FinalizerContext ctx) {
        System.enqueueJob(this);
    }


    // INNER

    public inherited sharing class Request {
        public Id sourceId;
        public Id destinationId;
        public Id sourceMetaFileId;
        public Id destinationMetaFileId;
        public copado__Deployment_Flow__c pipeline;


        // PRIVATE

        private void execute() {
            Id jobId = runJobForDifferenceAnalysis();
            PipelineInitializationDetails initializationData = getInitializationData();
            String latestInitializationData = getLatestInitializationData(initializationData, jobId);
            updateInitializationData(latestInitializationData);
        }


        private PipelineInitializationDetails getInitializationData() {
            if (String.isBlank(pipeline?.Initialization_Data__c)) {
                throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }));
            }

            return (PipelineInitializationDetails) JSON.deserialize(pipeline.Initialization_Data__c, PipelineInitializationDetails.class);
        }


        private Id runJobForDifferenceAnalysis() {
            copado.Jobs.ExecutionCreateFromTemplateRequest differenceAnalysisRequest = new copado.Jobs.ExecutionCreateFromTemplateRequest();
            differenceAnalysisRequest.templateAPIName = SFDX_DIFFERENCE_ANALYSIS;
            differenceAnalysisRequest.pipelineId = pipeline?.Id;
            differenceAnalysisRequest.sourceId = sourceId;
            differenceAnalysisRequest.destinationId = destinationId;
            differenceAnalysisRequest.dataJson = getJson();
            differenceAnalysisRequest.callback = PipelineDifferenceAnalysisCallback.class.getName();
            copado__JobExecution__c differenceAnalysisJob = copado.Jobs.Execution.createFromTemplate(differenceAnalysisRequest).jobExecution;

            copado.Jobs.ExecutionResult executionResult = copado.Jobs.Execution.execute(new copado.Jobs.ExecutionRequest(differenceAnalysisJob.Id));
            return executionResult.jobExecution.Id;
        }


        private String getLatestInitializationData(PipelineInitializationDetails currentInitializationData, Id jobId) {
            Boolean isAnalysisInProgress = false;

            if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
                currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
                isAnalysisInProgress = false;
            } else {
                for (PipelineInitializationDetails.ActivityLog log : currentInitializationData.activityLog) {
                    if (String.isNotBlank(log.title) && log.title.equalsIgnoreCase(Label.CalculatingDifferences) && log.status.equalsIgnoreCase(IN_PROGRESS)) {
                        isAnalysisInProgress = true;
                        break;
                    }
                }
            }

            if (!isAnalysisInProgress) {
                PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
                logEntry.status = IN_PROGRESS;
                logEntry.timestamp = System.now().getTime();
                logEntry.title = Label.CalculatingDifferences;

                currentInitializationData.activityLog.add(logEntry);
                currentInitializationData.diffAnalysisStatus = IN_PROGRESS;
            }

            currentInitializationData.diffAnalysisJobs = (currentInitializationData.diffAnalysisJobs == null) ? new List<Id>() : currentInitializationData.diffAnalysisJobs;
            currentInitializationData.diffAnalysisJobs.add(jobId);

            return JSON.serializePretty(currentInitializationData);
        }


        private void updateInitializationData(String latestInitializationData) {
            copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
                Id = pipeline.Id,
                Initialization_Data__c = latestInitializationData
            );
            Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
        }

        private String getJson() {
            Map<String, Id> fileIdByEnvironment = new Map<String, Id>();
            fileIdByEnvironment.put('sourceEnvironmentFileId', sourceMetaFileId);
            fileIdByEnvironment.put('targetEnvironmentFileId', destinationMetaFileId);

            return JSON.serialize(fileIdByEnvironment);
        }
    }
}