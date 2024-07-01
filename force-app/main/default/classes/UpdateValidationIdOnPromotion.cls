public with sharing class UpdateValidationIdOnPromotion {
    // PUBLIC

    @InvocableMethod(label='Update Validation Id on Promotion' category='Quick Deploy')
    public static void execute(List<Request> requests) {
        try {
            copado__Result__c resultRecord = new ResultsSelector().byIds(new Set<Id>{ requests[0].resultId })[0];

            Id promotionId = resultRecord?.copado__JobStep__r?.copado__JobExecution__r?.copado__Deployment__r?.copado__Promotion__c;
            List<copado__Promotion__c> promotionsToUpdate = new List<copado__Promotion__c>();

            Boolean isValidation = getIsValidation(resultRecord);

            promotionsToUpdate.addAll(getPromotionsForValidation(resultRecord, isValidation, promotionId));
            promotionsToUpdate.addAll(getPromotionsForDeployment(resultRecord, isValidation, promotionId));

            String message = getUpdatePromotionsResult(promotionsToUpdate);
            updateWarningOnJobExecution(resultRecord.copado__JobStep__r.copado__JobExecution__c, message);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static List<copado__Promotion__c> getPromotionsForValidation(copado__Result__c resultRecord, Boolean isValidation, Id promotionId) {
        List<copado__Promotion__c> result = new List<copado__Promotion__c>();
        if (isSuccessfullValidation(resultRecord, isValidation)) {
            Map<String, Object> validationResponseMap = (Map<String, Object>) JSON.deserializeUntyped(resultRecord.copado__Result_Data__c);
            if(validationResponseMap?.containsKey('validationId')) {
                result.add(
                    new copado__Promotion__c(Id = promotionId, Validate_Deploy_Request_Id__c = String.valueOf(validationResponseMap.get('validationId')))
                );
            }
        }
        return result;
    }

    private static Boolean isSuccessfullValidation(copado__Result__c resultRecord, Boolean isValidation) {
        return resultRecord.copado__Status__c == 'Success' && isValidation && !String.isBlank(resultRecord.copado__Result_Data__c);
    }

    private static List<copado__Promotion__c> getPromotionsForDeployment(copado__Result__c resultRecord, Boolean isValidation, Id promotionId) {
        List<copado__Promotion__c> result = new List<copado__Promotion__c>();
        result.addAll(getPromotionsForSuccess(resultRecord, isValidation));
        result.addAll(getPromotionsForFailure(resultRecord, isValidation, promotionId));
        return result;
    }

    private static List<copado__Promotion__c> getPromotionsForSuccess(copado__Result__c resultRecord, Boolean isValidation) {
        List<copado__Promotion__c> result = new List<copado__Promotion__c>();
        if (resultRecord.copado__Status__c == 'Success' && !isValidation) {
            List<copado__Promotion__c> promotionsOnDest = getByDestinationIds(resultRecord);
            result.addAll(setValidationIdsToBlank(promotionsOnDest));
        }
        return result;
    }

    private static List<copado__Promotion__c> getPromotionsForFailure(copado__Result__c resultRecord, Boolean isValidation, Id promotionId) {
        List<copado__Promotion__c> result = new List<copado__Promotion__c>();
        if(isFailedDeployment(resultRecord, isValidation)){
            result.add(new copado__Promotion__c(Id = promotionId, Validate_Deploy_Request_Id__c = null));
        }
        return result;
    }

    private static Boolean isFailedDeployment(copado__Result__c resultRecord, Boolean isValidation) {
        return resultRecord.copado__Status__c == 'Failed' && !isValidation && ( String.isBlank(resultRecord.copado__Error_Message__c) || (!String.isBlank(resultRecord.copado__Error_Message__c) && !(resultRecord.copado__Error_Message__c.containsIgnoreCase(Label.Cancelled_Deployment))));
    }

    private static Boolean getIsValidation(copado__Result__c resultRecord) {
        Map<String, Object> jobExecutionPayload = (Map<String, Object>) JSON.deserializeUntyped(
            resultRecord?.copado__JobStep__r?.copado__JobExecution__r?.copado__DataJson__c
        );
        return Boolean.valueOf(jobExecutionPayload.get('deploymentDryRun'));
    }

    private static List<copado__Promotion__c> setValidationIdsToBlank(List<copado__Promotion__c> promotions) {
        for (copado__Promotion__c promotion : promotions) {
            promotion.Validate_Deploy_Request_Id__c = null;
        }
        return promotions;
    }

    private static String getUpdatePromotionsResult(List<copado__Promotion__c> promotions) {
        String infoMessage = '';
        Set<Id> failedPromotionIds = new Set<Id>();
        List<Database.SaveResult> saveResultList = Database.update(promotions, false);
        for (Database.SaveResult sr : saveResultList) {
            if (!sr.isSuccess()) {
                failedPromotionIds.add(sr.getId());
            }
        }
        if (!failedPromotionIds.isEmpty()) {
            infoMessage = Label.Validation_Id_Update_Failed;
            List<String> failedPromotions = new List<String>();
            for (copado__Promotion__c promotion : new PromotionsSelector().byIds(failedPromotionIds)) {
                failedPromotions.add(promotion.Name);
            }
            infoMessage += String.join(failedPromotions, ',');
        }
        return infoMessage;
    }

    private static List<copado__Promotion__c> getByDestinationIds(copado__Result__c resultRecord) {
        return new PromotionsSelector()
            .byDestinationIds(new Set<Id>{ (Id) resultRecord?.copado__JobStep__r?.copado__JobExecution__r?.copado__Destination__c });
    }

    private static void updateWarningOnJobExecution(Id jobExecutionId, String infoMessage) {
        if (String.isNotBlank(infoMessage) && Schema.sObjectType.copado__JobExecution__c.fields.copado__ErrorMessage__c.isUpdateable()) {
            update new copado__JobExecution__c(Id = jobExecutionId, copado__ErrorMessage__c = infoMessage);
        }
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Result Id' required=true)
        public String resultId;
    }
}