@IsTest
private class ExecuteDataSetJobTemplateActionTest {
    private static final String ATTACHMENT_NAME = 'Template Detail';
    private final static String TASK_TEMPLATE = 'Task Template';


    @TestSetup
    static void makeData(){
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithValidInput() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Org__c dev1 = getOrg('dev1');
            copado__Org__c dev2 = getOrg('dev2');
            
            copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);

            copado__JobTemplate__c jobTemplate = getJobTemplate('Job1');
            copado__Data_Set__c dataset = getDataSet('dataset1');

            DataDeploy.DataSetExecutionRequest request = createRequest(jobTemplate.copado__ApiName__c, dataset.Id, 
                DataSetJobTemplateImpl.Source.ENVIRONMENT.toString(), DataSetJobTemplateImpl.Destination.DATASET.toString(), 
                dev1.Id, dev2.Id,'', dataset.Id, taskDataTemplate.Id);
            
            // EXERCISE
            List<DataDeploy.DataSetExecutionResult> results = ExecuteDataSetJobTemplateAction.execute(new List<DataDeploy.DataSetExecutionRequest> {request});
            

             // VERIFY
             copado__JobExecution__c jobExecution = getJobExecution(jobTemplate.copado__ApiName__c);
             Assert.isNotNull(results[0], 'Execution result must be not Null');
             Assert.isTrue(results[0].jobExecutionId.getSobjectType().getDescribe().getName().contains('JobExecution'), 'The Id must be in type of Job Execution Id');
             Assert.areEqual(jobExecution.Id, results[0].jobExecutionId, 'The job execution Id must be equal ' + jobExecution.Id);
        }
    } 

    @IsTest
    private static void executeWithInvalidInput() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Org__c dev1 = getOrg('dev1');
            copado__Org__c dev2 = getOrg('dev2');
            
            copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);

            copado__JobTemplate__c jobTemplate = getJobTemplate('Job1');
            copado__Data_Set__c dataset = getDataSet('dataset1');

            // INVALID input with both environment types are ENVIRONMENT
            DataDeploy.DataSetExecutionRequest request = createRequest(jobTemplate.copado__ApiName__c, dataset.Id, 
                DataSetJobTemplateImpl.Source.ENVIRONMENT.toString(), DataSetJobTemplateImpl.Destination.ENVIRONMENT.toString(), 
                dev1.Id, dev2.Id,'', dataset.Id, taskDataTemplate.Id);
            
            // EXERCISE
            String exceptionMessage;
            try {
                ExecuteDataSetJobTemplateAction.execute(new List<DataDeploy.DataSetExecutionRequest> {request});
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.isTrue(exceptionMessage.contains(Label.Error_Data_Set_Configure), 'Error message should contain: +' + Label.Error_Data_Set_Configure);
        }
    } 



    private static void createData() {
        new Credential(new Environment().name('dev1').platform('SFDX').type('Production/Developer')).type('Production/Developer');
        new Credential(new Environment().name('dev2').platform('SFDX').type('Production/Developer')).type('Production/Developer').persist();
        copado__Org__c sourceOrg = getOrg('dev1');
        copado__Org__c destOrg = getOrg('dev2');
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
        .name('Job1')
        .apiName('Job1_1')
        .add(new JobStep().name('step1').type('Manual'))
        .persist();

        copado__Data_Set__c dataset = new copado__Data_Set__c(Name = 'dataset1',copado__Data_Template__c = taskDataTemplate.Id);
        insert dataset;
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

    private static copado__JobExecution__c getJobExecution(String templateApiName) {
        return [SELECT Id FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = :templateApiName LIMIT 1];
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
    private static DataDeploy.DataSetExecutionRequest createRequest(
        String jobTemplateName,
        String parentId,
        String sourceType,
        String destinationType,
        String sourceCredentialId,
        String destinationCredentialId,
        String sourceDataSetId,
        String destinationDataSetId,
        String dataTemplateId
    ) {
        DataDeploy.DataSetExecutionRequest request = new DataDeploy.DataSetExecutionRequest();
        request.jobTemplateName = jobTemplateName;
        request.parentId = parentId;
        request.sourceType = sourceType;
        request.destinationType = destinationType;
        request.sourceCredentialId = sourceCredentialId;
        request.destinationCredentialId = destinationDataSetId;
        request.sourceDataSetId = sourceDataSetId;
        request.destinationDataSetId = destinationDataSetId;
        request.dataTemplateId = dataTemplateId;
        return request;
    }


   

}