@IsTest
public with sharing class CopadoUserStoryTestDefaults {
    public with sharing class PipelineDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Deployment_Flow__c.Name => 'MyPipeline',
                copado__Deployment_Flow__c.copado__Active__c => true,
                copado__Deployment_Flow__c.copado__Main_Branch__c => 'master',
                copado__Deployment_Flow__c.copado__Platform__c => 'Salesforce'
            };
            testDataFieldDefaultsByObject.put(copado__Deployment_Flow__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class PipelineConnectionDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{};
            testDataFieldDefaultsByObject.put(copado__Deployment_Flow_Step__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class UserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            // getRecordTypeInfosByDeveloperName does not use namespace
            Id userStoryRecordTypeId = Schema.SObjectType.copado__User_Story__c.getRecordTypeInfosByDeveloperName().get('User_Story').getRecordTypeId();
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__User_Story__c.RecordTypeId => userStoryRecordTypeId,
                copado__User_Story__c.copado__User_Story_Title__c => 'My new User Story'
            };
            testDataFieldDefaultsByObject.put(copado__User_Story__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class ProjectDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Project__c.Name => 'MyProject',
                copado__Project__c.copado__Index_Metadata__c => false
            };
            testDataFieldDefaultsByObject.put(copado__Project__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class ReleaseDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ copado__Release__c.Name => 'MyNextRelease' };
            testDataFieldDefaultsByObject.put(copado__Release__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class GitRepositoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Git_Repository__c.Name => 'MyGitRepo',
                copado__Git_Repository__c.copado__Source_Format__c => 'Metadata',
                copado__Git_Repository__c.copado__Git_Provider__c => 'Github',
                copado__Git_Repository__c.copado__URI__c => 'https://github.com/UserName/MyGitRepo.git',
                copado__Git_Repository__c.copado__Branch_Base_URL__c => 'https://github.com/UserName/borrar/tree/',
                copado__Git_Repository__c.copado__Commit_Base_URL__c => 'https://github.com/UserName/borrar/commit/',
                copado__Git_Repository__c.copado__Pull_Request_Base_URL__c => 'https://github.com/UserName/borrar/',
                copado__Git_Repository__c.copado__Tag_Base_URL__c => 'https://github.com/UserName/borrar/tags/'
            };
            testDataFieldDefaultsByObject.put(copado__Git_Repository__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class GitOrgCommitDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ copado__Git_Org_Commit__c.copado__Status__c => 'Complete' };
            testDataFieldDefaultsByObject.put(copado__Git_Org_Commit__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class UserStoryCommitDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{};
            testDataFieldDefaultsByObject.put(copado__User_Story_Commit__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class TestScriptDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Test_Script__c.copado__Status__c => 'Ready for testing',
                copado__Test_Script__c.copado__Test_Title__c => 'Test Title',
                copado__Test_Script__c.copado__Introduction__c => 'Test Introduction',
                copado__Test_Script__c.copado__Test_Description__c => 'Test Description',
                copado__Test_Script__c.copado__Prerequisites__c => 'Test Prerequisites',
                copado__Test_Script__c.copado__Expected_Result__c => 'Test Expected Result'
            };
            testDataFieldDefaultsByObject.put(copado__Test_Script__c.SObjectType, defaults);
            return this;
        }
    }

    public class TestScriptStepDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Test_Script_Step__c.copado__Step_Title__c => 'Step title',
                copado__Test_Script_Step__c.copado__Order__c => 1,
                copado__Test_Script_Step__c.copado__Action_Description__c => 'action',
                copado__Test_Script_Step__c.copado__Expected_Result__c => 'expected result'
            };

            testDataFieldDefaultsByObject.put(copado__Test_Script_Step__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class TestRunDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                copado__Test_Run__c.copado__Status__c => 'Ready for testing',
                copado__Test_Run__c.copado__Type__c => 'Peer-Review',
                copado__Test_Run__c.copado__Test_Phase__c => 'Developer',
                copado__Test_Run__c.copado__Overall_Test_Comments__c => 'Overall Test Comments'
            };
            testDataFieldDefaultsByObject.put(copado__Test_Run__c.SObjectType, defaults);
            return this;
        }
    }
    public class SprintDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ copado__Sprint__c.Name => 'Sprint' };
            testDataFieldDefaultsByObject.put(copado__Sprint__c.SObjectType, defaults);
            return this;
        }
    }
    public class DeploymentDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ copado__Deployment__c.Name => 'Deployment' };
            testDataFieldDefaultsByObject.put(copado__Deployment__c.SObjectType, defaults);
            return this;
        }
    }
    public class DeploymentStepDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ copado__Step__c.Name => 'Deployment Step' };
            testDataFieldDefaultsByObject.put(copado__Step__c.SObjectType, defaults);
            return this;
        }
    }
    public class DeploymentTaskDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>();
            testDataFieldDefaultsByObject.put(copado__Deployment_Task__c.SObjectType, defaults);
            return this;
        }
    }
}