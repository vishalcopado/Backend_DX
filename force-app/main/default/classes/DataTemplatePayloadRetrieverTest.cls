@SuppressWarnings('PMD.CognitiveComplexity, PMD.NcssMethodCount')
@IsTest
private class DataTemplatePayloadRetrieverTest {
    private final static String PARENT_ACCOUNT_TEMPLATE = 'Parent Account Template';
    private final static String ACCOUNT_TEMPLATE = 'Account Template';
    private final static String CONTACT_TEMPLATE = 'Contact Template';
    private final static String TASK_TEMPLATE = 'Task Template';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getPayloadWithValidDataTemplateID() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Data_Template__c accountDataTemplate = getDataTemplate(ACCOUNT_TEMPLATE);
            copado__Data_Template__c parentAccountDataTemplate = getDataTemplate(PARENT_ACCOUNT_TEMPLATE);
            copado__Data_Template__c contactDataTemplate = getDataTemplate(CONTACT_TEMPLATE);
            copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);

            // EXERCISE
            String result = new DataTemplatePayloadRetriever().getDataTemplatePayloadById(accountDataTemplate.Id);
            DataTemplatePayload payload = (DataTemplatePayload) JSON.deserialize(result, DataTemplatePayload.class);

            // VERIFY
            Assert.areEqual(accountDataTemplate.Id, payload.main_template.templateId, 'The main template id should be ' + accountDataTemplate.Id);
            Assert.areEqual(
                true,
                payload.main_template.externalIdGeneration.generateExternalId,
                'The main template generateExternalId should be true'
            );
            Assert.areEqual(false, payload.main_template.externalIdGeneration.needsHashing, 'The main template needsHashing should be false');
            Assert.areEqual(
                false,
                payload.main_template.externalIdGeneration.fields.isEmpty(),
                'The main template external id fields should not be empty'
            );
            Assert.areEqual(3, payload.main_template.externalIdGeneration.fields.size(), 'The main template external id fields should be 3 in size');
            Assert.areEqual(
                true,
                payload.main_template.externalIdGeneration.fields.contains('Name'),
                'The main template external id fields should contain Name'
            );
            Assert.areEqual(
                true,
                payload.main_template.externalIdGeneration.fields.contains('AccountNumber'),
                'The main template external id fields should contain AccountNumber'
            );
            Assert.areEqual(
                true,
                payload.main_template.externalIdGeneration.fields.contains('Fax'),
                'The main template external id fields should contain Fax'
            );
            Assert.areEqual(3, payload.related_templates.size(), 'There should be three related templates');
            for (DataTemplatePayload.DataTemplate dataTemplate : payload.related_templates) {
                switch on dataTemplate.templateName {
                    when 'Account' {
                        Assert.areEqual(
                            parentAccountDataTemplate.Id,
                            dataTemplate.templateId,
                            'The related template id should be ' + parentAccountDataTemplate.Id
                        );
                        Assert.areEqual(
                            false,
                            dataTemplate.externalIdGeneration.generateExternalId,
                            'The data template generateExternalId should be false'
                        );
                        Assert.areEqual(false, dataTemplate.externalIdGeneration.needsHashing, 'The data template needsHashing should be false');
                        Assert.areEqual(
                            true,
                            dataTemplate.externalIdGeneration.fields.isEmpty(),
                            'The data template external id fields should be empty'
                        );
                        Assert.isFalse(
                            dataTemplate.matchOwner,
                            'The data template match owner should be false'
                        );
                        Assert.isFalse(
                            dataTemplate.matchRecordType,
                            'The data template match record type should be false'
                        );
                        Boolean ownerColumn;
                        Boolean recordTypeColumn;
                        for(DataTemplatePayload.Column column : dataTemplate.columns) {
                            ownerColumn = column.name == 'OwnerId' && column.type == 'id' && column.anonymizerType.type == 'None' && column.anonymizerType.replaceValue == null && column.anonymizerType.maintainFormat == false && column.lookUpType == 'NONE';
                            recordTypeColumn = column.name == 'RecordTypeId' && column.type == 'id' && column.anonymizerType.type == 'None' && column.anonymizerType.replaceValue == null && column.anonymizerType.maintainFormat == false && column.lookUpType == 'NONE';
                        }
                        Assert.isFalse(
                            ownerColumn,
                            'The owner column should be false'
                        );
                        Assert.isFalse(
                            recordTypeColumn,
                            'The record type column should be false'
                        );
                    }
                    when 'Contact' {
                        Assert.areEqual(
                            contactDataTemplate.Id,
                            dataTemplate.templateId,
                            'The related template id should be ' + contactDataTemplate.Id
                        );
                        Assert.areEqual(
                            false,
                            dataTemplate.externalIdGeneration.generateExternalId,
                            'The data template generateExternalId should be false'
                        );
                        Assert.areEqual(false, dataTemplate.externalIdGeneration.needsHashing, 'The data template needsHashing should be false');
                        Assert.areEqual(
                            true,
                            dataTemplate.externalIdGeneration.fields.isEmpty(),
                            'The data template external id fields should be empty'
                        );
                        Assert.isFalse(
                            dataTemplate.matchOwner,
                            'The data template match owner should be false'
                        );
                        Assert.isFalse(
                            dataTemplate.matchRecordType,
                            'The data template match record type should be false'
                        );
                        Boolean ownerColumn;
                        Boolean recordTypeColumn;
                        for(DataTemplatePayload.Column column : dataTemplate.columns) {
                            ownerColumn = column.name == 'OwnerId' && column.type == 'id' && column.anonymizerType.type == 'None' && column.anonymizerType.replaceValue == null && column.anonymizerType.maintainFormat == false && column.lookUpType == 'NONE';
                            recordTypeColumn = column.name == 'RecordTypeId' && column.type == 'id' && column.anonymizerType.type == 'None' && column.anonymizerType.replaceValue == null && column.anonymizerType.maintainFormat == false && column.lookUpType == 'NONE';
                        }
                        Assert.isFalse(
                            ownerColumn,
                            'The owner column should be false'
                        );
                        Assert.isFalse(
                            recordTypeColumn,
                            'The record type column should be false'
                        );
                    }
                    when 'Task' {
                        Assert.areEqual(taskDataTemplate.Id, dataTemplate.templateId, 'The related template id should be ' + taskDataTemplate.Id);
                        Assert.areEqual(
                            false,
                            dataTemplate.externalIdGeneration.generateExternalId,
                            'The data template generateExternalId should be false'
                        );
                        Assert.areEqual(false, dataTemplate.externalIdGeneration.needsHashing, 'The data template needsHashing should be false');
                        Assert.areEqual(
                            true,
                            dataTemplate.externalIdGeneration.fields.isEmpty(),
                            'The data template external id fields should be empty'
                        );
                        Assert.isTrue(
                            dataTemplate.matchOwner,
                            'The data template match owner should be true'
                        );
                        Assert.isTrue(
                            dataTemplate.matchRecordType,
                            'The data template match record type should be true'
                        );
                        Boolean ownerColumn;
                        Boolean recordTypeColumn;
                        for(DataTemplatePayload.Column column : dataTemplate.columns) {
                            ownerColumn = column.name == 'OwnerId' && column.type == 'id' && column.anonymizerType.type == 'None' && column.anonymizerType.replaceValue == null && column.anonymizerType.maintainFormat == false && column.lookUpType == 'NONE';
                            recordTypeColumn = column.name == 'RecordTypeId' && column.type == 'id' && column.anonymizerType.type == 'None' && column.anonymizerType.replaceValue == null && column.anonymizerType.maintainFormat == false && column.lookUpType == 'NONE';
                        }
                        Assert.isTrue(
                            ownerColumn,
                            'The owner column should be true'
                        );
                        Assert.isTrue(
                            recordTypeColumn,
                            'The record type column should be true'
                        );
                    }
                }
            }
        }
    }


    @IsTest
    private static void getPayloadWithInvalidTemplateId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id randomId = fflib_IdGenerator.generate(SObjectType.copado__Data_Template__c.getKeyPrefix());
            String exceptionMessage;

            // EXERCISE
            try {
                new DataTemplatePayloadRetriever().getDataTemplatePayloadById(randomId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            
            // VERIFY
            Assert.isTrue(
                exceptionMessage.contains(Label.Data_Template_Missing),
                'The exception message should be ' + Label.Data_Template_Missing
            );
        }
    }

    

    private static void createData() {
        new DataTemplate().name(PARENT_ACCOUNT_TEMPLATE).activate();
        new DataTemplate().name(ACCOUNT_TEMPLATE).activate();
        new DataTemplate().name(CONTACT_TEMPLATE).activate();
        new DataTemplate().name(TASK_TEMPLATE).activate();
        new Credential(new Environment().name('dev').platform('SFDX').type('Production/Developer')).type('Production/Developer').persist();

        copado__Data_Template__c parentAccountDataTemplate = getDataTemplate(PARENT_ACCOUNT_TEMPLATE);
        copado__Data_Template__c accountDataTemplate = getDataTemplate(ACCOUNT_TEMPLATE);
        copado__Data_Template__c contactDataTemplate = getDataTemplate(CONTACT_TEMPLATE);
        copado__Data_Template__c taskDataTemplate = getDataTemplate(TASK_TEMPLATE);
        copado__Org__c sourceOrg = getOrganization();

        JobStepDataDeployController.DataTemplate template = new JobStepDataDeployController.DataTemplate(
            accountDataTemplate.Id,
            ACCOUNT_TEMPLATE,
            sourceOrg.Id,
            10.0
        );

        List<Copado.CopadoFunctions.FunctionParameter> functionParameters = new List<Copado.CopadoFunctions.FunctionParameter>();
        Copado.CopadoFunctions.FunctionParameter functionParameter = new Copado.CopadoFunctions.FunctionParameter(
            GetDataTemplatePayload.DATA_TEMPLATE,
            JSON.serialize(template)
        );
        functionParameters.add(functionParameter);

        GetDataTemplatePayload.StepConfig stepConfig = new GetDataTemplatePayload.StepConfig();
        stepConfig.functionName = 'SFDX Data Deploy';
        stepConfig.parameters = functionParameters;

        JobTemplate jobTemplate = new JobTemplate().name('SFDX Data Deploy').type('Custom');
        new JobStep(jobTemplate).name('SFDX Data Deploy').type('Function').configJson(JSON.serialize(stepConfig));
        new Attachment_t()
            .name(DataTemplateDetail.ATTACHMENT_NAME)
            .body(Blob.valueOf(getAccountDataTemplateDetail(parentAccountDataTemplate, accountDataTemplate, contactDataTemplate, sourceOrg)))
            .parent(accountDataTemplate.Id);
        new Attachment_t()
            .name(DataTemplateDetail.ATTACHMENT_NAME)
            .body(Blob.valueOf(getParentAccountDataTemplateDetail(parentAccountDataTemplate, taskDataTemplate, sourceOrg)))
            .parent(parentAccountDataTemplate.Id);
        new Attachment_t()
            .name(DataTemplateDetail.ATTACHMENT_NAME)
            .body(Blob.valueOf(getContactDataTemplateDetail(contactDataTemplate, accountDataTemplate, sourceOrg, false)))
            .parent(contactDataTemplate.Id);
        new Attachment_t()
            .name(DataTemplateDetail.ATTACHMENT_NAME)
            .body(Blob.valueOf(getTaskDataTemplateDetail(taskDataTemplate, sourceOrg)))
            .parent(taskDataTemplate.Id);
        new RecordMatchingFormula()
            .name('Test')
            .configSourceOrg(sourceOrg.Id)
            .object('Account')
            .field1('Name')
            .field2('AccountNumber')
            .field3('Fax')
            .persist();
    }


    private static copado__Data_Template__c getDataTemplate(String name) {
        return [SELECT Id FROM copado__Data_Template__c WHERE Name = :name];
    }

    private static copado__Org__c getOrganization() {
        return [SELECT Id FROM copado__Org__c LIMIT 1];
    }

    private static copado__JobStep__c getJobStep() {
        return [SELECT Id FROM copado__JobStep__c];
    }

    private static Attachment getAttachment(Id parentId) {
        return [SELECT Id FROM Attachment WHERE ParentId = :parentId];
    }


    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String getAccountDataTemplateDetail(
        copado__Data_Template__c parentAccountDataTemplate,
        copado__Data_Template__c accountDataTemplate,
        copado__Data_Template__c contactDataTemplate,
        copado__Org__c sourceOrg
    ) {
        return '{' +
            '"selectableFieldsMap": {' +
            '"Ext_Id_2__c": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Ext_Id_2__c",' +
            '"label": "Ext Id 2",' +
            '"isSelected": false,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": true,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Auto Generate For Empty Values": "recordMatching"' +
            '}' +
            '},' +
            '"YearStarted": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "YearStarted",' +
            '"label": "Year Started",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Scramble Value": "scramble",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"AccountNumber": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "AccountNumber",' +
            '"label": "Account Number",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "scramble",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Scramble Value": "scramble",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Fax": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "1234",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Fax",' +
            '"label": "Account Fax",' +
            '"isSelected": true,' +
            '"fieldType": "phone",' +
            '"fieldContentUpdate": "replace",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Phone": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Phone",' +
            '"label": "Account Phone",' +
            '"isSelected": true,' +
            '"fieldType": "phone",' +
            '"fieldContentUpdate": "scrambleWithFormat",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Type": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Type",' +
            '"label": "Account Type",' +
            '"isSelected": false,' +
            '"fieldType": "picklist",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Name": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Name",' +
            '"label": "Account Name",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Scramble Value": "scramble",' +
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
            '"label": "Account ID",' +
            '"isSelected": true,' +
            '"fieldType": "id",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Ext_Id__c": {' +
            '"useAsExternalId": true,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Ext_Id__c",' +
            '"label": "Ext Id",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "recordMatching",' +
            '"externalId": true,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Auto Generate For Empty Values": "recordMatching"' +
            '}' +
            '}' +
            '},' +
            '"selectableChildRelationsMap": {' +
            '"AccountId-WorkPlanSelectionRules": {' +
            '"relationshipName": "WorkPlanSelectionRules",' +
            '"objectApiNameMap": {' +
            '"WorkPlanSelectionRule": "Work Plan Selection Rule"' +
            '},' +
            '"isSelected": false,' +
            '"field": "AccountId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": null,' +
            '"childSObject": "WorkPlanSelectionRule"' +
            '},' +
            '"AccountId-Contacts": {' +
            '"relationshipName": "Contacts",' +
            '"objectApiNameMap": {' +
            '"Contact": "Contact"' +
            '},' +
            '"isSelected": true,' +
            '"field": "AccountId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": "' +
            CONTACT_TEMPLATE +
            '",' +
            '"childSObject": "Contact"' +
            '}' +
            '},' +
            '"queryFilterList": [],' +
            '"parentObjectsReferenceList": [' +
            '{' +
            '"templateId": "' +
            parentAccountDataTemplate.Id +
            '",' +
            '"relationName": "ParentId",' +
            '"childSObject": null' +
            '}' +
            '],' +
            '"dataTemplate": {' +
            '"templateSourceOrg": "' +
            sourceOrg.Id +
            '",' +
            '"templateSelectedAttachmentType": "attachments",' +
            '"templateQueryLimit": null,' +
            '"templateName": "' +
            ACCOUNT_TEMPLATE +
            '",' +
            '"templateMatchRecordTypes": false,' +
            '"templateMatchOwners": false,' +
            '"templateMainObject": "Account",' +
            '"templateId": "' +
            accountDataTemplate.Id +
            '",' +
            '"templateFilterLogic": "",' +
            '"templateDescription": null,' +
            '"templateContinueOnError": "Continue deployment until blocker issue",' +
            '"templateBatchSize": 200,' +
            '"templateAttachmentOption": "Insert Attachments",' +
            '"templateActive": false' +
            '},' +
            '"childrenObjectsReferenceList": [' +
            '{' +
            '"templateId": "' +
            contactDataTemplate.Id +
            '",' +
            '"relationName": "Contacts",' +
            '"childSObject": "Contact"' +
            '}' +
            ']' +
            '}';
    }

    private static String getParentAccountDataTemplateDetail(
        copado__Data_Template__c parentAccountDataTemplate,
        copado__Data_Template__c taskDataTemplate,
        copado__Org__c sourceOrg
    ) {
        return '{' +
            '"selectableFieldsMap": {' +
            '"Ext_Id_2__c": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Ext_Id_2__c",' +
            '"label": "Ext Id 2",' +
            '"isSelected": false,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": true,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Auto Generate For Empty Values": "recordMatching"' +
            '}' +
            '},' +
            '"YearStarted": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "YearStarted",' +
            '"label": "Year Started",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Scramble Value": "scramble",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"AccountNumber": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "AccountNumber",' +
            '"label": "Account Number",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "scramble",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Scramble Value": "scramble",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Fax": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "1234",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Fax",' +
            '"label": "Account Fax",' +
            '"isSelected": true,' +
            '"fieldType": "phone",' +
            '"fieldContentUpdate": "replace",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Phone": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Phone",' +
            '"label": "Account Phone",' +
            '"isSelected": true,' +
            '"fieldType": "phone",' +
            '"fieldContentUpdate": "scrambleWithFormat",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Type": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Type",' +
            '"label": "Account Type",' +
            '"isSelected": false,' +
            '"fieldType": "picklist",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Name": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Name",' +
            '"label": "Account Name",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Scramble With Format": "scrambleWithFormat",' +
            '"Scramble Value": "scramble",' +
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
            '"label": "Account ID",' +
            '"isSelected": true,' +
            '"fieldType": "id",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"Ext_Id__c": {' +
            '"useAsExternalId": true,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": "",' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Ext_Id__c",' +
            '"label": "Ext Id",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "recordMatching",' +
            '"externalId": true,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Auto Generate For Empty Values": "recordMatching"' +
            '}' +
            '}' +
            '},' +
            '"selectableChildRelationsMap": {' +
            '"AccountId-WorkPlanSelectionRules": {' +
            '"relationshipName": "WorkPlanSelectionRules",' +
            '"objectApiNameMap": {' +
            '"WorkPlanSelectionRule": "Work Plan Selection Rule"' +
            '},' +
            '"isSelected": false,' +
            '"field": "AccountId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": null,' +
            '"childSObject": "WorkPlanSelectionRule"' +
            '},' +
            '"AccountId-Contacts": {' +
            '"relationshipName": "Contacts",' +
            '"objectApiNameMap": {' +
            '"Contact": "Contact"' +
            '},' +
            '"isSelected": false,' +
            '"field": "AccountId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": "' +
            CONTACT_TEMPLATE +
            '",' +
            '"childSObject": "Contact"' +
            '},' +
            '"WhatId-Tasks": {' +
            '"relationshipName": "Tasks",' +
            '"objectApiNameMap": {' +
            '"Task": "Task"' +
            '},' +
            '"isSelected": true,' +
            '"field": "WhatId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": "' +
            TASK_TEMPLATE +
            '",' +
            '"childSObject": "Task"' +
            '}' +
            '},' +
            '"queryFilterList": [],' +
            '"parentObjectsReferenceList": [],' +
            '"dataTemplate": {' +
            '"templateSourceOrg": "' +
            sourceOrg.Id +
            '",' +
            '"templateSelectedAttachmentType": "attachments",' +
            '"templateQueryLimit": null,' +
            '"templateName": "' +
            PARENT_ACCOUNT_TEMPLATE +
            '",' +
            '"templateMatchRecordTypes": false,' +
            '"templateMatchOwners": false,' +
            '"templateMainObject": "Account",' +
            '"templateId": "' +
            parentAccountDataTemplate.Id +
            '",' +
            '"templateFilterLogic": "",' +
            '"templateDescription": null,' +
            '"templateContinueOnError": "Continue deployment until blocker issue",' +
            '"templateBatchSize": 200,' +
            '"templateAttachmentOption": "Insert Attachments",' +
            '"templateActive": false' +
            '},' +
            '"childrenObjectsReferenceList": [' +
            '{' +
            '"templateId": "' +
            taskDataTemplate.Id +
            '",' +
            '"relationName": "Tasks",' +
            '"childSObject": "Task"' +
            '}' +
            ']' +
            '}';
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String getContactDataTemplateDetail(
        copado__Data_Template__c contactDataTemplate,
        copado__Data_Template__c accountDataTemplate,
        copado__Org__c sourceOrg,
        Boolean setParentDataTemplate
    ) {
        return '{' +
            '"selectableFieldsMap": {' +
            '"Id": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "Id",' +
            '"label": "Contact ID",' +
            '"isSelected": true,' +
            '"fieldType": "id",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"AccountId": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {' +
            '"Account": "Account"' +
            '},' +
            '"name": "AccountId",' +
            '"label": "Account ID",' +
            '"isSelected": false,' +
            '"fieldType": "reference",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace"' +
            '}' +
            '},' +
            '"LastName": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "LastName",' +
            '"label": "Last Name",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace",' +
            '"Scramble Value": "scramble",' +
            '"Scramble With Format": "scrambleWithFormat"' +
            '}' +
            '},' +
            '"FirstName": {' +
            '"useAsExternalId": false,' +
            '"replaceValueNumber": null,' +
            '"replaceValueDatetime": null,' +
            '"replaceValueDate": null,' +
            '"replaceValue": null,' +
            '"parentObjectApiNameMap": {},' +
            '"name": "FirstName",' +
            '"label": "First Name",' +
            '"isSelected": true,' +
            '"fieldType": "string",' +
            '"fieldContentUpdate": "none",' +
            '"externalId": false,' +
            '"deploymentTemplateNameMap": null,' +
            '"deploymentTemplate": null,' +
            '"contentValueUpdateValues": {' +
            '"Replace Value": "replace",' +
            '"Scramble Value": "scramble",' +
            '"Scramble With Format": "scrambleWithFormat"' +
            '}' +
            '}' +
            '},' +
            '"selectableChildRelationsMap": {' +
            '"ParentId-Attachments": {' +
            '"relationshipName": "Attachments",' +
            '"objectApiNameMap": {' +
            '"Attachment": "Attachment"' +
            '},' +
            '"isSelected": false,' +
            '"field": "ParentId",' +
            '"deploymentTemplateNameMap": {},' +
            '"deploymentTemplate": null,' +
            '"childSObject": "Attachment"' +
            '}' +
            '},' +
            '"queryFilterList": [],' +
            '"parentObjectsReferenceList": [' +
            (setParentDataTemplate
                ? '{' + '"templateId": "' + accountDataTemplate.Id + '",' + '"relationName": "AccountId",' + '"childSObject": null' + '}'
                : '') +
            '],' +
            '"dataTemplate": {' +
            '"templateSourceOrg": "' +
            sourceOrg.Id +
            '",' +
            '"templateSelectedAttachmentType": "files",' +
            '"templateQueryLimit": null,' +
            '"templateName": "' +
            CONTACT_TEMPLATE +
            '",' +
            '"templateMatchRecordTypes": false,' +
            '"templateMatchOwners": false,' +
            '"templateMainObject": "Contact",' +
            '"templateId": "' +
            contactDataTemplate.Id +
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