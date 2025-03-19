@isTest
public class MinuteContact_DMN_TST {

    public static user UsertestUserAdmin;

    static {

        UsertestUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        System.runAs(UsertestUserAdmin){

            // initializes custom setting for account
            MinuteContactSettings__c minContactSettings = new MinuteContactSettings__c(
                CanAfterDelete__c = true,
                CanReworkConcatFields__c = true
                //default values applied (all active by default)
            );
            insert minContactSettings;

            
            // Create Minute records
            Minute__c minute1 = new Minute__c(Name = 'Minute 1');
            Minute__c minute2 = new Minute__c(Name = 'Minute 2');
            insert new List<Minute__c> {minute1, minute2};

            // Create Contacts
            Contact contact1 = new Contact(LastName = 'Contact 1');
            Contact contact2 = new Contact(LastName = 'Contact 2');
            insert new List<Contact> {contact1, contact2};

            // Create MinuteContacts records
            MinuteContacts__c minContact1 = new MinuteContacts__c(Minute__c = minute1.Id, Contact__c = contact1.Id);
            MinuteContacts__c minContact2 = new MinuteContacts__c(Minute__c = minute1.Id, Contact__c = contact2.Id);
            MinuteContacts__c minContact3 = new MinuteContacts__c(Minute__c = minute2.Id, Contact__c = contact1.Id);
            insert new List<MinuteContacts__c> {minContact1, minContact2, minContact3};
        }
        
    }

    @isTest
    static void testReworkConcatFields() {
        // Retrieve the test data
        List<MinuteContacts__c> oldList = [SELECT Id, Minute__c, Contact__c FROM MinuteContacts__c];

        
        // Call the method to test
        System.runAs(UsertestUserAdmin){
            Test.startTest();
                delete oldList;
            Test.stopTest();
        } 

        List<Contact> conList = [SELECT Id FROM Contact];

        // Verify the results
        List<Minute__c> updatedMinutes = [SELECT Id, ContactsConcat__c FROM Minute__c];
        for (Minute__c min : updatedMinutes) {
            System.debug('Minute__c: ' + min.Id + ', ContactsConcat__c: ' + min.ContactsConcat__c);
        }



        // Retrieve the updated Minute records
        Minute__c minute1 = [SELECT Id, ContactsConcat__c FROM Minute__c WHERE Name = 'Minute 1'];
        Minute__c minute2 = [SELECT Id, ContactsConcat__c FROM Minute__c WHERE Name = 'Minute 2'];

        // Validate the ContactsConcat__c field
        System.assertEquals(null, minute1.ContactsConcat__c, 'ContactsConcat__c for minute1 should be updated correctly');
        System.assertEquals(null, minute2.ContactsConcat__c, 'ContactsConcat__c for minute2 should be updated correctly');
    }
}