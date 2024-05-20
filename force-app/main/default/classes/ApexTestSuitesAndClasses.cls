@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class ApexTestSuitesAndClasses {
    private final static String APEX_TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String APEX_TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TEST_SUITE = 'ApexTestSuite';
    private static final String ADD = 'Add';

    // PUBLIC

    @AuraEnabled
    public static List<MetaDataItem> getRecords(String recordId) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        try {
            List<ContentVersion> fileVersions = getFileVersions(recordId, new Set<String>{ APEX_TEST_CLASSES_FILE_NAME, APEX_TEST_SUITES_FILE_NAME });
            result = retrieveSelectedTestSuitesAndClasses(fileVersions);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
        return result;
    }

    @AuraEnabled
    public static Boolean autoAddTests(String testId, String userStoryId) {
        Boolean isTestClassAdded = false;
        if (String.isBlank(testId) || String.isBlank(userStoryId)) {
            throw new ApplicationException(Label.Invalid_Test_Id_Or_User_Story_Id_Message);
        }

        List<copado__User_Story__c> userStories = new UserStoriesSelector()
            .byIdsWithUserStoryMetadataTypes(new Set<Id>{ userStoryId }, new Set<String>{ APEX_CLASS }, new Set<String>{ ADD });
        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.No_User_Story_Found_For_Auto_Add_Tests);
        }

        Set<String> searchTerms = getSearchTermForAutoAddTests(userStories[0].copado__User_Story_Metadata__r);
        if (!searchTerms.isEmpty()) {
            List<MetaDataItem> testClassesBasedOnSearchTerm = getTestClassesFromSearchTerm(userStories[0].copado__Org_Credential__c, searchTerms);
            isTestClassAdded = addAutoIdentifiedTestsToExistingTestClasses(testId, testClassesBasedOnSearchTerm);
        }
        return isTestClassAdded;
    }

    @AuraEnabled
    public static void removeMetadataItems(String testId, String metadataItemsToBeRemoved) {
        try {
            Map<String, List<String>> metadatasByType = getSuitesAndClassesToBeDeleted(metadataItemsToBeRemoved);
            Set<String> fileNames = getFilesNamesToBeRemovedFromApexTest(metadatasByType);
            List<ContentVersion> fileVersions = getFileVersions(testId, fileNames);
            List<MetaDataItem> testClassesMetadataItems = new List<MetaDataItem>();
            List<MetaDataItem> testSuitesMetadataItems = new List<MetaDataItem>();

            for (ContentVersion fileVersion : fileVersions) {
                if (fileVersion.Title == APEX_TEST_CLASSES_FILE_NAME) {
                    testClassesMetadataItems = getMetadataItemsAfterRemoval(fileVersion, metadatasByType.get(APEX_CLASS));
                } else if (fileVersion.Title == APEX_TEST_SUITES_FILE_NAME) {
                    testSuitesMetadataItems = getMetadataItemsAfterRemoval(fileVersion, metadatasByType.get(APEX_TEST_SUITE));
                }
            }
            AddApexTestsController.createFilesForTestClassesAndTestSuites(testClassesMetadataItems, testSuitesMetadataItems, testId, fileNames);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static Map<String, List<String>> getSuitesAndClassesToBeDeleted(String metadataItemsToBeRemoved) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        result.put(APEX_CLASS, new List<String>());
        result.put(APEX_TEST_SUITE, new List<String>());
        List<MetaDataItem> itemsList = MetaDataItem.parseForFileJSON(metadataItemsToBeRemoved);
        for (MetaDataItem item : itemsList) {
            result.get(item.t).add(item.n);
        }
        return result;
    }

    private static List<MetaDataItem> getMetadataItemsAfterRemoval(ContentVersion content, List<String> metadataItemsToBeRemoved) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        if (!metadataItemsToBeRemoved.isEmpty()) {
            List<MetaDataItem> contentItems = MetaDataItem.parseForFileJSON(content.VersionData.toString());
            for (MetadataItem contentItem : contentItems) {
                if (!metadataItemsToBeRemoved.contains(contentItem.n)) {
                    result.add(contentItem);
                }
            }
        }
        return result;
    }

    private static Set<String> getFilesNamesToBeRemovedFromApexTest(Map<String, List<String>> metadataItemsToBeRemoved) {
        Set<String> result = new Set<String>();
        if (!metadataItemsToBeRemoved.get(APEX_CLASS).isEmpty()) {
            result.add(APEX_TEST_CLASSES_FILE_NAME);
        }
        if (!metadataItemsToBeRemoved.get(APEX_TEST_SUITE).isEmpty()) {
            result.add(APEX_TEST_SUITES_FILE_NAME);
        }
        return result;
    }

    private static List<ContentVersion> getFileVersions(String testId, Set<String> fileNames) {
        List<ContentVersion> result = new List<ContentVersion>();
        List<ContentDocumentLink> documentLinks = new ContentDocumentLinksSelector()
            .versionDataByLinkedEntityIdsAndTitles(new Set<Id>{ testId }, fileNames);
        for (ContentDocumentLink documentLink : documentLinks) {
            result.add(
                new ContentVersion(
                    VersionData = documentLink.ContentDocument.LatestPublishedVersion.VersionData,
                    Title = documentLink.ContentDocument.LatestPublishedVersion.Title
                )
            );
        }
        return result;
    }

    private static List<MetaDataItem> retrieveSelectedTestSuitesAndClasses(List<ContentVersion> fileVersions) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        for (MetaDataItem metadataItem : getMetadataItemFromContentVersion(fileVersions)) {
            if (metadataItem.s) {
                result.add(metadataItem);
            }
        }

        return result;
    }

    private static List<MetaDataItem> getMetadataItemFromContentVersion(List<ContentVersion> fileVersions) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        for (ContentVersion fileVersion : fileVersions) {
            String content = fileVersion.VersionData.toString();
            if (String.isNotBlank(content)) {
                result.addAll(MetaDataItem.parseForFileJSON(fileVersion.VersionData.toString()));
            }
        }
        return result;
    }

    @TestVisible
    private static Set<String> getSearchTermForAutoAddTests(List<copado__User_Story_Metadata__c> userStoryMetadatas) {
        Set<String> result = new Set<String>();
        for (copado__User_Story_Metadata__c userStoryMetadata : userStoryMetadatas) {
            result.add('new ' + userStoryMetadata.copado__Metadata_API_Name__c + '\\(');
            result.add(userStoryMetadata.copado__Metadata_API_Name__c + '.*');
        }
        return result;
    }

    private static List<MetaDataItem> getTestClassesFromSearchTerm(Id credentialId, Set<String> searchTerms) {
        List<MetaDataItem> result = new List<MetaDataItem>();
        copado.GlobalAPI.ProxyOrgResponse response = new GetAllTestClassesFromOrg(credentialId, searchTerms).execute();
        if (String.isNotBlank(response.content)) {
            result = MetaDataItem.parse(response.content, new Set<String>(), new Set<String>());
        }
        return result;
    }

    private static Boolean addAutoIdentifiedTestsToExistingTestClasses(Id testId, List<MetaDataItem> testClassesBasedOnSearchTerm) {
        Boolean isTestClassAdded = false;
        List<MetaDataItem> sourceOrgTestClasses = new List<MetaDataItem>();
        if (!testClassesBasedOnSearchTerm.isEmpty()) {
            List<ContentVersion> contentVersions = getFileVersions(testId, new Set<String>{ APEX_TEST_CLASSES_FILE_NAME });
            sourceOrgTestClasses = getMetadataItemFromContentVersion(contentVersions);
            for (MetaDataItem testClass : testClassesBasedOnSearchTerm) {
                Integer index = sourceOrgTestClasses.indexOf(testClass);
                if (index >= 0 && !sourceOrgTestClasses.get(index).s) {
                    sourceOrgTestClasses.get(index).s = isTestClassAdded = true;
                } else if (index == -1) {
                    testClass.s = isTestClassAdded = true;
                    sourceOrgTestClasses.add(testClass);
                }
            }
        }

        if (isTestClassAdded) {
            AddApexTestsController.createFilesForTestClassesAndTestSuites(
                sourceOrgTestClasses,
                new List<MetaDataItem>(),
                testId,
                new Set<String>{ APEX_TEST_CLASSES_FILE_NAME }
            );
        }

        return isTestClassAdded;
    }
}