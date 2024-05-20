@IsTest
public with sharing class ProxyOrgResponse {
    public Integer statusCode;
    public String content;
    public String errorCode;
    public String errorMessage;

    // CTR

    public ProxyOrgResponse() {
        this.statusCode = null;
        this.content = null;
        this.errorCode = null;
        this.errorMessage = null;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public ProxyOrgResponse(Integer statusCode, String content, String errorCode, String errorMessage) {
        this.statusCode = statusCode;
        this.content = content;
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }

    // PUBLIC
    public String getResponse() {
        return JSON.serialize(this);
    }
}