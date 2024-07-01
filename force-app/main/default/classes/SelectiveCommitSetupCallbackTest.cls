@IsTest
private class SelectiveCommitSetupCallbackTest {
    private static final String SOURCE_ORG_FILE = 'test' + SelectiveCommitSetupCallback.SOURCE_ORG_FILE_SUFFIX;
    private static final String BASE_BRANCH_FILE = 'test' + SelectiveCommitSetupCallback.BASE_BRANCH_FILE_SUFFIX;
    private static final String DESTINATION_BRANCH_FILE = 'test' + SelectiveCommitSetupCallback.DESTINATION_BRANCH_FILE_SUFFIX;
    private static final String FEATURE_BRANCH_FILE = 'test' + SelectiveCommitSetupCallback.FEATURE_BRANCH_FILE_SUFFIX;

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void executeCallbackWithNoSelectiveCommitFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            String status = 'Success';
            copado__User_Story__c userStory = getUserStory();

            // EXERCISE

            SelectiveCommitSetupCallback callback = new SelectiveCommitSetupCallback();
            callback.execute(function, result, status);

            // VERIFY

            Assert.areEqual(0, getContentDocumentLinks(userStory.Id).size(), 'No content documnet links should be present');
        }
    }

    @IsTest
    private static void executeCallbackWithOneSetOfSelectiveCommitFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            String status = 'Success';
            copado__User_Story__c userStory = getUserStory();
            createFilesForSelectiveCommit(userStory.Id);
            Set<Id> contentDocumentLinkIdsBeforeExecution = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : getContentDocumentLinks(userStory.Id)) {
                contentDocumentLinkIdsBeforeExecution.add(contentDocumentLink.Id);
            }

            // EXERCISE

            SelectiveCommitSetupCallback callback = new SelectiveCommitSetupCallback();
            callback.execute(function, result, status);

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinksAfterExecution = getContentDocumentLinks(userStory.Id);
            Assert.areEqual(
                4,
                contentDocumentLinksAfterExecution.size(),
                'Four content documnet links should be present on the user story for the selective commits'
            );
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinksAfterExecution) {
                Assert.isTrue(contentDocumentLinkIdsBeforeExecution.contains(contentDocumentLink.Id), 'The content document link is incorrect');
            }
        }
    }

    @IsTest
    private static void executeCallbackWithMultipleSetOfSelectiveCommitFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            String status = 'Success';
            copado__User_Story__c userStory = getUserStory();
            createFilesForSelectiveCommit(userStory.Id);
            Set<Id> oldContentDocumentLinkIds = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : getContentDocumentLinks(userStory.Id)) {
                oldContentDocumentLinkIds.add(contentDocumentLink.Id);
            }
            TestUtilities.delay(1);
            createFilesForSelectiveCommit(userStory.Id);

            // EXERCISE

            SelectiveCommitSetupCallback callback = new SelectiveCommitSetupCallback();
            callback.execute(function, result, status);

            // VERIFY

            List<ContentDocumentLink> contentDocumentLinksAfterExecution = getContentDocumentLinks(userStory.Id);
            Assert.areEqual(
                4,
                contentDocumentLinksAfterExecution.size(),
                'Four content documnet links should be present on the user story for the selective commits'
            );
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinksAfterExecution) {
                Assert.isTrue(!oldContentDocumentLinkIds.contains(contentDocumentLink.Id), 'The content document link is incorrect');
            }
        }
    }

    // HELPER

    private static void makeData() {
        Credential credential = new Credential(new Environment().type('Production/Developer'));
        new UserStory().title('US 1').status('Draft').credential(credential).persist();
        copado__User_Story__c userStory = getUserStory();

        JobTemplate jobTemplate = new JobTemplate().name('SFDX Selective Commit Setup').type('Custom');
        JobStep jobStep = new JobStep(jobTemplate).name('SFDX Selective Commit Setup').type('Function');
        new Function().name('SFDX Selective Commit Setup').apiName('SFDX_Selective_Commit_Setup');
        new JobExecution(jobTemplate, new Environment()).dataJson('{"userStoryId":"' + userStory.Id + '", "filePrefix":"test"}').add(jobStep);
        new Result(jobStep).type('Function').status('Success').persist();
    }

    private static void createFilesForSelectiveCommit(Id userStoryId) {
        new ContentVersion_t()
            .title(SOURCE_ORG_FILE)
            .pathOnClient(SOURCE_ORG_FILE)
            .firstPublishLocationId(userStoryId)
            .versionData(Blob.valueOf(getLayoutMetadata()));
        new ContentVersion_t()
            .title(BASE_BRANCH_FILE)
            .pathOnClient(BASE_BRANCH_FILE)
            .firstPublishLocationId(userStoryId)
            .versionData(Blob.valueOf(getLayoutMetadata()));
        new ContentVersion_t()
            .title(DESTINATION_BRANCH_FILE)
            .pathOnClient(DESTINATION_BRANCH_FILE)
            .firstPublishLocationId(userStoryId)
            .versionData(Blob.valueOf(getLayoutMetadata()));
        new ContentVersion_t()
            .title(FEATURE_BRANCH_FILE)
            .pathOnClient(FEATURE_BRANCH_FILE)
            .firstPublishLocationId(userStoryId)
            .versionData(Blob.valueOf(getLayoutMetadata()))
            .persist();
    }

    private static copado__User_Story__c getUserStory() {
        return [SELECT Id FROM copado__User_Story__c LIMIT 1];
    }

    private static copado__Function__c getFunction() {
        return [SELECT Id FROM copado__Function__c LIMIT 1];
    }

    private static copado__Result__c getResult() {
        return [SELECT Id FROM copado__Result__c LIMIT 1];
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Id linkedEntityId) {
        Set<String> fileTitles = new Set<String>();
        fileTitles.add(SOURCE_ORG_FILE);
        fileTitles.add(BASE_BRANCH_FILE);
        fileTitles.add(DESTINATION_BRANCH_FILE);
        fileTitles.add(FEATURE_BRANCH_FILE);
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ linkedEntityId }, fileTitles);
    }

    private static String getLayoutMetadata() {
        String result =
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Layout xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<layoutSections>' +
            '<editHeading>true</editHeading>' +
            '<label>System Information</label>' +
            '<layoutColumns>' +
            '<layoutItems>' +
            '<behavior>Readonly</behavior>' +
            '<field>CreatedById</field>' +
            '</layoutItems>' +
            '<layoutItems>' +
            '<behavior>Required</behavior>' +
            '<field>Name</field>' +
            '</layoutItems>' +
            '</layoutColumns>' +
            '<layoutColumns>' +
            '<layoutItems>' +
            '<behavior>Readonly</behavior>' +
            '<field>LastModifiedById</field>' +
            '</layoutItems>' +
            '</layoutColumns>' +
            '<style>TwoColumnsTopToBottom</style>' +
            '</layoutSections>' +
            '<summaryLayout>' +
            '<masterLabel>Great Name</masterLabel>' +
            '<sizeX>4</sizeX>' +
            '<sizeY>2</sizeY>' +
            '<summaryLayoutItems>' +
            '<posX>0</posX>' +
            '<posY>0</posY>' +
            '<field>Name</field>' +
            '</summaryLayoutItems>' +
            '</summaryLayout>' +
            '</Layout>';
        return result;
    }
}