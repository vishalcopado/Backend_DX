@IsTest
public with sharing class JobStepDataSetTest {
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
    private static void testLoadAllDataSetsWithSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE
            Map<Id, JobStepDataSet.DataSet> result = JobStepDataSet.loadRelatedDataSets();
            JobStepDataSet.DataSet dataset1 = result.values()[0];
            JobStepDataSet.DataSet dataset2 = result.values()[1];

            // VERIFY
            Assert.areEqual(2, result.size(), 'The number of data set returned should be 2');
            Assert.areEqual('dataset1', dataset1.name, 'Data set 1 name is incorrect');
            Assert.areEqual('dataset2', dataset2.name, 'Data set 2 name is incorrect');

        }

    }

    @IsTest
    private static void testGetCurrentEnvironmentId() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // EXERCISE
            String envId = JobStepDataSet.getCurrentEnvironmentId();

            // VERIFY
            copado__Environment__c env = getEnvironment(Id.valueOf(envId));
            Assert.areEqual('currentDev', env.Name, 'Environment name must be currentDev');

        }

    }

    private static void createData() {
        new Credential(new Environment().name('currentDev').platform('SFDX').type('Production/Developer')).type('Production/Developer').persist();
        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        copado__Org__c currentDev = getOrg('currentDev');
        currentDev.copado__SFDC_Org_ID__c = sfdcOrgId;
        update currentDev;

        copado__Data_Set__c dataset = new copado__Data_Set__c(Name = 'dataset1');
        insert dataset;
        copado__Data_Set__c dataset2 = new copado__Data_Set__c(Name = 'dataset2');
        insert dataset2;

    }

    private static copado__Org__c getOrg(String name) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :name LIMIT 1];
    }


    private static copado__Environment__c getEnvironment(Id id) {
        return [SELECT Id, Name, copado__Org_ID__c FROM copado__Environment__c WHERE Id = :id LIMIT 1];
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