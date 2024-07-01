@IsTest
private class InitializeSFDXProjectTest {
    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }
    @IsTest
    private static void executeWithJobTemplate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobTemplate jobTemplate = new JobTemplate().name(SFDX_GIT_INITIALIZATION).apiName('SFDX Git Initialization_1').type('Custom');
            new JobStep(jobTemplate).name('Initialize Git with SFDX Project').type('Function').persist();
            update new copado__JobTemplate__c(Id = jobTemplate.id, copado__ApiName__c = 'SFDX Git Initialization_1');

            String projectDetails = getProjectDetails();

            // EXERCISE

            List<copado__JobExecution__c> result = InitializeSFDXProject.execute(projectDetails);

            // VERIFY

            copado__JobExecution__c latestExecutionResult = getLatestExecutionResult();
            Assert.areEqual(latestExecutionResult.Id, result[0].Id, 'The result id is incorrect');
            Assert.areEqual(latestExecutionResult.Name, result[0].Name, 'The result name is incorrect');
        }
    }

    @IsTest
    private static void executeWithoutJobTemplate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String projectDetails = getProjectDetails();
            String exceptionMessage;

            // EXERCISE

            try {
                InitializeSFDXProject.execute(projectDetails);
            } catch (Exception error) {
                exceptionMessage = error?.getMessage();
            }

            // VERIFY

            Assert.isTrue(
                exceptionMessage.contains('Invalid template name SFDX Git Initialization_1, it must be a valid Template Api Name'),
                'The relevent error should be thrown'
            );
        }
    }

    @IsTest
    private static void executeWithEmptyRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String projectDetails = '';
            String exceptionMessage;

            // EXERCISE

            try {
                InitializeSFDXProject.execute(projectDetails);
            } catch (Exception error) {
                exceptionMessage = error?.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('No content to map to Object'), 'The relevent error should be thrown');
        }
    }

    private static String getProjectDetails() {
        InitializeSFDXProject.ProjectInitializationDetails result = new InitializeSFDXProject.ProjectInitializationDetails();
        result.branch = 'main';
        result.defaultDirectory = 'force-app';
        result.gitRepositoryId = fflib_IDGenerator.generate('a0q');
        result.projectName = 'mywork';
        result.recreateProject = true;
        result.template = 'standard';
        return JSON.serialize(result);
    }

    private static copado__JobExecution__c getLatestExecutionResult() {
        return [
            SELECT Id, Name
            FROM copado__JobExecution__c
            WHERE copado__Template__r.Name = 'SFDX Git Initialization'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }
}