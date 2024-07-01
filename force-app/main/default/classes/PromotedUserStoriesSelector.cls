public with sharing class PromotedUserStoriesSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PromotedUserStoriesSelector() {
        this(true, true);
    }

    public PromotedUserStoriesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Promoted_User_Story__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Promoted_User_Story__c.Name,
            copado__Promoted_User_Story__c.copado__User_Story__c
        };
    }

    public List<copado__Promoted_User_Story__c> byPromotionIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory().setCondition(copado__Promoted_User_Story__c.copado__Promotion__c + ' IN :ids').toSOQL()
        );
    }
}