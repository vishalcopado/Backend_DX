@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class AddApexTestsController {
    private final static String TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TRIGGER = 'ApexTrigger';
    private final static String APEX_TEST_SUITE = 'ApexTestSuite';
    private final static String APEX_TEST_NAME_TEMPLATE = '{0} Apex Tests';
    private final static String ADD = 'Add';
    private final static String RETRIEVE_ONLY = 'RetrieveOnly';
    private final static String DELETE_OPERATION = 'Delete';
    private final static String APEX_TEST = getApexTestValue();

    // PUBLIC

    @AuraEnabled
    public static List<MetaDataItem> getApexTestClassList(String recordId, String userStoryId, ApexTestInfo apexTestInfo) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        recordId = getApexTestId(recordId, userStoryId);
        copado__User_Story__c userStory = getUserStory(userStoryId);
        apexTestInfo = getValidApexTestInfo(apexTestInfo);
        result = getTestClassesAndSuites(recordId, userStory, apexTestInfo);
        return result;
    }

    @AuraEnabled
    public static List<MetaDataItem> getApexTestClassForRollback(String recordId) {
        List<MetaDataItem> result = new List<MetaDataItem>();

        Map<String, ContentDocumentLink> contentDocumentLinksByTitle = getContentDocumentLink(recordId);
        Map<Id, ContentVersion> contentVersionsByContentDocumentId = getContentVersionFromContentDocument(contentDocumentLinksByTitle.values());
        Set<String> selectedTestSuites = getManualSelections(
            contentVersionsByContentDocumentId.get(contentDocumentLinksByTitle.get(TEST_SUITES_FILE_NAME)?.ContentDocumentId)
        );

        Id destinationCredential = getDestinationIdFromPromotion(recordId);
        List<TestSuiteMembership> testSuiteMemberships = getAllTestSuiteMembershipFromOrg(
            false,
            false,
            new Set<String>(),
            selectedTestSuites,
            destinationCredential
        );

        copado.GlobalAPI.ProxyOrgResponse testClassesResponse = new GetAllTestClassesFromOrg(destinationCredential).execute();
        List<MetaDataItem> testClassesMetadatas = extractSelectedTestClasses(
            testClassesResponse?.content,
            recordId,
            new Set<String>(),
            contentVersionsByContentDocumentId.get(contentDocumentLinksByTitle.get(TEST_CLASSES_FILE_NAME)?.ContentDocumentId)
        );

        List<MetaDataItem> testSuitesMetadatas = extractSelectedTestSuites(
            testSuiteMemberships,
            testClassesMetadatas,
            selectedTestSuites,
            new Set<String>()
        );

        result.addAll(testClassesMetadatas);
        result.addAll(testSuitesMetadatas);
        return result;
    }

    @AuraEnabled
    public static void createContentVersion(String recordId, List<MetaDataItem> metadata) {
        try {
            List<MetaDataItem> testClassesMetadataItems = new List<MetaDataItem>();
            List<MetaDataItem> testSuitesMetadataItems = new List<MetaDataItem>();

            for (MetaDataItem selectedRecord : metadata) {
                if (selectedRecord.t == APEX_CLASS) {
                    testClassesMetadataItems.add(selectedRecord);
                } else if (selectedRecord.t == APEX_TEST_SUITE) {
                    testSuitesMetadataItems.add(selectedRecord);
                }
            }

            createFilesForTestClassesAndTestSuites(testClassesMetadataItems, testSuitesMetadataItems, recordId, new Set<String>());
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void createFilesForTestClassesAndTestSuites(
        List<MetaDataItem> testClassesMetadataItems,
        List<MetaDataItem> testSuitesMetadataItems,
        Id recordId,
        Set<String> filesToBeDeleted
    ) {
        deleteTestSelections(recordId, filesToBeDeleted);
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        if (!testClassesMetadataItems.isEmpty()) {
            Blob testClassesContent = Blob.valueOf(JSON.serialize(testClassesMetadataItems, true));
            contentVersions.add(getContentVersion(TEST_CLASSES_FILE_NAME, testClassesContent, recordId));
        }

        if (!testSuitesMetadataItems.isEmpty()) {
            Blob testSuitesContent = Blob.valueOf(JSON.serialize(testSuitesMetadataItems, true));
            contentVersions.add(getContentVersion(TEST_SUITES_FILE_NAME, testSuitesContent, recordId));
        }
        Utilities.performDML(contentVersions, 'insert', AccessLevel.USER_MODE);
    }

    // PRIVATE

    private static String getApexTestId(String recordId, String userStoryId) {
        String result = recordId;
        if (String.isBlank(result)) {
            List<copado__Test__c> apexTests = new TestsSelector()
                .byUserStoriesAndExtensionTools(new Set<Id>{ userStoryId }, new Set<String>{ APEX_TEST });
            result = !apexTests.isEmpty() ? apexTests[0].Id : null;
        }
        return result;
    }

    private static copado__User_Story__c getUserStory(String userStoryId) {
        List<copado__User_Story__c> result = new UserStoriesSelector()
            .byIdsWithUserStoryMetadataTypes(
                new Set<Id>{ userStoryId },
                new Set<String>{ APEX_CLASS, APEX_TRIGGER, APEX_TEST_SUITE },
                new Set<String>{ ADD }
            );
        if (result.isEmpty()) {
            throw new ApplicationException(Label.User_Story_Not_Found);
        }
        return result[0];
    }

    private static ApexTestInfo getValidApexTestInfo(ApexTestInfo apexTestInfo) {
        return apexTestInfo == null ? new ApexTestInfo() : apexTestInfo;
    }

    private static List<MetaDataItem> getTestClassesAndSuites(String recordId, copado__User_Story__c userStory, ApexTestInfo apexTestInfo) {
        Boolean isCommitContext = isCommitContext(apexTestInfo);
        Boolean isApexCommitted = false;
        UserStoryMetadata usMetadata = getUserStoryMetadata(userStory.copado__User_Story_Metadata__r);

        /*
            TODO: This comment needs to be updated when the changes are done on addApexTests

            The getApexTestsAndSuitesMetadata() of AddApexTestsController is called from the two places
            1. HandleApexTestRecord.cls
                1. Called when we create test records in a commit execution
                2. fileWithSelectedChanges != null in a commit context
            2. addApexTests.js lwc
                1. Called when the test record page is loaded
                2. fileWithSelectedChanges = null when the controller is called from the lwc addApexTests.js
        */

        if (isCommitContext) {
            CommitChanges committedChanges = new CommitChanges(apexTestInfo.fileWithSelectedChanges, userStory.Id);
            isApexCommitted = isApexCommitted(committedChanges);
            usMetadata = updateUserStoryMetadata(usMetadata, apexTestInfo, committedChanges);
            if (!usMetadata.hasApex() && !usMetadata.hasTestSuites()) {
                deleteTestRecord(recordId);
                clearApexTestDetails(userStory.Id);
                return new List<MetaDataItem>();
            }
        }

        List<MetaDataItem> result = getTestClassesAndSuitesFromOrg(recordId, userStory, usMetadata, apexTestInfo);
        /* If the committed changes have any Apex committed, we need to clear the test fields on thw US.
            This is done after the callout since we cannot have uncommitted work pending before calling out
        */
        if (isCommitContext && (isApexCommitted || apexTestInfo?.removeExistingSelection)) {
            clearApexTestDetails(userStory.Id);
        }
        return result;
    }

    private static Boolean isApexCommitted(CommitChanges committedChanges) {
        List<CommitChanges.Change> addChanges = committedChanges.byTypeAndOperation(
            new Set<String>{ APEX_CLASS, APEX_TRIGGER },
            new Set<String>{ ADD }
        );
        return !addChanges?.isEmpty();
    }

    private static Boolean isCommitContext(ApexTestInfo apexTestInfo) {
        return apexTestInfo.fileWithSelectedChanges != null ? true : false;
    }

    private static UserStoryMetadata updateUserStoryMetadata(
        UserStoryMetadata usMetadata,
        ApexTestInfo apexTestInfo,
        CommitChanges committedChanges
    ) {
        if (apexTestInfo.removeExistingSelection) {
            usMetadata.clear();
        }
        List<CommitChanges.Change> addChanges = committedChanges.byTypeAndOperation(
            new Set<String>{ APEX_CLASS, APEX_TRIGGER, APEX_TEST_SUITE },
            new Set<String>{ ADD }
        );
        List<CommitChanges.Change> otherOperationChanges = committedChanges.byTypeAndOperation(
            new Set<String>{ APEX_CLASS, APEX_TRIGGER, APEX_TEST_SUITE },
            new Set<String>{ DELETE_OPERATION, RETRIEVE_ONLY }
        );

        for (CommitChanges.Change change : addChanges) {
            usMetadata.add(change.n, change.t);
        }
        for (CommitChanges.Change change : otherOperationChanges) {
            usMetadata.remove(change.n, change.t);
        }
        return usMetadata;
    }

    private static UserStoryMetadata getUserStoryMetadata(List<copado__User_Story_Metadata__c> userStoryMetadata) {
        return new UserStoryMetadata(userStoryMetadata);
    }

    private static void deleteTestRecord(String recordId) {
        deleteTestSelections(recordId, new Set<String>());
        deleteApexTests(getApexTests(recordId));
    }

    private static void deleteTestSelections(String recordId, Set<String> fileNames) {
        if (String.isNotBlank(recordId)) {
            fileNames = fileNames.isEmpty() ? new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME } : fileNames;
            List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, fileNames);
            if (!contentDocumentLinks.isEmpty()) {
                List<ContentDocument> contentDocuments = new List<ContentDocument>();
                for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
                    contentDocuments.add(new ContentDocument(Id = contentDocumentLink.ContentDocumentId));
                }
                new Utilities.DeleteSObjectWithoutSharing().execute(contentDocuments);
            }
        }
    }

    private static void deleteApexTests(List<copado__Test__c> apexTests) {
        Utilities.performDML(apexTests, 'delete', AccessLevel.USER_MODE);
    }

    private static List<copado__Test__c> getApexTests(String recordId) {
        List<copado__Test__c> result = new List<copado__Test__c>();
        if (String.isNotBlank(recordId)) {
            result.add(new copado__Test__c(Id = recordId));
        }
        return result;
    }

    private static void clearApexTestDetails(Id userStoryId) {
        copado__User_Story__c userStory = new copado__User_Story__c(
            Id = userStoryId,
            copado__Apex_Code_Coverage__c = 0,
            copado__Classes_Without_Coverage__c = 0,
            copado__Triggers_Without_Coverage__c = 0,
            copado__Failing_Methods__c = 0
        );
        Utilities.performDML(new List<copado__User_Story__c>{ userStory }, 'update', AccessLevel.USER_MODE);
    }

    private static Id createApexTest(copado__User_Story__c userStory, String apexTestName) {
        List<copado__Test__c> result;
        List<copado__ExtensionConfiguration__c> extensionConfigurations = new ExtensionConfigurationsSelector()
            .byActiveExtensionTools(new Set<String>{ APEX_TEST });
        if (extensionConfigurations.isEmpty()) {
            throw new ApplicationException(Label.Extension_Configuration_Missing);
        }
        result = new List<copado__Test__c>{
            new copado__Test__c(
                Name = apexTestName,
                copado__ExtensionConfiguration__c = extensionConfigurations[0].Id,
                copado__User_Story__c = userStory.Id,
                copado__ReadyToRun__c = true
            )
        };
        Utilities.performDML(result, 'insert', AccessLevel.USER_MODE);
        return result[0].Id;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<MetaDataItem> extractSelectedTestClasses(
        String testClassesJson,
        String recordId,
        Set<String> userStoryClasses,
        ContentVersion testsClassesContent
    ) {
        if (String.isBlank(testClassesJson)) {
            return new List<MetaDataItem>();
        }
        Set<String> manuallySelectedClasses = getManualSelections(testsClassesContent);
        return MetaDataItem.parse(testClassesJson, userStoryClasses, manuallySelectedClasses);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<MetaDataItem> extractSelectedTestSuites(
        List<TestSuiteMembership> testSuiteMemberships,
        List<MetaDataItem> testClassesMetadatas,
        Set<String> selectedTestSuites,
        Set<String> committedTestSuites
    ) {
        if (testSuiteMemberships.isEmpty()) {
            return new List<MetaDataItem>();
        }
        return MetaDataItem.parseTestSuites(testSuiteMemberships, testClassesMetadatas, committedTestSuites, selectedTestSuites);
    }

    private static Set<String> getManualSelections(ContentVersion contentVersion) {
        Set<String> result = new Set<String>();
        for (MetaDataItem metadata : getPreselections(contentVersion)) {
            if (metadata.s) {
                result.add(metadata.n);
            }
        }
        return result;
    }

    private static List<MetaDataItem> getPreselections(ContentVersion contentVersion) {
        try {
            List<MetaDataItem> result = new List<MetaDataItem>();
            if (contentVersion != null) {
                String data = contentVersion.VersionData.toString();
                result = (String.isNotBlank(data)) ? MetaDataItem.parseForFileJSON(data) : result;
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    private static Map<String, ContentDocumentLink> getContentDocumentLink(String recordId) {
        Map<String, ContentDocumentLink> result = new Map<String, ContentDocumentLink>();
        if (String.isBlank(recordId)) {
            return result;
        }
        for (
            ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector()
                .byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME })
        ) {
            result.put(contentDocumentLink.ContentDocument.Title, contentDocumentLink);
        }
        return result;
    }

    private static Map<Id, ContentVersion> getContentVersionFromContentDocument(List<ContentDocumentLink> contentDocumentLinks) {
        Map<Id, ContentVersion> result = new Map<Id, ContentVersion>();
        Set<Id> contentDocumentIds = new Set<Id>();
        if (contentDocumentLinks.isEmpty()) {
            return result;
        }
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }
        for (ContentVersion contentVersion : new ContentVersionsSelector().byContentDocumentIdWithLatest(contentDocumentIds)) {
            result.put(contentVersion.ContentDocumentId, contentVersion);
        }
        return result;
    }

    private static String getApexTestValue() {
        String result = '';
        if (Test.isRunningTest()) {
            //As "Apex Tests" value is a manual value we have to use a standard one for testing purposes
            List<String> picklistValues = Utilities.getPicklistValues(
                SObjectType.copado__ExtensionConfiguration__c.getName(),
                // PMD is giving a false positive here.
                copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
            );

            result = !picklistValues.isEmpty() ? picklistValues[0] : '';
        } else {
            result = 'Apex Tests';
        }
        return result;
    }

    private static ContentVersion getContentVersion(String fileName, Blob content, Id recordId) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = fileName + '.json';
        contentVersion.Title = fileName;
        contentVersion.VersionData = content;
        contentVersion.FirstPublishLocationId = recordId;
        return contentVersion;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<TestSuiteMembership> getAllTestSuiteMembershipFromOrg(
        Boolean isCommitContext,
        Boolean hasTestSuites,
        Set<String> userStoryCommittedTestSuites,
        Set<String> selectedTestSuites,
        Id credentialId
    ) {
        Set<String> apexTestSuites = new Set<String>(userStoryCommittedTestSuites);
        apexTestSuites.addAll(selectedTestSuites);

        return isCommitContext
            ? (hasTestSuites ? new GetAllTestSuiteMembershipFromOrg(credentialId, apexTestSuites).execute() : new List<TestSuiteMembership>())
            : new GetAllTestSuiteMembershipFromOrg(credentialId).execute();
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<MetaDataItem> getTestClassesAndSuitesFromOrg(
        String recordId,
        copado__User_Story__c userStory,
        UserStoryMetadata usMetadata,
        ApexTestInfo apexTestInfo
    ) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        Boolean isCommitContext = isCommitContext(apexTestInfo);
        Map<String, ContentDocumentLink> contentDocumentLinksByTitle = new Map<String, ContentDocumentLink>();
        Map<Id, ContentVersion> contentVersionsByContentDocumentId = new Map<Id, ContentVersion>();
        Set<String> selectedTestSuites = new Set<String>();

        // We only need to read the apex class and test suite files attached on the test record, when the
        // re-commit feature branch flag is false for a commit operation
        if (!apexTestInfo.removeExistingSelection) {
            contentDocumentLinksByTitle = getContentDocumentLink(recordId);
            contentVersionsByContentDocumentId = getContentVersionFromContentDocument(contentDocumentLinksByTitle.values());
            selectedTestSuites = getManualSelections(
                contentVersionsByContentDocumentId.get(contentDocumentLinksByTitle.get(TEST_SUITES_FILE_NAME)?.ContentDocumentId)
            );
        }

        copado.GlobalAPI.ProxyOrgResponse testClassesResponse = new GetAllTestClassesFromOrg(userStory.copado__Org_Credential__c).execute();
        List<TestSuiteMembership> testSuiteMemberships = getAllTestSuiteMembershipFromOrg(
            isCommitContext,
            usMetadata.hasTestSuites(),
            usMetadata.userStoryApexTestSuites,
            selectedTestSuites,
            userStory.copado__Org_Credential__c
        );

        if (apexTestInfo.removeExistingSelection) {
            deleteTestSelections(recordId, new Set<String>());
        }

        String apexTestName = String.format(APEX_TEST_NAME_TEMPLATE, new List<Object>{ userStory.Name });
        recordId = String.isBlank(recordId) ? createApexTest(userStory, apexTestName) : recordId;
        List<MetaDataItem> testClassesMetadatas = extractSelectedTestClasses(
            testClassesResponse?.content,
            recordId,
            usMetadata.userStoryClasses,
            contentVersionsByContentDocumentId.get(contentDocumentLinksByTitle.get(TEST_CLASSES_FILE_NAME)?.ContentDocumentId)
        );
        List<MetaDataItem> testSuitesMetadatas = extractSelectedTestSuites(
            testSuiteMemberships,
            testClassesMetadatas,
            selectedTestSuites,
            usMetadata.userStoryApexTestSuites
        );
        if (isCommitContext) {
            createFilesForTestClassesAndTestSuites(
                testClassesMetadatas,
                testSuitesMetadatas,
                recordId,
                getFilesNamesToBeRemovedFromApexTest(testClassesMetadatas, testSuitesMetadatas)
            );
        }
        result.addAll(testClassesMetadatas);
        result.addAll(testSuitesMetadatas);
        return result;
    }

    private static Set<String> getFilesNamesToBeRemovedFromApexTest(List<MetaDataItem> testClassesMetadatas, List<MetaDataItem> testSuitesMetadatas) {
        Set<String> result = new Set<String>();
        if (!testClassesMetadatas.isEmpty()) {
            result.add(TEST_CLASSES_FILE_NAME);
        }
        if (!testSuitesMetadatas.isEmpty()) {
            result.add(TEST_SUITES_FILE_NAME);
        }
        return result;
    }
    private static Id getDestinationIdFromPromotion(Id recordId) {
        List<copado__Promotion__c> promotions = new PromotionsSelector().byIds(new Set<Id>{ recordId });
        if (promotions.isEmpty()) {
            throw new AuraHandledException(Label.Promotion_does_not_exists);
        }
        return promotions[0]?.copado__Destination_Org_Credential__c;
    }
}