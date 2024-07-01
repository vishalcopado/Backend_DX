@IsTest
private with sharing class UserStoryCommitTest {
    private static final String METADATA_FILE = 'MetaData';
    private static final String VLOCITY_FILE = 'Vlocity.json';
    private static final String VLOCITY_ENABLED = 'vlocity_enabled';

    @TestSetup
    private static void setup() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void isReCreateFeatureBranchAvailable() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__Personal_Settings__c personalSettings = copado__Personal_Settings__c.getInstance();
            personalSettings.copado__Disable_Re_Create_Feature_Branch_in_US__c = true;
            upsert personalSettings;

            // Exercise
            Boolean isReCreateFeatureBranchAvailable = UserStoryCommit.isReCreateFeatureBranchAvailable();

            // Verify
            Assert.areEqual(true, !isReCreateFeatureBranchAvailable, 'Re-create feature branch option should not be available');
        }
    }

    @IsTest
    private static void commitChanges() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory().Id;

            UserStoryCommitRequest request = new UserStoryCommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.executeCommit = true;

            // Exercise
            Test.startTest();
            UserStoryCommit.commitChanges(request);
            Test.stopTest();

            // Verify
            Assert.areEqual(
                1,
                [SELECT COUNT() FROM ContentVersion WHERE Title = 'Copado Commit changes'],
                'Copado Commit changes.json file should have been upserted'
            );

            // Verify callback
            Assert.areNotEqual(
                null,
                getUserStory().copado__Latest_Commit_Date__c,
                'User_Story__c should have been updated with Latest_Commit_Date__c in callback execution'
            );
        }
    }

    @IsTest
    private static void commitChangesException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup & Exercise
            String exceptionMessage;
            Test.startTest();
            try {
                UserStoryCommitRequest request = new UserStoryCommitRequest();
                UserStoryCommit.commitChanges(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            Assert.areEqual(true, String.isNotBlank(exceptionMessage), 'Exception should have been thrown');
        }
    }

    @IsTest
    private static void validateCommitRequirements() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory().Id;
            copado__Deployment_Flow__c flow = getPipeline();
            flow.copado__Block_Commits__c = true;
            update flow;

            // Exercise
            Test.startTest();
            List<String> errors = UserStoryCommit.validateCommitRequirements(userStoryId, TestUtilities.getRunAsUser().Id);
            Test.stopTest();

            // Verify
            Assert.areEqual(true, !errors.isEmpty(), 'There should be some validation errors');
        }
    }

    @IsTest
    private static void validateCommitRequirementsException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            String exceptionMessage;

            // Exercise
            Test.startTest();
            try {
                UserStoryCommit.validateCommitRequirements('', TestUtilities.getRunAsUser().Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            Assert.areEqual(true, String.isNotBlank(exceptionMessage), 'Exception should have been thrown');
        }
    }

    @IsTest
    private static void validateCommitRequirementsWhenUserStoryInProgress() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id userStoryId = getUserStory().Id;
            UserStoryCommit_t usCommit = new UserStoryCommit_t(new SnapshotCommit().credentialId(getCredentialObj('Dev1').Id))
                .userStoryId(userStoryId);
            TestUtilities.createJobExecution(TestUtilities.getTemplateObj('Commit Template'), TestUtilities.getEnvironmentObj('Dev2'), '{}')
                .status('In Progress')
                .source(TestUtilities.getEnvironmentObj('Dev1'))
                .userStoryCommit(usCommit)
                .persist();

            // EXERCISE
            Test.startTest();
            List<String> errors = UserStoryCommit.validateCommitRequirements(userStoryId, TestUtilities.getRunAsUser().Id);
            Test.stopTest();

            // VERIFY
            Assert.areEqual(Label.UserStoryCommitInProgress, errors[0], 'There should be validation error if User Story is already in progress.');
        }
    }

    @IsTest
    private static void validateCommitRequirementsAndFetchUserStoryMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStory().Id;
            copado__Deployment_Flow__c flow = getPipeline();
            flow.copado__Block_Commits__c = true;
            update flow;

            new UserStoryMetadata_t().name('SampleClass').type('ApexClass').action('Add').userStory(new UserStory().recordId(userStoryId));
            new UserStoryMetadata_t()
                .name('SampleApexPage')
                .type('ApexPage')
                .action('Add')
                .userStory(new UserStory().recordId(userStoryId))
                .persist();

            // EXERCISE

            Test.startTest();
            UserStoryCommit.ValidationErrorsAndUserStoryMetadata result = UserStoryCommit.validateCommitRequirementsAndFetchUserStoryMetadata(
                userStoryId,
                TestUtilities.getRunAsUser().Id
            );
            Test.stopTest();

            // VERIFY

            Assert.areEqual(true, !result.validationErrors.isEmpty(), 'There should be some validation errors');
            Assert.areEqual(2, result.userStoryMetadata.size(), 'The user story metadata should be returned successfully');
        }
    }

    @IsTest
    private static void checkIfVlocityEnabledAndFetchMetadataVlocityFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getUserStory().copado__Org_Credential__c;
            Id pipelineId = getPipeline().Id;

            // EXERCISE
            Test.startTest();
            UserStoryCommit.IsVlocityPipelineAndMetadataFiles result = UserStoryCommit.getVlocityDetailsAndIndexFiles(
                credentialId,
                pipelineId
            );
            Test.stopTest();
            // VERIFY

            Assert.areEqual(true, result.isVlocityEnabled, 'The vlocity enabled property should be true');
            Assert.areEqual(2, result.contentVersionIds?.size(), 'The number of contentVersionIds returned should be 2');
        }
    }

    @IsTest
    private static void testgetDateTime24HoursAgo() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE
            Test.startTest();
            Datetime result = UserStoryCommit.getDateTime24HoursAgo();
            Test.stopTest();
            // VERIFY

            Assert.areEqual(Datetime.now().addHours(-24), result, 'The datetime returned is incorrect');
        }
    }

    private static void createData() {
        JobTemplate jobTemplate = new JobTemplate().name('Commit Template').apiName('Commit').type('Custom').add(new JobStep().type('Function'));

        Credential source = new Credential();

        Pipeline pipeline = new Pipeline()
            .mainBranch('main')
            .platform('SFDX')
            .add(
                new PipelineConnection()
                    .sourceEnvironment(new Environment().platform('SFDX').add(source).name('Dev1'))
                    .destinationEnvironment(new Environment().platform('SFDX').name('Stage').add(new Credential()))
                    .branch('dev1')
            )
            .add(
                new PipelineConnection()
                    .sourceEnvironment(new Environment().platform('SFDX').add(new Credential()).name('Dev2'))
                    .destinationEnvironment(new Environment().platform('SFDX').name('Stage').add(new Credential()))
                    .branch('dev2')
            )
            .add(new Project().add(new UserStory().credential(source)));
        createPipelineAction(pipeline, jobTemplate, 'Commit');
        createSystemProperties(pipeline, 'true', VLOCITY_ENABLED);

        ContentVersion vlocityFile = (ContentVersion) new ContentVersion_t()
            .pathOnClient(VLOCITY_FILE)
            .title(VLOCITY_FILE)
            .versionData(Blob.valueOf('Vlocity')).persist();

        ContentVersion metadataFile = (ContentVersion) new ContentVersion_t()
            .pathOnClient(METADATA_FILE)
            .title(METADATA_FILE)
            .versionData(Blob.valueOf('Metadata'))
            .persist();

        ContentVersion vlocityFileDetails = getContentVersion(vlocityFile.Id);
        createDocumentLink(vlocityFileDetails.ContentDocumentId, source.id);
        ContentVersion metadataFileDetails = getContentVersion(metadataFile.Id);
        createDocumentLink(metadataFileDetails.ContentDocumentId, source.id);
    }

    private static void createPipelineAction(Pipeline pipeline, JobTemplate template, String action) {
        new PipelineAction(pipeline).template(template).action(action);
    }

    private static copado__User_Story__c getUserStory() {
        return [SELECT copado__Org_Credential__c, copado__Latest_Commit_Date__c FROM copado__User_Story__c][0];
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];
    }

    private static List<MetadataItem> changes() {
        List<MetadataItem> result = new List<MetadataItem>();

        for (Integer i = 0; i < 10; i++) {
            MetadataItem change = new MetadataItem();
            change.a = 'add';
            change.n = 'TestClass_' + i;
            change.t = 'ApexClass';
            change.m = 'force-app/main/default';
            change.c = 'category';
            change.j = '{"vk": "6368cb8e-776c-4ad6-9906-444d460715d7"}';
            result.add(change);
        }

        return result;
    }

    private static Credential getCredentialObj(String envName) {
        return new Credential().recordId(getCredentialByEnvName(envName).Id);
    }

    private static copado__Org__c getCredentialByEnvName(String value) {
        return [
            SELECT Id, copado__Environment__r.Name, CreatedDate
            FROM copado__Org__c
            WHERE copado__Environment__r.Name = :value
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    private static void createDocumentLink(Id contentDocumentId, Id linkedEntityId) {
        insert new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = linkedEntityId, ShareType = 'V');
    }

    private static ContentVersion getContentVersion(Id contentVersionId) {
        return [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
    }

    private static SystemProperty createSystemProperties(Pipeline pipeline, String value, String apiName) {
        return new SystemProperty(pipeline).apiName(apiName).value(value);
    }
}