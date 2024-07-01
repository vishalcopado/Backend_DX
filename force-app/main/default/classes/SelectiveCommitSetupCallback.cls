@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SelectiveCommitSetupCallback implements copado.MCCallback {
    @TestVisible
    private static final String SOURCE_ORG_FILE_SUFFIX = '_source';
    @TestVisible
    private static final String BASE_BRANCH_FILE_SUFFIX = '_base';
    @TestVisible
    private static final String DESTINATION_BRANCH_FILE_SUFFIX = '_destination';
    @TestVisible
    private static final String FEATURE_BRANCH_FILE_SUFFIX = '_feature';

    // GLOBAL

    global void execute(copado__Function__c function, copado__Result__c result, String status) {
        copado__Result__c selectiveCommitSetupResult = getResult(result.Id);
        SelectiveCommitSetupPayload selectiveCommitSetupPayload = getSelectiveCommitSetupPayload(selectiveCommitSetupResult);
        Set<String> fileTitlesUsedInSelectiveCommitSetup = getFileTitlesUsedInSelectiveCommitSetup(selectiveCommitSetupPayload.filePrefix);
        List<ContentDocument> outdatedContentDocumnetsForSelectiveCommit = getOutdatedContentDocumentsForSelectiveCommit(
            selectiveCommitSetupPayload.userStoryId,
            fileTitlesUsedInSelectiveCommitSetup
        );
        deleteContentDocuments(outdatedContentDocumnetsForSelectiveCommit);
    }

    // PRIVATE

    private static copado__Result__c getResult(String recordId) {
        List<copado__Result__c> result = new ResultsSelector().byIds(new Set<Id>{ recordId });
        return result[0];
    }

    private static SelectiveCommitSetupPayload getSelectiveCommitSetupPayload(copado__Result__c selectiveCommitSetupResult) {
        SelectiveCommitSetupPayload result = (SelectiveCommitSetupPayload) JSON.deserialize(
            selectiveCommitSetupResult?.copado__JobStep__r?.copado__JobExecution__r?.copado__DataJson__c,
            SelectiveCommitSetupPayload.class
        );
        return result;
    }

    private static Set<String> getFileTitlesUsedInSelectiveCommitSetup(String filePrefix) {
        Set<String> result = new Set<String>();
        result.add(filePrefix + SOURCE_ORG_FILE_SUFFIX);
        result.add(filePrefix + BASE_BRANCH_FILE_SUFFIX);
        result.add(filePrefix + DESTINATION_BRANCH_FILE_SUFFIX);
        result.add(filePrefix + FEATURE_BRANCH_FILE_SUFFIX);
        return result;
    }

    private static List<ContentDocument> getOutdatedContentDocumentsForSelectiveCommit(String userStoryId, Set<String> titles) {
        List<ContentDocument> result = new List<ContentDocument>();
        Set<String> selectiveCommitFileTitles = new Set<String>();
        // This will give us the content document links of selective commit files attached on the user story in descending order of their created date
        for (
            ContentDocumentLink contentDocumentLink : new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ userStoryId }, titles)
        ) {
            if (selectiveCommitFileTitles.contains(contentDocumentLink.ContentDocument?.Title)) {
                result.add(new ContentDocument(Id = contentDocumentLink.ContentDocumentId));
            } else {
                /* 
                    The very first time we find a selective commit file, we don't add it to the result variable (we just skip it) 
                    as it contains the latest metadata details.
                */
                selectiveCommitFileTitles.add(contentDocumentLink.ContentDocument?.Title);
            }
        }
        return result;
    }

    private static void deleteContentDocuments(List<ContentDocument> contentDocumentsToBeDeleted) {
        new Utilities.DeleteSObjectWithoutSharing().execute(contentDocumentsToBeDeleted);
    }
}