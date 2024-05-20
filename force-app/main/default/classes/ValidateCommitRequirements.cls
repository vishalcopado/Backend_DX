@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class ValidateCommitRequirements {
    private static final String COMMIT_ACTION = 'Commit';
    private Id recordId;
    private Id userId;
    private copado__User_Story__c userStory {
        get {
            if (userStory == null) {
                List<copado__User_Story__c> userStories = new UserStoriesSelector().byIds(new Set<Id>{ this.recordId });
                if (!userStories.isEmpty()) {
                    userStory = userStories[0];
                }
            }
            return userStory;
        }
        set;
    }

    // CTOR

    public ValidateCommitRequirements(Id recordId, Id userId) {
        this.recordId = recordId;
        this.userId = userId;
    }

    // PUBLIC

    public List<String> execute() {
        if (userStory == null) {
            throw new ApplicationException(Label.InvalidUserStoryForValidation);
        }

        List<String> result = new List<String>();

        copado__Deployment_Flow__c pipeline = getPipelineFromUserStory(userStory);
        List<ValidationError> validationErrors = getValidationErrors(userStory, pipeline);

        result.addAll(groupErrorsByPriority(validationErrors));

        return result;
    }

    // PRIVATE
    private List<ValidationError> getValidationErrors(copado__User_Story__c userStory, copado__Deployment_Flow__c pipeline) {
        List<ValidationError> validationErrors = new List<ValidationError>();
        validationErrors.addAll(hasRequiredLicenses());
        validationErrors.addAll(hasSobjectPermissions());
        validationErrors.addAll(validatePipeline(pipeline));
        validationErrors.addAll(validateUserStory(userStory));
        validationErrors.addAll(commitNotInProgress(userStory, pipeline));

        return validationErrors;
    }

    private static List<String> groupErrorsByPriority(List<ValidationError> validationErrors) {
        List<String> higherPriorityErrors = new List<String>();
        List<String> lowerPriorityErrors = new List<String>();

        for (ValidationError validationError : validationErrors) {
            if (validationError.getPriority() == 1) {
                higherPriorityErrors.add(validationError.getMesssage());
            } else if (validationError.getPriority() == 2) {
                lowerPriorityErrors.add(validationError.getMesssage());
            }
        }

        return higherPriorityErrors.isEmpty() ? lowerPriorityErrors : higherPriorityErrors;
    }

    private static List<ValidationError> commitNotInProgress(copado__User_Story__c userStory, copado__Deployment_Flow__c pipeline) {
        List<ValidationError> result = new List<ValidationError>();
        String templateApiName = new ActionTemplate(COMMIT_ACTION, pipeline.Id).getApiName();
        List<copado__JobExecution__c> jobExecution = new JobExecutionsSelector()
            .byUserStoryTemplateAndStatus(userStory.Id, 'In Progress', templateApiName);

        if (!jobExecution.isEmpty()) {
            result.add(new ValidationError().priority(1).message(Label.UserStoryCommitInProgress));
        }

        return result;
    }

    private List<ValidationError> hasRequiredLicenses() {
        List<ValidationError> result = new List<ValidationError>();
        CheckLicense licenseInfo = new CheckLicense(this.userId);

        if (CheckLicense.areLicensesExceeded()) {
            result.add(new ValidationError().priority(1).message(Label.LICENSES_EXCEEDED));
        }

        if (!licenseInfo.has('Copado User') && !licenseInfo.has('Copado Admin')) {
            result.add(new ValidationError().priority(1).message(Label.CCM_License_Restriction));
        }

        if (!copado.Feature.isCCMEnabled()) {
            result.add(new ValidationError().priority(1).message(Label.FEATURE_NOT_SUPPORTED + ' Change Management'));
        }

        return result;
    }

    private static List<ValidationError> hasSobjectPermissions() {
        List<ValidationError> result = new List<ValidationError>();

        if (!Schema.SObjectType.copado__User_Story__c.isUpdateable()) {
            result.add(new ValidationError().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.copado__User_Story__c.Label)));
        }

        if (!Schema.SObjectType.copado__Deployment_Flow__c.isAccessible()) {
            result.add(new ValidationError().priority(1).message(Label.MISSING_PERMISSIONS_CBM_FLOW));
        }

        if (
            !Schema.SObjectType.copado__User_Story_Metadata__c.isCreateable() ||
            !Schema.SObjectType.copado__User_Story_Metadata__c.isUpdateable() ||
            !Schema.SObjectType.copado__User_Story_Metadata__c.isDeletable()
        ) {
            result.add(
                new ValidationError().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.copado__User_Story_Metadata__c.Label))
            );
        }

        if (!Schema.SObjectType.copado__Git_Org_Commit__c.isCreateable()) {
            result.add(new ValidationError().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.copado__Git_Org_Commit__c.Label)));
        }

        if (!Schema.SObjectType.copado__User_Story_Commit__c.isCreateable()) {
            result.add(new ValidationError().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.copado__User_Story_Commit__c.Label)));
        }

        return result;
    }

    private static String insufficientAccessOnObject(String objectLabel) {
        return String.format(Label.InsufficientAccessObject, new List<String>{ objectLabel });
    }

    private static List<ValidationError> validateUserStory(copado__User_Story__c userStory) {
        List<ValidationError> result = new List<ValidationError>();

        if (String.isBlank(userStory.copado__Project__c) && String.isBlank(userStory.copado__Release__r.copado__Project__c)) {
            result.add(new ValidationError().priority(2).message(Label.UserStoryWithoutProject));
        }

        if (String.isBlank(userStory.copado__Environment__c)) {
            result.add(new ValidationError().priority(2).message(Label.USER_STORY_COMMIT_NO_ENVIRONMENT));
        }

        if (userStory.copado__Org_Credential__r.copado__Validated_Date__c == null) {
            result.add(new ValidationError().priority(2).message(Label.Org_Is_Not_Valid));
        }

        return result;
    }

    private static List<ValidationError> validatePipeline(copado__Deployment_Flow__c pipeline) {
        List<ValidationError> result = new List<ValidationError>();

        if (pipeline != null && pipeline.copado__Block_Commits__c) {
            result.add(new ValidationError().priority(1).message(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED));
        }

        if (pipeline == null || !pipeline.copado__Active__c) {
            result.add(new ValidationError().priority(2).message(Label.PROMOTION_FLOW_INACTIVE));
        }

        return result;
    }

    private static copado__Deployment_Flow__c getPipelineFromUserStory(copado__User_Story__c userStory) {
        Id pipelineId = String.isNotBlank(userStory.copado__Project__r.copado__Deployment_Flow__c)
            ? userStory.copado__Project__r.copado__Deployment_Flow__c
            : userStory?.copado__Release__r?.copado__Project__r?.copado__Deployment_Flow__c;
        return pipelineId != null ? new PipelinesSelector().byId(new Set<Id>{ pipelineId })[0] : null;
    }

    //INNER

    private with sharing class ValidationError {
        private Integer priority;
        private String message;

        public ValidationError priority(Integer priority) {
            this.priority = priority;
            return this;
        }

        public Integer getPriority() {
            return this.priority;
        }

        public ValidationError message(String message) {
            this.message = message;
            return this;
        }

        public String getMesssage() {
            return this.message;
        }
    }
}