/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

@IsTest(IsParallel=true)
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.ClassNamingConventions')
private with sharing class fflib_SObjectUnitOfWorkTest {
    // SObjects (in order of dependency) used by UnitOfWork in tests bellow
    private static List<Schema.SObjectType> mySobjects = new List<Schema.SObjectType>{
        Account.SObjectType,
        Contact.SObjectType
    };

    @IsTest
    private static void testUnitOfWorkEmail() {
        String testRecordName = 'UoW Test Name 1';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ 'foobar@test.com' });
        email.setPlainTextBody('See Spot run.');

        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(mySobjects, mockDML);

        uow.m_emailWork = new Mock_SendEmailWork();

        Account acc = new Account();
        acc.Name = testRecordName;

        uow.registerNew(acc);

        uow.registerEmail(email);

        uow.registerRelationship(email, acc);

        uow.commitWork();

        // assert that mock email functionality was called
        System.assert(((Mock_SendEmailWork) uow.m_emailWork).doWorkWasCalled, 'Send email functionality failed');

        System.assertEquals(1, mockDML.recordsForInsert.size(), 'Mock DML failed');
    }

    @IsTest
    private static void testRegisterNewThrowExceptionOnDirtyRecord() {
        // GIVEN an existing record
        Account acc = new Account(Id = fflib_IDGenerator.generate(Schema.Account.SObjectType));
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(mySobjects);

        // WHEN we register the existing record as new
        Boolean exceptionThrown = false;
        try {
            unitOfWork.registerNew(acc);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assertEquals(
                'Only new records can be registered as new',
                e.getMessage(),
                'Incorrect exception message thrown'
            );
        }

        // THEN it should have thrown an exception
        System.assert(exceptionThrown, 'New records should not be registered as new');
    }

    @IsTest
    private static void testRegisterDirtyThrowExceptionOnNewRecord() {
        // GIVEN an new record
        Account acc = new Account();
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(mySobjects);

        // WHEN we register the existing record as new
        Boolean exceptionThrown = false;
        try {
            unitOfWork.registerDirty(acc);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assertEquals(
                'New records cannot be registered as dirty',
                e.getMessage(),
                'Incorrect exception message thrown'
            );
        }

        // THEN it should have thrown an exception
        System.assert(exceptionThrown, 'New records should not registered as dirty');
    }

    @IsTest
    private static void testRegisterEmptyRecycleBin() {
        // GIVEN - an existing record of the recycle bin
        Account acc = new Account(Id = fflib_IDGenerator.generate(Schema.Account.SObjectType));
        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(mySobjects, mockDML);

        // WHEN - we empty the record from the recycle bin
        unitOfWork.registerEmptyRecycleBin(new List<Account>{ acc });
        unitOfWork.commitWork();

        // THEN - the emptyRecycleBin action should be invoked
        System.assertEquals(1, mockDML.recordsForRecycleBin.size(), 'mockDML size should be greater than 1');
    }

    @IsTest
    private static void testAssertForNonEventSObjectTypeThrowExceptionOnEventObject() {
        Boolean exceptionThrown = false;
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(mySobjects);
        try {
            unitOfWork.assertForNonEventSObjectType('PlatformEventObject__e');
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('registerPublishBeforeTransaction'),
                'Incorrect exception message thrown'
            );
        }

        System.assert(exceptionThrown, 'Exception message should be thrown');
    }

    @IsTest
    private static void testAssertForEventSObjectTypeThrowExceptionOnNonEventObject() {
        Boolean exceptionThrown = false;
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(mySobjects);
        try {
            unitOfWork.assertForEventSObjectType('CustomObject__c');
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('invalid for publishing'),
                'Incorrect exception message thrown'
            );
        }
    }

    @IsTest
    private static void testAssertForSupportedSObjectTypeThrowExceptionOnUnsupportedType() {
        Boolean exceptionThrown = false;
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(mySobjects);
        try {
            unitOfWork.registerNew(new Case());
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('not supported by this unit of work'),
                'Incorrect exception message thrown'
            );
        }

        System.assert(exceptionThrown, 'should throw exception for unsupported object');
    }

    /**
     * Create uow with new records and commit
     *
     *	Testing:
     *
     *		- Correct events are fired when commitWork completes successfully
     *
     */
    @IsTest
    private static void testDerivedUnitOfWorkCommitSuccess() {
        // Insert accortunities with UnitOfWork
        MockDML mockDML = new MockDML();
        DerivedUnitOfWork uow = new DerivedUnitOfWork(mySobjects, mockDML);
        for (Integer o = 0; o < 10; o++) {
            Account acc = new Account();
            acc.Name = 'UoW Test Name ' + o;
            uow.registerNew(new List<SObject>{ acc });
            for (Integer i = 0; i < o + 1; i++) {
                Contact con = new Contact();
                con.LastName = 'Test LastName';
                uow.registerNew(con, Contact.AccountId, acc);
            }
        }
        uow.commitWork();

        // Assert Results
        System.assertEquals(65, mockDML.recordsForInsert.size(), 'Incorrect of new records');

        assertEvents(
            new List<String>{
                'onCommitWorkStarting',
                'onPublishBeforeEventsStarting',
                'onPublishBeforeEventsFinished',
                'onDMLStarting',
                'onDMLFinished',
                'onDoWorkStarting',
                'onDoWorkFinished',
                'onCommitWorkFinishing',
                'onPublishAfterSuccessEventsStarting',
                'onPublishAfterSuccessEventsFinished',
                'onCommitWorkFinished - true'
            },
            uow.getCommitWorkEventsFired(),
            new Set<Schema.SObjectType>(mySobjects),
            uow.getRegisteredTypes()
        );
    }

    /**
     * Create uow with data that results in DML Exception
     *
     *	Testing:
     *
     *		- Correct events are fired when commitWork fails during DML processing
     *
     */
    @IsTest
    private static void testDerivedUnitOfWorkCommitDMLFail() {
        // Insert accortunities with UnitOfWork forcing a failure on DML by not setting 'Name' field
        DerivedUnitOfWork uow = new DerivedUnitOfWork(mySobjects);
        Account acc = new Account();
        uow.registerNew(new List<SObject>{ acc });
        Boolean didFail = false;
        System.DmlException caughtEx = null;

        try {
            uow.commitWork();
        } catch (System.DmlException dmlex) {
            didFail = true;
            caughtEx = dmlex;
        }

        // Assert Results
        System.assertEquals(didFail, true, 'didFail');
        System.assert(
            caughtEx.getMessage().contains('REQUIRED_FIELD_MISSING'),
            String.format('Exception message was ', new List<String>{ caughtEx.getMessage() })
        );

        assertEvents(
            new List<String>{
                'onCommitWorkStarting',
                'onPublishBeforeEventsStarting',
                'onPublishBeforeEventsFinished',
                'onDMLStarting',
                'onPublishAfterFailureEventsStarting',
                'onPublishAfterFailureEventsFinished',
                'onCommitWorkFinished - false'
            },
            uow.getCommitWorkEventsFired(),
            new Set<Schema.SObjectType>(mySobjects),
            uow.getRegisteredTypes()
        );
    }

    /**
     * Create uow with work that fails
     *
     *	Testing:
     *
     *		- Correct events are fired when commitWork fails during DoWork processing
     *
     */
    @isTest
    private static void testDerivedUnitOfWorkCommitDoWorkFail() {
        // Insert accortunities with UnitOfWork
        MockDML mockDML = new MockDML();
        DerivedUnitOfWork uow = new DerivedUnitOfWork(mySobjects, mockDML);
        Account acc = new Account();
        acc.Name = 'UoW Test Name 1';
        uow.registerNew(new List<SObject>{ acc });

        // register work that will fail during processing
        FailDoingWork fdw = new FailDoingWork();
        uow.registerWork(fdw);

        Boolean didFail = false;
        FailDoingWorkException caughtEx = null;

        try {
            uow.commitWork();
        } catch (FailDoingWorkException fdwe) {
            didFail = true;
            caughtEx = fdwe;
        }

        // Assert Results
        System.assertEquals(didFail, true, 'didFail');
        System.assert(
            caughtEx.getMessage().contains('Work failed.'),
            String.format('Exception message was ', new List<String>{ caughtEx.getMessage() })
        );

        assertEvents(
            new List<String>{
                'onCommitWorkStarting',
                'onPublishBeforeEventsStarting',
                'onPublishBeforeEventsFinished',
                'onDMLStarting',
                'onDMLFinished',
                'onDoWorkStarting',
                'onPublishAfterFailureEventsStarting',
                'onPublishAfterFailureEventsFinished',
                'onCommitWorkFinished - false'
            },
            uow.getCommitWorkEventsFired(),
            new Set<Schema.SObjectType>(mySobjects),
            uow.getRegisteredTypes()
        );
    }

    /**
     * Try registering two instances of the same record as dirty. Second register should overwrite first.
     *
     *  Testing:
     *
     *      - Exception is thrown staccing second registration
     */
    @IsTest
    private static void testRegisterDirtyExpectReplacement() {
        final Account insertedacc = new Account(
            Id = fflib_IDGenerator.generate(Schema.Account.SObjectType),
            Name = 'Original'
        );

        Account acc = new Account(Id = insertedacc.Id, Name = 'Never');
        Account acc2 = new Account(Id = insertedacc.Id, Name = 'Expected');

        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(mySobjects, mockDML);
        uow.registerDirty(acc);
        uow.registerDirty(acc2);
        uow.commitWork();

        System.assertEquals(1, mockDML.recordsForUpdate.size(), 'mockDML record size should be 1');
        System.assertEquals('Expected', mockDML.recordsForUpdate.get(0).get(Schema.Account.Name), 'Expected Account is not available for update');
    }

    /**
     * Try registering a single field as dirty.
     *
     *  Testing:
     *
     *      - field is updated
     */
    @IsTest
    private static void testRegisterDirtyField() {
        Account acc = new Account(
            Id = fflib_IDGenerator.generate(Schema.Account.SObjectType),
            Name = 'test name'
        );

        Account nameUpdate = new Account(Id = acc.Id, Name = 'UpdateName');
        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(mySobjects, mockDML);
        uow.registerDirty(nameUpdate);
        uow.commitWork();

        System.assertEquals(1, mockDML.recordsForUpdate.size(), 'mockDML record size should be 1');
        System.assertEquals(
            nameUpdate.Name,
            mockDML.recordsForUpdate.get(0).get(Schema.Account.Name),
            'UpdateName Account is not available for update'
        );
    }

    /**
     * Try registering a single field as dirty on multiple records.
     *
     */
    @IsTest
    private static void testRegisterDirtyRecordsWithDirtyFields() {
        // GIVEN a list of existing records
        Account accountA = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Name = 'test name A'
        );
        Account accountB = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Name = 'test name B'
        );

        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(mySobjects, mockDML);
        uow.registerDirty(new List<Account>{ AccountA, AccountB });

        // WHEN we register the records again with different fields updated
        List<Account> recordsWithAccountNumberUpdate = new List<Account>{
            new Account(Id = AccountA.Id, AccountNumber = '06543'),
            new Account(Id = AccountB.Id, AccountNumber = '954398')
        };

        uow.registerDirty(
            recordsWithAccountNumberUpdate,
            new List<SObjectField>{ Account.AccountNumber }
        );
        uow.commitWork();

        System.assertEquals(2, mockDML.recordsForUpdate.size(), 'mockDML record size should be 2');
    }

    /**
     * Try registering a single field as dirty on multiple records.
     *
     */
    @IsTest
    private static void testRegisterDirtyRecordsWithDirtyFieldsEx() {
        // GIVEN a list of existing records
        Account accountA = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Name = 'test name A'
        );
        Account accountB = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Name = 'test name B'
        );

        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(mySobjects, mockDML);
        uow.registerDirty(new List<Account>{ accountA, accountB });

        // WHEN we register the records again with different fields updated
        List<Account> recordsWithAccountNumberUpdate = new List<Account>{
            new Account(Id = accountA.Id, AccountNumber = '123456'),
            new Account(Id = accountB.Id, AccountNumber = '234567')
        };

        uow.registerDirty(
            recordsWithAccountNumberUpdate,
            new List<SObjectField>{ Account.AccountNumber }
        );
        uow.registerDirty(new Account(Id = accountB.Id, Name = 'test name B')); // Register again the original record, should overwrite the one with the dirty fields
        uow.commitWork();
        System.assertEquals(2, mockDML.recordsForUpdate.size(), 'mockDML record size should be 2');
    }

    @IsTest
    private static void testRegisterUpsert() {
        Account existingacc = new Account(
            Id = fflib_IDGenerator.generate(Schema.Account.SObjectType),
            Name = 'Existing Account'
        );

        Account newAccount = new Account(Name = 'New Account');

        Test.startTest();
        MockDML mockDML = new MockDML();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(mySobjects, mockDML);
        uow.registerUpsert(new List<Account>{ existingacc, newAccount });
        uow.commitWork();
        Test.stopTest();

        System.assertEquals(1, mockDML.recordsForUpdate.size(), 'mockDML record size should be 1');
        System.assertEquals(1, mockDML.recordsForInsert.size(), 'mockDML record size should be 1');
    }

    /**
     * Assert that actual events exactly match expected events (size, order and name)
     * and types match expected types
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void assertEvents(
        List<String> expectedEvents,
        List<String> actualEvents,
        Set<Schema.SObjectType> expectedTypes,
        Set<Schema.SObjectType> actualTypes
    ) {
        // assert that events match
        System.assertEquals(expectedEvents.size(), actualEvents.size(), 'events size');
        for (Integer i = 0; i < expectedEvents.size(); i++) {
            System.assertEquals(
                expectedEvents[i],
                actualEvents[i],
                String.format(
                    'Event {0} was not fired in order expected.',
                    new List<String>{ expectedEvents[i] }
                )
            );
        }

        // assert that types match
        System.assertEquals(expectedTypes.size(), actualTypes.size(), 'types size');
        for (Schema.SObjectType sObjectType : expectedTypes) {
            System.assertEquals(
                true,
                actualTypes.contains(sObjectType),
                String.format(
                    'Type {0} was not registered.',
                    new List<String>{ sObjectType.getDescribe().getName() }
                )
            );
        }
    }

    /**
     * DoWork implementation that throws exception during processing
     */
    private class FailDoingWork implements fflib_SObjectUnitOfWork.IDoWork {
        public void doWork() {
            throw new FailDoingWorkException('Work failed.');
        }
    }

    /**
     * Derived unit of work that tracks event notifications and handle registration of type
     */
    private class DerivedUnitOfWork extends fflib_SObjectUnitOfWork {
        private List<String> commitWorkEventsFired = new List<String>();
        private Set<Schema.SObjectType> registeredTypes = new Set<Schema.SObjectType>();

        private List<String> getCommitWorkEventsFired() {
            return commitWorkEventsFired.clone();
        }

        private Set<Schema.SObjectType> getRegisteredTypes() {
            return registeredTypes.clone();
        }

        private DerivedUnitOfWork(List<Schema.SObjectType> sObjectTypes) {
            super(sObjectTypes);
        }

        private DerivedUnitOfWork(List<Schema.SObjectType> sObjectTypes, IDML dml) {
            super(sObjectTypes, dml);
        }

        private void addEvent(String event) {
            // events should only be fired one time
            // ensure that this event has not been fired already
            for (String eventName : commitWorkEventsFired) {
                if (event == eventName) {
                    throw new DerivedUnitOfWorkException(
                        String.format(
                            'Event {0} has already been fired.',
                            new List<String>{ event }
                        )
                    );
                }
            }
            commitWorkEventsFired.add(event);
        }

        public override void onRegisterType(Schema.SObjectType sObjectType) {
            if (registeredTypes.contains(sObjectType)) {
                throw new DerivedUnitOfWorkException(
                    String.format(
                        'Type {0} has already been registered.',
                        new List<String>{ sObjectType.getDescribe().getName() }
                    )
                );
            }
            registeredTypes.add(sObjectType);
        }

        public override void onCommitWorkStarting() {
            addEvent('onCommitWorkStarting');
        }

        public override void onPublishBeforeEventsStarting() {
            addEvent('onPublishBeforeEventsStarting');
        }

        public override void onPublishBeforeEventsFinished() {
            addEvent('onPublishBeforeEventsFinished');
        }

        public override void onDMLStarting() {
            addEvent('onDMLStarting');
        }

        public override void onDMLFinished() {
            addEvent('onDMLFinished');
        }

        public override void onDoWorkStarting() {
            addEvent('onDoWorkStarting');
        }

        public override void onDoWorkFinished() {
            addEvent('onDoWorkFinished');
        }

        public override void onCommitWorkFinishing() {
            addEvent('onCommitWorkFinishing');
        }

        public override void onPublishAfterSuccessEventsStarting() {
            addEvent('onPublishAfterSuccessEventsStarting');
        }

        public override void onPublishAfterSuccessEventsFinished() {
            addEvent('onPublishAfterSuccessEventsFinished');
        }

        public override void onPublishAfterFailureEventsStarting() {
            addEvent('onPublishAfterFailureEventsStarting');
        }

        public override void onPublishAfterFailureEventsFinished() {
            addEvent('onPublishAfterFailureEventsFinished');
        }

        public override void onCommitWorkFinished(Boolean wasSuccessful) {
            addEvent('onCommitWorkFinished - ' + wasSuccessful);
        }
    }

    /**
     * Mock implementation of fflib_SObjectUnitOfWork.SendEmailWork
     **/
    private class Mock_SendEmailWork implements fflib_SObjectUnitOfWork.IEmailWork {
        private List<Messaging.Email> emails;

        public Mock_SendEmailWork() {
            this.emails = new List<Messaging.Email>();
        }

        public void registerEmail(Messaging.Email email) {
            this.emails.add(email);
        }

        public void doWork() {
            doWorkWasCalled = true;
            // The code in the fflib_SObjectUnitOfWork class
            // causes unit test failures in Orgs that do not
            // have email enabled.
        }

        private Boolean doWorkWasCalled = false;
    }

    private class MockDML implements fflib_SObjectUnitOfWork.IDML {
        private List<SObject> recordsForInsert = new List<SObject>();
        private List<SObject> recordsForUpdate = new List<SObject>();
        private List<SObject> recordsForDelete = new List<SObject>();
        private List<SObject> recordsForRecycleBin = new List<SObject>();
        private List<SObject> recordsForEventPublish = new List<SObject>();

        public void dmlInsert(List<SObject> objList) {
            this.recordsForInsert.addAll(objList);
        }

        public void dmlUpdate(List<SObject> objList) {
            this.recordsForUpdate.addAll(objList);
        }

        public void dmlDelete(List<SObject> objList) {
            this.recordsForDelete.addAll(objList);
        }

        public void eventPublish(List<SObject> objList) {
            this.recordsForEventPublish.addAll(objList);
        }

        public void emptyRecycleBin(List<SObject> objList) {
            this.recordsForRecycleBin.addAll(objList);
        }
    }

    public class DerivedUnitOfWorkException extends Exception {
    }
    public class FailDoingWorkException extends Exception {
    }
}