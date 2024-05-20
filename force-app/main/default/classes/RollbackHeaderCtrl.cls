public with sharing class RollbackHeaderCtrl {
    @AuraEnabled
    public static Id executeRollback(String rollbackRequest) {
        try {
            if (String.isBlank(rollbackRequest)) {
                throw new AuraHandledException(Label.RollbackRequestHasEmptyValues);
            }

            RollbackActionRequest rollbackActionRequest = (RollbackActionRequest) JSON.deserialize(rollbackRequest, RollbackActionRequest.class);

            if (validateRequest(rollbackActionRequest)) {
                throw new AuraHandledException(Label.RollbackRequestHasEmptyValues);
            }

            RollbackImpl.Request request = new RollbackImpl.Request();

            request.isValidation = rollbackActionRequest.isValidation;
            request.testLevel = rollbackActionRequest.testLevel;
            request.promotionId = rollbackActionRequest.promotionId;
            request.startExecution = rollbackActionRequest.startExecution;

            return new RollbackImpl().create(request).job.Id;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    @AuraEnabled
    public static string getNamespace() {
        try {
            return Settings.NS;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static Boolean validateRequest(RollbackActionRequest rollbackActionRequest) {
        return rollbackActionRequest == null ||
            (String.isBlank(rollbackActionRequest.promotionId) ||
            rollbackActionRequest.isValidation == null ||
            rollbackActionRequest.startExecution == null ||
            String.isBlank(rollbackActionRequest.testLevel));
    }

    // INNER
    public class RollbackActionRequest {
        @AuraEnabled
        public Boolean isValidation;
        @AuraEnabled
        public String testLevel;
        @AuraEnabled
        public Id promotionId;
        @AuraEnabled
        public Boolean startExecution;
    }
}