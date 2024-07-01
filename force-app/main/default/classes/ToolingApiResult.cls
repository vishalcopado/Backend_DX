@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class ToolingApiResult {
    public Integer size;
    public Integer totalSize;
    public Boolean done;
    public Object queryLocator;
    public String entityTypeName;
    public List<MetadataRecord> records { get; set; }

    public class MetadataRecord {
        private Attributes attributes;
        public String id { get; set; }
        public String fullName { get; set; }
        public EntityDefinition definition { get; set; }
        public EntityDefinition entityDefinition { get; set; }
        public String namespacePrefix { get; set; }
        public String name { get; set; }
        public String validationName { get; set; }
        public String developerName { get; set; }
        public String masterLabel { get; set; }
        public String createdDate { get; set; }
        public String lastModifiedDate { get; set; }
        public CreatedBy createdBy { get; set; }
        public LastModifiedBy lastModifiedBy { get; set; }
    }

    public class EntityDefinition {
        private Attributes attributes;
        public String namespacePrefix { get; set; }
        public String developerName { get; set; }
        public String lastModifiedDate { get; set; }
    }

    public class CreatedBy {
        private Attributes attributes;
        public String name { get; set; }
    }

    public class LastModifiedBy {
        private Attributes attributes;
        public String name { get; set; }
    }

    public class Attributes {
        private String type;
        private String url;
    }
}