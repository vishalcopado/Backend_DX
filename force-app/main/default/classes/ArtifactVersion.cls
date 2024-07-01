@IsTest
public class ArtifactVersion extends DomainBuilder {
    public ArtifactVersion(Artifact artifact) {
        super(copado__Artifact_Version__c.SObjectType);
        setParent(copado__Artifact_Version__c.copado__Artifact__c, artifact);
    }

    public ArtifactVersion() {
        this(new Artifact());
    }

    public ArtifactVersion name(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Name, value);
    }

    public ArtifactVersion versionNumber(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Version_number__c, value);
    }

    public ArtifactVersion versionId(Id value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Subscriber_Version_Id__c, value);
    }

    public ArtifactVersion description(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Version_Description__c, value);
    }

    public ArtifactVersion versionName(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Version_Name__c, value);
    }

    public ArtifactVersion postInstallUrl(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Post_Install_URL__c, value);
    }

    public ArtifactVersion postInstallScript(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Post_Install_Script__c, value);
    }

    public ArtifactVersion releaseNotesUrl(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Release_Notes_URL__c, value);
    }

    public ArtifactVersion uninstallScript(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Uninstall_Script__c, value);
    }

    public ArtifactVersion definitionFile(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__DefinitionFile__c, value);
    }

    public ArtifactVersion ancestorVersion(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Ancestor_Version__c, value);
    }

    public ArtifactVersion ancestorId(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Ancestor_Id__c, value);
    }

    public ArtifactVersion isReleased(Boolean value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Is_released__c, value);
    }

    public ArtifactVersion subscriberId(Id value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Subscriber_Version_Id__c, value);
    }

    public ArtifactVersion recordId(Id recordId) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Id, recordId);
    }

    public ArtifactVersion codeCoverage(Boolean value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Code_Coverage__c, value);
    }

    public ArtifactVersion dataJSON(String value){
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Data_JSON__c, value);
    }

    public ArtifactVersion tag(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Tag__c, value);
    }

    public ArtifactVersion branch(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.copado__Branch__c, value);
    }

    public ArtifactVersion apiVersion(String value) {
        return (ArtifactVersion) set(copado__Artifact_Version__c.Api_Version__c, value);
    }

    public ArtifactVersion release(Release release) {
        setParent(copado__Artifact_Version__c.copado__Release__c, release);
        return this;
    }
}