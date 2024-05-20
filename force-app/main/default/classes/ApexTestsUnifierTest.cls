@IsTest
private with sharing class ApexTestsUnifierTest {
    private final static String APEX_TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String APEX_TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TEST_SUIT = 'ApexTestSuite';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void unifyTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            List<copado__Test__c> testToUnify = getCopadoTests();
            copado__User_Story__c destinationUS = new copado__User_Story__c(copado__User_Story_Title__c = 'US3');
            insert destinationUS;
            mockUserStoryBundle(destinationUS);

            // EXCERCISE

            Test.startTest();
            ApexTestsUnifier unifier = new ApexTestsUnifier();
            List<copado__Test__c> unifiedTests = unifier.unifyTests(testToUnify);
            for (copado__Test__c test : unifiedTests) {
                test.copado__User_Story__c = destinationUS.Id;
            }
            insert unifiedTests;
            unifier.additionalLogicAfterUnify(unifiedTests);
            Test.stopTest();

            // VERIFY

            List<copado__Test__c> testsForNewUs = [SELECT Id FROM copado__Test__c WHERE copado__User_Story__c = :destinationUS.Id];
            Assert.areEqual(1, testsForNewUs.size(), 'There should be a unified test for the new user story');

            List<ContentDocumentLink> files = new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(
                    new Set<Id>{ testsForNewUs[0].Id },
                    new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME }
                );
            Assert.areEqual(2, files.size(), 'There should be two files attached to the test');
            copado__User_Story__c bundleUserStory = [
                SELECT copado__Promotion_Test_Level__c
                FROM copado__User_Story__c
                WHERE Id = :destinationUS.Id
                LIMIT 1
            ];
            Assert.areEqual(
                'RunLocalTests',
                bundleUserStory.copado__Promotion_Test_Level__c,
                'Most restrictive test level should be updated for user story bundle'
            );
        }
    }

    private static List<copado__Test__c> getCopadoTests() {
        return [
            SELECT
                Id,
                Name,
                OwnerId,
                copado__Parent_Id__c,
                copado__Priority__c,
                copado__Promotion__c,
                copado__ReadyToRun__c,
                copado__Status__c,
                copado__ExtensionConfiguration__c,
                copado__Test_Tool__c,
                copado__User_Story__c,
                copado__AcceptanceCriteria__c,
                copado__Application__c,
                copado__Configuration__c,
                copado__Feature__c,
                copado__HasExtraConfiguration__c,
                copado__LatestJobExecution__c
            FROM copado__Test__c
            WHERE copado__User_Story__c != NULL
        ];
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private static void makeData() {
        List<copado__User_Story__c> stories = new List<copado__User_Story__c>();
        stories.add(new copado__User_Story__c(copado__User_Story_Title__c = 'US1', copado__Promotion_Test_Level__c = 'RunSpecifiedTests'));
        stories.add(new copado__User_Story__c(copado__User_Story_Title__c = 'US2', copado__Promotion_Test_Level__c = 'RunLocalTests'));
        insert stories;

        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );

        copado__TestTool__mdt testTool = new copado__TestTool__mdt(
            MasterLabel = !picklistValues.isEmpty() ? picklistValues[0] : '',
            copado__TestType__c = 'Mock Type'
        );

        copado__ExtensionConfiguration__c extensionConfig = new copado__ExtensionConfiguration__c(
            copado__ExtensionTool__c = testTool.MasterLabel,
            copado__ExtensionApplication__c = 'Test',
            copado__Active__c = true
        );
        insert extensionConfig;

        List<copado__Test__c> tests = new List<copado__Test__c>();
        tests.add(new copado__Test__c(Name = 'Test1', copado__ExtensionConfiguration__c = extensionConfig.Id, copado__User_Story__c = stories[0].id));
        tests.add(new copado__Test__c(Name = 'Test2', copado__ExtensionConfiguration__c = extensionConfig.Id, copado__User_Story__c = stories[1].id));
        insert tests;

        new ContentVersion_t()
            .title(APEX_TEST_SUITES_FILE_NAME)
            .pathOnClient(APEX_TEST_SUITES_FILE_NAME + '.json')
            .firstPublishLocationId(tests[0].Id)
            .versionData(createMetaDataItemsForSuite())
            .persist();

        new ContentVersion_t()
            .title(APEX_TEST_CLASSES_FILE_NAME)
            .pathOnClient(APEX_TEST_CLASSES_FILE_NAME + '.json')
            .firstPublishLocationId(tests[1].Id)
            .versionData(createMetaDataItemsForClasses())
            .persist();
    }

    private static Blob createMetaDataItemsForSuite() {
        List<MetaDataItem> result = new List<MetaDataItem>();

        List<MetaDataItem> testSuite1Classes = new List<MetaDataItem>();
        testSuite1Classes.add(
            TestDataFactory.createMetadataItem('TestClass1', '', APEX_CLASS, true, true, 'User User', '2023-04-04T05:08:09.000+0000', null)
        );
        testSuite1Classes.add(
            TestDataFactory.createMetadataItem('TestClass2', '', APEX_CLASS, true, true, 'User User', '2023-04-04T05:08:09.000+0000', null)
        );

        List<MetaDataItem> testSuite2Classes = new List<MetaDataItem>();
        testSuite2Classes.add(
            TestDataFactory.createMetadataItem('TestClass3', '', APEX_CLASS, false, false, 'User User', '2023-04-04T05:08:09.000+0000', null)
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

        return Blob.valueOf(JSON.serialize(result));
    }

    private static Blob createMetaDataItemsForClasses() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.createMetadataItem('TestClass2', '', APEX_CLASS, true, true, 'User User', '2023-04-04T05:08:09.000+0000', null));
        result.add(TestDataFactory.createMetadataItem('TestClass3', '', APEX_CLASS, true, true, 'User User', '2023-04-04T05:08:09.000+0000', null));
        result.add(TestDataFactory.createMetadataItem('TestClass4', '', APEX_CLASS, false, false, 'User User', '2023-04-04T05:08:09.000+0000', null));
        return Blob.valueOf(JSON.serialize(result));
    }

    private static void mockUserStoryBundle(copado__User_Story__c userStoryBundle) {
        Id recordTypeId = Schema.SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId();
        copado__Artifact__c packageRecord = new copado__Artifact__c(Name = 'Test', RecordTypeId = recordTypeId);
        insert packageRecord;
        copado__Artifact_Version__c packageVersion = new copado__Artifact_Version__c(
            copado__Artifact__c = packageRecord.Id,
            copado__Version_Name__c = 'Test',
            copado__User_Story__c = userStoryBundle.Id
        );
        insert packageVersion;
        List<copado__Bundled_Story__c> bundledStories = new List<copado__Bundled_Story__c>();
        for (copado__User_Story__c userStory : [
            SELECT Id
            FROM copado__User_Story__c
            WHERE copado__User_Story_Title__c != 'US3'
        ]) {
            bundledStories.add(new copado__Bundled_Story__c(copado__User_Story__c = userStory.Id, copado__Package_Version__c = packageVersion.Id));
        }
        insert bundledStories;
    }
}