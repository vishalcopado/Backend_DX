public with sharing class LwcLabelsTranslation {

    // PUBLIC 
    @AuraEnabled
    public static Map<String, String> execute(List<String> labels) {
        Map<String, String> result = new Map<String, String>();
        String namespace = Settings.NAMESPACE;
        String language = UserInfo.getLanguage();
        for (String label : labels) {
            result.put(label, getTranslatedLabelValue(namespace, label, language));
        }
        return result;
    }

    // PRIVATE
    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static String getTranslatedLabelValue(String namespace, String label, String language) {
        String result;
        // This try catch makes sure that if the label does not exist, then
        // we continue the execution hence preventing abrupt termination
        try {
            if (System.Label.translationExists(namespace, label, language)) {
                result = System.Label.get(namespace, label, language);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage() + ex.getStackTraceString());
        }
        return result;
    }
}