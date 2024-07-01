@SuppressWarnings('PMD.CognitiveComplexity')
public class UserStoryMetadata {
    private static final String APEX_TRIGGER = 'ApexTrigger';
    private static final String APEX_CLASS = 'ApexClass';
    private static final String APEX_TEST_SUITE = 'ApexTestSuite';
    public Set<String> userStoryClasses;
    public Set<String> userStoryTriggers;
    public Set<String> userStoryApexTestSuites;

    // CTR

    public UserStoryMetadata() {
        userStoryClasses = new Set<String>();
        userStoryTriggers = new Set<String>();
        userStoryApexTestSuites = new Set<String>();
    }

    public UserStoryMetadata(List<copado__User_Story_Metadata__c> userStoryMetadata) {
        this();
        if (!userStoryMetadata.isEmpty()) {
            toClassesAndTriggers(userStoryMetadata);
        }
    }

    // PUBLIC

    // TODO : Update the method name from toClassesAndTriggers to toClassesTriggersAndTestSuites
    // while working on UpdateTestsInfoOnStories apex class
    public void toClassesAndTriggers(List<copado__User_Story_Metadata__c> userStoryMetadata) {
        for (copado__User_Story_Metadata__c usMetadata : userStoryMetadata) {
            if (usMetadata.copado__Type__c == APEX_CLASS) {
                userStoryClasses.add(usMetadata.copado__Metadata_API_Name__c);
            } else if (usMetadata.copado__Type__c == APEX_TRIGGER) {
                userStoryTriggers.add(usMetadata.copado__Metadata_API_Name__c);
            } else if (usMetadata.copado__Type__c == APEX_TEST_SUITE) {
                userStoryApexTestSuites.add(usMetadata.copado__Metadata_API_Name__c);
            }
        }
    }

    // TODO : Update the method name from toClassesAndTriggers to toClassesTriggersAndTestSuites
    // while working on UpdateTestsInfoOnStories apex class
    public void toClassesAndTriggers(List<CommitChanges.Change> changes) {
        for (CommitChanges.Change change : changes) {
            if (change.t == APEX_CLASS) {
                userStoryClasses.add(change.n);
            } else if (change.t == APEX_TRIGGER) {
                userStoryTriggers.add(change.n);
            } else if (change.t == APEX_TEST_SUITE) {
                userStoryApexTestSuites.add(change.n);
            }
        }
    }

    public void add(String name, String type) {
        if (type == APEX_CLASS) {
            userStoryClasses.add(name);
        } else if (type == APEX_TRIGGER) {
            userStoryTriggers.add(name);
        } else if (type == APEX_TEST_SUITE) {
            userStoryApexTestSuites.add(name);
        }
    }

    public void remove(String name, String type) {
        if (type == APEX_CLASS) {
            userStoryClasses.remove(name);
        } else if (type == APEX_TRIGGER) {
            userStoryTriggers.remove(name);
        } else if (type == APEX_TEST_SUITE) {
            userStoryApexTestSuites.remove(name);
        }
    }

    public void removeAll(Set<String> names, String type) {
        if (type == APEX_CLASS) {
            userStoryClasses.removeAll(names);
        } else if (type == APEX_TRIGGER) {
            userStoryTriggers.removeAll(names);
        } else if (type == APEX_TEST_SUITE) {
            userStoryApexTestSuites.removeAll(names);
        }
    }

    public Boolean hasApex() {
        return !(userStoryClasses.isEmpty() && userStoryTriggers.isEmpty());
    }

    public Boolean hasTestSuites() {
        return !userStoryApexTestSuites.isEmpty();
    }

    public void clear() {
        userStoryClasses.clear();
        userStoryTriggers.clear();
        userStoryApexTestSuites.clear();
    }
}