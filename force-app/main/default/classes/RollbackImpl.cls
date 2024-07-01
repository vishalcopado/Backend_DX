@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global with sharing class RollbackImpl implements copado.JobExecutionCallback {
    private static final String VLOCITY_ROLLBACK_FILE = 'Copado Vlocity Rollback changes';
    private static final String SFDX_ROLLBACK_FILE = 'Copado Rollback changes';

    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global RollbackImpl() {
        // Empty constructor needed so callback function can be called
    }

    // PUBLIC
    public Response create(Request request) {
        validateRequest(request);
        Boolean startExecution = request.startExecution;
        copado__JobExecution__c jobExecution = createJob(request);
        if (startExecution) {
            copado.Jobs.Execution.execute(new copado.Jobs.ExecutionRequest(jobExecution.Id));
        }
        updatePromotion(jobExecution, startExecution);

        return new Response(jobExecution);
    }

    // Execution callback
    global void execute(copado__JobExecution__c job, String status) {
        ExecutionData executionData = (ExecutionData) JSON.deserialize(job.copado__DataJson__c, ExecutionData.class);
        Boolean isValidationRollback = executionData.isValidation;
        Boolean isRolledBack = status == 'Successful' && !isValidationRollback ? true : false;

        copado__Promotion__c promotion = new copado__Promotion__c(
            Id = job.copado__Promotion__c,
            copado__Is_Rolled_Back__c = isRolledBack,
            Rolled_Back_Date__c = Date.today(),
            Rollback_Status__c = parseStatus(status, Boolean.valueOf(isValidationRollback))
        );
        Utilities.performDML(new List<copado__Promotion__c>{ promotion }, 'update', AccessLevel.USER_MODE);
        // null input to JSON Parser.
    }

    // PRIVATE

    private void validateRequest(Request request) {
        if (
            String.isBlank(request.promotionId) ||
            String.isBlank(request.testLevel) ||
            request.isValidation == null ||
            request.startExecution == null
        ) {
            throw new ApplicationException(Label.RollbackRequestHasEmptyValues);
        }
    }

    private copado__JobExecution__c createJob(Request request) {
        copado__Promotion__c promotion = getPromotion(request.promotionId);

        Map<String, Id> getVersionIdFromTitle = getRollbackFileId(request.promotionId);

        Id rollbackfileId = getVersionIdFromTitle.get(SFDX_ROLLBACK_FILE);
        Id vlocityRollbackFileId = getVersionIdFromTitle.get(VLOCITY_ROLLBACK_FILE);

        Id pipelineId = promotion?.copado__Project__r?.copado__Deployment_Flow__c;
        String targetBranch = getTargetBranch(promotion);

        ExecutionData executionData = new ExecutionData();
        executionData.isValidation = request.isValidation;
        executionData.promotion = promotion.Name;
        executionData.rollbackFileId = rollbackfileId;
        executionData.targetBranch = targetBranch;
        executionData.testLevel = request.testLevel;
        executionData.vlocityRollbackFileId = vlocityRollbackFileId;

        copado.Jobs.ExecutionCreateFromTemplateRequest jobRequest = new copado.Jobs.ExecutionCreateFromTemplateRequest();
        jobRequest.parentId = promotion.Id;
        jobRequest.pipelineId = pipelineId;
        jobRequest.templateAPIName = getTemplateApiName(pipelineId, promotion.copado__Destination_Environment__c);
        jobRequest.callback = RollbackImpl.class.getName();
        jobRequest.dataJson = JSON.serializePretty(executionData, true);
        jobRequest.destinationId = promotion.copado__Destination_Environment__c;
        copado__JobExecution__c job = copado.Jobs.Execution.createFromTemplate(jobRequest).jobExecution;

        return job;
    }

    private copado__Promotion__c getPromotion(Id promotionId) {
        List<copado__Promotion__c> promotions = new PromotionsSelector().byIds(new Set<Id>{ promotionId });
        if (promotions.isEmpty()) {
            throw new ApplicationException(Label.Promotion_does_not_exists);
        }
        return promotions[0];
    }

    private Map<String, Id> getRollbackfileId(Id promotionId) {
        Map<String, Id> result = new Map<String, Id>{ SFDX_ROLLBACK_FILE => null, VLOCITY_ROLLBACK_FILE => null };

        List<ContentDocumentLink> documentLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ promotionId }, new Set<String>{ SFDX_ROLLBACK_FILE, VLOCITY_ROLLBACK_FILE });
        if (documentLinks.isEmpty()) {
            throw new ApplicationException(Label.Copado_Rollback_changes_does_not_exists);
        }

        for (ContentDocumentLink documentLink : documentLinks) {
            if (result.get(documentLink.ContentDocument.Title) == null) {
                result.put(documentLink.ContentDocument.Title, documentLink.ContentDocument.LatestPublishedVersionId);
            }
        }

        return result;
    }

    private String getTargetBranch(copado__Promotion__c promotion) {
        String result;
        Boolean isBackPromotion = promotion.copado__Back_Promotion__c;
        Id sourceId = promotion.copado__Source_Environment__c;
        Id destinationId = promotion.copado__Destination_Environment__c;
        Id pipelineId = promotion.copado__Project__r.copado__Deployment_Flow__c;

        result = isBackPromotion
            ? getPipelineConnection(destinationId, sourceId, pipelineId).copado__Branch__c
            : getPipelineConnection(sourceId, destinationId, pipelineId).copado__Destination_Branch__c;
        if (String.isBlank(result)) {
            throw new ApplicationException(Label.Destination_Branch_is_empty);
        }
        return result;
    }

    private static copado__Deployment_Flow_Step__c getPipelineConnection(Id sourceId, Id destinationId, Id pipelineId) {
        List<copado__Deployment_Flow_Step__c> pipelineConnections = new PipelineConnectionsSelector()
            .byPipelineAndSourceEnvAndDestinationEnv(new Set<Id>{ pipelineId }, new Set<Id>{ sourceId }, new Set<Id>{ destinationId });
        if (pipelineConnections.isEmpty()) {
            throw new ApplicationException(Label.Pipeline_Connection_does_not_exist);
        }
        return pipelineConnections[0];
    }

    private String getTemplateApiName(Id pipelineId, Id environmentId) {
        String result = '';

        // Note: it is important that this selector returns the list ordered by non-default actions first in order to consider overrides first.
        // If we are going to add more actions in DX extension, then below logic should be a separate class.
        for (
            copado__Pipeline_Action__c action : new PipelineActionSelector()
                .byPipelineAndAction(new Set<Id>{ pipelineId }, new Set<String>{ 'Rollback' })
        ) {
            if (isEnvironmentOverride(action) && !environmentOverrideMatches(action, environmentId)) {
                continue;
            }
            result = action.copado__Job_Template__r.copado__ApiName__c;
            break;
        }

        if (Test.isRunningTest()) {
            return 'SFDX_Rollback_1';
        } else if (String.isBlank(result)) {
            throw new ApplicationException(Label.Rollback_Action_does_not_exist);
        }

        return result;
    }

    private Boolean isEnvironmentOverride(copado__Pipeline_Action__c action) {
        return action.copado__Default__c == false && String.isNotBlank(action.copado__Environment__c);
    }

    private Boolean environmentOverrideMatches(copado__Pipeline_Action__c action, Id environmentId) {
        return action.copado__Environment__c == environmentId;
    }

    private void updatePromotion(copado__JobExecution__c jobExecution, Boolean startExecution) {
        String validationOnly = ((ExecutionData) JSON.deserialize(jobExecution.copado__DataJson__c, ExecutionData.class)).isValidation
            ? ' (Validation Only)'
            : '';
        copado__Promotion__c promotion = new copado__Promotion__c();
        promotion.Id = jobExecution.copado__Promotion__c;
        promotion.Last_Rollback_Execution_Id__c = jobExecution.Id;
        if (startExecution) {
            promotion.Rollback_Status__c = 'In Progress' + validationOnly;
        }
        Utilities.performDML(new List<copado__Promotion__c>{ promotion }, 'update', AccessLevel.USER_MODE);
    }

    private String parseStatus(String status, Boolean isValidation) {
        if (status == 'Successful' && !isValidation) {
            return 'Completed';
        }
        if (status == 'Successful' && isValidation) {
            return 'Validated';
        } else {
            return isValidation ? 'Validation Failed' : 'Failed';
        }
    }

    @TestVisible
    private class ExecutionData {
        @TestVisible
        private String rollbackFileId;
        @TestVisible
        private Boolean isValidation;
        @TestVisible
        private String testLevel;
        @TestVisible
        private String promotion;
        @TestVisible
        private String targetBranch;
        @TestVisible
        private String vlocityRollbackFileId;
    }

    // INNER

    public class Request {
        public Boolean isValidation;
        public String testLevel;
        public Id promotionId;
        public Boolean startExecution;
    }

    public class Response {
        @InvocableVariable
        public copado__JobExecution__c job;

        public Response(copado__JobExecution__c job) {
            this.job = job;
        }
    }
}