@IsTest
private class UpdateSourceOnJobExecutionFlowTest {
    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static final String SUBSCRIBER_ID = '04t09000000G3icAAC';
    
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }
    
    @IsTest
    private static void updateSourceId() {
        // Setup
        
        System.runAs(TestUtilities.getRunAsUser()) {
            copado__Environment__c environment = TestDataFactory.createEnvironment(
                'DevHub',
                'Production/Developer',
                'SFDX'
            );
            insert environment;
            
            copado__Org__c credential = TestDataFactory.createCredential(
                'DevHub',
                'test@test.com',
                environment.Id,
                'Production/Developer'
            );
            insert credential;
            
            copado__JobTemplate__c template = TestDataFactory.createJobTemplate(
                'SFDX Package Import'
            );
            insert template;
            
            copado__Result__c result = createResult(
                createJobStep(createJobExecution(template, environment))
            );
            
            Map<String, Object> flowParams = getFlowParams(credential, result);
            
            // Exercise
            Test.startTest();
            new Flow.Interview.Update_Source_on_Job_Execution(flowParams).start();
            Test.stopTest();
            // Verify
            List<copado__JobExecution__c> jobExecutions = getJobExecution();
            
            System.assertEquals(
                jobExecutions[0].copado__Source__c,
                environment.Id,
                'Source updation on Job Execution has been failed'
            );
        }
        
    }
    
    private static copado__JobExecution__c createJobExecution(
        copado__JobTemplate__c template,
        copado__Environment__c environment
    ) {
        copado__JobExecution__c execution = new copado__JobExecution__c(
            copado__Template__c = template.Id,
            copado__Destination__c = environment.Id
        );
        insert execution;
        return execution;
    }
    
    private static copado__JobStep__c createJobStep(
        copado__JobExecution__c execution
    ) {
        copado__JobStep__c step = new copado__JobStep__c(
            Name = 'Update Source on Job Execution',
            copado__JobExecution__c = execution.Id,
            copado__Type__c = 'Flow'
        );
        insert step;
        return step;
    }
    
    private static copado__Result__c createResult(copado__JobStep__c step) {
        copado__Result__c result = new copado__Result__c();
        result.copado__JobStep__c = step.Id;
        result.copado__Result_Data__c = SUBSCRIBER_ID;
        result.copado__Job_Type__c = 'Integration';
        insert result;
        return result;
    }
    
    private static Map<String, Object> getFlowParams(
        copado__Org__c credential,
        copado__Result__c result
    ) {
        Map<String, Object> flowParams = new Map<String, Object>{
            'jsonInformation' => '{\n    \"devhub\" :\"' + credential.Id + '\"\n}',
                'resultId' => result.Id
                };
                    return flowParams;
    }
    private static List<copado__JobExecution__c> getJobExecution() {
        return [SELECT copado__Source__c FROM copado__JobExecution__c];
    }
}