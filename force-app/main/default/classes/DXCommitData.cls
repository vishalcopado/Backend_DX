@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global with sharing class DXCommitData implements copado.JobExecutionCallback {
    // CONSTRUCTOR
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global DXCommitData() {
        // Empty constructor needed so callback function can be called
    }
   
    // PUBLIC
    public Id create(Request request) {
        // Pre-work: validate request, create Data Set if not exist
        validateRequest(request);

        List<copado__User_Story__c> userStories = new UserStoriesSelector().byIds(new Set<Id> { request.userStoryId });
        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.User_Story_Not_Found);
        }
        copado__User_Story__c userStory = userStories[0];

        Request.dataSetId = findExistingDataSet(request);
        if (Request.dataSetId == null) {
            Request.dataSetId = createDataSetIfNotExist(request, userStory).Id;
        }
        
        // Work: execute Data Set Job Template to generate dataset, create User Story Data Commit Records  
        String sourceOrgId = userStory.copado__Org_Credential__c;
        String sourceId = getOrgEnvironmentId(sourceOrgId);
        String destinationId = getCurrentOrgCredential().copado__Environment__c;
        copado.CreateExecution.request jobRequest = createJob(request, sourceId, destinationId, sourceOrgId);
        copado__JobExecution__c jobExecution = copado.CreateExecution.execute(new List<copado.CreateExecution.Request>{ jobRequest }).get(0);

        copado__User_Story_Data_Commit__c dataCommit = createDataCommit(request, jobExecution.id);

        return dataCommit.Id;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private copado.CreateExecution.request createJob(Request request, String sourceId, String destinationId, String sourceOrgId) {
        
        JobStepDataDeployController.DataTemplate dataTemplate = JobStepDataDeployController.loadDataTemplateById(new List<Id>{ request.dataTemplateId })
                                                                .get(request.dataTemplateId);
        dataTemplate.queryFilterList = DataTemplateFilterController.convertFilters(request.filters);
        dataTemplate.filterLogic = request.filterLogic;
        DataTemplatePayloadRetriever templatePayloadRetrieved = new DataTemplatePayloadRetriever();
        String dataTemplatePayload =  templatePayloadRetrieved.getDataTemplatePayload(dataTemplate);
        DataJson dataJson = new DataJson(sourceOrgId, request.userStoryId, request.dataSetId, dataTemplatePayload);
        
        copado.CreateExecution.request jobRequest = new copado.CreateExecution.request();
        jobRequest.templateName = 'SFDX_Generate_Data_Set_1';
        jobRequest.parentId = request.dataSetId;
        jobRequest.sourceId = sourceId;
        jobRequest.destinationId = destinationId;
        jobRequest.runAfterInstantiation = true;
        jobRequest.callback = DXCommitData.class.getName();
        jobRequest.dataJson = JSON.serialize(dataJson);
        
        return jobRequest;
    }

    private Id getOrgEnvironmentId(Id orgId) {
        copado__Org__c org = new CredentialsSelector().byIds(new List<Id> {orgId})[0];
        return org.copado__Environment__c;
    }

    private copado__Org__c getCurrentOrgCredential() {
        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        List<copado__Org__c> orgs = new CredentialsSelector().bySFDCOrgId(new Set<String> {sfdcOrgId});
        if (orgs.isEmpty()) {
            throw new ApplicationException(Label.Error_Validate_Current_Org_Credential);
        }
        return orgs[0];
    }
   
    // Execution callback
    @SuppressWarnings('PMD.CognitiveComplexity')
    global void execute(copado__JobExecution__c job, String status) {
        //Post Work - if success, create a new Data Set Deployment Step
        try {
            if (status != 'Successful') {
                return;
            }

            DataJson dataJson = (DataJson) JSON.deserialize(job.copado__DataJson__c, DataJson.class);
            Id userStoryId = dataJson.userStoryId;
            
            // update dataset details
            copado__Data_Set__c dataSet = new DataSetsSelector().byIds(new Set<Id>{job.copado__ParentId__c})[0];
            dataSet.copado__Last_Generated_Date__c = System.now();
            dataSet.copado__Source_Org__c = dataJson.sourceOrgId;
            Utilities.performDML(new List<copado__Data_Set__c>{ dataSet }, 'update', AccessLevel.USER_MODE);

            // check if deployment step exists
            List<copado__JobStep__c> steps = new JobStepsSelector().byUserStoryIds(new Set<Id>{userStoryId});
            Boolean isStepExisting = false;
            List<Parameter> parameters = new List<Parameter>();
            for (copado__JobStep__c step : steps){
                ConfigJson configJson = (ConfigJson) JSON.deserialize(step.copado__ConfigJson__c, ConfigJson.class);
                parameters.addAll(configJson.parameters);
            }
            for (Parameter parameter : parameters){
                if (parameter.name == 'dataJson'){
                    SourceDataSet sourceDataSet = (SourceDataSet) JSON.deserialize(parameter.value, SourceDataSet.class);
                    if (sourceDataSet.sourceDataSetId == dataSet.Id){
                        isStepExisting = true;
                        break;
                    }
                }
            }

            // create a deployment step
            if (!isStepExisting){
                copado__JobStep__c step = new copado__JobStep__c(
                    Name = 'Deploy ' + dataSet.Name,
                    copado__UserStory__c = userStoryId,
                    copado__Type__c = 'Function',
                    copado__CustomType__c = 'Data Set - Salesforce',
                    copado__ExecutionSequence__c = 'after',
                    copado__Order__c = getOrder(userStoryId),
                    copado__ConfigJson__c = buildConfigJson(dataSet)
                );
                Utilities.performDML(new List<copado__JobStep__c>{ step }, 'insert', AccessLevel.USER_MODE);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE
    private void validateRequest(Request request) {
        if (request.userStoryId == null) {
            throw new ApplicationException(Label.User_Story_Required);
        }
        if (request.dataTemplateId == null) {
            throw new ApplicationException(Label.Data_Template_Id_Missing);
        }
        if (String.isBlank(request.commitMessage)) {
            throw new ApplicationException(Label.Commit_Message_Required);
        }
    }

    private Id findExistingDataSet(Request request) {
        List<copado__User_Story_Data_Commit__c> dataCommits = new UserStoryDataCommitsSelector().byUserStoryIdAndTemplateId(request.userStoryId, request.dataTemplateId);
        return dataCommits.isEmpty() ? null : dataCommits[0].copado__Data_Set__r.Id;
    }

    private copado__Data_Set__c createDataSetIfNotExist(Request request, copado__User_Story__c userStory) {

        String userStoryName = userStory.Name;
        String dataTemplateName = getDataTemplate(request.dataTemplateId).Name;

        copado__Data_Set__c dataSet = new copado__Data_Set__c(
            Name = userStoryName + '/' + dataTemplateName,
            copado__Data_Template__c = request.dataTemplateId
        );

        Utilities.performDML(new List<copado__Data_Set__c>{ dataSet }, 'insert', AccessLevel.USER_MODE);
        return dataSet;
    }

    private copado__Data_Template__c getDataTemplate(Id dataTemplateId){
        List<copado__Data_Template__c> dataTemplates = new DataTemplatesSelector().byIdSelectedField(new Set<Id>{dataTemplateId});
        if (dataTemplates.isEmpty()){
            throw new ApplicationException(Label.Data_Template_Id_Missing);
        }
        return dataTemplates[0];
    }

    private copado__User_Story_Data_Commit__c createDataCommit(Request request, Id jobExecutionId) {
        copado__User_Story_Data_Commit__c dataCommit = new copado__User_Story_Data_Commit__c(
            copado__Commit_Date__c = Datetime.now(),
            copado__Commit_Message__c = request.commitMessage,
            copado__Data_Set__c = request.dataSetId,
            copado__Generate_Data_Set_Job_Execution_Id__c = jobExecutionId,
            copado__User_Story__c = request.userStoryId
        );
        Utilities.performDML(new List<copado__User_Story_Data_Commit__c>{ dataCommit }, 'insert', AccessLevel.USER_MODE);

        return dataCommit;
    }

    private Decimal getOrder(Id userStoryId) {
        Decimal maxOrder = (Decimal) [
                SELECT MAX(copado__Order__c) MaxOrder
                FROM copado__JobStep__c
                WHERE copado__UserStory__c = :userStoryId AND copado__ExecutionSequence__c = 'after'
            ]
            .get(0)
            .get('MaxOrder');

        return (maxOrder == null) ? 1 : (maxOrder + 1);
    }

    private String buildConfigJson(copado__Data_Set__c dataSet) {
        // get function parameters
        String functionName = 'SFDX_DATA_SET';
        String parametersString = JobStepDataDeployController.getFunctionParameters(functionName);
        List<FunctionParameter> functionParameters = (List<FunctionParameter>) JSON.deserialize(parametersString, List<FunctionParameter>.class);
        List<Parameter> configParameters = new List<Parameter>();
        
        // build config json parameters
        for (FunctionParameter functionParameter : functionParameters){
            if (functionParameter.name == 'dataJson'){
                configParameters.add(new Parameter(functionParameter.name, JSON.serialize(new Map<String, String>{'sourceDataSetId' => (String)dataSet.Id})));
            }
            else if (functionParameter.name == 'sourceOrgId'){
                configParameters.add(new Parameter(functionParameter.name, (String)getCurrentOrgCredential().copado__Environment__c));
            }
            else {
                configParameters.add(new Parameter(functionParameter.name, functionParameter.defaultValue));
            }
        }
        configParameters.add(new Parameter('dataSet', JSON.serialize(new JobStepDataSet.DataSet(dataSet.Id, dataSet.Name))));

        ConfigJson configJson = new ConfigJson(functionName);
        configJson.parameters = configParameters;

        return JSON.serialize(configJson);
    }

    // INNER
    public enum Source {
        ENVIRONMENT,
        DATASET
    }

    public class Request {
        public Id userStoryId;
        public Source sourceType;
        public Id dataTemplateId;
        public Id dataSetId;
        public String commitMessage;
        public List<DataFilter> filters;
        public String filterLogic;
    }

    public class Response {
        @InvocableVariable
        public copado__JobExecution__c job;

        public Response(copado__JobExecution__c job) {
            this.job = job;
        }
    }

    // INNER PRIVATE

    @TestVisible
    private class ConfigJson {
        @TestVisible
        public String functionName;

        @TestVisible
        public List<Parameter> parameters;

        public ConfigJson(String functionName) {
            this.functionName = functionName;
        }
    }

    @TestVisible
    private class Parameter {
        @TestVisible
        public String name;

        @TestVisible
        public String value;

        @TestVisible
        public Parameter(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }

    @TestVisible
    private class FunctionParameter {
        @TestVisible
        public String name;

        @TestVisible
        public String defaultValue;
    }

    @TestVisible
    private class SourceDataSet {
        @TestVisible
        public Id sourceDataSetId;
    }

    @TestVisible
    private class DataJson {
        @TestVisible
        public String sourceOrgId;

        @TestVisible
        public Id userStoryId;

        @TestVisible
        public String destinationDataSetId;

        @TestVisible
        public String dataTemplatePayload;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public DataJson(String sourceOrgId, Id userStoryId, String destinationDataSetId, String dataTemplatePayload) {
            this.sourceOrgId = sourceOrgId;
            this.userStoryId = userStoryId;
            this.destinationDataSetId = destinationDataSetId;
            this.dataTemplatePayload = dataTemplatePayload;
        }
    }

}