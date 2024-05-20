public with sharing class PipelineDistributionCtrl {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static UserStoryDetails getExistingStoryDetails(Id userStoryId) {
        try {
            copado__User_Story__c userStory = new UserStoriesSelector().byIds(new Set<Id>{ userStoryId }).get(0);

            return makeUserStoryDetails(userStory);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static UserStoryDetails getNewStoryDetails(String newSerializedUserStory) {
        try {
            copado__User_Story__c userStory = (copado__User_Story__c) JSON.deserialize(newSerializedUserStory, copado__User_Story__c.class);

            return makeUserStoryDetails(userStory);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFieldsFromFieldSet(String objectApiName, String fieldSet) {
        List<String> result = new List<String>();

        for (
            FieldSetMember field : Schema.getGlobalDescribe()
                .get(objectApiName)
                .getDescribe()
                .fieldSets.getMap()
                .get(Settings.NS + fieldSet)
                .getFields()
        ) {
            result.add(field.getFieldPath());
        }

        return result;
    }

    // PRIVATE

    private static UserStoryDetails makeUserStoryDetails(copado__User_Story__c userStory) {
        UserStoryDetails result = new UserStoryDetails();

        copado__Org__c credential = fetchCredential(userStory.copado__Org_Credential__c);

        copado__Project__c project = fetchProject(userStory.copado__Project__c);

        copado__Release__c release = fetchRelease(userStory.copado__Release__c);

        copado__Deployment_Flow_Step__c pipelineConnection = fetchPipelineConnection(
            project?.copado__Deployment_Flow__c,
            credential?.copado__Environment__c
        );

        result.pipelineName = project?.copado__Deployment_Flow__r?.Name;
        result.currentEnvironment = credential?.copado__Environment__r.Name;
        result.nextEnvironment = pipelineConnection?.copado__Destination_Environment__r.Name;
        result.userStoryNumber = userStory.Name;
        result.userStoryTitle = userStory?.copado__User_Story_Title__c;
        result.project = project?.Name;
        result.release = release?.Name;

        return result;
    }

    private static copado__Deployment_Flow_Step__c fetchPipelineConnection(Id pipelineId, Id sourceEnvironment) {
        List<copado__Deployment_Flow_Step__c> result = new PipelineConnectionsSelector()
            .byPipelineAndSourceEnv(new Set<Id>{ pipelineId }, new Set<Id>{ sourceEnvironment });
        if (result.isEmpty()) {
            throw new ApplicationException(Label.Credential_Not_Part_Of_Environment_In_Pipeline);
        }
        return result[0];
    }

    private static copado__Org__c fetchCredential(Id credentialId) {
        return String.isNotBlank(credentialId) ? new CredentialsSelector().byIds(new List<Id>{ credentialId }).get(0) : null;
    }

    private static copado__Project__c fetchProject(Id projectId) {
        return String.isNotBlank(projectId) ? new ProjectsSelector().byIds(new Set<Id>{ projectId }).get(0) : null;
    }

    private static copado__Release__c fetchRelease(Id releaseId) {
        return String.isNotBlank(releaseId) ? new ReleasesSelector().byIds(new Set<Id>{ releaseId }).get(0) : null;
    }

    // INNER

    public class UserStoryDetails {
        @AuraEnabled
        public String pipelineName;
        @AuraEnabled
        public String currentEnvironment;
        @AuraEnabled
        public String nextEnvironment;
        @AuraEnabled
        public String userStoryNumber;
        @AuraEnabled
        public String userStoryTitle;
        @AuraEnabled
        public String project;
        @AuraEnabled
        public String release;
    }
}