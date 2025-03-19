@isTest
public with sharing class AP67_UpdateTreatyLTATACIT_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty; 
    static List<User> lstUsers = new List<User>();

     static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006')
            };
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c>{
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[0].Id, '23002', '1', '25009'),
                    TestFactory.createProgram('TestProg3', '2', '3'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000222', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000222', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            lstTreaty[0].Deductions_Perc__c = 55;
            lstTreaty[2].Deductions_Perc__c = 68;
            insert lstTreaty;
        }
    }

    @IsTest
    public static void testUpdateTreaty_LTATACIT(){
        System.runAs(testUserCE) {
            Test.startTest();
              lstTreaty[0].LTA__c = lstProgram[0].LTA__c;
              lstTreaty[0].TacitRenewal__c = lstProgram[0].TacitRenewal__c;
               AP67_UpdateTreatyOnChangeLTA_TACIT.updateTreaty(lstTreaty);
            Test.stopTest();
        }
    }

     @IsTest
    public static void testUpdateTreaty_LTA_YES(){
        System.runAs(testUserCE) {
            Test.startTest();
             lstTreaty[0].LTA__c = '1';
               AP67_UpdateTreatyOnChangeLTA_TACIT.updateTreaty(lstTreaty);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdateTreaty_LTA_NO(){
        System.runAs(testUserCE) {
            Test.startTest();
             lstTreaty[0].LTA__c = '2';
               AP67_UpdateTreatyOnChangeLTA_TACIT.updateTreaty(lstTreaty);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdateTreaty_TACIT_YES(){
        System.runAs(testUserCE) {
            Test.startTest();
             lstTreaty[0].TacitRenewal__c = '1';
               AP67_UpdateTreatyOnChangeLTA_TACIT.updateTreaty(lstTreaty);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdateTreaty_TACIT_NO(){
        System.runAs(testUserCE) {
            Test.startTest();
             lstTreaty[0].TacitRenewal__c = '2';
               AP67_UpdateTreatyOnChangeLTA_TACIT.updateTreaty(lstTreaty);
            Test.stopTest();
        }
    }

}