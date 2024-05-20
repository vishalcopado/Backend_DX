public with sharing class AttachmentsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public AttachmentsSelector() {
        this(true, true);
    }

    public AttachmentsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Attachment.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Attachment.Body, Attachment.Name };
    }

    public List<Attachment> byStoryIdsAndTestClasses(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .setCondition(
                    Attachment.ParentId + ' IN :ids AND Name IN (\'Test Classes\', \'Test Classes.json\', \'cmcSf_TestClasses.json\')'
                )
                .toSOQL()
        );
    }

    public List<Attachment> byParentIdsAndNames(Set<Id> ids, Set<String> names, Integer maxRecords) {
        return Database.query(
            newQueryFactory()
                .selectField('LastModifiedDate')
                .selectField('ParentId')
                .setCondition(Attachment.ParentId + ' IN :ids AND ' + Attachment.Name + ' IN :names')
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING, true)
                .setLimit(maxRecords)
                .toSOQL()
        );
    }
}