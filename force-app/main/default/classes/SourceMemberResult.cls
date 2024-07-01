@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.FormalParameterNamingConventions,PMD.FieldNamingConventions')
global with sharing class SourceMemberResult {
    @AuraEnabled
    global String CreatedDate;
    @AuraEnabled
    global LookupUserField CreatedBy;
    @AuraEnabled
    global String LastModifiedDate;
    @AuraEnabled
    global LookupUserField LastModifiedBy;
    @AuraEnabled
    global Boolean IsNameObsolete;
    @AuraEnabled
    global String MemberName;
    @AuraEnabled
    global String MemberType;

    @TestVisible
    private SourceMemberResult(String memberName, String memberType, Boolean IsNameObsolete){
        this.MemberName = memberName;
        this.MemberType = memberType;
        this.IsNameObsolete = IsNameObsolete;
        this.CreatedDate = String.valueOf(Datetime.now());
        this.LastModifiedDate = String.valueOf(Datetime.now());
        this.CreatedBy = new LookupUserField('User User');
        this.LastModifiedBy = new LookupUserField('User User');
    }

    global with sharing class LookupUserField {
        @AuraEnabled
        global String Name;
        @TestVisible
        private LookupUserField(String name) {
            this.Name = name;
        }
    }
}