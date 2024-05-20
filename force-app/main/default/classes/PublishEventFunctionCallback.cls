@SuppressWarnings('PMD.AvoidGlobalModifier')
global class PublishEventFunctionCallback implements copado.MCCallBack {
    private static String stepEndpoint = '/events/copado/v1/step-result/';

    //We need to suppress this warning here, because 'publishedEvent' is only used in the respective test class.
    @SuppressWarnings('PMD.UnusedLocalVariableRule')
    @TestVisible
    private static copado__Event__e publishedEvent;

    global static void execute(copado__Function__c function, copado__Result__c result, String status) {
        try {
            Boolean isSuccess = status == 'Success' ? true : false;
            publishedEvent = publishEvent(new EventPayload(isSuccess, result.copado__Error_Message__c, result.copado__Result_Data__c), result.Id);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static copado__Event__e publishEvent(EventPayload payload, String resultId) {
        copado__Event__e event = new copado__Event__e();
        event.copado__Payload__c = JSON.serialize(payload);
        event.copado__Topic_Uri__c = stepEndpoint + resultId;
        EventBus.publish(event);
        return event;
    }
}