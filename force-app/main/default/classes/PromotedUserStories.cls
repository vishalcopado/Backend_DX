public with sharing class PromotedUserStories extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public PromotedUserStories(List<copado__Promoted_User_Story__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onAfterInsert() {
        if (isSfdxPlatform()) {
            new UpdatePromotionTestLevel(records).execute();
            new RemoveValidationIdFromPromotion(records).execute();
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> old) {
        if (isSfdxPlatform()) {
            new UpdatePromotionTestLevel(withStatusChange(records, (Map<Id, copado__Promoted_User_Story__c>) old)).execute();
        }
    }

    public override void onAfterDelete() {
        if (isSfdxPlatform()) {
            new UpdatePromotionTestLevel(records).execute();
            new RemoveValidationIdFromPromotion(records).execute();
        }
    }

    // PRIVATE

    private Set<Id> withStatusChange(List<copado__Promoted_User_Story__c> promotedUserStories, Map<Id, copado__Promoted_User_Story__c> old) {
        Set<Id> result = new Set<Id>();

        for (copado__Promoted_User_Story__c ps : promotedUserStories) {
            if (ps.copado__Status__c == 'Active' && ps.copado__Status__c != old.get(ps.Id).copado__Status__c) {
                result.add(ps.copado__Promotion__c);
            }
        }

        return result;
    }

    private Boolean isSfdxPlatform() {
        Set<Id> promotionIds = new Set<Id>();
        for (copado__Promoted_User_Story__c ps : (List<copado__Promoted_User_Story__c>) records) {
            promotionIds.add(ps.copado__Promotion__c);
        }

        List<AggregateResult> promotions = [
            SELECT COUNT(Id) promotions
            FROM copado__Promotion__c
            WHERE Id IN :promotionIds AND copado__Platform__c = 'SFDX'
            WITH SECURITY_ENFORCED
        ];

        return (Integer) promotions[0].get('promotions') > 0;
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new PromotedUserStories(records);
        }
    }
}