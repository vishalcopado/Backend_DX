@IsTest
private class RemoveValidationIdFromPromotionTest {
    @IsTest
    private static void onInsert() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            createData('SFDX');
            copado__Promotion__c promotion = promotion();
            promotion.Validate_Deploy_Request_Id__c = fflib_IDGenerator.generate('0Af');
            update promotion;

            System.assert(promotion().Validate_Deploy_Request_Id__c != null, 'Validate Deploy Request Id should not be null');

            // EXERCISE

            List<copado__User_Story__c> userStories = new List<copado__User_Story__c>{ createUserStory(project(), source()) };
            insert userStories;
            addUserStoriesToPromotion(userStories, promotion);

            // VERIFY
            System.assert(promotion().Validate_Deploy_Request_Id__c == null, 'Validate Deploy Request Id should be null');
        }
    }

    @IsTest
    private static void onDelete() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            createData('SFDX');
            copado__Promotion__c promotion = promotion();
            promotion.Validate_Deploy_Request_Id__c = fflib_IDGenerator.generate('0Af');
            update promotion;
            System.assert(promotion.Validate_Deploy_Request_Id__c != null, 'Validate Deploy Request Id should not be null');

            // EXERCISE

            deleteUserStoryFromPromotion(promotion);

            // VERIFY
            System.assert(promotion().Validate_Deploy_Request_Id__c == null, 'Validate Deploy Request Id should be null');
        }
    }

    /* 
        This test aims to check isSfdxPlatform() method inside "PromotedUserStories.cls" class. 
        That is why only "on update" is tested. On Insert and on delete uses same isSfdxPlatform() hence behaviour will be the same.
    */
    @IsTest
    private static void promotedUserStoriesTriggerNotFiredForClassic() {
        User classicUser = TestUtilities.getRunAsUser();
        TestUtilities.removePermissionSet(classicUser.Id, new Set<String>{ 'Copado_Functions', 'Copado_Job_Engine', 'CMC_SFDX_Admin' });
        System.runAs(classicUser) {
            // SETUP
            createData('Salesforce');
            Id validationId = fflib_IDGenerator.generate('0Af');

            // EXERCISE

            copado__Promotion__c promotion = promotion();
            promotion.Validate_Deploy_Request_Id__c = validationId;
            update promotion;

            // VERIFY

            System.assertEquals(validationId, promotion().Validate_Deploy_Request_Id__c, 'Validate Deploy Request Id should be the same');
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.setup();
    }

    // PRIVATE

    private static void deleteUserStoryFromPromotion(copado__Promotion__c promotion) {
        delete [SELECT Id FROM copado__Promoted_User_Story__c WHERE copado__Promotion__c = :promotion.Id LIMIT 1];
    }

    private static void createData(String platform) {
        Environment sourceEnv = new Environment().platform(platform);
        Environment destinationEnv = new Environment().platform(platform);

        Credential sourceCred = new Credential(sourceEnv);
        new Credential(destinationEnv);

        Project project = new Project();

        Pipeline pipeline = new Pipeline()
            .platform(platform)
            .repository(new Repository())
            .add(project)
            .add(new PipelineConnection().sourceEnvironment(sourceEnv).destinationEnvironment(destinationEnv));

        pipeline.persist();

        copado__Promotion__c promotion = createPromotion((copado__Project__c) project.record, (copado__Environment__c) sourceEnv.record);

        List<copado__User_Story__c> userStoriesList = new List<copado__User_Story__c>();
        userStoriesList.add(createUserStory((copado__Project__c) project.record, (copado__Org__c) sourceCred.record));
        userStoriesList.add(createUserStory((copado__Project__c) project.record, (copado__Org__c) sourceCred.record));

        insert userStoriesList;

        addUserStoriesToPromotion(userStoriesList, promotion);
    }

    private static void addUserStoriesToPromotion(List<copado__User_Story__c> userStories, copado__Promotion__c promotion) {
        List<copado__Promoted_User_Story__c> promotedUserStories = new List<copado__Promoted_User_Story__c>();
        for (copado__User_Story__c us : userStories) {
            promotedUserStories.add(new copado__Promoted_User_Story__c(copado__Promotion__c = promotion.Id, copado__User_Story__c = us.Id));
        }
        insert promotedUserStories;
    }

    private static copado__Promotion__c createPromotion(copado__Project__c project, copado__Environment__c sourceEnvironment) {
        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = project.Id,
            copado__Source_Environment__c = sourceEnvironment.Id
        );
        insert promotion;
        return promotion;
    }

    private static copado__User_Story__c createUserStory(copado__Project__c project, copado__Org__c credential) {
        return new copado__User_Story__c(copado__Project__c = project.Id, copado__Org_Credential__c = credential.Id);
    }

    private static copado__Promotion__c promotion() {
        return [SELECT Id, copado__Project__r.copado__Deployment_Flow__c, Validate_Deploy_Request_Id__c FROM copado__Promotion__c LIMIT 1];
    }

    private static copado__Project__c project() {
        return [SELECT Id FROM copado__Project__c LIMIT 1];
    }

    private static copado__Org__c source() {
        Id pipelineId = promotion().copado__Project__r.copado__Deployment_Flow__c;
        Id sourceEnv = [SELECT copado__Source_Environment__c FROM copado__Deployment_Flow_Step__c WHERE copado__Deployment_Flow__c = :pipelineId]
        .copado__Source_Environment__c;
        return [SELECT Id, copado__Environment__c FROM copado__Org__c WHERE copado__Environment__c = :sourceEnv][0];
    }
}