// NOTE - Class executes in without sharing mode as System Property records are private
// To be updated to replace SOQL with 'copado.Jobs.DynamicExpression().evaluate(copado.Jobs.DynamicExpressionEvaluateRequest request) service once service executes in 'inherited sharing' model'
public without sharing class PromotionRollbackCtrl {
    private static final String ROLLBACK_ENABLED = 'rollback_enabled';

    // PUBLIC
    @AuraEnabled(cacheable=true)
    public static Boolean isRollbackEnabledFor(Id recordId) {
        try {
            List<copado__Promotion__c> promotions = new PromotionsSelector().byIds(new Set<Id>{ recordId });

            if (promotions.isEmpty()) {
                throw new AuraHandledException(Label.Promotion_does_not_exists);
            }

            Id destinationEnvironment = promotions[0]?.copado__Destination_Environment__c;

            List<copado__System_Property__c> systemProperties = new SystemPropertiesSelector()
                .byEnvironmentForSFDX(new Set<Id>{ destinationEnvironment }, ROLLBACK_ENABLED);

            return !systemProperties.isEmpty() && systemProperties[0]?.copado__Value__c?.toLowerCase() == 'true';
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }
}