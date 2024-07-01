@IsTest
public class ContentVersion_t extends DomainBuilder {
    public ContentVersion_t() {
        super(ContentVersion.SObjectType);
    }

    public ContentVersion_t title(String value) {
        return (ContentVersion_t) set(ContentVersion.Title, value);
    }

    public ContentVersion_t pathOnClient(String value) {
        return (ContentVersion_t) set(ContentVersion.PathOnClient, value);
    }

    public ContentVersion_t versionData(Blob value) {
        return (ContentVersion_t) set(ContentVersion.VersionData, value);
    }

    public ContentVersion_t firstPublishLocationId(Id value) {
        return (ContentVersion_t) set(ContentVersion.FirstPublishLocationId, value);
    }

    public ContentVersion_t contentDocumentId(Id value) {
        return (ContentVersion_t) set(ContentVersion.ContentDocumentId, value);
    }
}