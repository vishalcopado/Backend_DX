public with sharing class SObjectItem {
    @AuraEnabled
    public String Name;
    @AuraEnabled
    public String Label;
}

// Note: following there is the list of whole properties of SObjectItem as per the Tooling API Query result
/*
    {
    "activateable" : false,
    "associateEntityType" : null,
    "associateParentEntity" : null,
    "createable" : true,
    "custom" : false,
    "customSetting" : false,
    "deepCloneable" : false,
    "deletable" : true,
    "deprecatedAndHidden" : false,
    "feedEnabled" : false,
    "hasSubtypes" : false,
    "isInterface" : false,
    "isSubtype" : false,
    "keyPrefix" : "0Pp",
    "label" : "AI Application",
    "labelPlural" : "AI Applications",
    "layoutable" : false,
    "mergeable" : false,
    "mruEnabled" : false,
    "name" : "AIApplication",
    "queryable" : true,
    "replicateable" : false,
    "retrieveable" : true,
    "searchable" : false,
    "triggerable" : false,
    "undeletable" : false,
    "updateable" : true,
    "urls" : {
      "rowTemplate" : "/services/data/v51.0/tooling/sobjects/AIApplication/{ID}",
      "describe" : "/services/data/v51.0/tooling/sobjects/AIApplication/describe",
      "sobject" : "/services/data/v51.0/tooling/sobjects/AIApplication"
    }
  }
*/