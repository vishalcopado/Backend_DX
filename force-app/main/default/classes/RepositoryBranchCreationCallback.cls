@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class RepositoryBranchCreationCallback implements copado.MCCallback {

    private static final String ERROR = 'Error';
    private static final String SUCCESS = 'Success';
    private static final String CANCELLED = 'Cancelled';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String BRANCHES_CREATED = 'Branches created';

    private static final Map<String, String> STATUS_VALUE_BY_JOB_STATUS = new Map<String,String>{ SUCCESS => SUCCESS, 'Failed' => ERROR, CANCELLED => CANCELLED };

    global void execute(copado__Function__c function, copado__Result__c result, String status) {
        try {
            if (result != null) {
                copado__Result__c resultRecord = new ResultsSelector().byIds(new Set<Id>{ result.Id })[0];

                if (STATUS_VALUE_BY_JOB_STATUS.containsKey(status)) {
                    Id pipelineId = resultRecord?.copado__JobStep__r?.copado__JobExecution__r?.copado__Pipeline__c;

                    PipelineInitializationDetails currentInitializationData = getCurrentInitializationData(pipelineId);
                    String latestInitializationData = getLatestInitializationData(currentInitializationData, status);
                    updateInitializationData(pipelineId, latestInitializationData);

                    notifyViaEmail(resultRecord, status);
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
        if (currentInitializationData.activityLog == null || currentInitializationData.activityLog.isEmpty()) {
            currentInitializationData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
        } else {
            for (PipelineInitializationDetails.ActivityLog log : currentInitializationData.activityLog) {
                if (String.isNotBlank(log.title) && log.title.equalsIgnoreCase(Label.CreatingBranches) && log.status.equalsIgnoreCase(IN_PROGRESS)) {
                    log.status = STATUS_VALUE_BY_JOB_STATUS.get(status);
                    break;
                }
            }
        }

        if (status == 'Success') {
            currentInitializationData.status = BRANCHES_CREATED;
            currentInitializationData.completedDate = System.now().toString();
            currentInitializationData.pendingEnvironmentIds = new List<Id>();
            currentInitializationData.currentEnvironmentId = null;

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();

            logEntry.status = SUCCESS;
            logEntry.timestamp = System.now().getTime();
            logEntry.title = Label.BranchesCreated;

            currentInitializationData.activityLog.add(logEntry);
        }

        return JSON.serializePretty(currentInitializationData);
    }

    private void notifyViaEmail(copado__Result__c result, String status) {
        copado.CopadoNotifications.SendRequest request = new copado.CopadoNotifications.SendRequest();

        request.name = status == 'Success' ? 'Branch_Creation_Success' : 'Branch_Creation_Failed';
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = new Map<String, String>{
            'PipelineName' => result.copado__JobStep__r?.copado__JobExecution__r?.copado__Pipeline__r?.Name,
            'JobExecutionLink' => getExternalLink(result?.copado__JobStep__r?.copado__JobExecution__c),
            'UserName' => UserInfo.getName()
        };

        copado.CopadoNotifications.send(request);
    }

    private String getExternalLink(Id recordId) {
        return URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
    }
}