public with sharing class UserStoryCommit {
    private static final String METADATA_FILE = 'MetaData';
    private static final String VLOCITY_FILE = 'Vlocity.json';
    @AuraEnabled
    public static copado__JobExecution__c commitChanges(UserStoryCommitRequest request) {
        try {
            return copado.CommitAction.commitChanges(new List<copado.CommitAction.Request>{ request.parse() })[0].jobExecution;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isReCreateFeatureBranchAvailable() {
        try {
            return !copado__Personal_Settings__c.getInstance().copado__Disable_Re_Create_Feature_Branch_in_US__c;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static List<String> validateCommitRequirements(String recordId, String userId) {
        try {
            return new ValidateCommitRequirements(recordId, userId).execute();
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static ValidationErrorsAndUserStoryMetadata validateCommitRequirementsAndFetchUserStoryMetadata(String recordId, String userId) {
        try {
            ValidationErrorsAndUserStoryMetadata result = new ValidationErrorsAndUserStoryMetadata();
            result.validationErrors = new ValidateCommitRequirements(recordId, userId).execute();
            result.userStoryMetadata = UserStoryCommitTableActionsCtrl.getUserStoryMetadata(recordId);
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static IsVlocityPipelineAndMetadataFiles getVlocityDetailsAndIndexFiles(String credentialId, String pipelineId) {
        try {
            IsVlocityPipelineAndMetadataFiles result = new IsVlocityPipelineAndMetadataFiles();
            result.isVlocityEnabled = CheckVlocityEnabled.execute(Id.valueOf(pipelineId));
            result.contentVersionIds = getContentVersionIds(credentialId, result.isVlocityEnabled);
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static Datetime getDateTime24HoursAgo(){
        try {
            return Datetime.now().addHours(-24);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    private static List<String> getFileNames(Boolean isVlocityEnabled) {
        List<String> result = new List<String>{ METADATA_FILE };
        if (isVlocityEnabled) {
            result.add(VLOCITY_FILE);
        }
        return result;
    }

    private static List<String> getContentVersionIds(String credentialId, Boolean isVlocityEnabled) {
        List<String> result = new List<String>();
        List<GetRefreshIndexContent.Response> fileDetails = GetRefreshIndexContent.execute(
            credentialId,
            getFileNames(isVlocityEnabled)
        );
        for (GetRefreshIndexContent.Response fileDetail : fileDetails) {
            if (fileDetail.isSuccess == false) {
                throw new ApplicationException(String.isNotBlank(fileDetail.message) ? fileDetail.message : Label.Failure_Fetching_File);
            } else {
                result.add(fileDetail.recordId);
            }
        }
        return result;
    }

    public with sharing class ValidationErrorsAndUserStoryMetadata {
        @AuraEnabled
        public List<String> validationErrors { get; set; }
        @AuraEnabled
        public List<copado__User_Story_Metadata__c> userStoryMetadata { get; set; }
    }

    public with sharing class IsVlocityPipelineAndMetadataFiles {
        public @AuraEnabled
        List<Id> contentVersionIds { get; set; }
        @AuraEnabled
        public Boolean isVlocityEnabled { get; set; }
    }
}