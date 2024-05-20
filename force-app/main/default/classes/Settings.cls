public with sharing class Settings {
    public static final String TOOLING_API_ENDPOINT = '/services/data/v' + Settings.API_VERSION + '/tooling';
    public static final String METADATA_API_ENDPOINT = '/services/Soap/m/' + Settings.API_VERSION;
    public static final String NAMESPACE = Settings.class
                                            .getName()
                                            .substringBefore('Settings')
                                            .removeEnd('.')
                                            .toLowerCase();

    // Note: Namespace with __ appended
    public static final String NS {
        get {
            return String.isBlank(NAMESPACE) ? '' : (NAMESPACE + '__');
        }
    }

    // Note: Namespace with . appended
    public static final String NAMESPACE_DOT {
        get {
            return String.isBlank(NAMESPACE) ? '' : (NAMESPACE + '.');
        }
    }

    public static final String API_VERSION {
        get {
            return '53.0';
        }
    }
}