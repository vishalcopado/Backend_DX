public with sharing class UpdatePromotionTestLevel {
    private Set<Id> promotionIds;
    private Boolean enforceCRUDFLS = !Trigger.isExecuting;

    @TestVisible
    private static final List<String> TEST_LEVELS_IN_ORDER = Utilities.getPicklistValues(
        SObjectType.copado__Promotion__c.getName(),
        copado__Promotion__c.Apex_Test_Level__c.getDescribe(FieldDescribeOptions.DEFAULT).getName() //NOPMD // PMD is giving a false positive here.
    );

    private Integer lastTestLevelIndex {
        get {
            return TEST_LEVELS_IN_ORDER.size() - 1;
        }
    }

    // CONSTRUCTOR

    public UpdatePromotionTestLevel(List<copado__Promoted_User_Story__c> promotedStories) {
        this.promotionIds = getPromotionIds(promotedStories);
    }

    public UpdatePromotionTestLevel(Set<Id> promotionIds) {
        this.promotionIds = promotionIds;
    }

    // PUBLIC

    public void execute() {
        try {
            List<copado__Promotion__c> promotionsToUpdate = new List<copado__Promotion__c>();

            for (
                copado__Promotion__c promotion : new PromotionsSelector(enforceCRUDFLS, enforceCRUDFLS).byIdsAndActivePromotedStories(promotionIds)
            ) {
                String newTestLevel = calculateTestLevel(promotion);

                if (newTestLevel != promotion.Apex_Test_Level__c) {
                    promotion.Apex_Test_Level__c = newTestLevel;
                    promotionsToUpdate.add(promotion);
                }
            }

            update Security.stripInaccessible(AccessType.UPDATABLE, promotionsToUpdate, true).getRecords();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    // PRIVATE

    private Set<Id> getPromotionIds(List<copado__Promoted_User_Story__c> promotedStories) {
        Set<Id> promotionIds = new Set<Id>();

        for (copado__Promoted_User_Story__c ps : promotedStories) {
            promotionIds.add(ps.copado__Promotion__c);
        }

        return promotionIds;
    }

    private String calculateTestLevel(copado__Promotion__c promotion) {
        Integer currIndex = TEST_LEVELS_IN_ORDER.contains(promotion.copado__Destination_Environment__r.Apex_Test_Level__c)
            ? TEST_LEVELS_IN_ORDER.indexOf(promotion.copado__Destination_Environment__r.Apex_Test_Level__c)
            : 0;

        if (!isTestLevelMostRestrictive(currIndex)) {
            for (copado__Promoted_User_Story__c ps : promotion.copado__Promoted_User_Stories__r) {
                Integer newIndex = TEST_LEVELS_IN_ORDER.indexOf(ps.copado__User_Story__r.Apex_Test_Level__c);
                currIndex = (newIndex > currIndex) ? newIndex : currIndex;

                if (isTestLevelMostRestrictive(currIndex)) {
                    break;
                }
            }
        }

        return TEST_LEVELS_IN_ORDER.get(currIndex);
    }

    private Boolean isTestLevelMostRestrictive(Integer currIndex) {
        return currIndex == lastTestLevelIndex;
    }
}