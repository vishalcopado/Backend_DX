public inherited sharing class SalesforceAPIProxyCallout extends CopadoServerCallout {
    // CTOR

    public SalesforceAPIProxyCallout() {
        super(new copado.GlobalAPI().getCopadoServerUrl()+'/json/v1/proxyOrgRequest/', HttpMethod.POST);
    }
}