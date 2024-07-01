public with sharing class EventPayload {
    private Boolean isSuccess;
    private String errorMessage;
    private String data;
    public String resultData;
    private Boolean fromCallBack = true;

    // CTR
    public EventPayload(Boolean isSuccess, String errorMessage) {
        this.isSuccess = isSuccess;
        this.errorMessage = errorMessage;
    }

    public EventPayload(Boolean isSuccess, String errorMessage, String resultData) {
        this.isSuccess = isSuccess;
        this.errorMessage = errorMessage;
        this.resultData = resultData;
        this.data = resultData;
    }

    // PUBLIC
    public void publish(Id resultId) {
        String stepEndpoint = '/events/copado/v1/step-result/' + resultId;

        if (String.isNotBlank(resultId)) {
            copado__Event__e stepCompleted = new copado__Event__e();
            stepCompleted.copado__Payload__c = JSON.serialize(this);
            stepCompleted.copado__Topic_Uri__c = stepEndpoint;
            EventBus.publish(stepCompleted);
        }
    }
}