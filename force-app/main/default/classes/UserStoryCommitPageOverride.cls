public with sharing class UserStoryCommitPageOverride {
    private static final String SFDX_USER_STORY_COMMIT_PAGE_OVERRIDE = '{$Context.Property.SFDXUserStoryCommitPageOverride}';

    // PUBLIC

    @AuraEnabled
    public static Boolean execute(Id userStoryId) {
        try {
            Id contextId = getPipelineId(userStoryId);
            copado.Jobs.DynamicExpressionEvaluateRequest request = new copado.Jobs.DynamicExpressionEvaluateRequest(
                contextId , new List<String>{ SFDX_USER_STORY_COMMIT_PAGE_OVERRIDE }
            );

            List<copado.Jobs.DynamicExpressionEvaluateResult> responses = copado.Jobs.DynamicExpression.evaluate(request);
            return String.isBlank(responses[0]?.value) ? false : Boolean.valueOf(responses[0]?.value);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE 

    private static Id getPipelineId(Id userStoryId) {
        Id result;
        List<copado__User_Story__c> userStories = new UserStoriesSelector().byIds(new Set<Id> { userStoryId });
        result = userStories[0].copado__Project__r.copado__Deployment_Flow__c;

        if (String.isBlank(result)) {
            throw new ApplicationException(Label.UserStory_Not_Associated_With_Pipeline);
        }

        return result;
    }
}