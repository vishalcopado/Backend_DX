@SuppressWarnings('PMD.ExcessivePublicCount, PMD.VariableNamingConventions,PMD.PropertyNamingConventions')
public class MetaDataItem {
    private final static String KEY_SEARCH_RECORDS = 'searchRecords';

    //PUBLIC
    @AuraEnabled
    public String t { get; set; } // Metadata Type
    @AuraEnabled
    public String n { get; set; } // Metadata Name
    @AuraEnabled
    public Boolean r { get; set; } // Retrieve Only
    @AuraEnabled
    public Boolean s { get; set; } // Metadata Is Selected
    @AuraEnabled
    public String ns { get; set; } // Namespace
    public String cb { get; set; } // Created By
    public String cd { get; set; } // Created Date
    public String vk { get; set; } // Vlocity key
    @AuraEnabled
    public String c { get; set; } // Category
    @AuraEnabled
    public String Name { get; set; }
    @AuraEnabled
    public String NamespacePrefix { get; set; }
    @AuraEnabled
    public String md { get; set; } // Last Modified Date
    @AuraEnabled
    public String mb { get; set; } // Last Modified By
    @AuraEnabled
    public Boolean cm { get; set; } // Is metadata committed on the user story
    @AuraEnabled
    public List<MetaDataItem> children { get; set; }
    @AuraEnabled
    public String a { get; set; }
    @AuraEnabled
    public String m { get; set; }
    @AuraEnabled
    public String j { get; set; }

    public static List<MetaDataItem> parse(String testClassesJson, Set<String> userStoryClasses, Set<String> manuallySelectedClasses) {
        List<MetaDataItem> result = new List<MetaDataItem>();

        Map<String, List<MetadataRecord>> metadataRecords = (Map<String, List<MetadataRecord>>) JSON.deserialize(
            testClassesJson,
            Map<String, List<MetadataRecord>>.class
        );

        for (MetadataRecord testItem : metadataRecords.get(KEY_SEARCH_RECORDS)) {
            MetaDataItem metadataRecord = extractMetadataRecord(testItem, userStoryClasses, manuallySelectedClasses);
            result.add(metadataRecord);
        }

        return result;
    }

    public static List<MetaDataItem> parseForFileJSON(String json) {
        return (List<MetaDataItem>) System.JSON.deserialize(json, List<MetaDataItem>.class);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<MetaDataItem> parseTestSuites(
        List<TestSuiteMembership> testSuiteMemberships,
        List<MetaDataItem> testClassesMetadatas,
        Set<String> committedTestSuites,
        Set<String> selectedTestSuites
    ) {
        String apexClass = 'ApexClass';
        String apexTestSuite = 'ApexTestSuite';
        Map<String, MetaDataItem> metadataItemsToMetadataName = new Map<String, MetaDataItem>();

        for (TestSuiteMembership testSuiteMembership : testSuiteMemberships) {
            if (!metadataItemsToMetadataName.containsKey(testSuiteMembership.ApexTestSuite.TestSuiteName)) {
                metadataItemsToMetadataName.put(
                    testSuiteMembership.ApexTestSuite.TestSuiteName,
                    getMetaDataItem(
                        testSuiteMembership.ApexTestSuite.TestSuiteName,
                        '',
                        testSuiteMembership.ApexTestSuite.LastModifiedDate,
                        testSuiteMembership.ApexTestSuite.LastModifiedBy?.Name,
                        apexTestSuite,
                        committedTestSuites.contains(testSuiteMembership.ApexTestSuite.TestSuiteName),
                        committedTestSuites.contains(testSuiteMembership.ApexTestSuite.TestSuiteName) ||
                        selectedTestSuites.contains(testSuiteMembership.ApexTestSuite.TestSuiteName),
                        true
                    )
                );
            }
            MetaDataItem testSuiteMetaDataItem = metadataItemsToMetadataName.get(testSuiteMembership.ApexTestSuite.TestSuiteName);
            MetaDataItem testClassMetaDataItem = getMetaDataItem(
                testSuiteMembership.ApexClass.Name,
                testSuiteMembership.ApexClass.NamespacePrefix,
                testSuiteMembership.ApexClass.LastModifiedDate,
                testSuiteMembership.ApexClass.LastModifiedBy?.Name,
                apexClass,
                testSuiteMetaDataItem.cm,
                testSuiteMetaDataItem.s,
                false
            );
            if (testClassesMetadatas.contains(testClassMetaDataItem)) {
                testSuiteMetaDataItem.children.add(testClassMetaDataItem);
            }
        }
        return metadataItemsToMetadataName.values();
    }

    public Boolean equals(Object obj) {
        MetaDataItem objectToCompare = (MetaDataItem) obj;
        return this.n == objectToCompare.n && this.t == objectToCompare.t;
    }

    public Integer hashCode() {
        String hashCodeContent = this.n + this.t;
        return hashCodeContent.hashCode();
    }

    public copado.CommitAction.Change parseCommitRequest() {
        copado.CommitAction.Change result = new copado.CommitAction.Change();
        result.a = a;
        result.c = c;
        result.m = m;
        result.n = n;
        result.t = t;
        result.j = j;
        return result;
    }

    //PRIVATE

    private static MetaDataItem extractMetadataRecord(MetadataRecord testItem, Set<String> userStoryClasses, Set<String> manuallySelectedClasses) {
        MetaDataItem metadataRecord = new MetaDataItem();

        metadataRecord.n = String.isBlank(testItem.name) ? '' : testItem.name;
        metadataRecord.ns = String.isBlank(testItem.namespacePrefix) ? '' : testItem.namespacePrefix;
        metadataRecord.md = String.isBlank(testItem.lastModifiedDate) ? '' : testItem.lastModifiedDate;
        metadataRecord.mb = String.isBlank(testItem.lastModifiedBy?.name) ? '' : testItem.lastModifiedBy.name;
        metadataRecord.t = String.isBlank(testItem.attributes.type) ? '' : testItem.attributes.type;
        metadataRecord.cm = userStoryClasses.contains(metadataRecord.n);
        metadataRecord.s = (manuallySelectedClasses.contains(metadataRecord.n) || metadataRecord.cm);
        return metadataRecord;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static MetaDataItem getMetaDataItem(
        String name,
        String namespace,
        DateTime lastModifiedDate,
        String lastModifiedBy,
        String type,
        Boolean committedInUS,
        Boolean isSelected,
        Boolean initializeChildren
    ) {
        MetaDataItem result = new MetaDataItem();
        result.n = name;
        result.ns = namespace;
        result.md = lastModifiedDate != null ? lastModifiedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : null;
        result.mb = lastModifiedBy;
        result.t = type;
        result.cm = committedInUS;
        result.s = isSelected;
        result.children = initializeChildren ? new List<MetaDataItem>() : null;
        return result;
    }

    private with sharing class LastModifiedBy {
        private String name;
        private Attribute attributes;
    }

    private with sharing class Attribute {
        private String type;
        private String url;
    }

    private with sharing class MetadataRecord {
        private String name;
        private String namespacePrefix;
        private String lastModifiedDate;
        private LastModifiedBy lastModifiedBy;
        private Attribute attributes;
    }
}