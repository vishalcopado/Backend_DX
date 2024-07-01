public with sharing class CopadoNotificationSelector extends fflib_SObjectSelector {
    public CopadoNotificationSelector() {
        this(true, true);
    }

    public CopadoNotificationSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    public SObjectType getSObjectType() {
        return copado__Copado_Notification__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>();
    }

    public List<copado__Copado_Notification__c> byParentIdsAndFinishedFlag(Set<Id> parentIds, Boolean isFinished) {
        return Database.query(
            newQueryFactory()
                .setCondition(
                    copado__Copado_Notification__c.copado__ParentId__c +
                        ' IN :parentIds AND ' +
                        copado__Copado_Notification__c.copado__isFinished__c +
                        ' =:isFinished'
                )
                .toSOQL()
        );
    }

    public List<copado__Copado_Notification__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectFields(
                    new List<Schema.SObjectField>{
                        copado__Copado_Notification__c.copado__ParentId__c,
                        copado__Copado_Notification__c.copado__isFinished__c,
                        copado__Copado_Notification__c.copado__isSuccess__c,
                        copado__Copado_Notification__c.copado__status__c,
                        copado__Copado_Notification__c.copado__Message__c
                    }
                )
                .setCondition(copado__Copado_Notification__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__Copado_Notification__c> byParentIdsFinishedAndCreatedDate(Set<Id> parentIds, Boolean isFinished, Datetime inputDate) {
        return Database.query(
            newQueryFactory()
                .setCondition(
                    copado__Copado_Notification__c.copado__ParentId__c +
                        ' IN :parentIds AND ' +
                        copado__Copado_Notification__c.copado__isFinished__c +
                        ' =:isFinished AND ' +
                        copado__Copado_Notification__c.CreatedDate +
                        ' > :inputDate'
                )
                .toSOQL()
        );
    }
}