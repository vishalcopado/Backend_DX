@IsTest
private class UpdateConflictResolutionFileTest {
    private static final String CONFLICT_RESOLUTION_FILE_NAME = 'GitConflictsResolution.json';

    @IsTest
    private static void executeWhenConflictsResolved() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createContentVersion();
            copado__JobStep__c jobStep = getJobStep();
            copado__Result__c result = createResult(jobStep, null, 'Success', null);
            ContentVersion contentVersion = getContentVersion();

            linkFile(contentVersion.ContentDocumentId, result.Id);
            createAttachmentOn(jobStep.copado__JobExecution__r.copado__Promotion__c);

            // EXERCISE

            UpdateConflictResolutionFile.Request request = new UpdateConflictResolutionFile.Request();
            request.resultId = String.valueOf(result.Id);
            UpdateConflictResolutionFile.execute(new List<UpdateConflictResolutionFile.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> fileOnPromotion = getFileOn(jobStep.copado__JobExecution__r.copado__Promotion__c);
            List<Attachment> attachmentsOnPromotion = getAttachmentOn(jobStep.copado__JobExecution__r.copado__Promotion__c);

            Assert.areEqual(
                contentVersion.ContentDocumentId,
                fileOnPromotion[0]?.ContentDocumentId,
                'GitConflictsResolution.json not Uploaded to Promotion'
            );

            Assert.areEqual(true, attachmentsOnPromotion.size() >= 1, 'GitConflictsResolution.json attachment not Uploaded to Promotion');

            Assert.areEqual(
                CONFLICT_RESOLUTION_FILE_NAME,
                attachmentsOnPromotion[0]?.Name,
                'GitConflictsResolution.json attachment not Uploaded to Promotion'
            );
            Assert.areEqual(
                Blob.valueOf(getConflictsResolutionContent()),
                attachmentsOnPromotion[0]?.Body,
                'GitConflictsResolution.json attachment not Uploaded to Promotion'
            );
        }
    }

    @IsTest
    private static void executeWhenConflictsOccured() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createContentVersion();
            copado__JobStep__c jobStep = getJobStep();
            copado__Result__c result = createResult(jobStep, '{ "status": "conflicts" }', 'Error', null);
            ContentVersion contentVersion = getContentVersion();
            result = getResult();

            linkFile(contentVersion.ContentDocumentId, jobStep.copado__JobExecution__r.copado__Promotion__c);
            createAttachmentOn(jobStep.copado__JobExecution__r.copado__Promotion__c);
            // EXERCISE

            UpdateConflictResolutionFile.Request request = new UpdateConflictResolutionFile.Request();
            request.resultId = String.valueOf(result.Id);
            UpdateConflictResolutionFile.execute(new List<UpdateConflictResolutionFile.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> fileOnPromotion = getFileOn(result.copado__JobStep__r.copado__JobExecution__r.copado__Promotion__c);
            List<Attachment> attachmentsOnPromotion = getAttachmentOn(jobStep.copado__JobExecution__r.copado__Promotion__c);

            Assert.areEqual(0, fileOnPromotion.size(), 'GitConflictsResolution.json on Promotion not removed');
            Assert.areEqual(0, attachmentsOnPromotion.size(), 'GitConflictsResolution.json attachment on Promotion not removed');
        }
    }

    @IsTest
    private static void executeWithDifferentUsersWhenConflictsOccur() {
        User standardUser = TestUtilities.getRunAsUser();
        // SETUP
        createContentVersion();
        copado__JobStep__c jobStep = getJobStep();
        copado__Result__c result = createResult(jobStep, '{ "status": "conflicts" }', 'Error', null);
        ContentVersion contentVersion = getContentVersion();
        result = getResult();
        linkFile(contentVersion.ContentDocumentId, jobStep.copado__JobExecution__r.copado__Promotion__c);

        System.runAs(standardUser) {
            // EXERCISE
            UpdateConflictResolutionFile.Request request = new UpdateConflictResolutionFile.Request();
            request.resultId = String.valueOf(result.Id);
            removePermissionSetAssignment(standardUser.Id);
            UpdateConflictResolutionFile.execute(new List<UpdateConflictResolutionFile.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> fileOnPromotion = getFileOn(result.copado__JobStep__r.copado__JobExecution__r.copado__Promotion__c);
            List<Attachment> attachmentsOnPromotion = getAttachmentOn(jobStep.copado__JobExecution__r.copado__Promotion__c);

            Assert.areEqual(0, fileOnPromotion.size(), 'GitConflictsResolution.json on Promotion not removed');
            Assert.areEqual(0, attachmentsOnPromotion.size(), 'GitConflictsResolution.json attachment on Promotion not removed');
        }
    }

    @IsTest
    private static void executeWithoutAnyConflicts() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__JobStep__c jobStep = getJobStep();
            copado__Result__c result = createResult(jobStep, null, 'Success', null);

            // EXERCISE

            UpdateConflictResolutionFile.Request request = new UpdateConflictResolutionFile.Request();
            request.resultId = String.valueOf(result.Id);
            UpdateConflictResolutionFile.execute(new List<UpdateConflictResolutionFile.Request>{ request });

            // VERIFY

            List<ContentDocumentLink> fileOnPromotion = getFileOn(jobStep.copado__JobExecution__r.copado__Promotion__c);
            List<Attachment> attachmentsOnPromotion = getAttachmentOn(jobStep.copado__JobExecution__r.copado__Promotion__c);
            copado__JobExecution__c jobExecution = getJobExecutionById(jobStep.copado__JobExecution__r.Id);

            Assert.isTrue(attachmentsOnPromotion.isEmpty(), 'There should not be any attachment uploaded on the promotion record');
            Assert.isTrue(fileOnPromotion.isEmpty(), 'There should not be any file uploaded on the promotion record');
            Assert.isTrue(
                String.isBlank(jobExecution?.copado__ErrorMessage__c),
                'The error message field on the job execution is populated with ' + jobExecution?.copado__ErrorMessage__c
            );
        }
    }

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }
    private static void createData() {
        Environment sourceEnv = new Environment();
        Environment destinationEnv = new Environment();

        new Credential(sourceEnv);
        new Credential(destinationEnv);

        Project project = new Project();

        Pipeline pipeline = new Pipeline()
            .repository(new Repository())
            .add(project)
            .add(new PipelineConnection().sourceEnvironment(sourceEnv).destinationEnvironment(destinationEnv));

        pipeline.persist();

        copado__Promotion__c promotion = createPromotion((copado__Project__c) project.record, (copado__Environment__c) sourceEnv.record);

        copado__JobTemplate__c jobTemplate = createJobTemplate('SFDX Promote');

        copado__JobExecution__c jobExecution = createJobExecution(jobTemplate, promotion.Id);

        createJobStep('Promote', jobExecution);
    }

    private static copado__Promotion__c createPromotion(copado__Project__c project, copado__Environment__c sourceEnvironment) {
        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = project.Id,
            copado__Source_Environment__c = sourceEnvironment.Id
        );
        insert promotion;
        return promotion;
    }

    private static copado__JobTemplate__c createJobTemplate(String name) {
        copado__JobTemplate__c jobTemplate = new copado__JobTemplate__c(Name = name, copado__Type__c = 'Custom', copado__Version__c = 1);
        insert jobTemplate;
        return jobTemplate;
    }

    private static copado__JobExecution__c createJobExecution(copado__JobTemplate__c jobTemplate, Id promotionId) {
        copado__JobExecution__c jobExecution = new copado__JobExecution__c(copado__Template__c = jobTemplate.Id, copado__Promotion__c = promotionId);
        insert jobExecution;
        return jobExecution;
    }

    private static copado__JobStep__c createJobStep(String name, copado__JobExecution__c jobExecution) {
        copado__JobStep__c jobStep = new copado__JobStep__c(Name = name, copado__JobExecution__c = jobExecution.Id, copado__Type__c = 'Function');
        insert jobStep;
        return jobStep;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static copado__Result__c createResult(copado__JobStep__c jobStep, String resultData, String status, String errorMessage) {
        copado__Result__c result = new copado__Result__c(
            copado__JobStep__c = jobStep.Id,
            copado__Result_Data__c = resultData,
            copado__Job_Type__c = 'Integration',
            copado__Status__c = status,
            copado__Error_Message__c = errorMessage
        );
        insert result;
        return result;
    }

    private static ContentVersion createContentVersion() {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S';
        contentVersion.PathOnClient = +'.json';
        contentVersion.Title = CONFLICT_RESOLUTION_FILE_NAME;
        contentVersion.VersionData = Blob.valueOf(getConflictsResolutionContent());
        insert contentVersion;
        return contentVersion;
    }

    private static ContentVersion getContentVersion() {
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Title = :CONFLICT_RESOLUTION_FILE_NAME LIMIT 1][0];
    }

    private static String getConflictsResolutionContent() {
        return '[' +
            '{' +
            '"conflictedPath": "force-app/main/default/classes/TemperatureConverter.cls",' +
            '"strategy": "ONLINE",' +
            '"sucessfulPromotion": "79332c1f4b02a8552a2f5744277050de30df588b"' +
            '}' +
            ']';
    }

    private static void linkFile(Id documentId, Id entityId) {
        ContentDocumentLink fileLink = new ContentDocumentLink(ContentDocumentId = documentId, LinkedEntityId = entityId, ShareType = 'V');
        insert fileLink;
    }

    private static copado__Result__c getResult() {
        return [
            SELECT Id, copado__Result_Data__c, copado__Error_Message__c, copado__JobStep__r.copado__JobExecution__r.copado__Promotion__c
            FROM copado__Result__c
            LIMIT 1
        ];
    }

    private static copado__JobStep__c getJobStep() {
        return [SELECT Id, copado__JobExecution__c, copado__JobExecution__r.copado__Promotion__c FROM copado__JobStep__c LIMIT 1][0];
    }

    private static List<ContentDocumentLink> getFileOn(Id entityId) {
        return [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocument.Title = :CONFLICT_RESOLUTION_FILE_NAME AND LinkedEntityId = :entityId
        ];
    }

    private static List<Attachment> getAttachmentOn(Id entityId) {
        return [SELECT Name, Body FROM Attachment WHERE ParentId = :entityId AND Name = :CONFLICT_RESOLUTION_FILE_NAME];
    }

    private static void createAttachmentOn(Id entityId) {
        Attachment att = new Attachment(
            Name = CONFLICT_RESOLUTION_FILE_NAME,
            ParentId = entityId,
            Body = Blob.valueOf(getConflictsResolutionContent())
        );
        insert att;
    }

    private static Id getPromotionId(Id resultId) {
        copado__Result__c result = new ResultsSelector().byIds(new Set<Id>{ resultId })[0];
        return result.copado__JobStep__r.copado__JobExecution__r.copado__Promotion__c;
    }

    private static void removePermissionSetAssignment(Id userId) {
        Set<String> permissions = new Set<String>{ 'Copado_User', 'Copado_Functions', 'Copado_Job_Engine', 'CMC_SFDX_Admin' };
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSet.Name IN :permissions
        ];
        delete permissionSetAssignments;
    }

    private static copado__JobExecution__c getJobExecutionById(Id jobExecutionId) {
        return [SELECT copado__ErrorMessage__c FROM copado__JobExecution__c WHERE Id = :jobExecutionId];
    }
}