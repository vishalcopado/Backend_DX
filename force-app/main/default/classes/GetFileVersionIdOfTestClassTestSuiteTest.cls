@IsTest
private class GetFileVersionIdOfTestClassTestSuiteTest {
    private final static String RUN_SPECIFIED_TESTS = 'Run Specified Tests';
    private final static String NO_TEST_RUN = 'No Test Run';
    private final static String TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TEST_SUIT = 'ApexTestSuite';

    @TestSetup
    private static void testSetup() {
        TestUtilities.setup();
    }

    @IsTest
    private static void executeWithRunSpecifiedTestInRollbackContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'SFDX_Rollback_1', 'Rollback');
            updateJobExecutionDataJsonForRollback(RUN_SPECIFIED_TESTS);
            copado__Promotion__c promotion = getPromotion();
            createContentVersion(promotion.Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            createContentVersion(promotion.Id, getTestSuitesMetadata(), TEST_SUITES_FILE_NAME);
            Set<Id> fileVersionIds = getFileVersionIds(new Set<Id>{ promotion.Id }, new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME });

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(
                fileVersionIds.size(),
                result.size(),
                'The received number of test classes and test suites file version ids are incorrect'
            );
            for (Id fileVersionId : result) {
                Assert.isTrue(fileVersionIds.contains(fileVersionId), 'Incorrect file version id is received for a test class/test suite');
            }
        }
    }

    @IsTest
    private static void executeWithNoFileInRollbackContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'SFDX_Rollback_1', 'Rollback');
            updateJobExecutionDataJsonForRollback(RUN_SPECIFIED_TESTS);

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(0, result.size(), 'The received number of test classes and test suites file version ids should be 0');
        }
    }

    @IsTest
    private static void executeWithNoTestRunInRollbackContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(NO_TEST_RUN, 'SFDX_Rollback_1', 'Rollback');
            updateJobExecutionDataJsonForRollback(NO_TEST_RUN);
            copado__Promotion__c promotion = getPromotion();
            createContentVersion(promotion.Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            createContentVersion(promotion.Id, getTestSuitesMetadata(), TEST_SUITES_FILE_NAME);

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(0, result.size(), 'The received number of test classes and test suites file version ids should be 0');
        }
    }

    @IsTest
    private static void executeWithRunSpecifiedTestInDeployContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'sfdx_deploy_1', 'Deploy');
            updateJobExecutionDataJsonForDeploy();
            List<copado__Test__c> tests = getTests();
            createContentVersion(tests[0].Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            createContentVersion(tests[0].Id, getTestSuitesMetadata(), TEST_SUITES_FILE_NAME);
            Set<Id> fileVersionIds = getFileVersionIds(
                new Set<Id>{ tests[0].Id, tests[1].Id },
                new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME }
            );

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(2, result.size(), 'The received number of test classes and test suites file version ids are incorrect');
            Assert.areEqual(
                fileVersionIds.size(),
                result.size(),
                'The received number of test classes and test suites file version ids are incorrect'
            );
            for (Id fileVersionId : result) {
                Assert.isTrue(fileVersionIds.contains(fileVersionId), 'Incorrect file version id is received for a test class/test suite');
            }
        }
    }

    @IsTest
    private static void executeWithNoFileInDeployContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'sfdx_deploy_1', 'Deploy');
            updateJobExecutionDataJsonForDeploy();

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(0, result.size(), 'The received number of test classes and test suites file version ids should be 0');
        }
    }

    @IsTest
    private static void executeWithNoTestRunInDeployContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(NO_TEST_RUN, 'sfdx_deploy_1', 'Deploy');
            updateJobExecutionDataJsonForDeploy();
            List<copado__Test__c> tests = getTests();
            createContentVersion(tests[0].Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            createContentVersion(tests[0].Id, getTestSuitesMetadata(), TEST_SUITES_FILE_NAME);

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(0, result.size(), 'The received number of test classes and test suites file version ids should be 0');
        }
    }

    @IsTest
    private static void executeWithQualityGateInApexTestContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'SFDX Run Apex Tests_1', 'Run Apex Test');
            updateJobExecutionDataJsonForApexTest(true);
            List<copado__Test__c> tests = getTests();
            createContentVersion(tests[0].Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            createContentVersion(tests[0].Id, getTestSuitesMetadata(), TEST_SUITES_FILE_NAME);
            createContentVersion(tests[1].Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            Set<Id> fileVersionIds = getFileVersionIds(
                new Set<Id>{ tests[0].Id, tests[1].Id },
                new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME }
            );

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(3, result.size(), 'The received number of test classes and test suites file version ids are incorrect');
            Assert.areEqual(
                fileVersionIds.size(),
                result.size(),
                'The received number of test classes and test suites file version ids are incorrect'
            );
            for (Id fileVersionId : result) {
                Assert.isTrue(fileVersionIds.contains(fileVersionId), 'Incorrect file version id is received for a test class/test suite');
            }
        }
    }

    @IsTest
    private static void executeWithQualityGateAndNoFileInApexTestContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'SFDX Run Apex Tests_1', 'Run Apex Test');
            updateJobExecutionDataJsonForApexTest(true);

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(0, result.size(), 'The received number of test classes and test suites file version ids should be 0');
        }
    }

    @IsTest
    private static void executeWithoutQualityGateInApexTestContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'SFDX Run Apex Tests_1', 'Run Apex Test');
            updateJobExecutionDataJsonForApexTest(false);
            List<copado__Test__c> tests = getTests();
            createContentVersion(tests[0].Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            createContentVersion(tests[0].Id, getTestSuitesMetadata(), TEST_SUITES_FILE_NAME);
            createContentVersion(tests[1].Id, getTestClassesMetadata(), TEST_CLASSES_FILE_NAME);
            Set<Id> fileVersionIds = getFileVersionIds(
                new Set<Id>{ tests[0].Id, tests[1].Id },
                new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME }
            );

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(3, result.size(), 'The received number of test classes and test suites file version ids are incorrect');
            Assert.areEqual(
                fileVersionIds.size(),
                result.size(),
                'The received number of test classes and test suites file version ids are incorrect'
            );
            for (Id fileVersionId : result) {
                Assert.isTrue(fileVersionIds.contains(fileVersionId), 'Incorrect file version id is received for a test class/test suite');
            }
        }
    }

    @IsTest
    private static void executeWithoutQualityGateAndNoFileInApexTestContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            makeData(RUN_SPECIFIED_TESTS, 'SFDX Run Apex Tests_1', 'Run Apex Test');
            updateJobExecutionDataJsonForApexTest(false);

            // EXERCISE

            Test.startTest();
            copado__JobStep__c jobStep = getJobStep();
            String response = new GetFileVersionIdOfTestClassTestSuite().execute(jobStep.Id);
            Test.stopTest();

            // VERIFY

            List<Id> result = (List<Id>) JSON.deserialize(response, List<Id>.class);
            Assert.areEqual(0, result.size(), 'The received number of test classes and test suites file version ids should be 0');
        }
    }

    private static void makeData(String testLevel, String jobTemplateName, String jobStepName) {
        ExtensionConfiguration extensionConfiguration = new ExtensionConfiguration()
            .extensionTool(TestUtilities.getExtensionTool())
            .phase('Test')
            .activate();
        Environment sourceEnvironment = new Environment().type('Production/Developer').name('source');
        Credential sourceCredential = new Credential(sourceEnvironment);
        Environment destinationEnvironment = new Environment().type('Production/Developer').name('destination');
        Credential destinationCredential = new Credential(destinationEnvironment);
        UserStory userStory1 = new UserStory().title('US 1').status('Draft').credential(sourceCredential);
        UserStory userStory2 = new UserStory().title('US 2').status('Draft').credential(sourceCredential);
        new Promotion(
                new Project(new Pipeline(new Repository().name('Test Repo')).platform('SFDX')),
                sourceCredential,
                sourceEnvironment,
                destinationCredential,
                destinationEnvironment
            )
            .testLevel(testLevel);
        new Test_t().extensionConfiguration(extensionConfiguration).userStory(userStory1);
        new Test_t().extensionConfiguration(extensionConfiguration).userStory(userStory2);

        JobTemplate jobTemplate = new JobTemplate().name(jobTemplateName).type('Custom').apiName(jobTemplateName);

        JobStep jobStep = new JobStep(jobTemplate).name(jobStepName).type('Function');
        new JobExecution(jobTemplate, destinationEnvironment).add(jobStep).persist();

        copado__JobTemplate__c template = getJobTemplate();
        template.copado__ApiName__c = jobTemplateName;
        update template;
    }

    private static void updateJobExecutionDataJsonForRollback(String testLevel) {
        copado__JobExecution__c jobExecution = getJobExecution();
        copado__Promotion__c promotion = getPromotion();
        String dataJson = '{"testLevel":"' + testLevel + '","promotion":"' + promotion.Name + '"}';
        jobExecution.copado__Promotion__c = promotion.Id;
        jobExecution.copado__DataJson__c = dataJson;
        update jobExecution;
    }

    private static void updateJobExecutionDataJsonForDeploy() {
        copado__JobExecution__c jobExecution = getJobExecution();
        copado__Promotion__c promotion = getPromotion();
        Set<Id> userStoryIds = new Set<Id>();
        for (copado__User_Story__c userStory : getUserStories()) {
            userStoryIds.add(userStory.Id);
        }

        String dataJson = '{"userStoryIds":' + JSON.serialize(userStoryIds) + ',"promotionId":"' + promotion.Id + '"}';
        jobExecution.copado__DataJson__c = dataJson;
        update jobExecution;
    }

    private static void updateJobExecutionDataJsonForApexTest(Boolean isQualityGateContext) {
        String dataJson = '';
        copado__JobExecution__c jobExecution = getJobExecution();
        Set<Id> testIds = new Set<Id>();
        for (copado__Test__c testRecord : getTests()) {
            testIds.add(testRecord.Id);
        }

        if (isQualityGateContext) {
            new Result().type('Function').persist();
            copado__Result__c result = getResults()[0];
            dataJson = '{"testIds":' + JSON.serialize(testIds) + ', "resultIds":[], "resultId":"' + result.Id + '"}';
        } else {
            new Result().type('Function');
            new Result().type('Function').persist();
            Set<Id> resultIds = new Set<Id>();
            for (copado__Result__c result : getResults()) {
                resultIds.add(result.Id);
            }
            dataJson = '{"testIds":' + JSON.serialize(testIds) + ', "resultIds":' + JSON.serialize(resultIds) + ', "resultId":""}';
        }

        jobExecution.copado__DataJson__c = dataJson;
        update jobExecution;
    }

    private static void createContentVersion(Id recordId, List<MetaDataItem> content, String title) {
        new ContentVersion_t()
            .title(title)
            .pathOnClient(title + '.json')
            .firstPublishLocationId(recordId)
            .versionData(Blob.valueOf(JSON.serialize(content)))
            .persist();
    }

    private static List<MetaDataItem> getTestClassesMetadata() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.createMetadataItem('TestClass1', '', APEX_CLASS, true, false, 'User User', '2023-04-04T05:08:09.000+0000', null));
        result.add(TestDataFactory.createMetadataItem('TestClass2', '', APEX_CLASS, true, false, 'User User', '2023-04-04T05:08:09.000+0000', null));
        return result;
    }

    private static List<MetaDataItem> getTestSuitesMetadata() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        List<MetaDataItem> testSuite1Classes = new List<MetaDataItem>();
        testSuite1Classes.add(
            TestDataFactory.createMetadataItem('SampleTestClass1', '', APEX_CLASS, true, true, 'User User', '2023-04-04T05:08:09.000+0000', null)
        );
        testSuite1Classes.add(
            TestDataFactory.createMetadataItem('SampleTestClass2', '', APEX_CLASS, true, true, 'User User', '2023-04-04T05:08:09.000+0000', null)
        );
        List<MetaDataItem> testSuite2Classes = new List<MetaDataItem>();
        testSuite2Classes.add(
            TestDataFactory.createMetadataItem('SampleTestClass3', '', APEX_CLASS, false, false, 'User User', '2023-04-04T05:08:09.000+0000', null)
        );
        result.add(
            TestDataFactory.createMetadataItem(
                'TestSuite1',
                '',
                APEX_TEST_SUIT,
                true,
                true,
                'User User',
                '2023-04-04T05:08:09.000+0000',
                testSuite1Classes
            )
        );
        result.add(
            TestDataFactory.createMetadataItem(
                'TestSuite2',
                '',
                APEX_TEST_SUIT,
                false,
                false,
                'User User',
                '2023-04-04T05:08:09.000+0000',
                testSuite2Classes
            )
        );
        return result;
    }

    private static Set<Id> getFileVersionIds(Set<Id> linkedEntityIds, Set<String> fileTitles) {
        Set<Id> result = new Set<Id>();
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink contentDocumentLink : [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :linkedEntityIds AND ContentDocument.Title IN :fileTitles
        ]) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }
        if (!contentDocumentIds.isEmpty()) {
            for (ContentVersion contentVersion : [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]) {
                result.add(contentVersion.Id);
            }
        }
        return result;
    }

    private static List<copado__Result__c> getResults() {
        return [SELECT Id FROM copado__Result__c];
    }

    private static List<copado__Test__c> getTests() {
        return [SELECT Id FROM copado__Test__c];
    }

    private static copado__JobStep__c getJobStep() {
        return [SELECT Id, copado__JobExecution__c FROM copado__JobStep__c];
    }

    private static copado__Promotion__c getPromotion() {
        return [SELECT Id, Name FROM copado__Promotion__c];
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id FROM copado__JobExecution__c];
    }

    private static List<copado__User_Story__c> getUserStories() {
        return [SELECT Id FROM copado__User_Story__c];
    }

    private static copado__JobTemplate__c getJobTemplate() {
        return [SELECT Id FROM copado__JobTemplate__c];
    }
}