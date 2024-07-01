@SuppressWarnings('PMD.CyclomaticComplexity')
@IsTest
private with sharing class AddApexTestsControllerTest {
    private final static String APEX_TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String APEX_TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TEST_SUIT = 'ApexTestSuite';
    private final static String PROJECT_NAME = 'MyProject';
    private final static String SOURCE_CRED_NAME = 'Dev1';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void retrieveApexTestAndSuitesFromNonCommitContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Test__c test = getCopadoTest();
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();

            // EXCERCISE

            List<MetaDataItem> response = AddApexTestsController.getApexTestClassList(test.Id, test.copado__User_Story__c, null);

            // VERIFY

            Assert.areEqual(5, response.size(), 'The total number of metadata items should be 5');
            for (MetaDataItem metaDataItem : response) {
                switch on metaDataItem.n {
                    when 'TestSuite1' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'TestSuite2' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'fflib_IDGeneratorTest' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample1Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample2Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                }
            }
            Assert.areEqual(0, getFileLinksForApexTestAndSuites(test.Id).size(), 'No files should be associated to the test record');
        }
    }

    @IsTest
    private static void retrieveApexTestAndSuitesFromCommitContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            delete getCopadoTest();
            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();

            // EXCERCISE

            List<MetaDataItem> response = AddApexTestsController.getApexTestClassList(null, getUserStory().Id, apexTestInfo);

            // VERIFY

            Assert.areEqual(5, response.size(), 'The total number of metadata items should be 5');
            for (MetaDataItem metaDataItem : response) {
                switch on metaDataItem.n {
                    when 'TestSuite1' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'TestSuite2' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'fflib_IDGeneratorTest' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample1Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample2Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                }
            }
            Assert.areEqual(2, getFileLinksForApexTestAndSuites(getCopadoTest().Id).size(), 'Two files should be associated to the test record');
        }
    }

    @IsTest
    private static void retrieveMetadataItemsWithExistingTestSuiteFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();
            delete getUserStoryMetadata('ApexTestSuite');
            createTestSuitesFile(getCopadoTest().Id);

            // EXCERCISE

            List<MetaDataItem> response = AddApexTestsController.getApexTestClassList(null, getUserStory().Id, apexTestInfo);

            // VERIFY

            Assert.areEqual(3, response.size(), 'The total number of metadata items should be 3');
            for (MetaDataItem metaDataItem : response) {
                switch on metaDataItem.n {
                    when 'fflib_IDGeneratorTest' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample1Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample2Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                }
            }
            Assert.areEqual(2, getFileLinksForApexTestAndSuites(getCopadoTest().Id).size(), 'Two files should be associated to the test record');
        }
    }

    @IsTest
    private static void retrieveMetadataItemsWithManualSelection() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();
            createTestSuitesFile(getCopadoTest().Id);

            // EXCERCISE

            List<MetaDataItem> response = AddApexTestsController.getApexTestClassList(null, getUserStory().Id, apexTestInfo);

            // VERIFY

            Assert.areEqual(5, response.size(), 'The total number of metadata items should be 5');
            for (MetaDataItem metaDataItem : response) {
                switch on metaDataItem.n {
                    when 'TestSuite1' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'TestSuite2' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'fflib_IDGeneratorTest' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isTrue(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isTrue(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample1Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample2Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                }
            }
            Assert.areEqual(2, getFileLinksForApexTestAndSuites(getCopadoTest().Id).size(), 'Two files should be associated to the test record');
        }
    }

    @IsTest
    private static void retrieveMetaDataWithoutApexTestAndSuiteCommit() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            delete getUserStoryMetadata();
            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();
            copado__User_Story__c userStory = getUserStory();

            // EXCERCISE

            List<MetaDataItem> response = AddApexTestsController.getApexTestClassList(null, userStory.Id, apexTestInfo);

            // VERIFY

            Assert.areEqual(0, response.size(), 'The total number of metadata items should be 0');
            Assert.isTrue(
                [SELECT Id FROM copado__Test__c WHERE copado__User_Story__c = :userStory.Id].isEmpty(),
                'There should be no test record associated with the user story'
            );
        }
    }

    @IsTest
    private static void retrieveApexTestAndSuitesWithCalloutFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getFailureResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();
            copado__User_Story__c userStory = getUserStory();
            Exception exceptionMessage;

            // EXCERCISE

            try {
                AddApexTestsController.getApexTestClassList(null, userStory.Id, apexTestInfo);
            } catch (Exception ex) {
                exceptionMessage = ex;
            }

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains('Failure in retrieving Apex Test Suite data'),
                'Exception message should be received'
            );
        }
    }

    @IsTest
    private static void commitApexOnUserStoryWithPopulatedTestFields() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Apex_Code_Coverage__c = 60;
            userStory.copado__Classes_Without_Coverage__c = 1;
            userStory.copado__Triggers_Without_Coverage__c = 1;
            userStory.copado__Failing_Methods__c = 1;
            update userStory;

            delete getUserStoryMetadata('ApexTestSuite');

            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();

            // EXCERCISE

            AddApexTestsController.getApexTestClassList(null, userStory.Id, apexTestInfo);

            // VERIFY

            copado__User_Story__c updatedUserStory = getUserStory();
            Assert.areEqual(
                0,
                updatedUserStory.copado__Apex_Code_Coverage__c,
                'The Apex code coverage should be reset instead of ' + updatedUserStory.copado__Apex_Code_Coverage__c
            );
            Assert.areEqual(
                0,
                updatedUserStory.copado__Classes_Without_Coverage__c,
                'The Classes without coverage should be reset instead of ' + updatedUserStory.copado__Classes_Without_Coverage__c
            );
            Assert.areEqual(
                0,
                updatedUserStory.copado__Triggers_Without_Coverage__c,
                'The triggers without coverage should be reset instead of ' + updatedUserStory.copado__Triggers_Without_Coverage__c
            );
            Assert.areEqual(
                0,
                updatedUserStory.copado__Failing_Methods__c,
                'The failing methods should be reset instead of ' + updatedUserStory.copado__Failing_Methods__c
            );
        }
    }

    @IsTest
    private static void commitNonApexOnUserStoryWithPopulatedTestFields() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Apex_Code_Coverage__c = 60;
            userStory.copado__Classes_Without_Coverage__c = 1;
            userStory.copado__Triggers_Without_Coverage__c = 1;
            userStory.copado__Failing_Methods__c = 1;
            update userStory;

            delete getUserStoryMetadata('ApexTestSuite');

            ApexTestInfo apexTestInfo = new ApexTestInfo(false, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();

            // EXCERCISE

            AddApexTestsController.getApexTestClassList(null, userStory.Id, apexTestInfo);

            // VERIFY

            copado__User_Story__c updatedUserStory = getUserStory();
            Assert.areEqual(
                60,
                updatedUserStory.copado__Apex_Code_Coverage__c,
                'The Apex code coverage should be reset instead of ' + updatedUserStory.copado__Apex_Code_Coverage__c
            );
            Assert.areEqual(
                1,
                updatedUserStory.copado__Classes_Without_Coverage__c,
                'The Classes without coverage should be reset instead of ' + updatedUserStory.copado__Classes_Without_Coverage__c
            );
            Assert.areEqual(
                1,
                updatedUserStory.copado__Triggers_Without_Coverage__c,
                'The triggers without coverage should be reset instead of ' + updatedUserStory.copado__Triggers_Without_Coverage__c
            );
            Assert.areEqual(
                1,
                updatedUserStory.copado__Failing_Methods__c,
                'The failing methods should be reset instead of ' + updatedUserStory.copado__Failing_Methods__c
            );
        }
    }

    @IsTest
    private static void commitNonApexOnUserStoryWithPopulatedTestFieldsWithRecreateFeatureBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Apex_Code_Coverage__c = 60;
            userStory.copado__Classes_Without_Coverage__c = 1;
            userStory.copado__Triggers_Without_Coverage__c = 1;
            userStory.copado__Failing_Methods__c = 1;
            update userStory;

            delete getUserStoryMetadata('ApexTestSuite');

            ApexTestInfo apexTestInfo = new ApexTestInfo(true, getCommitChangesFileWithoutApex());
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();

            // EXCERCISE

            AddApexTestsController.getApexTestClassList(null, userStory.Id, apexTestInfo);

            // VERIFY

            copado__User_Story__c updatedUserStory = getUserStory();
            Assert.areEqual(
                0,
                updatedUserStory.copado__Apex_Code_Coverage__c,
                'The Apex code coverage should be reset instead of ' + updatedUserStory.copado__Apex_Code_Coverage__c
            );
            Assert.areEqual(
                0,
                updatedUserStory.copado__Classes_Without_Coverage__c,
                'The Classes without coverage should be reset instead of ' + updatedUserStory.copado__Classes_Without_Coverage__c
            );
            Assert.areEqual(
                0,
                updatedUserStory.copado__Triggers_Without_Coverage__c,
                'The triggers without coverage should be reset instead of ' + updatedUserStory.copado__Triggers_Without_Coverage__c
            );
            Assert.areEqual(
                0,
                updatedUserStory.copado__Failing_Methods__c,
                'The failing methods should be reset instead of ' + updatedUserStory.copado__Failing_Methods__c
            );
        }
    }

    @IsTest
    private static void createContentDocument() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Test__c test = getCopadoTest();
            List<MetadataItem> metadata = getMetadataItems();
            Set<String> fileNames = new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME };

            // EXERCISE

            AddApexTestsController.createContentVersion(test.Id, metadata);

            // VERIFY
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : [
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :test.Id AND ContentDocument.Title IN :fileNames
            ]) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersion = [
                SELECT Id, VersionData, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentIds AND IsLatest = TRUE
            ];
            Assert.areEqual(2, contentVersion.size(), 'There should be two files created');
            Assert.isTrue(fileNames.contains(contentVersion[0].Title), 'This file name should be named as cmcSf_TestClasses or cmcSf_TestSuites');
            Assert.isTrue(fileNames.contains(contentVersion[1].Title), 'This file name should be named as cmcSf_TestClasses or cmcSf_TestSuites');
        }
    }

    @IsTest
    private static void createContentWithSameUserThanPreviousContentDocumentOfTestRecord() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Set<String> fileNames = new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME };
            copado__Test__c test = getCopadoTest();
            List<MetadataItem> metadata = getMetadataItems();
            AddApexTestsController.createContentVersion(test.Id, metadata);

            // EXERCISE

            AddApexTestsController.createContentVersion(test.Id, metadata);

            // VERIFY

            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : [
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :test.Id AND ContentDocument.Title IN :fileNames
            ]) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersion = [
                SELECT Id, VersionData, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentIds AND IsLatest = TRUE
            ];
            Assert.areEqual(2, contentVersion.size(), 'There should be two files created');
            Assert.isTrue(fileNames.contains(contentVersion[0].Title), 'This file name should be named as cmcSf_TestClasses or cmcSf_TestSuites');
            Assert.isTrue(fileNames.contains(contentVersion[1].Title), 'This file name should be named as cmcSf_TestClasses or cmcSf_TestSuites');
        }
    }

    @IsTest
    private static void createContentWithDifferentUserThanPreviousContentDocumentOfTestRecord() {
        // SETUP

        TestUtilities.createAdminUser('usernameAdmin@myemail.com');
        Set<String> fileNames = new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME };
        copado__Test__c test;
        List<MetadataItem> metadata;
        System.runAs(TestUtilities.getRunAsUser('usernameAdmin@myemail.com')) {
            test = getCopadoTest();
            metadata = getMetadataItems();
            AddApexTestsController.createContentVersion(test.Id, metadata);
        }

        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE

            AddApexTestsController.createContentVersion(test.Id, metadata);

            // VERIFY

            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : [
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :test.Id AND ContentDocument.Title IN :fileNames
            ]) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersion = [
                SELECT Id, VersionData, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentIds AND IsLatest = TRUE
            ];
            Assert.areEqual(2, contentVersion.size(), 'There should be two files created');
            Assert.isTrue(fileNames.contains(contentVersion[0].Title), 'This file name should be named as cmcSf_TestClasses or cmcSf_TestSuites');
            Assert.isTrue(fileNames.contains(contentVersion[1].Title), 'This file name should be named as cmcSf_TestClasses or cmcSf_TestSuites');
        }
    }
    @IsTest
    private static void retrieveApexTestAndSuitesForRollback() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String promotionId = (String) getPromotionId(PROJECT_NAME, SOURCE_CRED_NAME);
            GetAllTestClassesFromOrg.mockResponse = getSuccessResponseForSOSLSearch();
            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();

            // EXCERCISE

            List<MetaDataItem> response = AddApexTestsController.getApexTestClassForRollback(promotionId);

            // VERIFY

            Assert.areEqual(5, response.size(), 'The total number of metadata items should be 5');
            for (MetaDataItem metaDataItem : response) {
                switch on metaDataItem.n {
                    when 'TestSuite1' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'TestSuite2' {
                        Assert.areEqual('ApexTestSuite', metaDataItem.t, 'The metadata type should be ApexTestSuite');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isTrue(!metaDataItem.children.isEmpty(), 'The metadata type should consists of children');
                    }
                    when 'fflib_IDGeneratorTest' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample1Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                    when 'Sample2Test' {
                        Assert.areEqual('ApexClass', metaDataItem.t, 'The metadata type should be Apex Class');
                        Assert.isFalse(metaDataItem.cm, 'The metadata type should not be marked as cm');
                        Assert.isFalse(metaDataItem.s, 'The metadata type should not be marked as selected');
                        Assert.isNull(metaDataItem.children, 'The metadata type should not consists of children');
                    }
                }
            }
            Assert.areEqual(0, getFileLinksForApexTestAndSuites(promotionId).size(), 'No files should be associated to the test record');
        }
    }

    // HELPER

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private static void makeData() {
        copado__Git_Repository__c repository = TestDataFactory.createGitRepository('MyRepo');
        insert repository;

        copado__Environment__c devEnvironment = TestDataFactory.createEnvironment(SOURCE_CRED_NAME, 'Production/Developer', 'SFDX');
        copado__Environment__c uatEnvironment = TestDataFactory.createEnvironment('Uat', 'Production/Developer', 'SFDX');
        insert new List<copado__Environment__c>{ devEnvironment, uatEnvironment };

        copado__Org__c devCredential = TestDataFactory.createCredential(
            SOURCE_CRED_NAME,
            'name@example.com',
            devEnvironment.Id,
            'Production/Developer'
        );
        copado__Org__c uatCredential = TestDataFactory.createCredential('Uat', 'nameuat@example.com', uatEnvironment.Id, 'Production/Developer');
        insert new List<copado__Org__c>{ devCredential, uatCredential };

        copado__JobTemplate__c jobTemplate = TestDataFactory.createJobTemplate('Promotion');
        insert jobTemplate;

        copado__Deployment_Flow__c pipeline = TestDataFactory.createPipeline('MyPipeline', repository.Id);
        pipeline.copado__Platform__c = 'SFDX';
        insert pipeline;

        copado__Pipeline_Action__c action = TestDataFactory.createPipelineAction('Promotion', pipeline.Id, jobTemplate.Id);
        insert action;

        copado__Deployment_Flow_Step__c connection = TestDataFactory.createPipelineConnection(pipeline.Id, devEnvironment.Id, uatEnvironment.Id);
        insert connection;

        copado__Project__c project = TestDataFactory.createProject(PROJECT_NAME, pipeline.Id);
        insert project;

        copado__User_Story__c story = new copado__User_Story__c(
            copado__User_Story_Title__c = 'My Story One',
            copado__Project__c = project.Id,
            copado__Org_Credential__c = devCredential.Id
        );
        insert story;

        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );

        copado__TestTool__mdt testTool = new copado__TestTool__mdt(
            MasterLabel = !picklistValues.isEmpty() ? picklistValues[0] : '',
            copado__JobTemplate__c = 'MockTemplate',
            copado__TestType__c = 'Mock Type'
        );

        copado__ExtensionConfiguration__c extensionConfig = new copado__ExtensionConfiguration__c(
            copado__ExtensionTool__c = testTool.MasterLabel,
            copado__ExtensionApplication__c = 'Test',
            copado__Active__c = true
        );
        insert extensionConfig;

        copado__Test__c test = new copado__Test__c(
            Name = 'Mock Test',
            copado__ExtensionConfiguration__c = extensionConfig.Id,
            copado__User_Story__c = story.id
        );
        insert test;

        copado__User_Story_Metadata__c userStoryMetadata1 = new copado__User_Story_Metadata__c(
            Name = 'fflib_IDGeneratorTest',
            copado__Metadata_API_Name__c = 'fflib_IDGeneratorTest',
            copado__Action__c = 'Add',
            copado__Type__c = 'ApexClass',
            copado__User_Story__c = story.id
        );

        copado__User_Story_Metadata__c userStoryMetadata2 = new copado__User_Story_Metadata__c(
            Name = 'TestSuite1',
            copado__Metadata_API_Name__c = 'TestSuite1',
            copado__Action__c = 'Add',
            copado__Type__c = 'ApexTestSuite',
            copado__User_Story__c = story.id
        );
        insert new List<copado__User_Story_Metadata__c>{ userStoryMetadata1, userStoryMetadata2 };

        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = project.Id,
            copado__Source_Org_Credential__c = devCredential.Id,
            copado__Source_Environment__c = devEnvironment.Id
        );
        insert promotion;
    }

    private static copado__Test__c getCopadoTest() {
        return [SELECT Id, copado__User_Story__c, copado__User_Story__r.copado__Org_Credential__c FROM copado__Test__c LIMIT 1];
    }

    private static List<MetaDataItem> getMetadataItems() {
        List<MetaDataItem> result = new List<MetaDataItem>();

        MetaDataItem apexClass = new MetaDataItem();
        apexClass.t = 'ApexClass';
        apexClass.n = 'MyClass';
        result.add(apexClass);
        MetaDataItem testSuite = new MetaDataItem();
        testSuite.t = 'ApexTestSuite';
        testSuite.n = 'Mysuite';
        result.add(testSuite);

        return result;
    }

    private static String getSuccessResponseForSOSLSearch() {
        String content =
            '{' +
            '"searchRecords" : [' +
            '{' +
            '"Name": "fflib_IDGeneratorTest",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": null,' +
            '"attributes": ' +
            '{' +
            '"type": "ApexClass"' +
            '},' +
            '"NamespacePrefix": ""' +
            '},' +
            '{' +
            '"Name": "Sample1Test",' +
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
            '"Name": "Sample2Test",' +
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
            '}';
        return JSON.serialize(new ProxyOrgResponse(200, content, null, null));
    }

    private static String getSuccessResponseForTestSuite() {
        String content =
            '{' +
            '"size" : 2,' +
            '"totalSize" : 2,' +
            '"done" : true,' +
            '"queryLocator" : null,' +
            '"entityTypeName" : "ApexTestSuite",' +
            '"records" : [ {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/05F0p000000CbszEAC"' +
            '},' +
            '"Id" : "05F0p000000CbszEAC"' +
            '}, {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/05F0p000000Cbt4EAC"' +
            '},' +
            '"Id" : "05F0p000000Cbt4EAC"' +
            '} ]' +
            '}';
        return JSON.serialize(new ProxyOrgResponse(200, content, null, null));
    }

    private static String getFailureResponseForTestSuite() {
        return JSON.serialize(new ProxyOrgResponse(400, null, null, 'Failure in retrieving Apex Test Suite data'));
    }

    private static String getSuccessResponseForTestSuiteMembership() {
        String content =
            '{' +
            '"size" : 2,' +
            '"totalSize" : 2,' +
            '"done" : true,' +
            '"queryLocator" : null,' +
            '"entityTypeName" : "TestSuiteMembership",' +
            '"records" : [ {' +
            '"attributes" : {' +
            '"type" : "TestSuiteMembership",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/TestSuiteMembership/0Hd0p000000D18iCAC"' +
            '},' +
            '"Id" : "0Hd0p000000D18iCAC",' +
            '"ApexClass" : {' +
            '"attributes" : {' +
            '"type" : "ApexClass",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexClass/01p0p000004hcSMAAY"' +
            '},' +
            '"Name" : "Sample1Test",' +
            '"NamespacePrefix" : null,' +
            '"LastModifiedDate" : "2023-04-13T03:14:45.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/0050p000004c9V8AAI"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '},' +
            '"ApexTestSuite" : {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/05F0p000000CbszEAC"' +
            '},' +
            '"TestSuiteName" : "TestSuite1",' +
            '"LastModifiedDate" : "2023-04-13T03:52:30.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/0050p000004c9V8AAI"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '}' +
            '}, {' +
            '"attributes" : {' +
            '"type" : "TestSuiteMembership",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/TestSuiteMembership/0Hd0p000000D18nCAC"' +
            '},' +
            '"Id" : "0Hd0p000000D18nCAC",' +
            '"ApexClass" : {' +
            '"attributes" : {' +
            '"type" : "ApexClass",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexClass/01p0p000004hvHYAAY"' +
            '},' +
            '"Name" : "Sample2Test",' +
            '"NamespacePrefix" : null,' +
            '"LastModifiedDate" : "2023-04-13T03:11:49.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/0050p000004c9V8AAI"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '},' +
            '"ApexTestSuite" : {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/05F0p000000Cbt4EAC"' +
            '},' +
            '"TestSuiteName" : "TestSuite2",' +
            '"LastModifiedDate" : "2023-04-13T03:52:43.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/0050p000004c9V8AAI"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '}' +
            '} ]' +
            '}';
        return JSON.serialize(new ProxyOrgResponse(200, content, null, null));
    }

    private static Id getCommitChangesFileWithoutApex() {
        CommitChanges.Change change = new CommitChanges.Change('ApexPage', 'TestPage1', 'SFDX', 'File path is handled automatically', 'Add');
        return createCommitChangesFileOnUserStory(new List<CommitChanges.Change>{ change });
    }

    private static Id getCommitChangesFileWithApex() {
        CommitChanges.Change change = new CommitChanges.Change('ApexClass', 'TestClass', 'SFDX', 'File path is handled automatically', 'Add');
        return createCommitChangesFileOnUserStory(new List<CommitChanges.Change>{ change });
    }

    private static Id createCommitChangesFileOnUserStory(List<CommitChanges.Change> commitChanges) {
        ContentVersion content = new ContentVersion(
            Title = 'Copado Commit changes',
            origin = 'C',
            PathOnClient = 'Copado Commit changes.json',
            VersionData = Blob.valueOf(JSON.serialize(commitChanges))
        );
        insert content;

        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        copado__User_Story__c story = getUserStory();
        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = story.Id, ContentDocumentId = contentVersion.ContentDocumentId);
        insert link;
        return content.Id;
    }

    private static copado__User_Story__c getUserStory() {
        return [
            SELECT
                Id,
                copado__Apex_Code_Coverage__c,
                copado__Classes_Without_Coverage__c,
                copado__Triggers_Without_Coverage__c,
                copado__Failing_Methods__c
            FROM copado__User_Story__c
            LIMIT 1
        ];
    }

    private static List<copado__User_Story_Metadata__c> getUserStoryMetadata() {
        return [SELECT Id FROM copado__User_Story_Metadata__c];
    }

    private static List<ContentDocumentLink> getFileLinksForApexTestAndSuites(Id recordId) {
        List<ContentDocumentLink> result = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME });
        return result;
    }

    private static copado__User_Story_Metadata__c getUserStoryMetadata(String type) {
        return [SELECT Id FROM copado__User_Story_Metadata__c WHERE copado__Type__c = :type];
    }

    private static void createTestSuitesFile(Id recordId) {
        new ContentVersion_t()
            .title(APEX_TEST_SUITES_FILE_NAME)
            .pathOnClient(APEX_TEST_SUITES_FILE_NAME + '.json')
            .firstPublishLocationId(recordId)
            .versionData(getRecords())
            .persist();
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
                true,
                false,
                'User User',
                '2023-04-04T05:08:09.000+0000',
                testSuite2Classes
            )
        );

        return Blob.valueOf(JSON.serialize(result));
    }

    private static Id getPromotionId(String projectName, String sourceCredName) {
        return [
            SELECT Id, copado__Project__c, copado__Source_Org_Credential__c
            FROM copado__Promotion__c
            WHERE copado__Project__r.Name = :projectName AND copado__Source_Org_Credential__r.Name = :sourceCredName
        ]
        .Id;
    }
}