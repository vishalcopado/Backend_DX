@IsTest
private class PipelineInitializeStatusImplTest {
    
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }

    @IsTest
    private static void exceptionWithNoJobId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //Setup
            Exception expectedException;
            PipelineInitializer.InitializeResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = PipelineInitializer.Initialize.status(null);
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Assert.areEqual(null, expectedResult, 'Response should be null');
            Assert.areNotEqual(null, expectedException, 'An exception should be thrown');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<String> {'Job Execution Id'}), expectedException.getMessage(), 'Exception message should match.');
        }
    }


    @IsTest
    private static void successfulExecutionWithSuccessfulSteps() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // Setup

            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Successful'
            );
            insert job;
            copado__JobStep__c jobStep = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "MockedFlow"}',
                Name = 'Take logs',
                copado__JobExecution__c = job.Id
            );
            insert jobStep;
            copado__Result__c result = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Success',
                copado__JobStep__c = jobStep.Id
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // Exercise
            Test.startTest();
            PipelineInitializer.InitializeResult expectedResult = PipelineInitializer.Initialize.status(job.Id);
            Test.stopTest();

            // Verify
            Assert.areNotEqual(null, expectedResult, 'Result is not null');
            Assert.areEqual('Successful', expectedResult.jobStatus, 'Job Execution Status should match');
            Assert.areEqual(1, expectedResult.steps.size(), 'Should be one execution step');
            Assert.areEqual('Success', expectedResult.steps[0].copado__Status__c, 'Job Execution Step Status should match');
        }
    }


    @IsTest
    private static void erroredExecutionWithDifferentSteps() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // Setup
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Error'
            );
            insert job;

            List<copado__JobStep__c> jobSteps = new List<copado__JobStep__c>();
            copado__JobStep__c jobStep1 = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "MockedFlow"}',
                Name = 'Take logs',
                copado__Order__c = 1,
                copado__JobExecution__c = job.Id
            );
            jobSteps.add(jobStep1);
            copado__JobStep__c jobStep2 = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "SampleFlow"}',
                Name = 'Validate US',
                copado__Order__c = 2,
                copado__JobExecution__c = job.Id
            );
            jobSteps.add(jobStep2);
            copado__JobStep__c jobStep3 = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "TestFlow"}',
                Name = 'Process Record',
                copado__Order__c = 3,
                copado__JobExecution__c = job.Id
            );
            jobSteps.add(jobStep3);
            insert jobSteps;

            List<copado__Result__c> results = new List<copado__Result__c>();
            copado__Result__c result1 = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Success',
                copado__JobStep__c = jobStep1.Id
            );
            results.add(result1);
            copado__Result__c result2 = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Success',
                copado__JobStep__c = jobStep2.Id
            );
            results.add(result2);
            copado__Result__c result3 = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Failed',
                copado__JobStep__c = jobStep3.Id
            );
            results.add(result3);
            insert results;

            List<copado__JobStep__c> jobStepsToUpdate = new List<copado__JobStep__c>();
            jobStep1.copado__Result__c = result1.Id;
            jobStep2.copado__Result__c = result2.Id;
            jobStep3.copado__Result__c = result3.Id;
            jobStepsToUpdate.add(jobStep1);
            jobStepsToUpdate.add(jobStep2);
            jobStepsToUpdate.add(jobStep3);
            update jobStepsToUpdate;


            // Exercise
            Test.startTest();
            PipelineInitializer.InitializeResult expectedResult = PipelineInitializer.Initialize.status(job.Id);
            Test.stopTest();

            // Verify
            Assert.areNotEqual(null, expectedResult, 'Result is not null');
            Assert.areEqual('Error', expectedResult.jobStatus, 'Job Execution Status should match');
            Assert.areEqual(3, expectedResult.steps.size(), 'Should be 3 execution steps');
            Assert.areEqual('Success', expectedResult.steps[0].copado__Status__c, 'Job Execution Step Status should match');
            Assert.areEqual('Success', expectedResult.steps[1].copado__Status__c, 'Job Execution Step Status should match');
            Assert.areEqual('Failed', expectedResult.steps[2].copado__Status__c, 'Job Execution Step Status should match');
        }
    }

}