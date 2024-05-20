@IsTest
@SuppressWarnings('PMD.CyclomaticComplexity')
private class ApexTestSuitesAndClassesTest {
    private final static String APEX_TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String APEX_TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TEST_SUIT = 'ApexTestSuite';
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testWithTestClassesFileOnly() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            createTestClassesFile(testId);

            // EXERCISE
            List<MetadataItem> result = ApexTestSuitesAndClasses.getRecords(testId);

            // VERIFY
            List<String> testClasses = getMetadataItemNames(result);
            Assert.areEqual(testClasses.size(), 1, 'There should be only 1 selected Apex test Class instead of ' + testClasses.size());
            Assert.isTrue(testClasses.contains('TestClass1'), 'TestClasses list is incorrect');
        }
    }

    @IsTest
    private static void testWithTestSuitesFileOnly() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            createTestSuitesFile(testId);

            // EXERCISE
            List<MetadataItem> result = ApexTestSuitesAndClasses.getRecords(testId);

            // VERIFY
            List<String> testSuites = getMetadataItemNames(result);

            Assert.areEqual(testSuites.size(), 1, 'There should be only 1 selected Apex Test Suite instead of ' + testSuites.size());
            Assert.isTrue(testSuites.contains('TestSuite1'), 'Test Suites list is incorrect');
        }
    }

    @IsTest
    private static void testWithTestSuitesAndTestClassesFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            createTestClassesFile(testId);
            createTestSuitesFile(testId);

            // EXERCISE
            List<MetadataItem> result = ApexTestSuitesAndClasses.getRecords(testId);

            // VERIFY
            List<String> testClassesAndSuites = getMetadataItemNames(result);

            Assert.areEqual(
                testClassesAndSuites.size(),
                2,
                'There should be 2 selected Apex test Classes and suites instead of ' + testClassesAndSuites.size()
            );
            Assert.isTrue(testClassesAndSuites.contains('TestSuite1'), 'Test Suites list is incorrect');
            Assert.isTrue(testClassesAndSuites.contains('TestClass1'), 'Test Classes list is incorrect');
        }
    }

    @IsTest
    private static void testWithoutTestSuitesAndTestClassesFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;

            // EXERCISE
            List<MetadataItem> result = ApexTestSuitesAndClasses.getRecords(testId);

            // VERIFY

            Assert.areEqual(result.size(), 0, 'An empty list of MetadataItems should be returned');
        }
    }

    @IsTest
    private static void testsCreatedByAnotherUser() {
        // SETUP
        Id testId = getTest().Id;

        TestUtilities.createAdminUser('usernameAdmin@myemail.com');
        System.runAs(TestUtilities.getRunAsUser('usernameAdmin@myemail.com')) {
            createTestClassesFile(testId);
            createTestSuitesFile(testId);
        }

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            List<MetadataItem> result = ApexTestSuitesAndClasses.getRecords(testId);

            // VERIFY
            List<String> testClassesAndSuites = getMetadataItemNames(result);

            Assert.areEqual(
                testClassesAndSuites.size(),
                2,
                'There should be 2 selected Apex test Classes and suites instead of ' + testClassesAndSuites.size()
            );
            Assert.isTrue(testClassesAndSuites.contains('TestSuite1'), 'Test Suites list is incorrect');
            Assert.isTrue(testClassesAndSuites.contains('TestClass1'), 'Test Classes list is incorrect');
        }
    }

    @IsTest
    private static void removeTestClassesOnly() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            createTestClassesFile(testId);
            createTestSuitesFile(testId);

            // EXERCISE
            String metadataItemsToBeRemoved = '[{"n":"TestClass1","t":"ApexClass"}]';
            ApexTestSuitesAndClasses.removeMetadataItems(testId, metadataItemsToBeRemoved);

            // VERIFY
            Map<String, List<MetaDataItem>> testSuitesAndClasses = getTestSuitesAndClasses(testId);
            List<String> testSuites = getMetadataItemNames(testSuitesAndClasses.get(APEX_TEST_SUITES_FILE_NAME));
            List<String> testClasses = getMetadataItemNames(testSuitesAndClasses.get(APEX_TEST_CLASSES_FILE_NAME));

            Assert.areEqual(testClasses.size(), 1, 'There should be 1 Apex Class remaining in the file instead of' + testClasses.size());
            Assert.isTrue(testClasses.contains('TestClass2'), 'TestClasses list is incorrect');
            Assert.areEqual(testSuites.size(), 2, 'There should be 2 Apex Suites remaining in the file instead of' + testSuites.size());
            Assert.isTrue(testSuites.contains('TestSuite1'), 'Test Suites list is incorrect');
            Assert.isTrue(testSuites.contains('TestSuite2'), 'Test Suites list is incorrect');
        }
    }

    @IsTest
    private static void removeTestSuitesOnly() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            createTestClassesFile(testId);
            createTestSuitesFile(testId);

            // EXERCISE
            String metadataItemsToBeRemoved = '[{"n":"TestSuite1","t":"ApexTestSuite"}]';
            ApexTestSuitesAndClasses.removeMetadataItems(testId, metadataItemsToBeRemoved);

            // VERIFY
            Map<String, List<MetaDataItem>> testSuitesAndClasses = getTestSuitesAndClasses(testId);
            List<String> testSuites = getMetadataItemNames(testSuitesAndClasses.get(APEX_TEST_SUITES_FILE_NAME));
            List<String> testClasses = getMetadataItemNames(testSuitesAndClasses.get(APEX_TEST_CLASSES_FILE_NAME));

            Assert.areEqual(testClasses.size(), 2, 'There should be 2 Apex Class remaining in the file instead of' + testClasses.size());
            Assert.isTrue(testClasses.contains('TestClass1'), 'TestClasses list is incorrect');
            Assert.isTrue(testClasses.contains('TestClass2'), 'TestClasses list is incorrect');
            Assert.areEqual(testSuites.size(), 1, 'There should be 1 Apex Suites remaining in the file instead of' + testSuites.size());
            Assert.isTrue(testSuites.contains('TestSuite2'), 'Test Suites list is incorrect');
        }
    }

    @IsTest
    private static void removeTestSuitesAndClasses() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            createTestClassesFile(testId);
            createTestSuitesFile(testId);

            // EXERCISE
            String metadataItemsToBeRemoved = '[{"n":"TestSuite1","t":"ApexTestSuite"},{"n":"TestClass1","t":"ApexClass"}]';
            ApexTestSuitesAndClasses.removeMetadataItems(testId, metadataItemsToBeRemoved);

            // VERIFY
            Map<String, List<MetaDataItem>> testSuitesAndClasses = getTestSuitesAndClasses(testId);
            List<String> testSuites = getMetadataItemNames(testSuitesAndClasses.get(APEX_TEST_SUITES_FILE_NAME));
            List<String> testClasses = getMetadataItemNames(testSuitesAndClasses.get(APEX_TEST_CLASSES_FILE_NAME));

            Assert.areEqual(testClasses.size(), 1, 'There should be 1 Apex Class remaining in the file instead of' + testClasses.size());
            Assert.isTrue(testClasses.contains('TestClass2'), 'TestClasses list is incorrect');
            Assert.areEqual(testSuites.size(), 1, 'There should be 1 Apex Suites remaining in the file instead of' + testSuites.size());
            Assert.isTrue(testSuites.contains('TestSuite2'), 'Test Suites list is incorrect');
        }
    }

    @IsTest
    private static void autoAddTestsWithInvalidTestId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = null;
            Id userStoryId = getUserStory().Id;
            Exception exceptionData;

            // EXERCISE
            try {
                ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);
            } catch (Exception ex) {
                exceptionData = ex;
            }

            // VERIFY
            Assert.isTrue(exceptionData.getMessage().contains(Label.Invalid_Test_Id_Or_User_Story_Id_Message), 'Exception message is incorrect');
        }
    }

    @IsTest
    private static void autoAddTestsWithInvalidUserStoryId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Id userStoryId = null;
            Exception exceptionData;

            // EXERCISE
            try {
                ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);
            } catch (Exception ex) {
                exceptionData = ex;
            }

            // VERIFY
            Assert.isTrue(exceptionData.getMessage().contains(Label.Invalid_Test_Id_Or_User_Story_Id_Message), 'Exception message is incorrect');
        }
    }

    @IsTest
    private static void autoAddTestsWithIncorrectUserStoryId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Exception exceptionData;

            // EXERCISE
            try {
                ApexTestSuitesAndClasses.autoAddTests(testId, testId);
            } catch (Exception ex) {
                exceptionData = ex;
            }

            // VERIFY
            Assert.isTrue(exceptionData.getMessage().contains(Label.No_User_Story_Found_For_Auto_Add_Tests), 'Exception message is incorrect');
        }
    }

    @IsTest
    private static void autoAddTestsWithoutSearchTerm() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Id userStoryId = getUserStory().Id;

            // EXERCISE
            Boolean isTestClassAdded = ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);

            // VERIFY
            Assert.isFalse(isTestClassAdded, 'No test classes should be added');
        }
    }

    @IsTest
    private static void autoAddTestsWithFailureInGettingTestClasses() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Id userStoryId = getUserStory().Id;
            createUserStoryMetadata(userStoryId);
            String response = getTestClassesFailureResponse();
            GetAllTestClassesFromOrg.mockResponse = response;
            Exception exceptionData;

            // EXERCISE
            try {
                ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);
            } catch (Exception ex) {
                exceptionData = ex;
            }

            // VERIFY
            Assert.isTrue(exceptionData.getMessage().contains('Test error message'), 'Exception message is incorrect');
        }
    }

    @IsTest
    private static void autoAddTestsWithExistingTestClassesFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Id userStoryId = getUserStory().Id;
            createTestClassesFile(testId);
            createUserStoryMetadata(userStoryId);
            String response = getTestClassesSuccessfulResponse(getTestClassesResponseContent());
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE
            Boolean isTestClassAdded = ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);

            // VERIFY
            Set<String> testClassesBasedOnSearchTerm = new Set<String>{ 'SampleClassTest', 'TestClass2' };
            List<MetaDataItem> metaDataItems = getMetaDataItemFromTestRecord(testId, new Set<String>{ APEX_TEST_CLASSES_FILE_NAME });

            for (String testClassName : testClassesBasedOnSearchTerm) {
                MetaDataItem metaDataItem = new MetaDataItem();
                metaDataItem.t = 'ApexClass';
                metaDataItem.n = testClassName;
                Integer index = metaDataItems.indexOf(metaDataItem);
                MetaDataItem selectedMetaDataItem = metaDataItems.get(index);
                Assert.isTrue(selectedMetaDataItem.s, 'The test class should be marked as selected');
            }
            Assert.isTrue(isTestClassAdded, 'New Test classes should be added');
        }
    }

    @IsTest
    private static void autoAddTestsWithNoTestClassesFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Id userStoryId = getUserStory().Id;
            createUserStoryMetadata(userStoryId);
            String response = getTestClassesSuccessfulResponse(getTestClassesResponseContent());
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE
            Boolean isTestClassAdded = ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);

            // VERIFY
            Set<String> testClassesBasedOnSearchTerm = new Set<String>{ 'SampleClassTest', 'TestClass2' };
            List<MetaDataItem> metaDataItems = getMetaDataItemFromTestRecord(testId, new Set<String>{ APEX_TEST_CLASSES_FILE_NAME });
            for (String testClassName : testClassesBasedOnSearchTerm) {
                MetaDataItem metaDataItem = new MetaDataItem();
                metaDataItem.t = 'ApexClass';
                metaDataItem.n = testClassName;
                Integer index = metaDataItems.indexOf(metaDataItem);
                MetaDataItem selectedMetaDataItem = metaDataItems.get(index);
                Assert.isTrue(selectedMetaDataItem.s, 'The test class should be marked as selected');
            }
            Assert.isTrue(isTestClassAdded, 'New Test classes should be added');
        }
    }

    @IsTest
    private static void autoAddTestsWithNoMatchingTestClass() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id testId = getTest().Id;
            Id userStoryId = getUserStory().Id;
            createTestClassesFile(testId);
            createUserStoryMetadata(userStoryId);
            String response = getTestClassesSuccessfulResponse('{"searchRecords" : []}');
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE
            Boolean isTestClassAdded = ApexTestSuitesAndClasses.autoAddTests(testId, userStoryId);

            // VERIFY
            Assert.isFalse(isTestClassAdded, 'New Test classes should not be added');
        }
    }

    @IsTest
    private static void validateSearchTermsWithoutUserStoryMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id userStoryId = getUserStory().Id;
            List<copado__User_Story_Metadata__c> userStoryMetadatas = getUserStoryMetadata(userStoryId);

            // EXERCISE
            Set<String> result = ApexTestSuitesAndClasses.getSearchTermForAutoAddTests(userStoryMetadatas);

            // VERIFY
            Assert.isTrue(result.isEmpty(), 'There should be no search term available');
        }
    }

    @IsTest
    private static void validateSearchTermsWithUserStoryMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id userStoryId = getUserStory().Id;
            createUserStoryMetadata(userStoryId);
            List<copado__User_Story_Metadata__c> userStoryMetadatas = getUserStoryMetadata(userStoryId);

            // EXERCISE
            Set<String> result = ApexTestSuitesAndClasses.getSearchTermForAutoAddTests(userStoryMetadatas);

            // VERIFY
            Assert.areEqual(4, result.size(), 'There should be 4 search terms');
            for (copado__User_Story_Metadata__c userStoryMetadata : userStoryMetadatas) {
                Assert.isTrue(result.contains('new ' + userStoryMetadata.copado__Metadata_API_Name__c + '\\('), 'The search term should match');
                Assert.isTrue(result.contains(userStoryMetadata.copado__Metadata_API_Name__c + '.*'), 'The search term should match');
            }
        }
    }

    private static void createData() {
        ExtensionConfiguration extensionConfiguration = new ExtensionConfiguration().extensionTool(getExtensionTool()).phase('Test').activate();

        Credential credential = new Credential(new Environment().type('Production/Developer'));
        UserStory userStory = new UserStory().title('US 1').status('Draft').credential(credential);

        new Test_t().extensionConfiguration(extensionConfiguration).userStory(userStory).persist();
    }

    private static String getExtensionTool() {
        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );
        return !picklistValues.isEmpty() ? picklistValues[0] : '';
    }

    private static Map<String, List<MetaDataItem>> getTestSuitesAndClasses(Id testId) {
        Map<String, List<MetaDataItem>> result = new Map<String, List<MetaDataItem>>();
        List<ContentDocumentLink> documentLinks = new ContentDocumentLinksSelector()
            .versionDataByLinkedEntityIdsAndTitles(new Set<Id>{ testId }, new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME });
        for (ContentDocumentLink documentLink : documentLinks) {
            result.put(
                documentLink.ContentDocument.LatestPublishedVersion.Title,
                MetaDataItem.parseForFileJSON(documentLink.ContentDocument.LatestPublishedVersion.VersionData.toString())
            );
        }
        return result;
    }

    private static void createTestClassesFile(Id recordId) {
        deleteFile(APEX_TEST_CLASSES_FILE_NAME, recordId);
        new ContentVersion_t()
            .title(APEX_TEST_CLASSES_FILE_NAME)
            .pathOnClient(APEX_TEST_CLASSES_FILE_NAME + '.json')
            .firstPublishLocationId(recordId)
            .versionData(getTestClassesOnly())
            .persist();
    }

    private static void deleteFile(String fileName, String testId) {
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE FirstPublishLocationId = :testId AND Title = :fileName
        ];
        if (!contentVersions.isEmpty()) {
            delete [SELECT Id FROM ContentDocument WHERE Id = :contentVersions[0].ContentDocumentId];
        }
    }

    private static void createTestSuitesFile(Id recordId) {
        deleteFile(APEX_TEST_SUITES_FILE_NAME, recordId);
        new ContentVersion_t()
            .title(APEX_TEST_SUITES_FILE_NAME)
            .pathOnClient(APEX_TEST_SUITES_FILE_NAME + '.json')
            .firstPublishLocationId(recordId)
            .versionData(getRecords())
            .persist();
    }

    private static void createUserStoryMetadata(Id userStoryId) {
        UserStory userStory = new UserStory().recordId(userStoryId);
        new UserStoryMetadata_t().name('SampleClass').type('ApexClass').action('Add').userStory(userStory);
        new UserStoryMetadata_t().name('SampleApexPage').type('ApexPage').action('Add').userStory(userStory).persist();
    }

    private static Blob getTestClassesOnly() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.createMetadataItem('TestClass1', '', APEX_CLASS, true, false, 'User User', '2023-04-04T05:08:09.000+0000', null));
        result.add(TestDataFactory.createMetadataItem('TestClass2', '', APEX_CLASS, false, false, 'User User', '2023-04-04T05:08:09.000+0000', null));
        return Blob.valueOf(JSON.serialize(result));
    }

    private static Blob getRecords() {
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
            TestDataFactory.createMetadataItem('adiosTest1', '', APEX_CLASS, false, false, 'User User', '2023-04-04T05:08:09.000+0000', null)
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

    private static copado__Test__c getTest() {
        return [SELECT Id FROM copado__Test__c LIMIT 1];
    }

    private static copado__User_Story__c getUserStory() {
        return [SELECT Id FROM copado__User_Story__c LIMIT 1];
    }

    private static List<String> getMetadataItemNames(List<MetaDataItem> metadataItems) {
        List<String> result = new List<String>();
        for (MetaDataItem metadataItem : metadataItems) {
            result.add(metadataItem.n);
        }
        return result;
    }

    private static String getTestClassesFailureResponse() {
        return new ProxyOrgResponse(500, '', '', 'Test error message').getResponse();
    }

    private static String getTestClassesSuccessfulResponse(String response) {
        return new ProxyOrgResponse(200, response, null, null).getResponse();
    }

    private static String getTestClassesResponseContent() {
        return '{' +
            '"searchRecords" : [' +
            '{' +
            '"Name": "SampleClassTest",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "ApexClass"' +
            '},' +
            '"NamespacePrefix": ""' +
            '},' +
            '{' +
            '"Name": "TestClass2",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "ApexClass"' +
            '},' +
            '"NamespacePrefix": ""' +
            '}' +
            ']' +
            '}"' +
            '}';
    }

    private static List<MetaDataItem> getMetaDataItemFromTestRecord(String testId, Set<String> fileNames) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        List<ContentDocumentLink> documentLinks = new ContentDocumentLinksSelector()
            .versionDataByLinkedEntityIdsAndTitles(new Set<Id>{ testId }, fileNames);
        for (ContentDocumentLink documentLink : documentLinks) {
            String content = documentLink.ContentDocument.LatestPublishedVersion.VersionData.toString();
            if (String.isNotBlank(content)) {
                result.addAll(MetaDataItem.parseForFileJSON(content));
            }
        }
        return result;
    }

    private static List<copado__User_Story_Metadata__c> getUserStoryMetadata(Id userStoryId) {
        return [SELECT Id, copado__Metadata_API_Name__c FROM copado__User_Story_Metadata__c WHERE copado__User_Story__c = :userStoryId];
    }
}