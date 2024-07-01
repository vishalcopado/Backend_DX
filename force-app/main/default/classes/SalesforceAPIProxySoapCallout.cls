public with sharing class SalesforceAPIProxySoapCallout extends CopadoServerCallout {
    // CTOR

    public SalesforceAPIProxySoapCallout() {
        super(new copado.GlobalAPI().getCopadoServerUrl() + '/json/v1/proxyOrgRequest/soap', HttpMethod.POST);
    }
}