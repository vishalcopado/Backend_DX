@SuppressWarnings('PMD.CyclomaticComplexity')
public inherited sharing class DataSetJobTemplateImpl {

    public static DataDeploy.DataSetExecutionResult execute(DataDeploy.DataSetExecutionRequest request) {
        return new DataSetJobTemplateImpl().process(request);
	}

    private DataDeploy.DataSetExecutionResult process(DataDeploy.DataSetExecutionRequest request) {

        DataDeploy.DataSetExecutionResult result = new DataDeploy.DataSetExecutionResult();
        copado.CreateExecution.request jobTemplateRequest = getJobTemplateRequest(request);

        List<copado__JobExecution__c> jobExecutions = copado.CreateExecution.execute(new List<copado.CreateExecution.request> {jobTemplateRequest});

        result.jobExecutionId = jobExecutions[0].Id;

        updateDataSetLastExecutionDetails(request, result);

        return result;
    }

    private Id getCurrentOrgCredential() {
        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        List<copado__Org__c> orgs = new CredentialsSelector().bySFDCOrgId(new Set<String> {sfdcOrgId});
        if (orgs.isEmpty()) {
            throw new ApplicationException(Label.Error_Validate_Current_Org_Credential);
        }
        return orgs[0].Id;
    }


    private copado.CreateExecution.request getJobTemplateRequest(DataDeploy.DataSetExecutionRequest request) {
        copado.CreateExecution.request jobTemplateRequest = new copado.CreateExecution.request();
        jobTemplateRequest.templateName = request.jobTemplateName;
        jobTemplateRequest.parentId = request.parentId;
        jobTemplateRequest.runAfterInstantiation = true;
        Map<String,String> dataJson = new Map<String, String>();

        String dataTemplatePayload = request.destinationType.equalsIgnoreCase(Destination.DATASET.toString()) ? new DataTemplatePayloadRetriever().getDataTemplatePayloadById(request.dataTemplateId) : '';
        dataJson.put('dataTemplatePayload', dataTemplatePayload);

        Id currentOrgId = getCurrentOrgCredential();
        if (request.sourceType.equalsIgnoreCase(Source.DATASET.toString()) && request.destinationType.equalsIgnoreCase(Destination.ENVIRONMENT.toString()) && String.isNotBlank(request.sourceDataSetId)) {
            Id sourceCredentialId = currentOrgId;
            if (!validateCredential(sourceCredentialId)) {
                throw new ApplicationException(Label.Error_Validate_Current_Org_Credential);
            }
            jobTemplateRequest.sourceId = (String)getCredentialEnvironmentId(sourceCredentialId);
            jobTemplateRequest.destinationId = (String)getCredentialEnvironmentId(request.destinationCredentialId);
            dataJson.put('sourceDataSetId', request.sourceDataSetId);

        } else if (request.destinationType.equalsIgnoreCase(Destination.DATASET.toString()) && request.sourceType.equalsIgnoreCase(Source.ENVIRONMENT.toString()) && String.isNotBlank(request.destinationDataSetId)) {
            Id destinationCredentialId = currentOrgId;
            if (!validateCredential(destinationCredentialId)) {
                throw new ApplicationException(Label.Error_Validate_Current_Org_Credential);
            }
            jobTemplateRequest.sourceId = (String)getCredentialEnvironmentId(request.sourceCredentialId);
            jobTemplateRequest.destinationId = (String)getCredentialEnvironmentId(destinationCredentialId);
            dataJson.put('destinationDataSetId', request.destinationDataSetId);
        } else {
            throw new ApplicationException(Label.Error_Data_Set_Configure);
        }
        jobTemplateRequest.dataJson = JSON.serialize(dataJson);

        return jobTemplateRequest;

    }

    private Boolean validateCredential(Id id) {
        copado.ValidateOrgAction.Request request = new copado.ValidateOrgAction.Request();
        request.orgId = id;
        List<copado.ValidateOrgAction.Result> results = copado.ValidateOrgAction.execute(new List<copado.ValidateOrgAction.Request>{request});
        return !results.isEmpty() ? results.get(0).isValidOrg : false;
    }

    // use this function after validation return true
    private Id getCredentialEnvironmentId(Id id) {
        List<copado__Org__c> credentials = new CredentialsSelector().byIds(new List<Id>{id});
        return credentials[0].copado__Environment__c;
    }

    private void updateDataSetLastExecutionDetails(DataDeploy.DataSetExecutionRequest request, DataDeploy.DataSetExecutionResult result) {
        if (request.destinationType.equalsIgnoreCase(Destination.DATASET.toString())) {
            copado__Data_Set__c updatedDataSet = new copado__Data_Set__c(
                Id = request.parentId,
                copado__Last_Generated_Date__c = System.now(),
                copado__Source_Org__c = request.sourceCredentialId
            );
            Utilities.performDML(new List<copado__Data_Set__c>{ updatedDataSet }, 'update',AccessLevel.USER_MODE);
        }
    }

   // INNER
    @TestVisible
    private enum Source {
        ENVIRONMENT,
        DATASET,
        BRANCH
    }
    @TestVisible
    private enum Destination {
        ENVIRONMENT,
        DATASET,
        BRANCH
    }
}