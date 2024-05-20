public with sharing class UserStoryCommitTableActionsCtrl {
    @AuraEnabled(cacheable=true)
    public static Boolean isSourceMemberAvailable(String credentialId) {
        try {
            validateCredentialId(credentialId);
            if (!Test.isRunningTest()) {
                DateTime dateTimeToRetrieveChanges = DateTime.now().addMinutes(-1);
                new copado.GlobalAPI().getRecentChanges(credentialId, dateTimeToRetrieveChanges);
            }
            return true;
        } catch (Exception ex) {
            if (ex.getMessage() != null && ex.getMessage().contains('sObject type \'SourceMember\' is not supported')) {
                return false;
            } else {
                throw new ApplicationException().auraHandled(ex);
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SobjectItem> listAllSobjectsInOrg(String credentialId) {
        try {
            List<SobjectItem> options = new List<SobjectItem>();
            for (String type : MetadataTypes.supportedMetadataTypes()) {
                SobjectItem option = new SobjectItem();
                option.Label = type;
                option.Name = type;
                options.add(option);
            }
            return options;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<copado.SourceMemberResult> retrieveRecentChanges(String orgId, DateTime dateTimeToRetrieveChanges) {
        try {
            List<copado.SourceMemberResult> results = new List<copado.SourceMemberResult>();
            if (!Test.isRunningTest()) {
                results = new copado.GlobalAPI().getRecentChanges(orgId, dateTimeToRetrieveChanges);
            } else {
                results = new List<copado.SourceMemberResult>{ getSmrDataForTestClass() };
            }
            return results;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<MetadataSearchResult> searchMetadata(String orgId, String type, String searchTerm) {
        try {
            return new SearchMetadata(orgId, type, searchTerm).execute();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<copado__User_Story_Metadata__c> getUserStoryMetadata(String recordId) {
        return new UserStoryMetadataSelector().byUserStoryId(new Set<Id>{ recordId });
    }

    @AuraEnabled
    public static String getDeletedMetadatas(Id credentialId, String fileName) {
        try {
            if (String.isBlank(credentialId)) {
                throw new ApplicationException(Label.Credential_Not_Found);
            }
            return ContentDocumentHelper.getContentVersionData(credentialId, fileName);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static copado.SourceMemberResult getSmrDataForTestClass() {
        copado.SourceMemberResult smr = new copado.SourceMemberResult();
        smr.CreatedDate = String.valueOf(System.now());
        smr.CreatedBy = new copado.SourceMemberResult.LookupUserField();
        smr.CreatedBy.Name = 'Test name';
        smr.LastModifiedDate = String.valueOf(System.now());
        smr.LastModifiedBy = new copado.SourceMemberResult.LookupUserField();
        smr.LastModifiedBy.Name = 'Test name';
        smr.IsNameObsolete = false;
        smr.MemberName = 'test';
        smr.MemberType = 'ApexClass';
        return smr;
    }

    private static void validateCredentialId(Id credentialId) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }

        copado.ValidateOrgAction.Request request = new copado.ValidateOrgAction.Request();
        request.orgId = credentialId;

        List<copado.ValidateOrgAction.Result> result = copado.ValidateOrgAction.execute(new List<copado.ValidateOrgAction.Request>{ request });
        Boolean isValid = !result.isEmpty() ? result.get(0).isValidOrg : false;

        if (!isValid) {
            throw new ApplicationException(Label.Org_Is_Not_Valid);
        }
    }
}