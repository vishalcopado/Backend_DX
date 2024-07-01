public with sharing class MetadataSearchResult {
    @AuraEnabled
    public String id {get;set;}
    @AuraEnabled
    public String type {get;set;}
    @AuraEnabled
    public String name {get;set;}
    @AuraEnabled
    public String lastModifiedBy {get;set;}
    @AuraEnabled
    public String lastModifiedDate {get;set;}
    @AuraEnabled
    public String createdDate {get;set;}
    @AuraEnabled
    public String createdBy {get;set;}
}