@isTest
public class MinuteAccount_DMN_TST {


    public static user UsertestUserAdmin;
    static  {
        // Create test data

        UsertestUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());

        System.runAs(UsertestUserAdmin){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                AP_Constant.sObjectAcc
            });
    
            // Create parent Account
            Account parentAccount = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCompanyGroup),'Parent Account','C_0001');
            insert parentAccount;
    
            // Create child Account
            Account childAccount = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Child Account (R)','C_0002');
            childAccount.ParentId = parentAccount.Id; 
            insert childAccount;
    
            // Create Contacts
            Contact contact1 = TestFactory.createContact('Contact 1', 'ReinsurerPortal', childAccount.Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015');
            Contact contact2 = TestFactory.createContact('Contact 2', 'ReinsurerPortal', childAccount.Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015');
            contact1.BrokerReinsurer__c = 'Reinsurer';
            contact2.BrokerReinsurer__c = 'Reinsurer';
            insert new List<Contact> {contact1, contact2};
    
            // Create Minute records
            Minute__c minute1 = new Minute__c(Name = 'Minute 1');
            Minute__c minute2 = new Minute__c(Name = 'Minute 2');
            insert new List<Minute__c> {minute1, minute2};
    
            // Create MinuteAccount records
            MinuteAccount__c minAcc1 = new MinuteAccount__c(Minute__c = minute1.Id, Company__c = childAccount.Id);
            MinuteAccount__c minAcc2 = new MinuteAccount__c(Minute__c = minute2.Id, Company__c = childAccount.Id);
            insert new List<MinuteAccount__c> {minAcc1, minAcc2};
    
            // Create MinuteContacts records
            MinuteContacts__c minContact1 = new MinuteContacts__c(Minute__c = minute1.Id, Contact__c = contact1.Id);
            MinuteContacts__c minContact2 = new MinuteContacts__c(Minute__c = minute1.Id, Contact__c = contact2.Id);
            insert new List<MinuteContacts__c> {minContact1, minContact2};
    
            // // Create AccountContactRelation records
            // AccountContactRelation acr1 = new AccountContactRelation(AccountId = childAccount.Id, ContactId = contact1.Id);
            // AccountContactRelation acr2 = new AccountContactRelation(AccountId = childAccount.Id, ContactId = contact2.Id);
            // insert new List<AccountContactRelation> {acr1, acr2};
        }
        
    }

    @isTest
    static void testReworkConcatFields() {
        // Retrieve the test data
        List<MinuteAccount__c> oldList = [SELECT Id, Minute__c, Company__c FROM MinuteAccount__c];
        
        // Call the method to test
        System.runAs(UsertestUserAdmin){
            Test.startTest();
                delete oldList;
            Test.stopTest();
        }   
        

        // Verify the results
        Minute__c updatedMinute = [SELECT Id, ConcatAccounts__c, ContactAccountParents__c FROM Minute__c WHERE Id = :oldList[0].Minute__c];
        System.assertEquals(null, updatedMinute.ConcatAccounts__c, 'ConcatAccounts__c should not be null');
        System.assertEquals(null, updatedMinute.ContactAccountParents__c, 'ContactAccountParents__c should not be null');
    }

    @isTest
    static void testDeleteMinuteContacts() {
        // Retrieve the test data
        List<MinuteAccount__c> oldList = [SELECT Id, Minute__c, Company__c FROM MinuteAccount__c];
        
        // Call the method to test
        System.runAs(UsertestUserAdmin){
            Test.startTest();
                delete oldList;
            Test.stopTest();
        } 

        // Verify the results
        List<MinuteContacts__c> remainingContacts = [SELECT Id FROM MinuteContacts__c];
        System.assertEquals(0, remainingContacts.size(), 'All MinuteContacts__c records should be deleted');
    }
}