@IsTest
private with sharing class AddApexTestsAcceptanceCriteriaCtrlTest {
    @IsTest
    private static void executeUpdateExtensionConfig() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String body = '{"testsRan": {"operator": "Equals or Greater than","input": "1","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "75","type": "Percent","errorDescription": "test errorDescription"}}';
            copado__ExtensionConfiguration__c extensionConfiguration = [SELECT id FROM copado__ExtensionConfiguration__c];

            // EXERCISE
            AddApexTestsAcceptanceCriteriaCtrl.storeAcceptanceCriteria(body, extensionConfiguration.id);

            // VERIFY
            System.assertEquals(
                body,
                [SELECT copado__AcceptanceCriteria__c FROM copado__ExtensionConfiguration__c].copado__AcceptanceCriteria__c,
                'Acceptance Criteria should be updated.'
            );
        }
    }

    @IsTest
    private static void executeUpdateTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String body = '{"testsRan": {"operator": "Equals or Greater than","input": "1","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "75","type": "Percent","errorDescription": "test errorDescription"}}';
            copado__Test__c test = [SELECT id FROM copado__Test__c];

            // EXERCISE
            AddApexTestsAcceptanceCriteriaCtrl.storeAcceptanceCriteria(body, test.id);

            // VERIFY
            System.assertEquals(
                body,
                [SELECT copado__AcceptanceCriteria__c FROM copado__Test__c].copado__AcceptanceCriteria__c,
                'Acceptance Criteria should be updated.'
            );
        }
    }

    @IsTest
    private static void fetchExtConfigAcceptanceCriteria() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__ExtensionConfiguration__c extensionConfiguration = [
                SELECT id, copado__AcceptanceCriteria__c
                FROM copado__ExtensionConfiguration__c
            ];

            // EXERCISE
            AddApexTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(extensionConfiguration.id);

            // VERIFY
            System.assertEquals(
                extensionConfiguration.copado__AcceptanceCriteria__c,
                '{"testsRan": {"operator": "Equals or Greater than","input": "2","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "85","type": "Percent","errorDescription": "test errorDescription"}}',
                'Acceptance Criteria should be the same.'
            );
        }
    }

    @IsTest
    private static void fetchTestAcceptanceCriteria() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Test__c test = [SELECT Id, copado__AcceptanceCriteria__c FROM copado__Test__c];

            // EXERCISE
            AddApexTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(test.id);

            // VERIFY
            System.assertEquals(
                test.copado__AcceptanceCriteria__c,
                '{"testsRan": {"operator": "Equals or Greater than","input": "2","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "85","type": "Percent","errorDescription": "test errorDescription"}}',
                'Acceptance Criteria should be the same.'
            );
        }
    }

    @IsTest
    private static void fetchQualityGateRuleConditionAcceptanceCriteria() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Quality_Gate_Rule_Condition__c condition = getQualityGateRuleCondition();
            QualityGateRuleConditionsSelector.setMock(new List<copado__Quality_Gate_Rule_Condition__c>{ condition });

            // EXERCISE
            String acceptanceCriteria = AddApexTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(condition.id);

            // VERIFY
            System.assertEquals(condition.copado__AcceptanceCriteria__c, acceptanceCriteria, 'Acceptance Criteria should be the same.');
        }
    }

    /*
        This test has only code coverage purposes. In order to perform a correct test, a qualit gate rule needs to be created. 
        This is not possible because the "Tool__c" field is a Mandatory Field in a restricted picklist. And that picklist is empty in packaging context.
    */
    @IsTest
    private static void fetchJobStepAcceptanceCriteria() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__JobExecution__c execution = new copado__JobExecution__c();
            insert execution;
            copado__JobStep__c step = new copado__JobStep__c(copado__JobExecution__c = execution.Id, copado__Type__c = 'Test');
            insert step;

            // EXERCISE
            String acceptanceCriteria = AddApexTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(step.id);

            // VERIFY
            System.assertEquals('{}', acceptanceCriteria, 'Acceptance Criteria should be the same.');
        }
    }

    @IsTest
    private static void fetchTestAcceptanceCriteriaWithNoRecordID() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE
            String acceptanceCriteria = AddApexTestsAcceptanceCriteriaCtrl.fetchAcceptanceCriteria(null);

            // VERIFY
            System.assertEquals('{}', acceptanceCriteria, 'Acceptance criteria should be {}.');
        }
    }

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private static void createData() {
        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );
        copado__ExtensionConfiguration__c extensionConfiguration = new copado__ExtensionConfiguration__c(
            copado__Active__c = true,
            copado__ExtensionTool__c = !picklistValues.isEmpty() ? picklistValues[0] : '',
            copado__ExtensionApplication__c = 'Test',
            copado__AcceptanceCriteria__c = '{"testsRan": {"operator": "Equals or Greater than","input": "2","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "85","type": "Percent","errorDescription": "test errorDescription"}}'
        );
        insert extensionConfiguration;

        copado__User_Story__c userStory = new copado__User_Story__c(copado__Minimum_Apex_Code_Coverage__c = 75);
        insert userStory;

        copado__Test__c testItem = new copado__Test__c(
            copado__ExtensionConfiguration__c = extensionConfiguration.Id,
            copado__User_Story__c = userStory.Id,
            copado__AcceptanceCriteria__c = '{"testsRan": {"operator": "Equals or Greater than","input": "2","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "85","type": "Percent","errorDescription": "test errorDescription"}}'
        );
        insert testItem;
    }

    private static copado__Quality_Gate_Rule_Condition__c getQualityGateRuleCondition() {
        copado__Quality_Gate_Rule_Condition__c condition = new copado__Quality_Gate_Rule_Condition__c(
            copado__Extension_Configuration__c = getExtensionConfigurationId(),
            copado__Platform__c = 'Other',
            copado__AcceptanceCriteria__c = '{"testsRan": {"operator": "Equals or Greater than","input": "2","type": "Integer","errorDescription": "Test errorDescription"},"testRunCoverage": {"operator": "Equals or Greater than","input": "85","type": "Percent","errorDescription": "test errorDescription"}}'
        );

        return condition;
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM copado__ExtensionConfiguration__c LIMIT 1].id;
    }
}