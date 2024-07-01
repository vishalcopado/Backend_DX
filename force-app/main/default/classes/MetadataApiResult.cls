@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class MetadataApiResult {
    public List<MetadataRecord> records { get; set; }

    public class MetadataRecord {
        private Attributes attributes;
        public String createdById { get; set; }
        public String createdByName { get; set; }
        public String createdDate { get; set; }
        public String fileName { get; set; }
        public String fullName { get; set; }
        public String id { get; set; }
        public String lastModifiedById { get; set; }
        public String lastModifiedByName { get; set; }
        public String lastModifiedDate { get; set; }
        public String manageableState { get; set; }
        public String namespacePrefix { get; set; }
        public String type { get; set; }
    }

    public class Attributes {
        private String type;
        private String url;
    }

    public static MetadataApiResult fromResponse(String response) {
        MetadataApiResult result = new MetadataApiResult();

        String unescapedXml = response.unescapeJava();
        String contentJson = XmlToJsonParser.xmlToJson(unescapedXml);
        result.records = parseResponse(contentJson);

        return result;
    }

    private static List<MetadataRecord> parseResponse(String contentJson) {
        List<MetadataRecord> result = new List<MetadataRecord>();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(contentJson);
        if (responseMap.containsKey('Envelope')) {
            Map<String, Object> envelopeMap = (Map<String, Object>) responseMap.get('Envelope');
            if (envelopeMap.containsKey('Body')) {
                Map<String, Object> bodyMap = (Map<String, Object>) envelopeMap.get('Body');
                if (bodyMap.containsKey('listMetadataResponse')) {
                    Object listMetadataResponse = (Object) bodyMap.get('listMetadataResponse');
                    result.addAll(parseListMetadataResponse(listMetadataResponse));
                }
            }
        }
        return result;
    }

    private static List<MetadataRecord> parseListMetadataResponse(Object listMetadataResponse) {
        List<MetadataRecord> result = new List<MetadataRecord>();
        if (JSON.serialize(listMetadataResponse).startsWith('[')) {
            List<MetadataRecord> metadataRecords = (List<MetadataRecord>) JSON.deserialize(
                JSON.serialize(listMetadataResponse),
                List<MetadataRecord>.class
            );
            result.addAll(metadataRecords);
        } else {
            Map<String, Object> listMap = (Map<String, Object>) listMetadataResponse;
            if (listMap.containsKey('result')) {
                MetadataRecord metadataRecord = (MetadataRecord) JSON.deserialize(JSON.serialize(listMap.get('result')), MetadataRecord.class);
                result.add(metadataRecord);
            }
        }
        return result;
    }
}