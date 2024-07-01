@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ApexTestsUnifier extends copado.UserStoryBundleTestsUnifier {
    private static final List<String> TEST_LEVELS_IN_ORDER = Utilities.getPicklistValues(
        SObjectType.copado__User_Story__c.getName(),
        copado__User_Story__c.copado__Promotion_Test_Level__c.getDescribe(FieldDescribeOptions.DEFAULT).getName() //NOPMD // PMD is giving a false positive here.
    );
    private static Integer lastTestLevelIndex = TEST_LEVELS_IN_ORDER.size() - 1;
    private List<MetaDataItem> metadataItems = new List<MetaDataItem>();
    private List<copado__User_Story__c> bundledStories = new List<copado__User_Story__c>();

    // GLOBAL
    global override List<copado__Test__c> unifyTests(List<copado__Test__c> testToUnify) {
        List<copado__Test__c> result = new List<copado__Test__c>();

        if (!testToUnify.isEmpty()) {
            copado__Test__c originalTest = testToUnify[0];
            result.add(cloneTest(originalTest));
            this.metadataItems = getMetadataItems(testToUnify);

            Set<Id> storyIds = new Set<Id>();
            for (copado__Test__c record : testToUnify) {
                storyIds.add(record.copado__User_Story__c);
            }
            bundledStories = new UserStoriesSelector().byIds(storyIds);
        }

        return result;
    }

    global override void additionalLogicAfterUnify(List<copado__Test__c> unifiedTests) {
        if (!unifiedTests.isEmpty() && !this.metadataItems.isEmpty()) {
            copado__Test__c unifiedTest = unifiedTests[0];
            AddApexTestsController.createContentVersion(unifiedTest.Id, this.metadataItems);

            String apexTestLevel = getApexTestLevel(unifiedTests);

            Utilities.performDML(
                new List<copado__User_Story__c>{
                    new copado__User_Story__c(Id = unifiedTest.copado__User_Story__c, copado__Promotion_Test_Level__c = apexTestLevel)
                },
                'update',
                AccessLevel.USER_MODE
            );
        }
    }

    // PRIVATE

    private copado__Test__c cloneTest(copado__Test__c originalTest) {
        copado__Test__c clonedTest = originalTest.clone(false, true, false, false);
        clonedTest.Name = String.format(Label.Unified_Test_Name, new List<String>{ originalTest.copado__Test_Tool__c });
        clonedTest = emptyInvalidFields(clonedTest);
        return clonedTest;
    }

    private List<MetaDataItem> getMetadataItems(List<copado__Test__c> testToUnify) {
        List<MetaDataItem> result = new List<MetaDataItem>();

        Set<Id> testIds = new Map<Id, copado__Test__c>(testToUnify).keySet();
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink documentLink : new ContentDocumentLinksSelector().byLinkedEntityId(testIds)) {
            contentDocumentIds.add(documentLink.ContentDocumentId);
        }

        Map<String, MetaDataItem> metadataItemByKey = new Map<String, MetaDataItem>();
        for (ContentVersion contentVersion : new ContentVersionsSelector().byContentDocumentIdWithLatest(contentDocumentIds)) {
            String versionData = contentVersion.VersionData.toString();
            List<MetaDataItem> testItems = (String.isNotBlank(versionData)) ? MetaDataItem.parseForFileJSON(versionData) : new List<MetaDataItem>();
            for (MetaDataItem item : testItems) {
                String key = item.t + item.ns + item.n;
                if (!metadataItemByKey.containsKey(key) || item.s == true) {
                    metadataItemByKey.put(key, item);
                }
            }
        }

        result.addAll(metadataItemByKey.values());

        return result;
    }

    private String getApexTestLevel(List<copado__Test__c> unifiedTests) {
        Set<Id> userStoryIds = new Set<Id>();
        for (copado__Test__c test : unifiedTests) {
            userStoryIds.add(test.copado__User_Story__c);
        }
        Integer currIndex = 0;

        for (copado__User_Story__c bundledUserStory : bundledStories) {
            String apexTestLevel = bundledUserStory.copado__Promotion_Test_Level__c;
            if (String.isNotBlank(apexTestLevel)) {
                Integer newIndex = TEST_LEVELS_IN_ORDER.indexOf(apexTestLevel);
                currIndex = (newIndex > currIndex) ? newIndex : currIndex;
                if (currIndex == lastTestLevelIndex) {
                    break;
                }
            }
        }

        return TEST_LEVELS_IN_ORDER[currIndex];
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private copado__Test__c emptyInvalidFields(copado__Test__c test) {
        Set<String> invalidFields = new Set<String>{
            copado__Test__c.copado__Test_Tool__c.getDescribe().getName(),
            copado__Test__c.copado__LatestJobExecution__c.getDescribe().getName()
        };

        Map<String, Object> testFields = new Map<String, Object>(test.getPopulatedFieldsAsMap());
        for (String testField : invalidFields) {
            testFields.remove(testField);
        }
        return (copado__Test__c) JSON.deserialize(JSON.serialize(testFields), copado__Test__c.class);
    }
}