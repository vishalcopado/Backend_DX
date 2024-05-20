public with sharing class ConfigurePipelineDistributionStep {
    private Request request;
    private copado__Artifact_Version__c version;
    private static final String SFDX_PLATFORM = 'SFDX';
    private static final String SALESFORCE_PLATFORM = 'Salesforce';
    private static final List<String> USERSTORY_FIELDS = new List<String>{
        'copado__User_Story_Title__c',
        'copado__Status__c',
        'copado__Project__c',
        'copado__Release__c',
        'copado__Org_Credential__c',
        'copado__Environment__c'
    };

    // CTOR

    public ConfigurePipelineDistributionStep(Request request) {
        this.request = request;
    }

    // PUBLIC

    @InvocableMethod(label='Create deployment step for user story' category='Package Distribution')
    public static List<Result> createDeploymentStep(List<Request> requests) {
        try {
            Result result = new Result();
            result.userStoryId = new ConfigurePipelineDistributionStep(requests[0]).execute();

            return new List<Result>{ result };
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    public Id execute() {
        Id userStoryId = String.isBlank(request.existingUserStoryId) ? createUserStory() : request.existingUserStoryId;
        version = getpackageVersion();
        String platform = getPlatform(userStoryId);
        String stepName = buildStepName();
        String installSecurityType = request.installSecurityType;

        if (platform.equals(SFDX_PLATFORM)) {
            new JobStepCreate(version.Id, userStoryId, stepName, installSecurityType).execute();
        } else if (platform.equals(SALESFORCE_PLATFORM)) {
            new DeploymentTaskCreate(version.Id, userStoryId, stepName, installSecurityType).execute();
        }

        return userStoryId;
    }

    // PRIVATE

    private Id createUserStory() {
        copado__User_Story__c userStory = (copado__User_Story__c) JSON.deserialize(request.newSerializedUserStory, copado__User_Story__c.class);
        fflib_ISObjectUnitOfWork unitOfWork = unitOfWork();
        fflib_SecurityUtils.checkInsert(copado__User_Story__c.SObjectType, USERSTORY_FIELDS);
        unitOfWork.registerNew(userStory);
        unitOfWork.commitWork();

        return userStory.Id;
    }

    private static fflib_SObjectUnitOfWork unitOfWork() {
        return new fflib_SObjectUnitOfWork(new List<SObjectType>{ copado__User_Story__c.SObjectType });
    }

    private copado__Artifact_Version__c getpackageVersion() {
        List<copado__Artifact_Version__c> versions = new PackageVersionsSelector().byIds(new Set<Id>{ request.packageVersionId });
        if (versions.isEmpty()) {
            throw new ApplicationException(Label.Selected_Version_is_Unavailable);
        }

        return versions[0];
    }

    private String getPlatform(Id userStoryId) {
        List<copado__User_Story__c> userStories = new UserStoriesSelector().byIds(new Set<Id>{ userStoryId });
        if (userStories.isEmpty()) {
            throw new ApplicationException(Label.The_selected_user_story_is_unavailable);
        }

        String platform = userStories[0].copado__Platform__c;
        if (String.isBlank(platform)) {
            throw new ApplicationException(Label.Populate_a_Valid_Pipeline_with_Platform);
        }

        return platform;
    }

    private String buildStepName() {
        return 'Start ' + version.copado__Artifact__r.Name + ' - ' + version.copado__Version_number__c + ' Installation Job';
    }

    // INNER PUBLIC

    public class Request {
        @InvocableVariable(label='Existing User Story Id')
        public String existingUserStoryId;

        @InvocableVariable(label='New Serialized User Story')
        public String newSerializedUserStory;

        @InvocableVariable(label='Package Version Id' required=true)
        public String packageVersionId;

        @InvocableVariable(label='Package Installation Security Type')
        public String installSecurityType;
    }

    public class Result {
        @InvocableVariable(label='User Story Id')
        public String userStoryId;
    }
}