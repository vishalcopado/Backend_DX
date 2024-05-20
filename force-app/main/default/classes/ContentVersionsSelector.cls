public with sharing class ContentVersionsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public ContentVersionsSelector() {
        this(true, true);
    }

    public ContentVersionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return ContentVersion.sObjectType;
    }

    /* 
        Kindly do not add the ContentVersion.VersionData field inside 
        getSObjectFieldList(), as it contains the whole file content and it is
        not needed in every case.
    */
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ ContentVersion.ContentDocumentId };
    }

    public List<ContentVersion> byContentDocumentIdWithLatest(Set<Id> contentDocumentIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String>{ 'LastModifiedDate', 'VersionData', 'ContentDocumentId' })
            .setCondition('ContentDocumentId IN :contentDocumentIds AND isLatest = TRUE');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }

    public List<ContentVersion> byIdsAndTitles(Set<Id> ids, Set<String> titles) {
        fflib_QueryFactory query = newQueryFactory().selectFields(new Set<String>{ 'VersionData' }).setCondition('Id IN :ids AND Title IN :titles');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }

    public List<ContentVersion> byIds(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().selectFields(new Set<String>{ 'VersionData' }).setCondition('Id IN :ids ');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }

    /* 
        Request : Kindly do not add the ContentVersion.VersionData field inside 
        byContentDocumentId(), as it is being used on the commit page and can cause
        Apex Heap Size issue there (US-0035057).
    */
    public List<ContentVersion> byContentDocumentId(Set<Id> contentDocumentIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String>{ 'LastModifiedDate', 'Title' })
            .setCondition('ContentDocumentId IN :contentDocumentIds AND isLatest = TRUE');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }

    public List<ContentVersion> byFirstPublishLocationIdAndTitleAndIsLatest(Set<Id> firstPublishLocationIds, List<String> titles) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('FirstPublishLocationId IN :firstPublishLocationIds AND Title IN :titles AND IsLatest = TRUE');
        return (List<ContentVersion>) Database.query(query.toSOQL());
    }
}