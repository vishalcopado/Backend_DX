public with sharing class CreateCopadoNotificationPushTopic {
    @TestVisible
    private static final String COPADO_NOTIFICATIONS = Test.isRunningTest() ? 'Test' + 'CopadoNotifications' : 'CopadoNotifications';
    @TestVisible
    private static final String QUERY = 'SELECT Id, Name, copado__status__c, copado__AttachmentId__c, copado__Type__c, copado__Message__c, copado__ParentId__c, copado__Parent2Id__c, copado__isFinished__c, CreatedDate, LastModifiedDate FROM copado__Copado_Notification__c';
    // PUBLIC

    @AuraEnabled
    public static LwcResponse execute() {
        LwcResponse result = new LwcResponse(true, null);
        try {
            List<PushTopic> copadoNotifications = [
                SELECT Id, Name
                FROM PushTopic
                WHERE Name = :COPADO_NOTIFICATIONS
                WITH SYSTEM_MODE
            ];
            if (copadoNotifications.isEmpty()) {
                PushTopic pushTopic = new PushTopic();
                pushTopic.Name = COPADO_NOTIFICATIONS;
                pushTopic.Query = QUERY;
                pushTopic.ApiVersion = 32.0;
                pushTopic.NotifyForOperationCreate = true;
                pushTopic.NotifyForOperationUpdate = true;
                pushTopic.NotifyForOperationUndelete = true;
                pushTopic.NotifyForOperationDelete = true;
                pushTopic.NotifyForFields = 'All';
                Utilities.performDML(new List<PushTopic>{ pushTopic }, 'insert', AccessLevel.SYSTEM_MODE);
            }
        } catch (Exception ex) {
            result = new LwcResponse(false, ex.getMessage() + ex.getStackTraceString());
        }
        return result;
    }
}