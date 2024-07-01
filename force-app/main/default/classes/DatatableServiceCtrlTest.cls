@IsTest
private with sharing class DatatableServiceCtrlTest {
    private static final String STANDARD_USER = 'test_user@myorg.com';

    @TestSetup
    private static void makeData() {
        Map<String, RecordTypeInfo> deploymentRecordTypes = SObjectType.copado__Deployment__c.getRecordTypeInfosByDeveloperName();
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(standardUser.Id);
            new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(
                    copado__Deployment__c.SObjectType,
                    copado__Deployment__c.RecordTypeId,
                    deploymentRecordTypes.get('Advanced_multi_step').getRecordTypeId()
                )
                .setDataSize(copado__Deployment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(copado__Step__c.SObjectType, copado__Step__c.copado__Type__c, 'Salesforce Flow')
                .setFieldValue(
                    copado__Step__c.SObjectType,
                    copado__Step__c.copado__DataJson__c,
                    '{"flowApiName": "TestFlow","type":"wait","flowParameters":[]}'
                )
                .setDataSize(copado__Step__c.SObjectType, 10)
                .setSObjectRelation(
                    copado__Step__c.SObjectType,
                    copado__Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ copado__Step__c.copado__Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    private static void getTableInfo() {
        // Setup
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(standardUser.Id);

        System.runAs(standardUser) {
            copado__Deployment__c deployment = [SELECT Id FROM copado__Deployment__c];

            String namespace = 'copado__';
            String pageType = 'RecordPage';
            String objectName = namespace + 'Deployment__c';
            String childObjectLabel = 'Step';
            String desiredFieldSet = 'copado__Deployment_Steps';

            Map<String, String> availableChildObjects = new Map<String, String>();
            RelatedListVisualPicklist picklistHandler = new RelatedListVisualPicklist(pageType, objectName);
            System.assertEquals(null, picklistHandler.getDefaultValue(), 'There should not be a default value');
            VisualEditor.DynamicPickListRows relatedObjects = picklistHandler.getValues();
            List<VisualEditor.DataRow> rows = relatedObjects.getDataRows();
            for (VisualEditor.DataRow row : rows) {
                availableChildObjects.put(row.getLabel(), String.valueOf(row.getValue()));
            }
            System.assertEquals('copado__Step__c', availableChildObjects.get(childObjectLabel), 'Step__c should be available');

            DatatableColumnsConfiguration columnsConfiguration = new DatatableColumnsConfiguration();
            columnsConfiguration.objectApiName = availableChildObjects.get(childObjectLabel);
            columnsConfiguration.fieldSetName = desiredFieldSet;
            columnsConfiguration.hideDefaultColumnsActions = true;
            columnsConfiguration.sortable = true;
            columnsConfiguration.editable = true;
            columnsConfiguration.searchable = true;

            DatatableQueryConfiguration queryConfig = new DatatableQueryConfiguration();
            queryConfig.selectFieldSet = desiredFieldSet;
            queryConfig.fromObject = availableChildObjects.get(childObjectLabel);
            queryConfig.relationshipField = objectName;
            queryConfig.parentId = deployment.Id;
            queryConfig.orderBy = 'copado__Order__c';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            // Exercise
            Test.startTest();

            List<DatatableServiceColumnConfig> columnsConfig = DatatableServiceCtrl.fetchColumnsConfiguration(columnsConfiguration);

            List<SObject> data = DatatableServiceCtrl.fetchData(queryConfig);

            // If relationshipField is not provided, it tries to find the default
            queryConfig.relationshipField = null;
            List<SObject> data2 = DatatableServiceCtrl.fetchData(queryConfig);

            Test.stopTest();

            // Verify
            System.assertEquals(2, columnsConfig.size(), 'columnsConfig size should match the number of fields in the field set');
            System.assertEquals(10, data.size(), 'There should be 10 steps related to the deployment');
            System.assertEquals(10, data2.size(), 'There should be 10 steps related to the deployment');
        }
    }

    @IsTest
    private static void fetchDataException() {
        // Setup
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(standardUser.Id);

        System.runAs(standardUser) {
            copado__Deployment__c deployment = [SELECT Id FROM copado__Deployment__c];

            String namespace = 'copado__';
            String objectName = namespace + 'Deployment__c';
            String desiredFieldSet = 'Deployment_Steps';

            DatatableQueryConfiguration queryConfig = new DatatableQueryConfiguration();
            queryConfig.selectFieldSet = desiredFieldSet;
            queryConfig.fromObject = namespace + 'Step__c';
            queryConfig.relationshipField = objectName;
            queryConfig.parentId = deployment.Id;
            queryConfig.orderBy = 'Order__c';
            queryConfig.recordsLimit = 20;
            queryConfig.recordsOffset = 0;

            // Exercise
            String ex;
            try {
                queryConfig.fromObject = 'Acc';
                DatatableServiceCtrl.fetchData(queryConfig);
                System.assert(false, 'fetchData should have thrown an exception due to invalid object api name');
            } catch (Exception e) {
                ex = e.getMessage();
            }

            // Verify
            System.assert(String.isNotBlank(ex), 'fetchData should have thrown an exception due to invalid object api name');
        }
    }

    @IsTest
    private static void updateRecords() {
        // Setup
        Account acc = new Account(Name = 'test1');
        insert acc;

        // Exercise
        acc.Name = 'test2';
        DatatableServiceCtrl.updateRecords(new List<SObject>{ acc });

        // Verify
        System.assertEquals('test2', [SELECT Name FROM Account WHERE Id = :acc.Id].Name, 'Account name should have been updated');
    }
}