@IsTest
private class PublishEventFunctionCallbackTest {
    @IsTest
    private static void publishEventWithSuccessStatus() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            copado__Event__e event = new Copado__Event__e();

            // EXERCISE

            Test.startTest();
            PublishEventFunctionCallback.execute(getFunction('vlocity_refresh_index'), getResult(getJobStep('Vlocity Refresh Index').Id), 'Success');
            event = PublishEventFunctionCallback.publishedEvent;
            Test.stopTest();

            //VERIFY

            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(event.copado__Payload__c);
            Assert.isTrue((Boolean) payload.get('isSuccess'), 'Event should be successfully published with success');
            Assert.areEqual('Test Data', payload.get('resultData'), 'Event should be successfully published with result data');
        }
    }

    @IsTest
    private static void publishEventWithFailureStatus() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            copado__Event__e event = new Copado__Event__e();

            //EXERCISE

            Test.startTest();
            PublishEventFunctionCallback.execute(getFunction('vlocity_refresh_index'), getResult(getJobStep('Vlocity Refresh Index').Id), 'Failed');
            event = PublishEventFunctionCallback.publishedEvent;
            Test.stopTest();

            //VERIFY

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(event.copado__Payload__c);
            Assert.isFalse((Boolean) data.get('isSuccess'), 'Event should be successfully published with failure');
        }
    }

    @IsTest
    private static void publishEventWithCancelledStatus() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            copado__Event__e event = new Copado__Event__e();

            //EXERCISE

            Test.startTest();
            PublishEventFunctionCallback.execute(getFunction('vlocity_refresh_index'), getResult(getJobStep('Vlocity Refresh Index').Id), 'Cancelled');
            event = PublishEventFunctionCallback.publishedEvent;
            Test.stopTest();

            //VERIFY

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(event.copado__Payload__c);
            Assert.isFalse((Boolean) data.get('isSuccess'), 'Event should be successfully published with failure');
        }
    }

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    private static void makeData() {
        Environment env = TestUtilities.createEnvironment('Vlocity Test Environment');
        TestUtilities.createCredential(true, env);
        Function function = createFunctionObj('vlocity_refresh_index');
        JobStep jobStep = createJobStep('Vlocity Refresh Index', 'Function');
        createMockResult(env.Id, function, jobStep).persist();
    }

    private static Result createMockResult(String contextId, Function function, JobStep step) {
        return new Result(step).contextId(contextId).type('vlocity_refresh_index').status('Success').data('Test Data').functionId(function.Id);
    }

    private static JobStep createJobStep(String name, String type) {
        return new JobStep().name(name).type(type);
    }

    private static Function createFunctionObj(String apiName) {
        return new Function().apiName(apiName).script('script here');
    }

    private static copado__Function__c getFunction(String apiName) {
        return [SELECT Name, copado__API_Name__c FROM copado__Function__c WHERE copado__API_Name__c = :apiName];
    }

    private static copado__Result__c getResult(Id jobStepId) {
        return [SELECT Id, Name, copado__Result_Data__c, copado__Error_Message__c, copado__JobStep__c FROM copado__Result__c WHERE copado__JobStep__c = :jobStepId LIMIT 1];
    }

    private static copado__JobStep__c getJobStep(String stepName) {
        return [SELECT Id, Name FROM copado__JobStep__c WHERE Name =:stepName LIMIT 1];
    }
}