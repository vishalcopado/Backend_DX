@IsTest
public class Credential extends DomainBuilder {
    public Credential(Environment env) {
        super(copado__Org__c.SObjectType);
        set(copado__Org__c.copado__Validated_Date__c, System.now());
        setParent(copado__Org__c.copado__Environment__c, env);
        type('Production/Developer');
    }

    public Credential() {
        this(new Environment());
    }

    public Credential type(String value) {
        return (Credential) set(copado__Org__c.copado__Org_Type__c, value);
    }

    public Credential default(Boolean value) {
        return (Credential) set(copado__Org__c.copado__Default_Credential__c, value);
    }

    public Credential orgId(String value) {
        return (Credential) set(copado__Org__c.copado__SFDC_Org_ID__c, value);
    }

    public Credential devhub(Boolean value) {
        return (Credential) set(copado__Org__c.copado__is_Developer_Hub_Org__c, value);
    }

    public Credential recordId(Id recordId) {
        return (Credential) set(copado__Org__c.Id, recordId);
    }

    public Credential name(String name) {
        return (Credential) set(copado__Org__c.Name, name);
    }

    public Credential sfdcOrgId(String sfdcOrgId) {
        return (Credential) set(copado__Org__c.copado__SFDC_Org_ID__c, sfdcOrgId);
    }

    public Credential oauthSignature(String value) {
        return (Credential) set(copado__Org__c.copado__Oauth_Signature__c, value);
    }

    public Credential validatedDate(Datetime validatedDate) {
        return (Credential) set(copado__Org__c.copado__Validated_Date__c, validatedDate);
    }
}