@IsTest
private class CommitDataTest {
    private static final String ATTACHMENT_NAME = 'Template Detail';
    private final static String TASK_TEMPLATE = 'Task Template';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void fetchDataTemplateConfigurationTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Id dataTemplateId = getDataTemplate(TASK_TEMPLATE).Id;

            // EXERCISE
            Test.startTest();
            CommitData.DataTemplateConfiguration configuration = CommitData.fetchDataTemplateConfiguration(dataTemplateId);
            Test.stopTest();

            // VERIFY
            Assert.areEqual(0, configuration.totalRelatedObjects, 'There is no related object for task template');
        }
    }

    @IsTest
    private static void fetchMCDDEnabledStatusTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Id userStoryId = getUserStory().Id;
            Pipeline pipeLine = getPipelineObj();
            createSystemProperties(pipeLine, 'true', 'mcdd_disabled').persist();

            // EXERCISE
            Test.startTest();
            Boolean result = CommitData.fetchMCDDEnabledStatus(userStoryId);
            Test.stopTest();

            // VERIFY
            Assert.isFalse(result, 'Nextgen DD should be disabled');
        }
    }

    @IsTest
    private static void validateOrgCredentialIdTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Id credentialId = getOrg('dev1').Id;

            // EXERCISE
            Test.startTest();
            Boolean result = CommitData.validateOrgCredential(credentialId);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(result, 'Orgcredential must be validated');
        }
    }

    @IsTest
    private static void executeTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            DataFilter customFilter = new DataFilter();
            customFilter.order = 1;
            customFilter.fieldLabel = 'Reminder Date/Time';
            customFilter.fieldName = 'ReminderDateTime';
            customFilter.fieldType = 'datetime';
            customFilter.operatorCode = 'e';
            customFilter.value = 'TODAY';

            CommitDataPayload payload = new CommitDataPayload();
            payload.commitMessage = 'Test commit message';
            payload.dataTemplateId = getDataTemplate(TASK_TEMPLATE).Id;
            payload.filterLogic = '1';
            payload.filters = new List<DataFilter>();
            payload.dataSetId = null;
            payload.userStoryId = getUserStory().Id;

            // EXERCISE
            Test.startTest();
            Id userStoryDataCommitId = CommitData.execute(payload);
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(userStoryDataCommitId, 'user Story Data Commit Id is blank');
        }
    }

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Credential source = new Credential();

            new Pipeline()
                .mainBranch('main')
                .platform('SFDX')
                .add(
                    new PipelineConnection()
                        .sourceEnvironment(new Environment().platform('SFDX').add(source).name('Dev1'))
                        .destinationEnvironment(new Environment().platform('SFDX').name('Stage').add(new Credential()))
                        .branch('dev1')
                )
                .add(
                    new PipelineConnection()
                        .sourceEnvironment(new Environment().platform('SFDX').add(new Credential()).name('Dev2'))
                        .destinationEnvironment(new Environment().platform('SFDX').name('Stage').add(new Credential()))
                        .branch('dev2')
                )
                .add(new Project().add(new UserStory().credential(source)))
                .persist();

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
                .parent(taskDataTemplate.Id)
                .persist();
            new JobTemplate()
                .name('SFDX Generate Data Set')
                .apiName('SFDX_Generate_Data_Set_1')
                .add(new JobStep().name('step1').type('Manual'))
                .persist();
        }
    }

    private static SystemProperty createSystemProperties(Pipeline pipeline, String value, String apiName) {
        return new SystemProperty(pipeline).apiName(apiName).value(value);
    }

    private static Pipeline getPipelineObj() {
        return new Pipeline().recordId(getPipeline().Id);
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [
            SELECT Id, copado__Git_Repository__r.Name
            FROM copado__Deployment_Flow__c
            LIMIT 1
        ];
    }

    private static copado__User_Story__c getUserStory() {
        return [SELECT copado__Org_Credential__c, copado__Latest_Commit_Date__c FROM copado__User_Story__c][0];
    }

    private static copado__Data_Template__c getDataTemplate(String name) {
        return [SELECT Id FROM copado__Data_Template__c WHERE Name = :name];
    }

    private static copado__Org__c getOrg(String name) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :name LIMIT 1];
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
}