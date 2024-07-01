public with sharing virtual class LwcResponse {
    @AuraEnabled
    public Boolean isSuccess;
    @AuraEnabled
    public String message;

    public LwcResponse(Boolean isSuccess, String message) {
        this.isSuccess = isSuccess;
        this.message = message;
    }
}