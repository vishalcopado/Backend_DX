@IsTest
private class RollbackImplTest {
    private final static String COPADO_ROLLBACK_CHANGES = 'Copado Rollback changes';
    private final static String VLOCITY_ROLLBACK_CHANGES = 'Copado Vlocity Rollback changes';
    private final static String SFDX_ROLLBACK = 'SFDX Rollback';
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testCreateRollbackExecutionWithImmediateExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            RollbackImpl.Response execution = new RollbackImpl().create(request);
            Test.stopTest();

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Id templateId = getTemplateId(SFDX_ROLLBACK);
            RollbackImpl.ExecutionData executionData = (RollbackImpl.ExecutionData) JSON.deserialize(
                execution.job.copado__DataJson__c,
                RollbackImpl.ExecutionData.class
            );

            Assert.areEqual(request.promotionId, execution.job.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(templateId, execution.job.copado__Template__c, 'Template Id is not correct');
            Assert.areEqual(request.testLevel, executionData.testLevel, 'Test Level is not correct');
            Assert.areEqual(promotion.Name, executionData.promotion, 'Promotion Name is not correct');
            Assert.areEqual(request.isValidation, executionData.isValidation, 'Validation should be false');
            Assert.areEqual('staging', executionData.targetBranch, 'Target branch is incorrect');
            Assert.areEqual(getFileId(request.promotionId, COPADO_ROLLBACK_CHANGES), executionData.rollbackFileId, 'File Id is not correct');
            Assert.areEqual(getFileId(request.promotionId, VLOCITY_ROLLBACK_CHANGES), executionData.vlocityRollbackFileId, 'File Id is not correct');
            Assert.areEqual(execution.job.Id, assertPromotion.Last_Rollback_Execution_Id__c, 'Job Id is not correct');
            Assert.areEqual('In Progress', assertPromotion.Rollback_Status__c, 'Rollback Status should be In Progress');
        }
    }

    @IsTest
    private static void testCreateValidationRollbackExecutionWithImmediateExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = true;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            RollbackImpl.Response execution = new RollbackImpl().create(request);
            Test.stopTest();

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Id templateId = getTemplateId(SFDX_ROLLBACK);
            RollbackImpl.ExecutionData executionData = (RollbackImpl.ExecutionData) JSON.deserialize(
                execution.job.copado__DataJson__c,
                RollbackImpl.ExecutionData.class
            );

            Assert.areEqual(request.promotionId, execution.job.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(templateId, execution.job.copado__Template__c, 'Template Id is not correct');
            Assert.areEqual(request.testLevel, executionData.testLevel, 'Test Level is not correct');
            Assert.areEqual(promotion.Name, executionData.promotion, 'Promotion Name is not correct');
            Assert.areEqual(request.isValidation, executionData.isValidation, 'Validation should be false');
            Assert.areEqual('staging', executionData.targetBranch, 'Target branch is incorrect');
            Assert.areEqual(getFileId(request.promotionId, COPADO_ROLLBACK_CHANGES), executionData.rollbackFileId, 'File Id is not correct');
            Assert.areEqual(getFileId(request.promotionId, VLOCITY_ROLLBACK_CHANGES), executionData.vlocityRollbackFileId, 'File Id is not correct');
            Assert.areEqual(execution.job.Id, assertPromotion.Last_Rollback_Execution_Id__c, 'Job Id is not correct');
            Assert.areEqual(
                'In Progress (Validation Only)',
                assertPromotion.Rollback_Status__c,
                'Rollback Status should be In Progress (Validation Only)'
            );
        }
    }

    @IsTest
    private static void testCreateRollbackExecutionWithNotImmediateExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = false;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            RollbackImpl.Response execution = new RollbackImpl().create(request);
            Test.stopTest();

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Id templateId = getTemplateId(SFDX_ROLLBACK);
            RollbackImpl.ExecutionData executionData = (RollbackImpl.ExecutionData) JSON.deserialize(
                execution.job.copado__DataJson__c,
                RollbackImpl.ExecutionData.class
            );

            Assert.areEqual(request.promotionId, execution.job.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(templateId, execution.job.copado__Template__c, 'Template Id is not correct');
            Assert.areEqual(request.testLevel, executionData.testLevel, 'Test Level is not correct');
            Assert.areEqual(promotion.Name, executionData.promotion, 'Promotion Name is not correct');
            Assert.areEqual(request.isValidation, executionData.isValidation, 'Validation should be false');
            Assert.areEqual('staging', executionData.targetBranch, 'Target branch is incorrect');
            Assert.areEqual(getFileId(request.promotionId, COPADO_ROLLBACK_CHANGES), executionData.rollbackFileId, 'File Id is not correct');
            Assert.areEqual(getFileId(request.promotionId, VLOCITY_ROLLBACK_CHANGES), executionData.vlocityRollbackFileId, 'File Id is not correct');
            Assert.areEqual(execution.job.Id, assertPromotion.Last_Rollback_Execution_Id__c, 'Job Id is not correct');
            Assert.areEqual('Not Started', assertPromotion.Rollback_Status__c, 'Rollback Status should be Not Started');
        }
    }

    @IsTest
    private static void testCreateValidationRollbackExecutionWithNotImmediateExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = false;
            request.isValidation = true;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            RollbackImpl.Response execution = new RollbackImpl().create(request);
            Test.stopTest();

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Id templateId = getTemplateId(SFDX_ROLLBACK);
            RollbackImpl.ExecutionData executionData = (RollbackImpl.ExecutionData) JSON.deserialize(
                execution.job.copado__DataJson__c,
                RollbackImpl.ExecutionData.class
            );

            Assert.areEqual(request.promotionId, execution.job.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(templateId, execution.job.copado__Template__c, 'Template Id is not correct');
            Assert.areEqual(request.testLevel, executionData.testLevel, 'Test Level is not correct');
            Assert.areEqual(promotion.Name, executionData.promotion, 'Promotion Name is not correct');
            Assert.areEqual(request.isValidation, executionData.isValidation, 'Validation should be false');
            Assert.areEqual('staging', executionData.targetBranch, 'Target branch is incorrect');
            Assert.areEqual(getFileId(request.promotionId, COPADO_ROLLBACK_CHANGES), executionData.rollbackFileId, 'File Id is not correct');
            Assert.areEqual(getFileId(request.promotionId, VLOCITY_ROLLBACK_CHANGES), executionData.vlocityRollbackFileId, 'File Id is not correct');
            Assert.areEqual(execution.job.Id, assertPromotion.Last_Rollback_Execution_Id__c, 'Job Id is not correct');
            Assert.areEqual('Not Started', assertPromotion.Rollback_Status__c, 'Rollback Status should be Not Started');
        }
    }

    @IsTest
    private static void testCreateRollbackExecutionForBackPromotion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getBackPromotion();

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            RollbackImpl.Response execution = new RollbackImpl().create(request);
            Test.stopTest();

            // VERIFY
            copado__Promotion__c assertPromotion = getBackPromotion();
            Id templateId = getTemplateId(SFDX_ROLLBACK);
            RollbackImpl.ExecutionData executionData = (RollbackImpl.ExecutionData) JSON.deserialize(
                execution.job.copado__DataJson__c,
                RollbackImpl.ExecutionData.class
            );

            Assert.areEqual(request.promotionId, execution.job.copado__Promotion__c, 'Promotion Id is not correct');
            Assert.areEqual(templateId, execution.job.copado__Template__c, 'Template Id is not correct');
            Assert.areEqual(request.testLevel, executionData.testLevel, 'Test Level is not correct');
            Assert.areEqual(promotion.Name, executionData.promotion, 'Promotion Name is not correct');
            Assert.areEqual(request.isValidation, executionData.isValidation, 'Validation should be false');
            Assert.areEqual(getFileId(request.promotionId, COPADO_ROLLBACK_CHANGES), executionData.rollbackFileId, 'File Id is not correct');
            Assert.areEqual('dev1', executionData.targetBranch, 'Target branch is incorrect');
            Assert.areEqual(execution.job.Id, assertPromotion.Last_Rollback_Execution_Id__c, 'Job Id is not correct');
            Assert.areEqual('In Progress', assertPromotion.Rollback_Status__c, 'Rollback Status should be In Progress');
        }
    }
    @IsTest
    private static void testCreateRollbackExecutionWithUnexistingPromotion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion().clone(false, false, false, false);
            insert promotion;
            Id promotionFakeId = promotion.Id;
            delete promotion;
            String error;

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotionFakeId;
            try {
                new RollbackImpl().create(request);
            } catch (Exception ex) {
                error = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.areEqual(
                Label.Promotion_does_not_exists,
                error,
                'The rollback execution failed with error: ' +
                error +
                ' instead of ' +
                Label.Promotion_does_not_exists
            );
        }
    }

    @IsTest
    private static void testCreateRollbackExecutionWithUnexistingFileId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion().clone(false, false, false, false);
            insert promotion;
            String error;

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            try {
                new RollbackImpl().create(request);
            } catch (Exception ex) {
                error = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.areEqual(
                Label.Copado_Rollback_changes_does_not_exists,
                error,
                'The rollback execution failed with error: ' +
                error +
                ' instead of ' +
                Label.Copado_Rollback_changes_does_not_exists
            );
        }
    }

    @IsTest
    private static void testCreateRollbackExecutionWithoutDestinationBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();
            copado__Deployment_Flow_Step__c pipelineConnection = getPipelineConnection();
            pipelineConnection.copado__Destination_Branch__c = '';
            update pipelineConnection;
            String error;

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            try {
                new RollbackImpl().create(request);
            } catch (Exception ex) {
                error = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.areEqual(
                Label.Destination_Branch_is_empty,
                error,
                'The rollback execution failed with error: ' +
                error +
                ' instead of ' +
                Label.Destination_Branch_is_empty
            );
        }
    }

    @IsTest
    private static void testCreateRollbackExecutionWithoutExistingPipelineConnection() {
        // Deletion cannot be performed as a standard user
        copado__Deployment_Flow_Step__c pipelineConnection = getPipelineConnection();
        delete pipelineConnection;

        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();

            String error;

            // EXERCISE
            Test.startTest();
            RollbackImpl.Request request = new RollbackImpl.Request();
            request.startExecution = true;
            request.isValidation = false;
            request.testLevel = 'Run Local Tests';
            request.promotionId = promotion.Id;
            try {
                new RollbackImpl().create(request);
            } catch (Exception ex) {
                error = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.areEqual(
                Label.Pipeline_Connection_does_not_exist,
                error,
                'The rollback execution failed with error: ' +
                error +
                ' instead of ' +
                Label.Pipeline_Connection_does_not_exist
            );
        }
    }

    @IsTest
    private static void testValidationRequestErrors() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Promotion__c promotion = getPromotion();
            String errorPromotionNull;
            String errorTestLevelNull;
            String errorIsValidationNull;
            String errorStartExecutionNull;

            // EXERCISE promotionId null
            RollbackImpl.Request requestPromotionNull = new RollbackImpl.Request();
            requestPromotionNull.startExecution = true;
            requestPromotionNull.isValidation = false;
            requestPromotionNull.testLevel = 'Run Local Tests';

            try {
                new RollbackImpl().create(requestPromotionNull);
            } catch (Exception ex) {
                errorPromotionNull = ex.getMessage();
            }

            // EXERCISE Testlevel null
            RollbackImpl.Request requestTestLevelNull = new RollbackImpl.Request();
            requestTestLevelNull.startExecution = true;
            requestTestLevelNull.isValidation = false;
            requestTestLevelNull.promotionId = promotion.Id;
            try {
                new RollbackImpl().create(requestTestLevelNull);
            } catch (Exception ex) {
                errorTestLevelNull = ex.getMessage();
            }

            // EXERCISE isValidation null
            RollbackImpl.Request requestIsValidationNull = new RollbackImpl.Request();
            requestIsValidationNull.startExecution = true;
            requestIsValidationNull.testLevel = 'Run Local Tests';
            requestIsValidationNull.promotionId = promotion.Id;
            try {
                new RollbackImpl().create(requestIsValidationNull);
            } catch (Exception ex) {
                errorIsValidationNull = ex.getMessage();
            }

            // EXERCISE startExecution null
            RollbackImpl.Request requestStartExecutionNull = new RollbackImpl.Request();
            requestStartExecutionNull.isValidation = true;
            requestStartExecutionNull.testLevel = 'Run Local Tests';
            requestStartExecutionNull.promotionId = promotion.Id;
            try {
                new RollbackImpl().create(requestStartExecutionNull);
            } catch (Exception ex) {
                errorStartExecutionNull = ex.getMessage();
            }

            // VERIFY
            Assert.areEqual(Label.RollbackRequestHasEmptyValues, errorPromotionNull, 'Rollback request error does not match');
            Assert.areEqual(Label.RollbackRequestHasEmptyValues, errorTestLevelNull, 'Rollback request error does not match');
            Assert.areEqual(Label.RollbackRequestHasEmptyValues, errorIsValidationNull, 'Rollback request error does not match');
            Assert.areEqual(Label.RollbackRequestHasEmptyValues, errorStartExecutionNull, 'Rollback request error does not match');
        }
    }

    @IsTest
    private static void testRollbackExecutionCallbackSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            RollbackImpl.ExecutionData executionData = new RollbackImpl.ExecutionData();
            executionData.isValidation = false;

            Promotion promotion = new Promotion().recordId(getPromotion().Id);
            JobTemplate jobTemplate = new JobTemplate().recordId(getTemplateId(SFDX_ROLLBACK));
            JobExecution execution = new JobExecution(jobTemplate).promotion(promotion).dataJSON(JSON.serialize(executionData));
            execution.persist();

            // EXERCISE
            new RollbackImpl().execute((copado__JobExecution__c) execution.record, 'Successful');

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Assert.areEqual(true, assertPromotion.copado__Is_Rolled_Back__c, 'Promotion should be rolled back');
            Assert.areEqual(Date.today(), assertPromotion.Rolled_Back_Date__c, 'Rolled back date should be today');
            Assert.areEqual('Completed', assertPromotion.Rollback_Status__c, 'Roll back status hould be Completed');
        }
    }

    @IsTest
    private static void testValidationRollbackExecutionCallbackSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            RollbackImpl.ExecutionData executionData = new RollbackImpl.ExecutionData();
            executionData.isValidation = true;

            Promotion promotion = new Promotion().recordId(getPromotion().Id);
            JobTemplate jobTemplate = new JobTemplate().recordId(getTemplateId(SFDX_ROLLBACK));
            JobExecution execution = new JobExecution(jobTemplate).promotion(promotion).dataJSON(JSON.serialize(executionData));
            execution.persist();

            // EXERCISE
            new RollbackImpl().execute((copado__JobExecution__c) execution.record, 'Successful');

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Assert.areEqual(false, assertPromotion.copado__Is_Rolled_Back__c, 'Promotion should be rolled back');
            Assert.areEqual(Date.today(), assertPromotion.Rolled_Back_Date__c, 'Rolled back date should be today');
            Assert.areEqual('Validated', assertPromotion.Rollback_Status__c, 'Roll back status hould be Validate');
        }
    }

    @IsTest
    private static void testRollbackExecutionCallbackError() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            RollbackImpl.ExecutionData executionData = new RollbackImpl.ExecutionData();
            executionData.isValidation = false;

            Promotion promotion = new Promotion().recordId(getPromotion().Id);
            JobTemplate jobTemplate = new JobTemplate().recordId(getTemplateId(SFDX_ROLLBACK));
            JobExecution execution = new JobExecution(jobTemplate).promotion(promotion).dataJSON(JSON.serialize(executionData));
            execution.persist();

            // EXERCISE
            new RollbackImpl().execute((copado__JobExecution__c) execution.record, 'Error');

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Assert.areEqual(false, assertPromotion.copado__Is_Rolled_Back__c, 'Promotion should not be rolled back');
            Assert.areEqual(Date.today(), assertPromotion.Rolled_Back_Date__c, 'Rolled back date should be today');
            Assert.areEqual('Failed', assertPromotion.Rollback_Status__c, 'Roll back status hould be Failed');
        }
    }

    @IsTest
    private static void testValidationRollbackExecutionCallbackError() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            RollbackImpl.ExecutionData executionData = new RollbackImpl.ExecutionData();
            executionData.isValidation = true;

            Promotion promotion = new Promotion().recordId(getPromotion().Id);
            JobTemplate jobTemplate = new JobTemplate().recordId(getTemplateId(SFDX_ROLLBACK));
            JobExecution execution = new JobExecution(jobTemplate).promotion(promotion).dataJSON(JSON.serialize(executionData));
            execution.persist();

            // EXERCISE
            new RollbackImpl().execute((copado__JobExecution__c) execution.record, 'Error');

            // VERIFY
            copado__Promotion__c assertPromotion = getPromotion();
            Assert.areEqual(false, assertPromotion.copado__Is_Rolled_Back__c, 'Promotion should not be rolled back');
            Assert.areEqual(Date.today(), assertPromotion.Rolled_Back_Date__c, 'Rolled back date should be today');
            Assert.areEqual('Validation Failed', assertPromotion.Rollback_Status__c, 'Roll back status hould be Validation Failed');
        }
    }

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1);
            new Credential(staging);

            Pipeline pipeline = new Pipeline()
                .name('MyPipeline')
                .mainBranch('staging')
                .platform('SFDX')
                .repository(new Repository().name('Repo'))
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).branch('dev1').destinationBranch('staging'));

            Project project = new Project(pipeline).name('MyProject');

            project.persist();

            JobTemplate jobTemplate = new JobTemplate().name(SFDX_ROLLBACK).type('Custom').apiName('SFDX_Rollback_1');
            new JobStep(jobTemplate).name('Rollback Step').type('Function').persist();

            // I can't use Domain Builder here.

            copado__Promotion__c promotion = new copado__Promotion__c(
                copado__Project__c = getProjectId(),
                copado__Source_Environment__c = getEnvironmentId('Dev1'),
                copado__Source_Org_Credential__c = getCredentialId('dev1'),
                copado__Destination_Environment__c = getEnvironmentId('Staging'),
                copado__Destination_Org_Credential__c = getCredentialId('staging')
            );
            insert promotion;
            createFile(promotion.Id, COPADO_ROLLBACK_CHANGES);
            createFile(promotion.Id, VLOCITY_ROLLBACK_CHANGES);

            // back promotion
            copado__Promotion__c backPromotion = new copado__Promotion__c(
                copado__Project__c = getProjectId(),
                copado__Source_Environment__c = getEnvironmentId('Staging'),
                copado__Source_Org_Credential__c = getCredentialId('staging'),
                copado__Destination_Environment__c = getEnvironmentId('Dev1'),
                copado__Destination_Org_Credential__c = getCredentialId('dev1'),
                copado__Back_Promotion__c = true
            );
            insert backPromotion;

            createFile(backPromotion.Id, COPADO_ROLLBACK_CHANGES);
        }
    }

    private static copado__Promotion__c getPromotion() {
        return [
            SELECT
                Id,
                Name,
                copado__Project__c,
                copado__Source_Environment__c,
                copado__Source_Org_Credential__c,
                copado__Destination_Environment__c,
                copado__Destination_Org_Credential__c,
                copado__Is_Rolled_Back__c,
                Last_Rollback_Execution_Id__c,
                Rolled_Back_Date__c,
                Rollback_Status__c
            FROM copado__Promotion__c
            WHERE copado__Project__r.Name = 'MyProject' AND copado__Back_Promotion__c = FALSE
            LIMIT 1
        ][0];
    }

    private static copado__Promotion__c getBackPromotion() {
        return [
            SELECT
                Id,
                Name,
                copado__Project__c,
                copado__Source_Environment__c,
                copado__Source_Org_Credential__c,
                copado__Destination_Environment__c,
                copado__Destination_Org_Credential__c,
                copado__Is_Rolled_Back__c,
                Last_Rollback_Execution_Id__c,
                Rolled_Back_Date__c,
                Rollback_Status__c
            FROM copado__Promotion__c
            WHERE copado__Project__r.Name = 'MyProject' AND copado__Back_Promotion__c = TRUE
            LIMIT 1
        ][0];
    }

    private static Id getProjectId() {
        return [SELECT Id FROM copado__Project__c WHERE Name = 'MyProject' LIMIT 1][0].Id;
    }

    private static Id getCredentialId(String name) {
        return [SELECT Id FROM copado__Org__c WHERE Name = :name LIMIT 1][0].Id;
    }

    private static Id getEnvironmentId(String name) {
        return [SELECT Id FROM copado__Environment__c WHERE Name = :name LIMIT 1][0].Id;
    }

    private static Id getTemplateId(String name) {
        return [SELECT Id FROM copado__JobTemplate__c WHERE Name = :name LIMIT 1][0].Id;
    }

    private static copado__Deployment_Flow_Step__c getPipelineConnection() {
        return [SELECT Id, copado__Destination_Branch__c FROM copado__Deployment_Flow_Step__c LIMIT 1][0];
    }

    private static Id getFileId(Id promotionId, String title) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ promotionId }, new Set<String>{ title })[0]
            .ContentDocument.LatestPublishedVersionId;
    }

    private static void createFile(Id promotionId, String title) {
        String base64Content = EncodingUtil.Base64Encode(Blob.valueOf('Testing File'));
        Blob blobContent = EncodingUtil.base64Decode(base64Content);
        ContentVersion contentVersion = new ContentVersion(Title = title, PathOnClient = title + '.json', VersionData = blobContent);
        insert contentVersion;
        contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = promotionId,
            Visibility = 'AllUsers'
        );
        insert contentDocumentLink;
    }
}