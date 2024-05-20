@IsTest
private class DXCommitDataTest {
    private static final String ATTACHMENT_NAME = 'Template Detail';
    private final static String TASK_TEMPLATE = 'Task Template';
    private final static String JOB_TEMPLATE_NAME = 'SFDX_Generate_Data_Set';
    private final static String USER_STORY_NAME = 'US_Sample';
    private final static String DATASET_NAME = 'Dataset_Sample';
    private final static String SOURCE_DEV_NAME = 'dev1';
    private final static String DESTINATION_DEV_NAME = 'dev2';
    private static String dataJson = '{"userStoryId":}';

    @TestSetup
    static void makeData(){
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testCreateWithValidInput() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__JobTemplate__c jobTemplate = getJobTemplate(JOB_TEMPLATE_NAME);
            copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);
            copado__Data_Set__c dataset = getDataSet(DATASET_NAME);
            copado__User_Story__c userStory = getUserStory(USER_STORY_NAME);

            DXCommitData.Request request = createRequest(userStory.Id, DXCommitData.Source.ENVIRONMENT, 
                taskDataTemplate.Id, dataset.Id, 'commit message');
            
            // EXERCISE
            Id dataCommitId = new DXCommitData().create(request);  

            copado__User_Story_Data_Commit__c dataCommit = getUSDataCommit(dataCommitId);
            copado__JobExecution__c jobExecution = getJobExecutionByTemplateApi(jobTemplate.copado__ApiName__c);
            
            new DXCommitData().execute(jobExecution, 'Successful');

            // VERIFY
            Assert.areEqual(userStory.Id, dataCommit.copado__User_Story__c, 'The user story Id inside data commit must be ' + userStory.Id);
            Assert.areEqual(jobExecution.Id, dataCommit.copado__Generate_Data_Set_Job_Execution_Id__c, 'The job execution Id must be equal ' + jobExecution.Id);

            String dataSetCommitName = 'Deploy ' + userStory.Name + '/' + TASK_TEMPLATE;
            copado__JobStep__c jobStep = getJobStepByUserStory(userStory.Id);
            Assert.areEqual(dataSetCommitName, jobStep.Name, 'Job Step should have name equal ' + dataSetCommitName);
        }
    }

    @IsTest
    private static void testCreateWithInValidInput() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);
            copado__Data_Set__c dataset = getDataSet(DATASET_NAME);
            copado__User_Story__c userStory = getUserStory(USER_STORY_NAME);

            DXCommitData.Request request = createRequest(userStory.Id, DXCommitData.Source.ENVIRONMENT, 
                taskDataTemplate.Id , dataset.Id, '');
            
            // EXERCISE
            String exceptionMessage;
            try {
                new DXCommitData().create(request);     
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.isTrue(exceptionMessage.contains(Label.Commit_Message_Required), 'Error message should contain: +' + Label.Commit_Message_Required);
        }
    }
   
    private static void createData() {
        new Credential(new Environment().name(SOURCE_DEV_NAME).platform('SFDX').type('Production/Developer')).type('Production/Developer');
        new Credential(new Environment().name(DESTINATION_DEV_NAME).platform('SFDX').type('Production/Developer')).type('Production/Developer').persist();
        copado__Org__c sourceOrg = getOrg(SOURCE_DEV_NAME);
        copado__Org__c destOrg = getOrg(DESTINATION_DEV_NAME);
        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        destOrg.copado__SFDC_Org_ID__c = sfdcOrgId;
        update destOrg;

        new DataTemplate().name(TASK_TEMPLATE).activate().persist();
        copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);
        new Attachment_t()
        .name(DataTemplateDetail.ATTACHMENT_NAME)
        .body(Blob.valueOf(getTaskDataTemplateDetail(taskDataTemplate, sourceOrg)))
        .parent(taskDataTemplate.Id);

        new JobTemplate()
        .name(JOB_TEMPLATE_NAME)
        .apiName('SFDX_Generate_Data_Set_1')
        .add(new JobStep().name('step1').type('Manual'))
        .persist();

        copado__Data_Set__c dataset = new copado__Data_Set__c(Name = DATASET_NAME, copado__Data_Template__c = taskDataTemplate.Id);
        insert dataset;

        copado__User_Story__c userStory = new copado__User_Story__c(copado__User_Story_Title__c = USER_STORY_NAME, copado__Org_Credential__c = sourceOrg.Id);
        insert userStory;

        copado__Function__c function = new copado__Function__c();
        function.Name = 'SFDX_DATA_SET';
        function.copado__API_Name__c = 'SFDX_DATA_SET';
        insert function;

    }

    private static copado__Data_Template__c getDataTemplate(String name) {
        return [SELECT Id FROM copado__Data_Template__c WHERE Name = :name];
    }

    private static copado__Org__c getOrg(String name) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :name LIMIT 1];
    }

    private static copado__Data_Set__c getDataSet(String name) {
        return [SELECT Id FROM copado__Data_Set__c WHERE Name = :name LIMIT 1];
    }

    private static copado__JobTemplate__c getJobTemplate(String name) {
        return [SELECT Id, Name, copado__ApiName__c FROM copado__JobTemplate__c WHERE Name = :name LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecutionByTemplateApi(String templateApiName) {
        return [SELECT Id, copado__DataJson__c, copado__ParentId__c FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = :templateApiName LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecutionById(Id id) {
        return [SELECT Id, copado__DataJson__c, copado__ParentId__c  FROM copado__JobExecution__c WHERE Id = :id LIMIT 1];
    }

    private static copado__User_Story__c getUserStory(String name) {
        return [SELECT Id, Name FROM copado__User_Story__c WHERE copado__User_Story_Title__c = :name LIMIT 1];
    }

    private static copado__User_Story_Data_Commit__c getUSDataCommit(Id id) {
        return [SELECT Id, copado__Data_Set__c, copado__User_Story__c, copado__Generate_Data_Set_Job_Execution_Id__c FROM copado__User_Story_Data_Commit__c WHERE Id = :id LIMIT 1];
    }

    private static copado__JobStep__c getJobStepByUserStory(Id id) {
        return [SELECT Id, Name, copado__UserStory__c FROM copado__JobStep__c WHERE copado__UserStory__c = :id LIMIT 1];
    }

    private static String getTaskDataTemplateDetail(copado__Data_Template__c taskDataTemplate, copado__Org__c sourceOrg) {
        return '{' +
            '"selectableFieldsMap": {' +
            '"ReminderDateTime": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "ReminderDateTime",' +
            '"label": "Reminder Date/Time",' +
            '"isSelected": true,' +
            '"fieldType": "datetime",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Id": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Id",' +
            '"label": "Activity ID",' +
            '"isSelected": true,' +
            '"fieldType": "id",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '}' +
            '},' +
            '"selectableChildRelationsMap": {' +
            '"RecurrenceActivityId-RecurringTasks": {' +
            '"relationshipName": "RecurringTasks",' +
            '"objectApiNameMap": {' +
            '"Task": "Task"' +
            '},' +
            '"isSelected": false,' +
            '"field": "RecurrenceActivityId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": null,' +
            '"childSObject": "Task"' +
            '}' +
            '},' +
            '"queryFilterList": [],' +
            '"parentObjectsReferenceList": [],' +
            '"dataTemplate": {' +
            '"templateSourceOrg": "' +
            sourceOrg.Id +
            '",' +
            '"templateSelectedAttachmentType": "files",' +
            '"templateQueryLimit": null,' +
            '"templateName": "' +
            TASK_TEMPLATE +
            '",' +
            '"templateMatchRecordTypes": true,' +
            '"templateMatchOwners": true,' +
            '"templateMainObject": "' +
            TASK_TEMPLATE +
            '",' +
            '"templateId": "' +
            taskDataTemplate.Id +
            '",' +
            '"templateFilterLogic": "1",' +
            '"templateDescription": null,' +
            '"templateContinueOnError": "Continue deployment until blocker issue",' +
            '"templateBatchSize": 200,' +
            '"templateAttachmentOption": "No Attachments",' +
            '"templateActive": true' +
            '},' +
            '"childrenObjectsReferenceList": []' +
            '}';
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static DXCommitData.Request createRequest(
        String userStoryId,
        DXCommitData.Source sourceType,
        Id dataTemplateId,
        Id dataSetId,
        String commitMessage
    ) {
        DXCommitData.Request request = new DXCommitData.Request();
        request.userStoryId = userStoryId;
        request.sourceType = sourceType;
        request.dataTemplateId = dataTemplateId;
        request.dataSetId = dataSetId;
        request.commitMessage = commitMessage;
        request.filterLogic = '';
        request.filters = new List<DataFilter>();
        return request;
    }


}