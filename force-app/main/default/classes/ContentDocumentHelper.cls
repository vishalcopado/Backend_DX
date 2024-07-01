public with sharing class ContentDocumentHelper {
    // PUBLIC

    public static String getContentDocumentIdByLinkedEntinityAndFileName(Id byLinkedEntityId, String fileName) {
        String result = '';
        List<ContentDocumentLink> packageVersionFileDetails = getContentDocumentLink(byLinkedEntityId, fileName);
        if (!packageVersionFileDetails.isEmpty()) {
            List<ContentVersion> contentVersions = new ContentVersionsSelector().byContentDocumentIdWithLatest(new Set<Id>{packageVersionFileDetails[0].ContentDocumentId });
            if(!contentVersions.isEmpty()) {
                result = contentVersions[0]?.Id;
            }
        }
        return result;
    }

    public static String getContentVersionData(Id byLinkedEntityId, String fileName) {
        List<ContentDocumentLink> fileDetails = getContentDocumentLink(byLinkedEntityId, fileName);
        if (fileDetails.isEmpty()) {
            return '';
        }
        return new ContentVersionsSelector().byContentDocumentIdWithLatest(new Set<Id>{fileDetails[0].ContentDocumentId })[0]?.VersionData?.toString();
    }

    // PRIVATE

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId, String fileName) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ fileName });
    }
}