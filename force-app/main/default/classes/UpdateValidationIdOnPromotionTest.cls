@IsTest
private class UpdateValidationIdOnPromotionTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void setValidationIdForSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__JobStep__c jobStep = getJobStep(true);
            String resultData = '{ "validationId": "testValidationId" }';
            copado__Result__c result = createResult(jobStep, resultData, null, 'Success');
            copado__Result__c fetchedResult = getResult(jobStep.Id);

            // Exercise
            Test.startTest();

            UpdateValidationIdOnPromotion.Request request = new UpdateValidationIdOnPromotion.Request();
            request.resultId = String.valueOf(fetchedResult.Id);
            UpdateValidationIdOnPromotion.execute(new List<UpdateValidationIdOnPromotion.Request>{ request });

            Test.stopTest();

            // Verify
            String validationIdOnPromotionRecord = getPromotionById(
                    fetchedResult.copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c
                )
                .Validate_Deploy_Request_Id__c;
            copado__JobExecution__c jobExecution = getJobExecution();
            System.assertEquals(
                'testValidationId',
                validationIdOnPromotionRecord,
                'Validation Id on the Result data was not set successfully set on the Promotion Record'
            );
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'There was some error updating validation id');
        }
    }

    @IsTest
    private static void handleNoValidationIdForSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__JobStep__c jobStep = getJobStep(true);
            copado__Result__c result = createResult(jobStep, null, null, 'Success');
            copado__Result__c fetchedResult = getResult(jobStep.Id);

            // Exercise
            Test.startTest();

            UpdateValidationIdOnPromotion.Request request = new UpdateValidationIdOnPromotion.Request();
            request.resultId = String.valueOf(fetchedResult.Id);
            UpdateValidationIdOnPromotion.execute(new List<UpdateValidationIdOnPromotion.Request>{ request });

            Test.stopTest();

            // Verify
            String validationIdOnPromotionRecord = getPromotionById(
                    fetchedResult.copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c
                )
                .Validate_Deploy_Request_Id__c;
            copado__JobExecution__c jobExecution = getJobExecution();
            System.assertEquals(
                null,
                validationIdOnPromotionRecord,
                'Validation Id on the Result data was not set successfully set on the Promotion Record'
            );
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'There was some error updating validation id');
        }
    }

    @IsTest
    private static void removeValidationIdForFailedDeployment() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__JobStep__c jobStep = getJobStep(false);
            copado__Result__c result = createResult(jobStep, null, null, 'Failed');
            copado__Result__c fetchedResult = getResult(jobStep.Id);
            updateValidationIdOnPromotion(fetchedResult);

            // Exercise
            Test.startTest();

            UpdateValidationIdOnPromotion.Request request = new UpdateValidationIdOnPromotion.Request();
            request.resultId = String.valueOf(fetchedResult.Id);
            UpdateValidationIdOnPromotion.execute(new List<UpdateValidationIdOnPromotion.Request>{ request });

            Test.stopTest();

            // Verify
            String validationIdOnPromotionRecord = getPromotionById(
                    fetchedResult.copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c
                )
                .Validate_Deploy_Request_Id__c;
            copado__JobExecution__c jobExecution = getJobExecution();
            System.assertEquals(null, validationIdOnPromotionRecord, 'Validation Id was not set to blank on the Promotion Record');
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'There was some error updating validation id');
        }
    }

    @IsTest
    private static void handleCancelledDeployments() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__JobStep__c jobStep = getJobStep(false);
            copado__Result__c result = createResult(jobStep, null, 'The deployment was cancelled on the target org', 'Failed');
            copado__Result__c fetchedResult = getResult(jobStep.Id);
            updateValidationIdOnPromotion(fetchedResult);

            // Exercise
            Test.startTest();

            String validationIdOnPromotionRecordPrev = getPromotionById(
                fetchedResult.copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c
            )
            .Validate_Deploy_Request_Id__c;

            UpdateValidationIdOnPromotion.Request request = new UpdateValidationIdOnPromotion.Request();
            request.resultId = String.valueOf(fetchedResult.Id);
            UpdateValidationIdOnPromotion.execute(new List<UpdateValidationIdOnPromotion.Request>{ request });

            Test.stopTest();

            // Verify
            String validationIdOnPromotionRecord = getPromotionById(
                    fetchedResult.copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c
                )
                .Validate_Deploy_Request_Id__c;
            copado__JobExecution__c jobExecution = getJobExecution();
            System.assertNotEquals(null, validationIdOnPromotionRecord, 'Validation Id was not set to blank on the Promotion Record');
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'There was some error updating validation id');
        }
    }

    @IsTest
    private static void removeValidationIdForSameDestinationDeployment() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__JobStep__c jobStep = getJobStep(false);
            copado__Result__c result = createResult(jobStep, null, null, 'Success');
            copado__Result__c fetchedResult = getResult(jobStep.Id);
            updateValidationIdOnPromotion(fetchedResult);

            // Exercise
            Test.startTest();

            UpdateValidationIdOnPromotion.Request request = new UpdateValidationIdOnPromotion.Request();
            request.resultId = String.valueOf(fetchedResult.Id);
            UpdateValidationIdOnPromotion.execute(new List<UpdateValidationIdOnPromotion.Request>{ request });

            Test.stopTest();

            // Verify
            List<copado__Promotion__c> promotionsWtihSameDestination = getPromotionsByDestinationId(
                fetchedResult.copado__JobStep__r.copado__JobExecution__r.copado__Destination__c
            );
            copado__JobExecution__c jobExecution = getJobExecution();
            for (copado__Promotion__c promotion : promotionsWtihSameDestination) {
                System.assertEquals(null, promotion.Validate_Deploy_Request_Id__c, 'Validation Id was not set to null on the Promotion Record');
            }
            System.assertEquals(null, jobExecution.copado__ErrorMessage__c, 'There was some error updating validation id');
        }
    }

    private static copado__JobStep__c getJobStep(Boolean isValidation) {
        copado__Deployment__c deployment = getDeployment();
        copado__JobTemplate__c jobTemplate = getJobTemplate();
        copado__JobExecution__c jobExecution = createJobExecution(jobTemplate, deployment, '{ "deploymentDryRun": "' + isValidation + '" }', getDestinationId());
        copado__JobStep__c jobStep = createJobStep('Deploy', jobExecution);
        return jobStep;
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT copado__ErrorMessage__c FROM copado__JobExecution__c LIMIT 1];
    }

    private static copado__Promotion__c getPromotionById(Id promotionId) {
        return [SELECT Id, Validate_Deploy_Request_Id__c FROM copado__Promotion__c WHERE Id = :promotionId LIMIT 1][0];
    }

    private static List<copado__Promotion__c> getPromotionsByDestinationId(Id destinationId) {
        return [SELECT Id, Validate_Deploy_Request_Id__c FROM copado__Promotion__c WHERE copado__Destination_Environment__c = :destinationId];
    }

    private static copado__Result__c getResult(Id jobStepId) {
        return [
            SELECT
                Id,
                copado__Result_Data__c,
                copado__JobStep__r.copado__JobExecution__r.copado__DataJson__c,
                copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c,
                copado__JobStep__r.copado__JobExecution__r.copado__Destination__c
            FROM copado__Result__c
            WHERE copado__JobStep__c = :jobStepId
            LIMIT 1
        ][0];
    }

    private static copado__Deployment__c getDeployment() {
        return [SELECT Id FROM copado__Deployment__c LIMIT 1][0];
    }

    private static copado__JobTemplate__c getJobTemplate() {
        return [SELECT Id FROM copado__JobTemplate__c LIMIT 1][0];
    }
    private static void createData() {
        Environment sourceEnv = new Environment();
        Environment destinationEnv = new Environment();

        Credential sourceCred = new Credential(sourceEnv);
        Credential destinationCred = new Credential(destinationEnv);

        Project project = new Project();

        Pipeline pipeline = new Pipeline()
            .repository(new Repository())
            .add(project)
            .add(new PipelineConnection().sourceEnvironment(sourceEnv).destinationEnvironment(destinationEnv));

        pipeline.persist();

        copado__Promotion__c promotion = createPromotion((copado__Project__c) project.record, (copado__Environment__c) sourceEnv.record);

        copado__Deployment__c deployment = createDeployment(promotion);

        copado__JobTemplate__c jobTemplate = createJobTemplate('SFDX Deploy');
    }

    private static copado__Promotion__c createPromotion(copado__Project__c project, copado__Environment__c sourceEnvironment) {
        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = project.Id,
            copado__Source_Environment__c = sourceEnvironment.Id
        );
        insert promotion;
        return promotion;
    }

    private static copado__Deployment__c createDeployment(copado__Promotion__c promotion) {
        copado__Deployment__c deployment = new copado__Deployment__c(copado__Promotion__c = promotion.Id);
        insert deployment;
        return deployment;
    }

    private static copado__JobTemplate__c createJobTemplate(String name) {
        copado__JobTemplate__c jobTemplate = new copado__JobTemplate__c(Name = name, copado__Type__c = 'Custom', copado__Version__c = 1);
        insert jobTemplate;
        return jobTemplate;
    }

    private static copado__JobExecution__c createJobExecution(
        copado__JobTemplate__c jobTemplate,
        copado__Deployment__c deployment,
        String dataJson,
        Id destinationId
    ) {
        copado__JobExecution__c jobExecution = new copado__JobExecution__c(
            copado__Template__c = jobTemplate.Id,
            copado__Deployment__c = deployment.Id,
            copado__DataJson__c = dataJson,
            copado__Destination__c = destinationId
        );
        insert jobExecution;
        return jobExecution;
    }

    private static copado__JobStep__c createJobStep(String name, copado__JobExecution__c jobExecution) {
        copado__JobStep__c jobStep = new copado__JobStep__c(Name = name, copado__JobExecution__c = jobExecution.Id, copado__Type__c = 'Function');
        insert jobStep;
        return jobStep;
    }

    private static copado__Result__c createResult(copado__JobStep__c jobStep, String resultData, String errorMessage, String status) {
        copado__Result__c result = new copado__Result__c(
            copado__JobStep__c = jobStep.Id,
            copado__Result_Data__c = resultData,
            copado__Error_Message__c = errorMessage,
            copado__Job_Type__c = 'Integration',
            copado__Status__c = status
        );
        insert result;
        return result;
    }

    private static Id getDestinationId() {
        return [SELECT copado__Destination_Environment__c FROM copado__Deployment_Flow_Step__c LIMIT 1][0].copado__Destination_Environment__c;
    }

    private static void removePermissionSets(Set<String> permissions, Id userId) {
        Map<Id, PermissionSet> permissionSet = new Map<Id, PermissionSet>([SELECT Id, Name FROM PermissionSet WHERE Name IN :permissions]);
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetId IN :permissionSet.keySet()
        ];
        delete assignments;
    }

    private static void updateValidationIdOnPromotion(copado__Result__c result) {
        copado__Promotion__c promotion = getPromotionById(
            result.copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c
        );
        promotion.Validate_Deploy_Request_Id__c = fflib_IDGenerator.generate('0Af');
        update promotion;
    }
}