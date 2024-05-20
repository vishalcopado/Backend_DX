@IsTest
private class HasNoApexWithAddOperationInQGTest {
    private final static String SFDX_RUN_APEX_TESTS = 'SFDX Run Apex Tests';
    private final static String RUN_APEX_TESTS = 'Run Apex Tests';
    private final static String APEX_CLASS_TYPE = 'ApexClass';
    private final static String APEX_TRIGGER_TYPE = 'ApexTrigger';
    private final static String ADD = 'Add';
    private final static String DELETE_ACTION = 'Delete';
    private final static String RETRIEVE_ONLY = 'RetrieveOnly';
    private final static String SFDX = 'SFDX';


    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeAsQualityGateAndApexWithAddOperation() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__JobStep__c jobStep = getJobStep(RUN_APEX_TESTS);
            Id fileWithSelectedChanges = getFileHavingApexWithAddOperation();

            // In a Quality Gate, the Job execution DataJson will have the property fileWithSelectedChanges
            JobExecutionPayload dataJson = new JobExecutionPayload(fileWithSelectedChanges);
            populateDataJsonOnJobExecution(jobStep, dataJson);

            String result = new HasNoApexWithAddOperationInQualityGate().execute(jobStep.Id);

            Assert.areEqual('false', result, 'The skip step condition should be false as the fileWithSelectedChanges has Apex With Add operation');
        }
    }

    @IsTest
    private static void executeAsQualityGateAndApexWithDeleteAndRetrieveOnlyOperation() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__JobStep__c jobStep = getJobStep(RUN_APEX_TESTS);
            Id fileWithSelectedChanges = getFileHavingApexWithDeleteAndRetrieveOnlyOperation();

            // In a Quality Gate, the Job execution DataJson will have the property fileWithSelectedChanges
            JobExecutionPayload dataJson = new JobExecutionPayload(fileWithSelectedChanges);
            populateDataJsonOnJobExecution(jobStep, dataJson);

            String result = new HasNoApexWithAddOperationInQualityGate().execute(jobStep.Id);

            Assert.areEqual(
                'true',
                result,
                'The skip step condition should be true as the fileWithSelectedChanges has Apex With Delete and RetrieveOnly operations only'
            );
        }
    }

    @IsTest
    private static void executeWithoutQualityGateAndApexWithDeleteAndRetrieveOnlyOperation() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__JobStep__c jobStep = getJobStep(RUN_APEX_TESTS);
            Id fileWithSelectedChanges = null;

            // In a Quality Gate, the Job execution DataJson will have the property fileWithSelectedChanges
            JobExecutionPayload dataJson = new JobExecutionPayload(fileWithSelectedChanges);
            populateDataJsonOnJobExecution(jobStep, dataJson);

            String result = new HasNoApexWithAddOperationInQualityGate().execute(jobStep.Id);

            Assert.areEqual(
                'false',
                result,
                'The skip step condition should be false as it is running as a standalone execution'
            );
        }
    }


    private static void createData() {
        JobTemplate apexTestJobTemplate = new JobTemplate().name(SFDX_RUN_APEX_TESTS).type('Custom');
        JobStep apexTestJobStep = new JobStep(apexTestJobTemplate).name(RUN_APEX_TESTS).type('Function');
        new JobExecution(apexTestJobTemplate).add(apexTestJobStep).persist();
    }

    private static void populateDataJsonOnJobExecution(copado__JobStep__c jobStep, JobExecutionPayload dataJson) {
        new JobExecution().recordId(jobStep.copado__JobExecution__c).dataJSON(JSON.serialize(dataJson)).persist();
    }

    private static copado__JobStep__c getJobStep(String name) {
        return [SELECT Id, copado__JobExecution__c FROM copado__JobStep__c WHERE Name = :name];
    }

    private static Id getFileHavingApexWithAddOperation() {
        List<CommitChanges.Change> changes = new List<CommitChanges.Change>();
        changes.add(new CommitChanges.Change(APEX_CLASS_TYPE, 'HelloWorld', '', SFDX, ADD));
        changes.add(new CommitChanges.Change(APEX_TRIGGER_TYPE, 'HelloTrigger', '', SFDX, DELETE_ACTION));
        return createFile(JSON.serialize(changes));
    }

    private static Id getFileHavingApexWithDeleteAndRetrieveOnlyOperation() {
        List<CommitChanges.Change> changes = new List<CommitChanges.Change>();
        changes.add(new CommitChanges.Change(APEX_CLASS_TYPE, 'HelloWorld', '', SFDX, RETRIEVE_ONLY));
        changes.add(new CommitChanges.Change(APEX_TRIGGER_TYPE, 'HelloTrigger', '', SFDX, DELETE_ACTION));
        return createFile(JSON.serialize(changes));
    }

    private static Id createFile(String versionData) {
        ContentVersion fileVersion = (ContentVersion) new ContentVersion_t()
            .title('Changes')
            .pathOnClient('Changes' + '.json')
            .versionData(Blob.valueOf(versionData))
            .persist();
        return fileVersion.Id;
    }

    // INNER CLASS

    /*
     Creating duplicate wrapper in test class because calling 
     HasNoApexWithAddOperationInQualityGate.JobExecutionPayload is not readable
     */
    private class JobExecutionPayload {
        Id fileWithSelectedChanges;
        JobExecutionPayload(Id fileWithSelectedChanges) {
            this.fileWithSelectedChanges = fileWithSelectedChanges;
        }
    }
}