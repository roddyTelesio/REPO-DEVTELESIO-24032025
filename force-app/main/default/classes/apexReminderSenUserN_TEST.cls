@isTest
public with sharing class apexReminderSenUserN_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static Id idTestUserRole = [SELECT Id FROM UserRole WHERE Name ='ASPEN INS /BM (R) Partner User'].Id;
    static User testUserExternal;
    static User testUserInternal;
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<User> lstUsers = new List<User>();
    static USerRole ur = [SELECT Id, DeveloperName FROM UserRole WHERE PortalType <> 'Partner' Limit 1];
    static {
        //create User ANG
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;
        
        System.runAs(testUserAdmin){
            //Create EmailTemplate
            EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = 'Template Reminder Portal reinBroker from List User Id'); // plus any other fields that you want to set 
            insert e;
        }
    }
    @IsTest
    public static void testApexReminderSendUserName(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            List<Id> lstIdUser = new List<Id>();           
            User thisUser = new User(Id=UserInfo.getUserId());
            thisUser.UserRoleId = ur.Id;
            update thisUser;
            System.runAs(thisUser) {
                Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
                //create Account
                lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A (P)','C_0001'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B (P)','C_0002'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C (C)','C_0003'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D (C)','C_0004'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Account E (B)','C_0005'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F (R)','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A (B)','C_0007'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B (B)','C_0008'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A (R)','C_0009'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account E - Covered Ceding (C)','C_0010')
                };
                insert lstAccount;

                lstAccount[0].EmailSA__c = 'test@test.com;test2@test.com';
                lstAccount[1].EmailSA__c = 'test@test.com;test2@test.com';
                lstAccount[0].EmailPCLife__c = 'test@test.com;test2@test.com';
                lstAccount[1].EmailPCLife__c = 'test@test.com;test2@test.com';
                lstAccount[9].IsPartner = true;//Covered Ceding Acc
                lstAccount[4].IsPartner = true;//Broker Acc
                lstAccount[5].IsPartner = true;//Reinsurer Acc
                update lstAccount;

                lstContact = new List<Contact> {
                    TestFactory.createContact('Account D - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                    TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                    TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015')
                };
                
                lstContact[0].Email = 'test@test.com';
                lstContact[0].BrokerReinsurer__c = 'Reinsurer';
                lstContact[1].BrokerReinsurer__c = 'Broker';
                lstContact[2].BrokerReinsurer__c = 'Reinsurer';
                lstContact[1].Email = 'test@test.com';
                lstContact[2].Email = 'test@test.com';
                insert lstContact;
            }
            
            User uPortal = new User( email='test@test.com',
                        profileid = TestFactory.getProfileExternalId(), 
                        UserName='portalUser@portalTestUser.com', 
                        Alias = 'a',
                        TimeZoneSidKey='Australia/Sydney',
                        EmailEncodingKey='ISO-8859-1',
                        LocaleSidKey='en_US', 
                        LanguageLocaleKey='en_US',
                        ContactId = lstContact[0].Id,
                        FirstName = 'Test FirstName',
                        LastName = 'LastName'
                      );
    
            insert uPortal;
            lstIdUser.add(uPortal.Id);
            apexReminderSendUserName.sendMailMethod(lstIdUser);
            Test.stopTest();
        }
    }
}