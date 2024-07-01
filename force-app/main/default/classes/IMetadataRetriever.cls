public interface IMetadataRetriever {
    IMetadataRetriever configure(String type, String searchTerm);
    Object execute(String credentialId);
    List<MetadataSearchResult> handle(Object result);
}