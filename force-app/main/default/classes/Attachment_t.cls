@IsTest
public class Attachment_t extends DomainBuilder {
    public Attachment_t() {
        super(Attachment.SObjectType);
    }

    public Attachment_t recordId(Id recordId) {
        return (Attachment_t) set(Attachment.Id, recordId);
    }

    public Attachment_t name(String name) {
        return (Attachment_t) set(Attachment.Name, name);
    }

    public Attachment_t body(Blob body) {
        return (Attachment_t) set(Attachment.Body, body);
    }

    public Attachment_t parent(DomainBuilder value) {
        setParent(Attachment.ParentId, value);
        return this;
    }

    public Attachment_t parent(Id value) {
        return (Attachment_t) set(Attachment.ParentId, value);
    }
}