@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PipelineInitializeMainCallback implements copado.JobExecutionCallback {

    private static final String MAIN_INITIALIZED = 'Main Initialized';
    private static final String ERROR_INITIALIZING_MAIN = 'Error initializing main';
    private static final String SUCCESS = 'Success';
    private static final String ERROR = 'Error';
    private static final String CANCELLED = 'Cancelled';

    private static final Map<String, String> STATUS_VALUE_BY_JOB_STATUS = new Map<String,String>{ 'Successful' => SUCCESS, ERROR => ERROR, 'Canceled' => CANCELLED };

    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global PipelineInitializeMainCallback() {
        // Empty constructor needed so callback function can be called
    }

    // Execution callback
    global void execute(copado__JobExecution__c job, String status) {
        try {
            PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(job.copado__Pipeline__c);
            String latestInitializationData = getLatestInitializationData(currentInitializationData, status);

            switch on status {
                when 'Successful' {
                    updateInitializationData(job.copado__Pipeline__c, latestInitializationData);
                    initializePipeline(job.copado__Pipeline__c);
                }
                when 'Error', 'Canceled' {
                    updateInitializationData(job.copado__Pipeline__c, latestInitializationData);
                }
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private void updateInitializationData(Id pipelineId, String latestInitializationData) {
        copado__Deployment_Flow__c pipelineWithInitializationData = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = latestInitializationData
        );
        Utilities.performDML(new List<copado__Deployment_Flow__c>{ pipelineWithInitializationData }, 'update', AccessLevel.USER_MODE);
    }

    private PipelineInitializationDetails getCurrentInitializationData(Id pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ pipelineId });
        if (pipelines.isEmpty()) {
            throw new ApplicationException(Label.NoPipelineFound);
        }

        if (String.isBlank(pipelines[0]?.Initialization_Data__c)) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }));
        }

        return (PipelineInitializationDetails) JSON.deserialize(pipelines[0]?.Initialization_Data__c, PipelineInitializationDetails.class);
    }

    private String getLatestInitializationData(PipelineInitializationDetails currentInitializationData, String status) {
        currentInitializationData.status = status == 'Successful' ? MAIN_INITIALIZED : ERROR_INITIALIZING_MAIN;

        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        } else {
            for (PipelineInitializationDetails.ActivityLog log : currentInitializationData.activityLog) {
                if (String.isNotBlank(log.title) && log.title.equalsIgnoreCase(Label.SnapshotMessage)) {
                    log.status = STATUS_VALUE_BY_JOB_STATUS.get(status);
                    break;
                }
            }
        }

        if (status == 'Successful') {
            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();

            logEntry.status = SUCCESS;
            logEntry.timestamp = System.now().getTime();
            logEntry.title = Label.SnapshotComplete;

            currentInitializationData.activityLog.add(logEntry);
        }

        return JSON.serializePretty(currentInitializationData);
    }

    private void initializePipeline(Id pipelineId) {
        PipelineInitializer.Initialize.execute(pipelineId);
    }
}