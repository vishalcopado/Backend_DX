public with sharing class SearchMetadata {
    private String credentialId;
    private String type;
    private String searchTerm;

    // CTOR

    public SearchMetadata(String credentialId, String type, String searchTerm) {
        this.credentialId = credentialId;
        this.type = type;
        this.searchTerm = searchTerm;
    }

    // PUBLIC

    public List<MetadataSearchResult> execute() {
        IMetadataRetriever retriever = new MetadataRetrieverFactory().getRetriever(type);

        Object apiResult = retriever.configure(type, searchTerm).execute(credentialId);
        List<MetadataSearchResult> result = retriever.handle(apiResult);

        return result;
    }
}