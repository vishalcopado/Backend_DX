public inherited sharing virtual class CopadoServerCallout extends HttpCallout {
    // CTOR

    public CopadoServerCallout(String url, HttpMethod method) {
        super(url, method);
    }

    // PUBLIC

    public CopadoServerCallout default() {
        header('userId', UserInfo.getUserId());
        header('orgId', UserInfo.getOrganizationId());
        header('token', authenticationToken());
        header('Accept', 'application/json');
        header('content-type', 'application/json');
        timeout(30000);
        return this;
    }

    // PRIVATE

    private String authenticationToken() {
        String fakeSessionId = '<sessionId might change>';
        String currentDate = Datetime.now().formatGmt('yyyy-MM-dd');
        String dummyData = 'Copado Deployer by Copado Ltd' + UserInfo.getUserId() + UserInfo.getOrganizationId() + fakeSessionId + currentDate;
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(dummyData));
        return EncodingUtil.convertToHex(hash);
    }
}