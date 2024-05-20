public with sharing class MetadataRetrieverFactory {
    public IMetadataRetriever getRetriever(String type) {
        if (MetadataTypes.toolingApiTypes().contains(type)) {
            return new ToolingApiMetadataRetriever();
        }
        return new MetadataApiMetadataRetriever();
    }
}