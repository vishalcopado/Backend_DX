@IsTest
public with sharing class CopadoSetupTestDefaults {
    public with sharing class OrgCredentialDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Org__c.Name => 'Dev Org',
                copado__Org__c.copado__Org_Type__c => 'Production/Developer',
                copado__Org__c.copado__Username__c => 'myUserName'
            };
            testDataFieldDefaultsByObject.put(copado__Org__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class EnvironmentDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Environment__c.Name => 'Dev Environment',
                copado__Environment__c.copado__Type__c => 'Production/Developer',
                copado__Environment__c.copado__Platform__c => 'Salesforce'
            };
            testDataFieldDefaultsByObject.put(copado__Environment__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class PermissionSetAssignmentDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            PermissionSet permSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Copado_User' LIMIT 1];
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ PermissionSetAssignment.PermissionSetId => permSet.Id };
            testDataFieldDefaultsByObject.put(PermissionSetAssignment.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class UserDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                User.LastName => 'AdminUser',
                User.FirstName => 'FirstName',
                User.Alias => 'myAlias',
                User.Email => 'test@test.org',
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LocaleSidKey => 'en_US',
                User.TimeZoneSidKey => 'America/Los_Angeles'
            };
            testDataFieldDefaultsByObject.put(User.SObjectType, defaults);
            return this;
        }
    }
}