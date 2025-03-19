@IsTest
public with sharing class CntDocLink_Test {
    /*static testmethod void testIncrement() {
        CntDocLinkTriggerHandler.justIncrement();
    }*/

    static List<ContentDocumentLink> lstContentDocLink;
    static List<ContentDocumentLink> lstContentDocLink2 = new List<ContentDocumentLink>();
    static List<Account> lstAcc2;
    static List<Contact> lstContact;

    static User adminUser = TestFactory.createAdminUserWithCLMAdminPermissionSet(); 
    static User testUserCE;
    static User testUserAdmin;
    static User testUserAdminAGRE;
    static User testUserExternal;
    static User testUserInternal;
    static User testUserCEAXAXL;
    static User testUserActorBasicSFAccess;
    static User testUserActorBasicSFplatform;
    static User testUserSFReadOnly;
    static Map<String, Id> mapRecTypeId;
    static Account compte;
    static Work__c wk;
    static Campaign cp;
    static Apttus__APTS_Agreement__c agreement;
    static Universign_Transaction__c univT;
    static Minute__c min;
    static ContentVersion testContentVersion1;
    static ContentVersion testContentVersion2;
    static ContentVersion testContentVersion3;
    static ContentVersion testContentVersion4;
    static ContentVersion testContentVersion5;
    static ContentVersion testContentVersion6;

    static {
        
        mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
            AP_Constant.sObjectAcc
        });
         //creating Account
         lstAcc2 = new List<Account>{
            TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'testAcc11', 'Y_83921'),
            TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer), 'testAccReinsurer11', 'Y_83931'),
            TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker), 'testAccBroker11', 'Y_83941')
        };
        //insert lstAcc2;
        //create Ceding Portal Contact + Broker/Reinsurer Contact
        lstContact = new List<Contact> {
            TestFactory.createContact('Account E - Broker (B)', 'BrokerPortal', lstAcc2[2].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
            TestFactory.createContact('Account F - Reinsurer (R)', 'ReinsurerPortal', lstAcc2[1].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015')
        };

        lstContact[0].Email = 'test@test.com';
        lstContact[0].BrokerReinsurer__c = 'Broker';
        lstContact[1].Email = 'test@test.com';
        lstContact[1].BrokerReinsurer__c = 'Reinsurer';
        
        //insert lstContact;
    
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserExternal = TestFactory.createUser('testUserExternal', TestFactory.getProfileExternalId());
        testUserExternal.ContactId =  lstContact[0].Id;
        //insert testUserExternal;
        testUserInternal = TestFactory.createUser('testUserInternal22', TestFactory.getProfileInternalId());
        testUserInternal.ContactId =  lstContact[1].Id;
        //insert testUserInternal;
        testUserAdminAGRE = TestFactory.createUser('testUserAdminAGRE', ([SELECT Id FROM Profile WHERE Name = 'AGRE_System Admin'].Id));
        testUserCEAXAXL = TestFactory.createUser('testUserCEAXAXL', ([SELECT Id FROM Profile WHERE Name = 'AGRE_C.E_AXA XL'].Id));
        testUserActorBasicSFAccess = TestFactory.createUser('testUserActorBasicSFAccess', ([SELECT Id FROM Profile WHERE Name = 'AGRE_Actor Basic Salesforce Access'].Id));
        testUserActorBasicSFplatform = TestFactory.createUser('testUserActorBasicSFplatform', ([SELECT Id FROM Profile WHERE Name = 'AGRE_Actor Basic SF Platform Access'].Id));
        testUserSFReadOnly = TestFactory.createUser('testUserSFReadOnly',([SELECT Id FROM Profile WHERE Name = 'Salesforce Platform_read only'].Id));

        System.runAs(adminUser){
            // Create common test data
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                AP_Constant.sObjectAcc
            });

            //create Account
            compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001');
            insert compte;
            
            wk = new Work__c();
            wk.Subject__c = 'Test';
            wk.RecordTypeId = '0127S000000CgHtQAK';
            wk.Assigned_To__c = adminUser.id;
            wk.Related_Phase_Detail__c = 'Other';
            wk.status__c = 'New';
            wk.Description__c = 'test Description__c';
            wk.context__c = 'UAT';
            insert wk;
            
            Campaign cp = new Campaign();
            cp.name = 'test campaign';
            insert cp;
            
            Program__c pro = TestFactory.createProgram('TestProg3', '2', '3'
            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
            , '2018', compte.Id, '23001', '1', '25001');
            insert pro;
            
            agreement = TestFactory.createAgreement('Test agreement');
            agreement.program__c = pro.id;
            agreement.Apttus__Status__c = 'In Renewal';
            insert agreement;
            
            univT = new Universign_Transaction__c();
            univT.Agreement__c = agreement.Id;
            insert univT;
            
            min = new 	Minute__c();
            min.Name = 'test min7';
            min.Market__c = 'AXA XL;High growth market'; 
            insert min;
            // Create a test ContentDocument
            List<ContentVersion> listContentVer1 = new List<ContentVersion>();
            List<ContentVersion> listContentVer2 = new List<ContentVersion>();
            List<ContentVersion> listContentVer3 = new List<ContentVersion>();
            List<ContentVersion> listContentVer4 = new List<ContentVersion>();
            List<ContentVersion> listContentVer5 = new List<ContentVersion>();
            List<ContentVersion> listContentVer6 = new List<ContentVersion>();
            testContentVersion1 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
            );
            listContentVer1.add(testContentVersion1);
            insert listContentVer1;
            testContentVersion2 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
            );
            listContentVer2.add(testContentVersion2);
    
            insert listContentVer2;
            
            testContentVersion3 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
            );
            listContentVer3.add(testContentVersion3);
    
            insert listContentVer3;
            
            testContentVersion4 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
            );
            listContentVer4.add(testContentVersion4);
    
            insert listContentVer4;
            
            testContentVersion5 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
            );
            listContentVer5.add(testContentVersion5);
    
            insert listContentVer5;
            
            testContentVersion6 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
            );
            listContentVer6.add(testContentVersion6);
    
            insert listContentVer6;
    
            lstContentDocLink = new List<ContentDocumentLink>();
            
            ContentDocumentLink testContentDocumentLink1 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion1.Id].ContentDocumentId,
                LinkedEntityId = compte.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink1);
            //insert lstContentDocLink2;
            ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                LinkedEntityId = wk.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink2);
            ContentDocumentLink testContentDocumentLink3 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion3.Id].ContentDocumentId,
                LinkedEntityId = cp.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink3);
            ContentDocumentLink testContentDocumentLink4 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion4.Id].ContentDocumentId,
                LinkedEntityId = agreement.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink4);
            ContentDocumentLink testContentDocumentLink5 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion5.Id].ContentDocumentId,
                LinkedEntityId = univT.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink5);
            ContentDocumentLink testContentDocumentLink6 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion6.Id].ContentDocumentId,
                LinkedEntityId = min.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink6);
        }
        
    }
    
    
    @IsTest
   public static void testGetProfilesCEForWorkObject() {
        System.runAs(testUserCE) {
            Test.startTest();
                wk = new Work__c();
                wk.Subject__c = 'Test';
                wk.RecordTypeId = '0127S000000CgHtQAK';
                wk.Assigned_To__c = adminUser.id;
                wk.Related_Phase_Detail__c = 'Other';
                wk.status__c = 'New';
                wk.Description__c = 'test Description__c';
                wk.context__c = 'UAT';
                insert wk;
                
                testContentVersion2 = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test document content')
                );
                insert testContentVersion2;
                
                ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                LinkedEntityId = wk.id,
                ShareType = 'V'
                );
                insert testContentDocumentLinkWork;
            Test.stopTest();
        }
    }
   
        @IsTest
        public static void testGetProfilesCEForWorkObjectNotExt() {
            System.runAs(testUserCE) {
            DmlException expectedException;
                Test.startTest();
                try{
                    wk = new Work__c();
                    wk.Subject__c = 'Test';
                    wk.RecordTypeId = '0127S000000CgHtQAK';
                    wk.Assigned_To__c = adminUser.id;
                    wk.Related_Phase_Detail__c = 'Other';
                    wk.status__c = 'New';
                    wk.Description__c = 'test Description__c';
                    wk.context__c = 'UAT';
                    insert wk;
                    testContentVersion2 = new ContentVersion(
                    Title = 'Test Document',
                    PathOnClient = 'TestDocument.xvi',
                    VersionData = Blob.valueOf('Test document content')
                    );
                    insert testContentVersion2;
                    
                    ContentDocumentLink testContentDocumentLinkMin = new ContentDocumentLink(
                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                    LinkedEntityId = wk.id,
                    ShareType = 'V'
                    );
                    insert testContentDocumentLinkMin;
                }
                catch (DmlException dmx){
                    expectedException = dmx;
                }
                
                Test.stopTest();
                system.assertNotEquals(null, expectedException, 'You can not upload files xvi');
            }
        }
   
    @IsTest
    public static void testGetProfilesCEForCampaignObject() {
         System.runAs(testUserCE) {
             Test.startTest();
                Campaign cp = new Campaign();
                cp.name = 'test campaign1';
                insert cp;
                 
                 testContentVersion2 = new ContentVersion(
                 Title = 'Test Document',
                 PathOnClient = 'TestDocument.pdf',
                 VersionData = Blob.valueOf('Test document content')
                 );
                 insert testContentVersion2;
                 
                 ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                 ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                 LinkedEntityId = cp.id,
                 ShareType = 'V'
                 );
                 insert testContentDocumentLinkWork;
             Test.stopTest();
         }
     }
   
    @IsTest
    public static void testGetProfilesCEforAccountObject() {
         System.runAs(testUserCE) {
             Test.startTest();
                compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account ADA','C_01010');
                insert compte;
                 
                 testContentVersion2 = new ContentVersion(
                 Title = 'Test Document',
                 PathOnClient = 'TestDocument.pdf',
                 VersionData = Blob.valueOf('Test document content')
                 );
                 insert testContentVersion2;
                 
                 ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                 ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                 LinkedEntityId = compte.id,
                 ShareType = 'V'
                 );
                 insert testContentDocumentLinkAcc;
             Test.stopTest();
         }
     }
    
    
     @IsTest
     public static void testGetProfilesCEforMinuteObject() {
          System.runAs(testUserCE) {
              Test.startTest();
                min = new Minute__c();
                min.Name = 'test min1';
                min.Market__c = 'AXA XL;High growth market'; 
                insert min;
                  testContentVersion2 = new ContentVersion(
                  Title = 'Test Document',
                  PathOnClient = 'TestDocument.pdf',
                  VersionData = Blob.valueOf('Test document content')
                  );
                  insert testContentVersion2;
                  
                  ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                  ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                  LinkedEntityId = min.id,
                  ShareType = 'V'
                  );
                  insert testContentDocumentLinkMinute;
              Test.stopTest();
          }
      }
   
   
      @IsTest
      public static void testGetProfilesAdminForWorkObject() {
           System.runAs(testUserAdmin) {
               Test.startTest();
                   wk = new Work__c();
                   wk.Subject__c = 'Test';
                   wk.RecordTypeId = '0127S000000CgHtQAK';
                   wk.Assigned_To__c = adminUser.id;
                   wk.Related_Phase_Detail__c = 'Other';
                   wk.status__c = 'New';
                   wk.Description__c = 'test Description__c';
                   wk.context__c = 'UAT';
                   insert wk;
                   
                   testContentVersion2 = new ContentVersion(
                   Title = 'Test Document',
                   PathOnClient = 'TestDocument.pdf',
                   VersionData = Blob.valueOf('Test document content')
                   );
                   insert testContentVersion2;
                   
                   ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                   ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                   LinkedEntityId = wk.id,
                   ShareType = 'V'
                   );
                   insert testContentDocumentLinkWork;
               Test.stopTest();
           }
       }
      
        @IsTest
        public static void testGetProfilesAdminForCampaignbject() {
            System.runAs(testUserAdmin) {
                Test.startTest();
                    Campaign cp = new Campaign();
                    cp.name = 'test campaign2';
                    insert cp;
                    
                    testContentVersion2 = new ContentVersion(
                    Title = 'Test Document',
                    PathOnClient = 'TestDocument.pdf',
                    VersionData = Blob.valueOf('Test document content')
                    );
                    insert testContentVersion2;
                    
                    ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                    LinkedEntityId = cp.id,
                    ShareType = 'V'
                    );
                    insert testContentDocumentLinkWork;
                Test.stopTest();
            }
        }
   
       @IsTest
       public static void testGetProfilesAdminforAccountObject() {
            System.runAs(testUserAdmin) {
                Test.startTest();
                   compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account DAAB','C_800101');
                   insert compte;
                    
                    testContentVersion2 = new ContentVersion(
                    Title = 'Test Document',
                    PathOnClient = 'TestDocument.pdf',
                    VersionData = Blob.valueOf('Test document content')
                    );
                    insert testContentVersion2;
                    
                    ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                    LinkedEntityId = compte.id,
                    ShareType = 'V'
                    );
                    insert testContentDocumentLinkAcc;
                Test.stopTest();
            }
        }
   
        @IsTest
        public static void testGetProfilesAdminforMinuteObject() {
             System.runAs(testUserAdmin) {
                 Test.startTest();
                   min = new Minute__c();
                   min.Name = 'test min2';
                   min.Market__c = 'AXA XL;High growth market'; 
                   insert min;
                     testContentVersion2 = new ContentVersion(
                     Title = 'Test Document',
                     PathOnClient = 'TestDocument.pdf',
                     VersionData = Blob.valueOf('Test document content')
                     );
                     insert testContentVersion2;
                     
                     ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                     ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                     LinkedEntityId = min.id,
                     ShareType = 'V'
                     );
                     insert testContentDocumentLinkMinute;
                 Test.stopTest();
             }
         }
   
 
 
         @IsTest
         public static void testGetProfilesSystAdminAGREForWorkObject() {
              System.runAs(testUserAdminAGRE) {
                  Test.startTest();
                      wk = new Work__c();
                      wk.Subject__c = 'Test';
                      wk.RecordTypeId = '0127S000000CgHtQAK';
                      wk.Assigned_To__c = adminUser.id;
                      wk.Related_Phase_Detail__c = 'Other';
                      wk.status__c = 'New';
                      wk.Description__c = 'test Description__c';
                      wk.context__c = 'UAT';
                      insert wk;
                      
                      testContentVersion2 = new ContentVersion(
                      Title = 'Test Document',
                      PathOnClient = 'TestDocument.pdf',
                      VersionData = Blob.valueOf('Test document content')
                      );
                      insert testContentVersion2;
                      
                      ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                      ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                      LinkedEntityId = wk.id,
                      ShareType = 'V'
                      );
                      insert testContentDocumentLinkWork;
                  Test.stopTest();
              }
          }
         
         
          @IsTest
          public static void testGetProfilesSystAdminAGREforCampaignObject() {
              System.runAs(testUserAdminAGRE) {
                  Test.startTest();
                      Campaign cp = new Campaign();
                      cp.name = 'test campaign3';
                      insert cp;
                      
                      testContentVersion2 = new ContentVersion(
                      Title = 'Test Document',
                      PathOnClient = 'TestDocument.pdf',
                      VersionData = Blob.valueOf('Test document content')
                      );
                      insert testContentVersion2;
                      
                      ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                      ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                      LinkedEntityId = cp.id,
                      ShareType = 'V'
                      );
                      insert testContentDocumentLinkWork;
                  Test.stopTest();
              }
          }
          
          @IsTest
          public static void testGetProfilesSystAdminAGREforAccountObject() {
               System.runAs(testUserAdminAGRE) {
                   Test.startTest();
                      compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account SAAB','C_500101');
                      insert compte;
                       
                       testContentVersion2 = new ContentVersion(
                       Title = 'Test Document',
                       PathOnClient = 'TestDocument.pdf',
                       VersionData = Blob.valueOf('Test document content')
                       );
                       insert testContentVersion2;
                       
                       ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                       ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                       LinkedEntityId = compte.id,
                       ShareType = 'V'
                       );
                       insert testContentDocumentLinkAcc;
                   Test.stopTest();
               }
           }
          
           @IsTest
           public static void testGetProfilesSystAdminAGREforMinuteObject() {
                System.runAs(testUserAdminAGRE) {
                    Test.startTest();
                      min = new Minute__c();
                      min.Name = 'test min3';
                      min.Market__c = 'AXA XL;High growth market'; 
                      insert min;
                        testContentVersion2 = new ContentVersion(
                        Title = 'Test Document',
                        PathOnClient = 'TestDocument.pdf',
                        VersionData = Blob.valueOf('Test document content')
                        );
                        insert testContentVersion2;
                        
                        ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                        LinkedEntityId = min.id,
                        ShareType = 'V'
                        );
                        insert testContentDocumentLinkMinute;
                    Test.stopTest();
                }
            }
           
            @IsTest
            public static void testGetProfilesSystAdminAGRECLMObject() {
                 System.runAs(adminUser) {
                     Test.startTest();
                        Program__c pro = TestFactory.createProgram('TestProg3', '2', '3'
                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                        , '2018', compte.Id, '23001', '1', '25001');
                        insert pro;
                        
                        agreement = TestFactory.createAgreement('Test agreement');
                        agreement.program__c = pro.id;
                        agreement.Apttus__Status__c = 'In Renewal';
                        insert agreement;
                         
                         testContentVersion2 = new ContentVersion(
                         Title = 'Test Document',
                         PathOnClient = 'TestDocument.pdf',
                         VersionData = Blob.valueOf('Test document content')
                         );
                         insert testContentVersion2;
                         
                         ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                         ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                         LinkedEntityId = agreement.id,
                         ShareType = 'V'
                         );
                         insert testContentDocumentLinkMinute;
                     Test.stopTest();
                 }
             }
            
             @IsTest
             public static void testGetProfilesSystAdminAGRECLMObjectNotPDF() {
                DmlException expectedException;
                  System.runAs(adminUser) {
                      Test.startTest();
                      try{
                            Program__c pro = TestFactory.createProgram('TestProg3', '2', '3'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', compte.Id, '23001', '1', '25001');
                            insert pro;
                            
                            agreement = TestFactory.createAgreement('Test agreement');
                            agreement.program__c = pro.id;
                            agreement.Apttus__Status__c = 'In Renewal';
                            insert agreement;
                            
                            testContentVersion2 = new ContentVersion(
                            Title = 'Test Document',
                            PathOnClient = 'TestDocument.txt',
                            VersionData = Blob.valueOf('Test document content')
                            );
                            insert testContentVersion2;
                            
                            ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                            LinkedEntityId = agreement.id,
                            ShareType = 'V'
                            );
                            insert testContentDocumentLinkMinute;
                            }
                        catch (DmlException dmx){
                            expectedException = dmx;
                        }
                         
                      Test.stopTest();
                      system.assertNotEquals(null, expectedException, 'You can not upload files with extension txt');
                  }
              }
            
             @IsTest
             public static void testGetProfilesSystAdminCLMObject() {
                  System.runAs(adminUser) {
                      Test.startTest();

                        univT = new Universign_Transaction__c();
                        univT.Agreement__c = agreement.Id;
                        insert univT;
                          
                        testContentVersion2 = new ContentVersion(
                        Title = 'Test Document',
                        PathOnClient = 'TestDocument.pdf',
                        VersionData = Blob.valueOf('Test document content')
                        );
                        insert testContentVersion2;
                        
                        ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                        LinkedEntityId = univT.id,
                        ShareType = 'V'
                        );
                        insert testContentDocumentLinkMinute;
                      Test.stopTest();
                  }
              }
             
              @IsTest
              public static void testGetProfilesSystAdminCLMObjectNotPDF() {
                   System.runAs(adminUser) {
                       DmlException expectedException;
                       Test.startTest();
                       try{
                            univT = new Universign_Transaction__c();
                            univT.Agreement__c = agreement.Id;
                            insert univT;
                            
                            testContentVersion2 = new ContentVersion(
                            Title = 'Test Document',
                            PathOnClient = 'TestDocument.txt',
                            VersionData = Blob.valueOf('Test document content')
                            );
                            insert testContentVersion2;
                            
                            ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                            LinkedEntityId = univT.id,
                            ShareType = 'V'
                            );
                            insert testContentDocumentLinkMinute;
                       }
                       catch (DmlException dmx){
                           expectedException = dmx;
                       }
                       Test.stopTest();
                       system.assertNotEquals(null, expectedException, 'You can not upload files with extension txt');
                   }
               }
         

              @IsTest
              public static void testGetProfilesCEAXAXLForWorkObject() {
                   System.runAs(testUserCEAXAXL) {
                       Test.startTest();
                           wk = new Work__c();
                           wk.Subject__c = 'Test';
                           wk.RecordTypeId = '0127S000000CgHtQAK';
                           wk.Assigned_To__c = adminUser.id;
                           wk.Related_Phase_Detail__c = 'Other';
                           wk.status__c = 'New';
                           wk.Description__c = 'test Description__c';
                           wk.context__c = 'UAT';
                           insert wk;
                           
                           testContentVersion2 = new ContentVersion(
                           Title = 'Test Document',
                           PathOnClient = 'TestDocument.pdf',
                           VersionData = Blob.valueOf('Test document content')
                           );
                           insert testContentVersion2;
                           
                           ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                           ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                           LinkedEntityId = wk.id,
                           ShareType = 'V'
                           );
                           insert testContentDocumentLinkWork;
                       Test.stopTest();
                   }
               }
              
          @IsTest
          public static void testGetProfilesCEAXAXLForCampaignObject() {
              System.runAs(testUserCEAXAXL) {
                  Test.startTest();
                      Campaign cp = new Campaign();
                      cp.name = 'test campaign4';
                      insert cp;
                      
                      testContentVersion2 = new ContentVersion(
                      Title = 'Test Document',
                      PathOnClient = 'TestDocument.pdf',
                      VersionData = Blob.valueOf('Test document content')
                      );
                      insert testContentVersion2;
                      
                      ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                      ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                      LinkedEntityId = cp.id,
                      ShareType = 'V'
                      );
                      insert testContentDocumentLinkWork;
                  Test.stopTest();
              }
          }
              
               @IsTest
               public static void testGetProfilesCEAXAXLforAccountObject() {
                    System.runAs(testUserCEAXAXL) {
                        Test.startTest();
                           compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account NAB','C_001101');
                           insert compte;
                            
                            testContentVersion2 = new ContentVersion(
                            Title = 'Test Document',
                            PathOnClient = 'TestDocument.pdf',
                            VersionData = Blob.valueOf('Test document content')
                            );
                            insert testContentVersion2;
                            
                            ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                            LinkedEntityId = compte.id,
                            ShareType = 'V'
                            );
                            insert testContentDocumentLinkAcc;
                        Test.stopTest();
                    }
                }
               
                @IsTest
                public static void testGetProfilesCEAXAXLforMinuteObject() {
                     System.runAs(testUserCEAXAXL) {
                         Test.startTest();
                           min = new Minute__c();
                           min.Name = 'test min4';
                           min.Market__c = 'AXA XL;High growth market'; 
                           insert min;
                             testContentVersion2 = new ContentVersion(
                             Title = 'Test Document',
                             PathOnClient = 'TestDocument.pdf',
                             VersionData = Blob.valueOf('Test document content')
                             );
                             insert testContentVersion2;
                             
                             ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                             ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                             LinkedEntityId = min.id,
                             ShareType = 'V'
                             );
                             insert testContentDocumentLinkMinute;
                         Test.stopTest();
                     }
                 }


                 @IsTest
                 public static void testGetProfilesActorBasicSFAccessForWorkObject() {
                      System.runAs(testUserActorBasicSFAccess) {
                          Test.startTest();
                              wk = new Work__c();
                              wk.Subject__c = 'Test';
                              wk.RecordTypeId = '0127S000000CgHtQAK';
                              wk.Assigned_To__c = adminUser.id;
                              wk.Related_Phase_Detail__c = 'Other';
                              wk.status__c = 'New';
                              wk.Description__c = 'test Description__c';
                              wk.context__c = 'UAT';
                              insert wk;
                              
                              testContentVersion2 = new ContentVersion(
                              Title = 'Test Document',
                              PathOnClient = 'TestDocument.pdf',
                              VersionData = Blob.valueOf('Test document content')
                              );
                              insert testContentVersion2;
                              
                              ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                              ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                              LinkedEntityId = wk.id,
                              ShareType = 'V'
                              );
                              insert testContentDocumentLinkWork;
                          Test.stopTest();
                      }
                  }
                 
          @IsTest
          public static void testGetProfilesActorBasicSFAccessForCampaignObject() {
              System.runAs(testUserActorBasicSFAccess) {
                  Test.startTest();
                      Campaign cp = new Campaign();
                      cp.name = 'test campaign5';
                      insert cp;
                      
                      testContentVersion2 = new ContentVersion(
                      Title = 'Test Document',
                      PathOnClient = 'TestDocument.pdf',
                      VersionData = Blob.valueOf('Test document content')
                      );
                      insert testContentVersion2;
                      
                      ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                      ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                      LinkedEntityId = cp.id,
                      ShareType = 'V'
                      );
                      insert testContentDocumentLinkWork;
                  Test.stopTest();
              }
          }
                 
                  @IsTest
                  public static void testGetProfilesActorBasicSFAccessforAccountObject() {
                       System.runAs(testUserActorBasicSFAccess) {
                           Test.startTest();
                              compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account C2AAB','C_000201');
                              insert compte;
                               
                               testContentVersion2 = new ContentVersion(
                               Title = 'Test Document',
                               PathOnClient = 'TestDocument.pdf',
                               VersionData = Blob.valueOf('Test document content')
                               );
                               insert testContentVersion2;
                               
                               ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                               ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                               LinkedEntityId = compte.id,
                               ShareType = 'V'
                               );
                               insert testContentDocumentLinkAcc;
                           Test.stopTest();
                       }
                   }
                  
                   @IsTest
                   public static void testGetProfilesActorBasicSFAccessforMinuteObject() {
                        System.runAs(testUserActorBasicSFAccess) {
                            Test.startTest();
                              min = new Minute__c();
                              min.Name = 'test min5';
                              min.Market__c = 'AXA XL;High growth market'; 
                              insert min;  
                                testContentVersion2 = new ContentVersion(
                                Title = 'Test Document',
                                PathOnClient = 'TestDocument.pdf',
                                VersionData = Blob.valueOf('Test document content')
                                );
                                insert testContentVersion2;
                                
                                ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                LinkedEntityId = min.id,
                                ShareType = 'V'
                                );
                                insert testContentDocumentLinkMinute;
                            Test.stopTest();
                        }
                    }
    
                    @IsTest
                    public static void testGetProfilesActorBasicSFplatformForWorkObject() {
                         System.runAs(testUserActorBasicSFplatform) {
                             Test.startTest();
                                 wk = new Work__c();
                                 wk.Subject__c = 'Test';
                                 wk.RecordTypeId = '0127S000000CgHtQAK';
                                 wk.Assigned_To__c = adminUser.id;
                                 wk.Related_Phase_Detail__c = 'Other';
                                 wk.status__c = 'New';
                                 wk.Description__c = 'test Description__c';
                                 wk.context__c = 'UAT';
                                 insert wk;
                                 
                                 testContentVersion2 = new ContentVersion(
                                 Title = 'Test Document',
                                 PathOnClient = 'TestDocument.pdf',
                                 VersionData = Blob.valueOf('Test document content')
                                 );
                                 insert testContentVersion2;
                                 
                                 ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                                 ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                 LinkedEntityId = wk.id,
                                 ShareType = 'V'
                                 );
                                 insert testContentDocumentLinkWork;
                             Test.stopTest();
                         }
                     }
                    
                     @IsTest
                     public static void testGetProfilesActorBasicSFplatformForCampaignObject() {
                         System.runAs(testUserActorBasicSFplatform) {
                             Test.startTest();
                                 Campaign cp = new Campaign();
                                 cp.name = 'test campaign6';
                                 insert cp;
                                 
                                 testContentVersion2 = new ContentVersion(
                                 Title = 'Test Document',
                                 PathOnClient = 'TestDocument.pdf',
                                 VersionData = Blob.valueOf('Test document content')
                                 );
                                 insert testContentVersion2;
                                 
                                 ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                                 ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                 LinkedEntityId = cp.id,
                                 ShareType = 'V'
                                 );
                                 insert testContentDocumentLinkWork;
                             Test.stopTest();
                         }
                     }
                    
                     @IsTest
                     public static void testGetProfilesActorBasicSFplatformforAccountObject() {
                          System.runAs(testUserActorBasicSFplatform) {
                              Test.startTest();
                                 compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account AC','C_100101');
                                 insert compte;
                                  
                                  testContentVersion2 = new ContentVersion(
                                  Title = 'Test Document',
                                  PathOnClient = 'TestDocument.pdf',
                                  VersionData = Blob.valueOf('Test document content')
                                  );
                                  insert testContentVersion2;
                                  
                                  ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                                  ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                  LinkedEntityId = compte.id,
                                  ShareType = 'V'
                                  );
                                  insert testContentDocumentLinkAcc;
                              Test.stopTest();
                          }
                      }
                     
                      @IsTest
                      public static void testGetProfilesActorBasicSFplatformforMinuteObject() {
                           System.runAs(testUserActorBasicSFplatform) {
                               Test.startTest();
                                 min = new Minute__c();
                                 min.Name = 'test min6';
                                 min.Market__c = 'AXA XL;High growth market'; 
                                 insert min;
                                   testContentVersion2 = new ContentVersion(
                                   Title = 'Test Document',
                                   PathOnClient = 'TestDocument.pdf',
                                   VersionData = Blob.valueOf('Test document content')
                                   );
                                   insert testContentVersion2;
                                   
                                   ContentDocumentLink testContentDocumentLinkMinute = new ContentDocumentLink(
                                   ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                   LinkedEntityId = min.id,
                                   ShareType = 'V'
                                   );
                                   insert testContentDocumentLinkMinute;
                               Test.stopTest();
                           }
                       }
    
    
                       @IsTest
                       public static void testGetProfilesSFReadOnlyForWorkObject() {
                            DmlException expectedException;
                            System.runAs(testUserSFReadOnly) {
                                Test.startTest();
                                try{
                                    wk = new Work__c();
                                    wk.Subject__c = 'Test';
                                    wk.RecordTypeId = '0127S000000CgHtQAK';
                                    wk.Assigned_To__c = adminUser.id;
                                    wk.Related_Phase_Detail__c = 'Other';
                                    wk.status__c = 'New';
                                    wk.Description__c = 'test Description__c';
                                    wk.context__c = 'UAT';
                                    insert wk;
                                    testContentVersion2 = new ContentVersion(
                                    Title = 'Test Document',
                                    PathOnClient = 'TestDocument.pdf',
                                    VersionData = Blob.valueOf('Test document content')
                                    );
                                    insert testContentVersion2;
                                    
                                    ContentDocumentLink testContentDocumentLinkWork = new ContentDocumentLink(
                                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                    LinkedEntityId = wk.id,
                                    ShareType = 'V'
                                    );
                                    insert testContentDocumentLinkWork;
                                }
                                catch (DmlException dmx){
                                    expectedException = dmx;
                                }
                                   
                                Test.stopTest();
                                system.assertNotEquals(null, expectedException, 'You can not upload files ');
                            }
                        }
                       
                       
                        @IsTest
                        public static void testGetProfilesSFReadOnlyforAccountObject() {
                            DmlException expectedException;
                             System.runAs(testUserSFReadOnly) {
                                 Test.startTest();
                                 try{
                                    compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account AC','C_100101');
                                    insert compte;
                                    testContentVersion2 = new ContentVersion(
                                    Title = 'Test Document',
                                    PathOnClient = 'TestDocument.pdf',
                                    VersionData = Blob.valueOf('Test document content')
                                    );
                                    insert testContentVersion2;
                                    
                                    ContentDocumentLink testContentDocumentLinkAcc = new ContentDocumentLink(
                                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                    LinkedEntityId = compte.id,
                                    ShareType = 'V'
                                    );
                                    insert testContentDocumentLinkAcc;
                                }
                                catch (DmlException dmx){
                                    expectedException = dmx;
                                }
                                    
                                 Test.stopTest();
                                 system.assertNotEquals(null, expectedException, 'You can not upload files ');
                             }
                         }
                        
                         @IsTest
                         public static void testGetProfilesSFReadOnlyMinuteObject() {
                              System.runAs(testUserSFReadOnly) {
                                DmlException expectedException;
                                  Test.startTest();
                                  try{
                                        min = new Minute__c();
                                        min.Name = 'test min6';
                                        min.Market__c = 'AXA XL;High growth market'; 
                                        insert min;
                                        testContentVersion2 = new ContentVersion(
                                        Title = 'Test Document',
                                        PathOnClient = 'TestDocument.pdf',
                                        VersionData = Blob.valueOf('Test document content')
                                        );
                                        insert testContentVersion2;
                                        
                                        ContentDocumentLink testContentDocumentLinkMin = new ContentDocumentLink(
                                        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                                        LinkedEntityId = compte.id,
                                        ShareType = 'V'
                                        );
                                        insert testContentDocumentLinkMin;
                                    }
                                    catch (DmlException dmx){
                                        expectedException = dmx;
                                    }
                                    
                                  Test.stopTest();
                                  system.assertNotEquals(null, expectedException, 'You can not upload files ');
                              }
                          }
    /*@IsTest
    public static void testGetProfilesSFReadOnly() {
        System.runAs(testUserSFReadOnly) {
            Test.startTest();
                //insert lstContentDocLink;
        }
    }*/
}