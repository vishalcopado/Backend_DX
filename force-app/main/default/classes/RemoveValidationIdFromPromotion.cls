public with sharing class RemoveValidationIdFromPromotion {
    private Set<Id> promotionIds;
    public RemoveValidationIdFromPromotion(List<copado__Promoted_User_Story__c> promotedStories) {
        this.promotionIds = getPromotionIds(promotedStories);
    }

    public void execute() {
        List<copado__Promotion__c> promotionsToUpdate = new PromotionsSelector().byIdsAndNotNullValidationIds(this.promotionIds);
        for (copado__Promotion__c ps : promotionsToUpdate) {
            ps.Validate_Deploy_Request_Id__c = null;
        }
        if (Schema.sObjectType.copado__Promotion__c.fields.Validate_Deploy_Request_Id__c.isUpdateable()) {
            update promotionsToUpdate;
        }
    }

    private Set<Id> getPromotionIds(List<copado__Promoted_User_Story__c> promotedStories) {
        Set<Id> result = new Set<Id>();
        for (copado__Promoted_User_Story__c ps : promotedStories) {
            result.add(ps.copado__Promotion__c);
        }
        return result;
    }
}