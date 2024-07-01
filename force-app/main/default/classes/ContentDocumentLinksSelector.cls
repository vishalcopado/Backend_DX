public with sharing class ContentDocumentLinksSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public ContentDocumentLinksSelector() {
        this(true, true);
    }

    public ContentDocumentLinksSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return ContentDocumentLink.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ ContentDocumentLink.ContentDocumentId };
    }

    public List<ContentDocumentLink> byLinkedEntityIdAndTitles(Set<Id> linkedEntityIds, Set<String> titles) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'ContentDocument.LatestPublishedVersionId', 'LinkedEntityId', 'ContentDocument.Title', 'ContentDocumentId' })
                .setCondition('LinkedEntityId IN :linkedEntityIds AND ContentDocument.Title IN :titles')
                .setOrdering('ContentDocument.CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }

    public List<ContentDocumentLink> byLinkedEntityId(Set<Id> linkedEntityIds) {
        return Database.query(newQueryFactory().setCondition('LinkedEntityId IN :linkedEntityIds').toSOQL());
    }

    public List<ContentDocumentLink> versionDataByLinkedEntityIdsAndTitles(Set<Id> linkedEntityIds, Set<String> titles) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'ContentDocument.LatestPublishedVersion.Title', 'ContentDocument.LatestPublishedVersion.VersionData', 'LinkedEntityId' })
                .setCondition('LinkedEntityId IN :linkedEntityIds AND ContentDocument.LatestPublishedVersion.Title IN : titles')
                .toSOQL()
        );
    }

    public List<ContentDocumentLink> byLinkedEntityIdAndTitlesAscending(Set<Id> linkedEntityIds, Set<String> titles) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'ContentDocument.LatestPublishedVersionId', 'LinkedEntityId', 'ContentDocument.Title', 'ContentDocumentId' })
                .setCondition('LinkedEntityId IN :linkedEntityIds AND ContentDocument.Title IN :titles')
                .setOrdering('ContentDocument.CreatedDate', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL()
        );
    }
}