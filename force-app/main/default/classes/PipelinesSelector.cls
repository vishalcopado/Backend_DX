public with sharing class PipelinesSelector extends fflib_SObjectSelector {
  // CONSTRUCTOR

  public PipelinesSelector() {
    this(true);
  }

  public PipelinesSelector(Boolean enforceFLS) {
    super(false, true, enforceFLS, false);
  }

  // PUBLIC

  public List<SObjectField> getSObjectFieldList() {
    return new List<SObjectField>{
      copado__Deployment_Flow__c.Name,
      copado__Deployment_Flow__c.copado__Git_Repository__c,
      copado__Deployment_Flow__c.copado__Block_Commits__c,
      copado__Deployment_Flow__c.copado__Active__c,
      copado__Deployment_Flow__c.copado__Main_Branch__c,
      copado__Deployment_Flow__c.copado__Platform__c,
      copado__Deployment_Flow__c.Initialization_Data__c
    };
  }

  public SObjectType getSObjectType() {
    return copado__Deployment_Flow__c.sObjectType;
  }

  public List<copado__Deployment_Flow__c> byId(Set<Id> ids) {
    return Database.query(
      newQueryFactory()
        .selectFields(new Set<String>{ 'copado__Git_Repository__r.copado__URI__c' })
        .selectFields(new Set<String>{ 'copado__Git_Repository__r.Name' })
        .setCondition('Id IN :ids')
        .toSOQL()
    );
  }
}