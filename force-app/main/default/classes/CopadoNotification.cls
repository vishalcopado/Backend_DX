@IsTest
public class CopadoNotification extends DomainBuilder {
    public CopadoNotification() {
        super(copado__Copado_Notification__c.SObjectType);
    }

    public CopadoNotification(Credential credential) {
        super(copado__Copado_Notification__c.SObjectType);
        setParent(copado__Copado_Notification__c.copado__ParentId__c, credential);
    }

    public CopadoNotification recordId(Id value) {
        return (CopadoNotification) set(copado__Copado_Notification__c.Id, value);
    }

    public CopadoNotification isFinished(Boolean value) {
        return (CopadoNotification) set(copado__Copado_Notification__c.copado__isFinished__c, value);
    }

    public CopadoNotification isSuccess(Boolean value) {
        return (CopadoNotification) set(copado__Copado_Notification__c.copado__isSuccess__c, value);
    }

    public CopadoNotification status(String value) {
        return (CopadoNotification) set(copado__Copado_Notification__c.copado__status__c, value);
    }

    public CopadoNotification message(String value) {
        return (CopadoNotification) set(copado__Copado_Notification__c.copado__Message__c, value);
    }

    public CopadoNotification parentId(Id value) {
        return (CopadoNotification) set(copado__Copado_Notification__c.copado__ParentId__c, value);
    }
}