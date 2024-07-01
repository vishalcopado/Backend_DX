public with sharing class UpdateTestsInfoOnStories {
    private static final String APEX_TEST_OUTPUT_FILE = 'apex-tests-output.json';
    private static final String APEX_CLASS = 'ApexClass';
    private static final String APEX_TRIGGER = 'ApexTrigger';
    private final static String ADD = 'Add';
    private final static String RETRIEVE_ONLY = 'RetrieveOnly';
    private final static String DELETE_OPERATION = 'Delete';
    private static Set<String> userStoryUncoveredItems = new Set<String>();

    // PUBLIC

    public static ApexTestDetails execute(List<UpdateTestsInfoOnStories.Request> requests) {

        ApexTestsResult testsResult = getApexTestResultFrom(requests[0].testResults, requests[0].consolidatedResultId);

        // if this logic is executing as part of a commit quality gate execution, then we need to consider the committed changes file content also
        Map<String, UserStoryMetadata> userStoryToMetadataMapping = getUserStoriesMetadataDetails(requests[0].userStories, testsResult);

        if (isCommitContext(requests)) {
            userStoryToMetadataMapping = updateUserStoryMetadata(
                userStoryToMetadataMapping,
                requests[0].fileWithSelectedChanges,
                requests[0].userStories[0],
                requests[0].recreateFeatureBranch,
                testsResult
            );
        }

        if (!userStoryUncoveredItems.isEmpty()) {
            updateResultWithNonCoveredClasses(testsResult, requests[0].userStories);
        }
        ApexTestDetails result = new ApexTestDetails(testsResult, userStoryToMetadataMapping);
        if (requests[0].userStories.size() == 1) {
            //Note - The User story fields will only be updated if all the tests, running together, belong to one US.
            updateTestInformation(requests[0].userStories[0], testsResult, userStoryToMetadataMapping, result);
        }
        return result;
    }

    // PRIVATE

    private static Boolean isCommitContext(List<UpdateTestsInfoOnStories.Request> requests) {
        return (requests[0].fileWithSelectedChanges != null &&
            requests[0].recreateFeatureBranch != null &&
            requests[0].userStories.size() == 1)
            ? true
            : false;
    }

    private static ApexTestsResult getApexTestResultFrom(List<Id> testResults, Id consolidatedResultId) {
        ApexTestsResult result;

        // Note: If tests results are not given, it means the execution is a quality gate and therefore there is only a consolidated result
        Id availableResultId = testResults.isEmpty() ? consolidatedResultId : testResults[0];
        List<ContentDocumentLink> apexTestResultFileLink = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ availableResultId }, new Set<String>{ APEX_TEST_OUTPUT_FILE });
        if (!apexTestResultFileLink.isEmpty()) {
            List<ContentVersion> contentVersion = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ apexTestResultFileLink[0].ContentDocumentId });
            if (!contentVersion.isEmpty()) {
                String apexTestResultFileContent = contentVersion[0].VersionData.toString();
                result = new ApexTestsResult().fromJson(apexTestResultFileContent);
            }
        }
        if (result == null) {
            throw new ApplicationException(Label.Apex_Test_Result_Unavailable);
        }
        return result;
    }

    private static void updateResultWithNonCoveredClasses(ApexTestsResult testsResult, List<copado__User_Story__c> userStories) {
        // @Note: Test result don't provide information of the classes that are not covered by the tests,
        // therefore, we do a callout in order to know the amount of "coveragable" lines that those contain.
        GetApexCodeCoverageFromOrg.SoqlApiResponse queryResponse = new GetApexCodeCoverageFromOrg(
                userStoryUncoveredItems,
                userStories[0].copado__Org_Credential__c
            )
            .execute();

        if (queryResponse?.records != null) {
            for (GetApexCodeCoverageFromOrg.MetadataCoverage metadataCoverage : queryResponse?.records) {
                ApexTestsResult.MetadataCoverage unaccountedCoverage = new ApexTestsResult.MetadataCoverage();
                unaccountedCoverage.Name = metadataCoverage.ApexClassOrTrigger.Name;
                // @Note: Retrieved classes by the callout don't have any coverage given by the US tests, their coverage comes from other classes,
                // because of that, the only information we need to know is the total amount of lines, which for the US tests are all uncovered.
                unaccountedCoverage.totalCovered = 0;
                unaccountedCoverage.totalLines = metadataCoverage.numLinesCovered + metadataCoverage.numLinesUncovered;

                testsResult.result.coverage.coverage.add(unaccountedCoverage);
            }
        }
    }

    private static Map<String, UserStoryMetadata> getUserStoriesMetadataDetails(
        List<copado__User_Story__c> userStories,
        ApexTestsResult testsResult
    ) {
        Map<String, UserStoryMetadata> result = new Map<String, UserStoryMetadata>();
        for (copado__User_Story__c userStory : userStories) {
            result.put(userStory.Id, new UserStoryMetadata());
            findCoveredAndUncoveredApex(userStory.copado__User_Story_Metadata__r, testsResult, result);
        }
        return result;
    }

    private static void findCoveredAndUncoveredApex(
        List<copado__User_Story_Metadata__c> userStoryMetadata,
        ApexTestsResult testsResult,
        Map<String, UserStoryMetadata> userStoryToMetadataMapping
    ) {
        for (copado__User_Story_Metadata__c usMetadata : userStoryMetadata) {
            if (!isTestClass(usMetadata.copado__Metadata_API_Name__c, testsResult)) {
                addDetailsInUserStoryMetadata(usMetadata, userStoryToMetadataMapping);
                if (!hasSomeCoverage(usMetadata.copado__Metadata_API_Name__c, testsResult)) {
                    userStoryUncoveredItems.add(usMetadata.copado__Metadata_API_Name__c);
                }
            }
        }
    }

    private static void addDetailsInUserStoryMetadata(
        copado__User_Story_Metadata__c usMetadata,
        Map<String, UserStoryMetadata> userStoryToMetadataMapping
    ) {
        UserStoryMetadata userStoryMetadata = userStoryToMetadataMapping.get(usMetadata.copado__User_Story__c);
        userStoryMetadata.toClassesAndTriggers(new List<copado__User_Story_Metadata__c>{ usMetadata });
    }

    private static Boolean isTestClass(String metadataItem, ApexTestsResult testsResult) {
        ApexTestsResult.TestExecution testExecution = new ApexTestsResult.TestExecution();
        ApexTestsResult.MetadataClass metadata = new ApexTestsResult.MetadataClass();
        metadata.Name = metadataItem;
        testExecution.ApexClass = metadata;
        return testsResult.result.tests.contains(testExecution);
    }

    // @Note: Classes or Triggers without coverage never appear in the test result summary given by the SFDX command "sfdx force:apex:test:run"
    private static Boolean hasSomeCoverage(String metadataItem, ApexTestsResult testsResult) {
        ApexTestsResult.MetadataCoverage metadataCoverage = new ApexTestsResult.MetadataCoverage();
        metadataCoverage.name = metadataItem;
        return testsResult.result.coverage.coverage.contains(metadataCoverage);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Map<String, UserStoryMetadata> updateUserStoryMetadata(
        Map<String, UserStoryMetadata> userStoryToMetadataMapping,
        Id fileWithSelectedChanges,
        copado__User_Story__c userStory,
        Boolean recreateFeatureBranch,
        ApexTestsResult testsResult
    ) {
        if (recreateFeatureBranch) {
            userStoryToMetadataMapping.get(userStory.Id).clear();
            userStoryUncoveredItems.clear();
        }
        CommitChanges commitChanges = new CommitChanges(fileWithSelectedChanges, userStory.Id);
        removeOtherMetadata(userStoryToMetadataMapping.get(userStory.Id), commitChanges);
        List<copado__User_Story_Metadata__c> usMetadata = commitChanges.toUserStoryMetadata(
            commitChanges.byTypeAndOperation(new Set<String>{ APEX_CLASS, APEX_TRIGGER }, new Set<String>{ ADD }));
        findCoveredAndUncoveredApex(usMetadata, testsResult, userStoryToMetadataMapping);
        return userStoryToMetadataMapping;
    }

    private static void removeOtherMetadata(UserStoryMetadata usMetadata, CommitChanges commitChanges) {
        UserStoryMetadata otherOperationsApex = new UserStoryMetadata();
        otherOperationsApex.toClassesAndTriggers(
            commitChanges.byTypeAndOperation(new Set<String>{ APEX_CLASS, APEX_TRIGGER }, new Set<String>{ DELETE_OPERATION, RETRIEVE_ONLY })
        );
        usMetadata.removeAll(otherOperationsApex.userStoryClasses, APEX_CLASS);
        usMetadata.removeAll(otherOperationsApex.userStoryTriggers, APEX_TRIGGER);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void updateTestInformation(
        copado__User_Story__c userStory,
        ApexTestsResult testsResult,
        Map<String, UserStoryMetadata> userStoryToMetadataMapping,
        ApexTestDetails apexTestDetails
    ) {
        List<copado__User_Story__c> userStories = new List<copado__User_Story__c>();
        if (userStoryToMetadataMapping.containsKey(userStory.Id)) {
            UserStoryMetadata userStoryMetadata = userStoryToMetadataMapping.get(userStory.Id);
            Set<String> metadata = new Set<String>(userStoryMetadata.userStoryClasses);
            metadata.addAll(userStoryMetadata.userStoryTriggers);

            copado__User_Story__c userStoryWithCoverageResult = getUserStoryWithCoverage(userStory, userStoryMetadata, testsResult, metadata);
            updateApexTestDetails(apexTestDetails, userStoryWithCoverageResult);

            userStories.add(userStoryWithCoverageResult);
            userStories = Security.stripInaccessible(AccessType.UPDATABLE, userStories).getRecords();

            if (Schema.sObjectType.copado__User_Story__c.isUpdateable()) {
                update userStories;
            } else {
                throw new ApplicationException(Label.NonUpdateableUserStory);
            }
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static copado__User_Story__c getUserStoryWithCoverage(
        copado__User_Story__c userStory,
        UserStoryMetadata userStoryMetadata,
        ApexTestsResult testsResult,
        Set<String> metadata
    ) {
        return new copado__User_Story__c(
            Id = userStory.Id,
            copado__Apex_Code_Coverage__c = testsResult.getTestRunCoverage(metadata),
            copado__Failing_Methods__c = testsResult.result.summary.failing,
            copado__Classes_Without_Coverage__c = testsResult.getMetadataWithoutCoverage(
                    (Integer) userStory.copado__Minimum_Apex_Code_Coverage__c,
                    userStoryMetadata.userStoryClasses
                )
                .size(),
            copado__Triggers_Without_Coverage__c = testsResult.getMetadataWithoutCoverage(
                    (Integer) userStory.copado__Minimum_Apex_Code_Coverage__c,
                    userStoryMetadata.userStoryTriggers
                )
                .size()
        );
    }

    private static void updateApexTestDetails(ApexTestDetails apexTestDetails, copado__User_Story__c userStory) {
        apexTestDetails.codeCoverage = (Integer) userStory.copado__Apex_Code_Coverage__c;
        apexTestDetails.classesWithoutCoverage = (Integer) userStory.copado__Classes_Without_Coverage__c;
        apexTestDetails.triggersWithoutCoverage = (Integer) userStory.copado__Triggers_Without_Coverage__c;
    }

    // INNER

    public class ApexTestDetails {
        public ApexTestsResult testsResult;
        public Map<String, UserStoryMetadata> userStoryToMetadataMapping;
        public Integer codeCoverage;
        public Integer classesWithoutCoverage;
        public Integer triggersWithoutCoverage;

        public ApexTestDetails(ApexTestsResult testsResult, Map<String, UserStoryMetadata> userStoryToMetadataMapping) {
            this.testsResult = testsResult;
            this.userStoryToMetadataMapping = userStoryToMetadataMapping;
        }
    }

    public class Request {
        List<Id> testResults;
        Id consolidatedResultId;
        List<copado__User_Story__c> userStories;
        Id fileWithSelectedChanges;
        Boolean recreateFeatureBranch;
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Request(List<Id> testResults,Id consolidatedResultId,List<copado__User_Story__c> userStories,String fileWithSelectedChanges,String recreateFeatureBranch) {
            this.testResults = testResults;
            this.consolidatedResultId = consolidatedResultId;
            this.userStories = userStories;
            this.fileWithSelectedChanges = String.isBlank(fileWithSelectedChanges) ? null : fileWithSelectedChanges;
            this.recreateFeatureBranch = String.isBlank(recreateFeatureBranch) ? null : Boolean.valueOf(recreateFeatureBranch);
        }
    }
}