@IsTest
private class CommitFunctionCallbackTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void jobExecutionDataJsonUpdateTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            List<CommitFunctionCallback.Request> requests = new List<CommitFunctionCallback.Request>();
            CommitFunctionCallback.Request request = new CommitFunctionCallback.Request();
            request.resultId = (getResult()).Id;
            requests.add(request);

            // Exercise

            Test.startTest();
            CommitFunctionCallback.execute(requests);
            Test.stopTest();

            // Verify

            copado__JobExecution__c jobExecution = getJobExecution();
            Map<String, Object> dataJsonResponse = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.copado__DataJson__c);
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'The result of commit function callback should be blank');
            System.assertEquals(
                Settings.NAMESPACE_DOT + 'JobExecutionForTestRecords',
                (String) dataJsonResponse.get('actionCallback'),
                'The action callback of commit job execution is not set correctly'
            );
        }
    }

    @IsTest
    private static void invalidResultStatus() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            copado__Result__c commitResult = getResult();
            commitResult.copado__Status__c = 'Failed';
            update commitResult;

            List<CommitFunctionCallback.Request> requests = new List<CommitFunctionCallback.Request>();
            CommitFunctionCallback.Request request = new CommitFunctionCallback.Request();
            request.resultId = commitResult.Id;
            requests.add(request);

            // Exercise

            Test.startTest();
            CommitFunctionCallback.execute(requests);
            Test.stopTest();

            // Verify

            copado__JobExecution__c jobExecution = getJobExecution();
            Map<String, Object> dataJsonResponse = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.copado__DataJson__c);
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'The result of commit function callback should be blank');
            String actionCallback = dataJsonResponse.containsKey('actionCallback') ? (String) dataJsonResponse.get('actionCallback') : '';
            System.assert(String.isBlank(actionCallback), 'The action callback of commit job execution should be blank');
        }
    }

    @IsTest
    private static void invalidResultData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            copado__Result__c commitResult = getResult();
            commitResult.copado__Result_Data__c = '{"status":"No Changes"}';
            update commitResult;

            List<CommitFunctionCallback.Request> requests = new List<CommitFunctionCallback.Request>();
            CommitFunctionCallback.Request request = new CommitFunctionCallback.Request();
            request.resultId = commitResult.Id;
            requests.add(request);

            // Exercise

            Test.startTest();
            CommitFunctionCallback.execute(requests);
            Test.stopTest();

            // Verify

            copado__JobExecution__c jobExecution = getJobExecution();
            Map<String, Object> dataJsonResponse = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.copado__DataJson__c);
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'The result of commit function callback should be blank');
            String actionCallback = dataJsonResponse.containsKey('actionCallback') ? (String) dataJsonResponse.get('actionCallback') : '';
            System.assert(String.isBlank(actionCallback), 'The action callback of commit job execution should be blank');
        }
    }

    private static void createData() {
        JobTemplate jobTemplate = new JobTemplate().name('Commit').type('Custom');
        JobStep jobStep = new JobStep(jobTemplate).name('Commit Step').type('Function');
        new JobExecution(jobTemplate, new Environment()).dataJson('{"sampleKey":"sampleValue"}').add(jobStep);
        new Result(jobStep).type('Integration').status('Success').data('{"commitId":"sampleCommitId"}').persist();
    }

    private static copado__Result__c getResult() {
        return [SELECT Id, copado__Result_Data__c FROM copado__Result__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id, copado__DataJson__c, copado__ErrorMessage__c FROM copado__JobExecution__c LIMIT 1];
    }
}