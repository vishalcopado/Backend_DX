public with sharing class AddFileLinksOnPromotion {
    // PUBLIC
    @InvocableMethod(
        label='Add File Links On Promotion'
        description='This method deletes the old file links and add new links on promotion as per the result record'
        category='Deployment'
    )
    public static void execute(List<Request> requests) {
        copado__Result__c result = getResult(requests);
        String fileName = getFileName(requests);
        if (!isDataValid(result, fileName)) {
            return;
        }

        try {
            List<ContentDocumentLink> contentDocumentLinksOnResult = getContentDocumentLinks(new Set<Id>{ result.Id }, new Set<String>{ fileName });
            Id promotionId = getPromotionId(result);
            if (String.isNotBlank(promotionId)) {
                updateContentDocumentLinksOnPromotion(contentDocumentLinksOnResult, promotionId, fileName);
            }
        } catch (Exception ex) {
            String exceptionMessage = ex.getMessage() + ' ' + ex.getStackTraceString();
            throw new ApplicationException(exceptionMessage);
        }
    }

    // PRIVATE
    private static List<ContentDocumentLink> getContentDocumentLinks(Set<Id> entityIds, Set<String> fileNames) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(entityIds, fileNames);
    }

    private static void updateContentDocumentLinksOnPromotion(
        List<ContentDocumentLink> contentDocumentLinksOnResult,
        Id promotionId,
        String fileName
    ) {
        List<ContentDocumentLink> contentDocumentLinksOnPromotion = getContentDocumentLinks(new Set<Id>{ promotionId }, new Set<String>{ fileName });
        deleteContentDocumentLinks(contentDocumentLinksOnPromotion);
        if (!contentDocumentLinksOnResult.isEmpty()) {
            createContentDocumentLinksOnPromotion(getContentDocumentIds(contentDocumentLinksOnResult), promotionId);
        }
    }

    private static void createContentDocumentLinksOnPromotion(Set<Id> contentDocumentIds, Id promotionId) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Id contentDocumentId : contentDocumentIds) {
            contentDocumentLinks.add(new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = promotionId, ShareType = 'V'));
        }
        // We are running this logic in SYSTEM_MODE, because we need the
        // file links to be created irrespective of the permissions of the logged in user.
        Utilities.performDML(contentDocumentLinks, 'insert', AccessLevel.SYSTEM_MODE);
    }

    private static Set<Id> getContentDocumentIds(List<ContentDocumentLink> contentDocumentLinks) {
        Set<Id> result = new Set<Id>();
        for (ContentDocumentLink documentLink : contentDocumentLinks) {
            result.add(documentLink.ContentDocumentId);
        }
        return result;
    }

    private static void deleteContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinks) {
        // We are running this logic in SYSTEM_MODE, because we need the
        // file links to be deleted irrespective of the permissions of the logged in user.
        Utilities.performDML(contentDocumentLinks, 'delete', AccessLevel.SYSTEM_MODE);
    }

    private static Id getPromotionId(copado__Result__c result) {
        return result.copado__JobStep__r?.copado__JobExecution__r?.copado__Deployment__r?.copado__Promotion__c;
    }

    private static void updateErrorOnJobExecution(Id jobExecutionId, String errorMessage) {
        copado__JobExecution__c jobExecution = new copado__JobExecution__c(Id = jobExecutionId, copado__ErrorMessage__c = errorMessage);
        Utilities.performDML(new List<copado__JobExecution__c>{ jobExecution }, 'update', AccessLevel.USER_MODE);
    }

    private static copado__Result__c getResult(List<Request> requests) {
        Id resultId = requests != null && !requests.isEmpty() ? requests[0].resultId : null;
        List<copado__Result__c> results = new ResultsSelector().byIds(new Set<Id>{ resultId });
        return !results.isEmpty() ? results[0] : null;
    }

    private static String getFileName(List<Request> requests) {
        String result = requests != null && !requests.isEmpty() ? requests[0].fileName : null;
        return result;
    }

    private static Boolean isDataValid(copado__Result__c result, String fileName) {
        return result != null &&
            result.copado__Status__c == 'Success' &&
            String.isNotBlank(result.copado__JobStep__r?.copado__JobExecution__c) &&
            String.isNotBlank(fileName);
    }

    // INNER
    public class Request {
        @InvocableVariable(label='Result Id' required=true)
        public String resultId;
        @InvocableVariable(label='File Name' required=true)
        public String fileName;
    }
}