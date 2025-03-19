@IsTest
public with sharing class LWC66_ListViewAgreem_TEST {
  public static Account compte;
  public static Program__c pro;
  public static Apttus__APTS_Agreement__c agreement;
    /**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC18_SendUpdateRemind
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 16-SEP-2020  SAU   1.0      Initial version
-- 24-MAY-2021  MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
--------------------------------------------------------------------------------------
**************************************************************************************/
   static {         // Create common test data
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
            AP_Constant.sObjectAcc
        });

        //create Account
        compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001');
        insert compte;
        pro = TestFactory.createProgram('TestProg1', '1', '1'
                                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                        , '2018', compte.Id, '23002','2'
                                        , '25009');
        insert pro;
        System.debug('pro init ==' + pro);
        agreement = TestFactory.createAgreement('Test agreement');
        agreement.DeleteRenewedAgreementDocuments__c = true;
        agreement.program__c = pro.id;
        agreement.UnderwritingYear__c = '2018';
        agreement.PrincipalCedingCompany__c = compte.Id;
        agreement.Apttus__Contract_End_Date__c = System.today()+360;
        insert agreement;
        Apttus__DocumentVersion__c testDocumentVersion = TestFactory.createDocumentVersion('1.0','1','Title');
        testDocumentVersion.Apttus__AgreementId__c = agreement.id;
        insert testDocumentVersion;
        Apttus__DocumentVersionDetail__c testDocumentVersionDetail = TestFactory.createDocumentVersionDetail('1.0',testDocumentVersion.id,'Ttitle',1,0,1);
        testDocumentVersionDetail.ToProcessDelete__c =true;
        // Add any required field assignments
        insert testDocumentVersionDetail;


        // Create a test ContentDocument
        List<ContentVersion> listContentVer = new List<ContentVersion>();
        ContentVersion testContentVersion1 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test document content')
        );
        listContentVer.add(testContentVersion1);

        ContentVersion testContentVersion2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test document content')
        );
        listContentVer.add(testContentVersion2);

        insert listContentVer;

        List<ContentDocumentLink> lstContentDocLink = new List<ContentDocumentLink>();
        ContentDocumentLink testContentDocumentLink1 = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion1.Id].ContentDocumentId,
            LinkedEntityId = agreement.id,
            ShareType = 'V'
        );
        lstContentDocLink.add(testContentDocumentLink1);
        ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
            LinkedEntityId = agreement.id,
            ShareType = 'V'
        );
        lstContentDocLink.add(testContentDocumentLink2);

        insert lstContentDocLink;

        
    }


    @IsTest
    public static void testGetPrograms(){
        Test.startTest();
            List<Program__c> lstProgram = LWC66_ListViewAgreement.getPrograms('2018', compte.Id);
        Test.stopTest();
        System.assertEquals(1, lstProgram.size());
    }

    @IsTest
    public static void testGetRT(){
        Test.startTest();
            List<LWC66_ListViewAgreement.OptionWrapper> lstRT = LWC66_ListViewAgreement.getRecordTypeName();
        Test.stopTest();
        System.assertEquals(6, lstRT.size());
    }

     @IsTest
    public static void testGetSigningStatus(){
          Test.startTest();
              List<LWC66_ListViewAgreement.OptionWrapper> lstSigningStatus = LWC66_ListViewAgreement.getSigningStatus();
          Test.stopTest();
          System.assertEquals(4, lstSigningStatus.size());
   }

    @IsTest
    public static void testGetAgreementsAll(){
        Test.startTest();
          LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
          filterAgreement.uwy = '--All--';
          filterAgreement.pcc = '--All--';
          filterAgreement.prg = null;
          filterAgreement.rt = '--All--';
          filterAgreement.sigstat = '--All--';
          List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

     @IsTest
    public static void testGetAgreementsAllRTSIGSTAT(){
        Test.startTest();
          LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
          filterAgreement.uwy = '--All--';
          filterAgreement.pcc = '--All--';
          filterAgreement.prg = null;
          filterAgreement.rt = 'Acceptation';
          filterAgreement.sigstat = '--All--';
         List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

     @IsTest
    public static void testGetAgreementsAllRTSIGSTAT2(){
        Test.startTest();
          LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
          filterAgreement.uwy = '--All--';
          filterAgreement.pcc = '--All--';
          filterAgreement.prg = null;
          filterAgreement.rt = '--All--';
          filterAgreement.sigstat = 'To be signed';
          List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

     @IsTest
    public static void testGetAgreementsAllUWY(){
        Test.startTest();
            LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
            filterAgreement.uwy = '2018';
            filterAgreement.pcc = '--All--';
            filterAgreement.prg = null;
            filterAgreement.rt = '--All--';
            filterAgreement.sigstat = '--All--';
            List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
            Test.stopTest();
    }

     @IsTest
    public static void testGetAgreementsAllUWYRTSIGSTAT(){
        Test.startTest();
            LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
            filterAgreement.uwy = '2018';
            filterAgreement.pcc = '--All--';
            filterAgreement.prg = null;
            filterAgreement.rt = '--All--';
            filterAgreement.sigstat = 'To be signed';
            List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
            Test.stopTest();
    }

    @IsTest
    public static void testGetAgreementsAllUWYRTSIGSTAT2(){
        Test.startTest();
            LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
            filterAgreement.uwy = '2018';
            filterAgreement.pcc = '--All--';
            filterAgreement.prg = null;
            filterAgreement.rt = 'Acceptation';
            filterAgreement.sigstat = '--All--';
             List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
            Test.stopTest();
    }

    @IsTest
    public static void testGetAgreementsAllPCC(){
        Test.startTest();
          LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
          filterAgreement.uwy = '--All--';
          filterAgreement.pcc = compte.Id;
          filterAgreement.prg = null;
          filterAgreement.rt = '--All--';
          filterAgreement.sigstat = '--All--';
          List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

    @IsTest
    public static void testGetAgreementsAllPCCRTSIGSTAT(){
        Test.startTest();
          LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
          filterAgreement.uwy = '--All--';
          filterAgreement.pcc = compte.Id;
          filterAgreement.prg = null;
          filterAgreement.rt = '--All--';
          filterAgreement.sigstat = 'To be signed';
          List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

    @IsTest
    public static void testGetAgreementsAllPCCRTSIGSTAT2(){
        Test.startTest();
          LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
          filterAgreement.uwy = '--All--';
          filterAgreement.pcc = compte.Id;
          filterAgreement.prg = null;
          filterAgreement.rt = 'Acceptation';
          filterAgreement.sigstat = '--All--';
          List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

    @IsTest
    public static void testGetAgreementsAllUWYPCC(){
        Test.startTest();
            LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
            filterAgreement.uwy = '2018';
            filterAgreement.pcc = compte.Id;
            filterAgreement.prg = pro.Id;
            filterAgreement.rt = '--All--';
            filterAgreement.sigstat = '--All--';
            List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }
    @IsTest
    public static void testGetAgreementsAllUWYPCCRT(){
        Test.startTest();
            LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
            filterAgreement.uwy = pro.UwYear__c;
            filterAgreement.pcc = compte.Id;
            filterAgreement.prg = pro.Id;
            filterAgreement.rt = 'Acceptation';
            filterAgreement.sigstat = '--All--';
            List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

     @IsTest
    public static void testGetAgreementsAllUWYPCCSIGNSTAT(){
        Test.startTest();
            LWC66_ListViewAgreement.FilterAgreementsWrapper filterAgreement = new LWC66_ListViewAgreement.FilterAgreementsWrapper();
            filterAgreement.uwy = pro.UwYear__c;
            filterAgreement.pcc = compte.Id;
            filterAgreement.prg = pro.Id;
            filterAgreement.rt = '--All--';
            filterAgreement.sigstat = 'To be signed';
            List<Apttus__APTS_Agreement__c> lstAgreements = LWC66_ListViewAgreement.getAgreements(filterAgreement, 10, 0);
        Test.stopTest();
    }

    @IsTest
    public static void testDeleteAgreementsSelected(){
        Test.startTest();
         System.debug('pro 11== ' + pro);
        System.debug('pro Id == ' + pro.Id);
            Apttus__APTS_Agreement__c agreements = new Apttus__APTS_Agreement__c();
            agreements = TestFactory.createAgreement('Test 1 agreement');
            agreements.DeleteRenewedAgreementDocuments__c = true;
            agreements.program__c = pro.Id;
            agreements.Apttus__Contract_End_Date__c = System.today()+360;
            insert agreements;
            String strAgreements = LWC66_ListViewAgreement.deleteAgreementsSelected(agreements.id);
        Test.stopTest();
    }

     @IsTest
    public static void testFetchDataAgreementsALL(){
        Test.startTest();
            Apttus__APTS_Agreement__c agreements = new Apttus__APTS_Agreement__c();
            agreements = TestFactory.createAgreement('Test 2 agreement');
            agreements.DeleteRenewedAgreementDocuments__c = true;
            agreements.program__c = pro.Id;
            agreements.Apttus__Contract_End_Date__c = System.today()+360;
            insert agreements;
            List<Apttus__APTS_Agreement__c>  fetchAgreements = LWC66_ListViewAgreement.fetchDataAgreements(agreements.Name, '--All--', '--All--', 0);
        Test.stopTest();
    }

    @IsTest
    public static void testFetchDataAgreementsALLPCC(){
        Apttus__APTS_Agreement__c agreements = new Apttus__APTS_Agreement__c();
        agreements = TestFactory.createAgreement('Test 3 agreement');
        agreements.DeleteRenewedAgreementDocuments__c = true;
        agreements.program__c = pro.Id;
        agreements.Apttus__Contract_End_Date__c = System.today()+360;
        insert agreements;
        Test.startTest();
            List<Apttus__APTS_Agreement__c>  fetchAgreements = LWC66_ListViewAgreement.fetchDataAgreements(agreements.Name, '--All--',pro.PrincipalCedingCompany__c, 0);
        Test.stopTest();
    }

     @IsTest
    public static void testFetchDataAgreementsALLUWY(){
        Test.startTest();
         Apttus__APTS_Agreement__c agreements = new Apttus__APTS_Agreement__c();
        agreements = TestFactory.createAgreement('Test 4 agreement');
        agreements.DeleteRenewedAgreementDocuments__c = true;
        agreements.program__c = pro.Id;
        agreements.Apttus__Contract_End_Date__c = System.today()+360;
        insert agreements;
        List<Apttus__APTS_Agreement__c>  fetchAgreements = LWC66_ListViewAgreement.fetchDataAgreements(agreements.Name, pro.UwYear__c,'--All--', 0);
        Test.stopTest();
    }


    @IsTest
    public static void testFetchDataAgreements(){
        Test.startTest();

        Apttus__APTS_Agreement__c agreements = new Apttus__APTS_Agreement__c();
        agreements = TestFactory.createAgreement('Test 5 agreement');
        agreements.DeleteRenewedAgreementDocuments__c = true;
        agreements.program__c = pro.Id;
        agreements.Apttus__Contract_End_Date__c = System.today()+360;
        insert agreements;
              List<Apttus__APTS_Agreement__c>  fetchAgreements = LWC66_ListViewAgreement.fetchDataAgreements(agreements.Name, pro.UwYear__c, pro.PrincipalCedingCompany__c, 0);
        Test.stopTest();
    }
     @IsTest
    public static void testGetUWYAgreements(){
         List<LWC66_ListViewAgreement.OptionWrapper> lstUWY = LWC66_ListViewAgreement.getUWYAgreements();
        Test.startTest();
        System.assertEquals(1, lstUWY.size());
        Test.stopTest();
    }

     @IsTest
    public static void testGetPCCAgreements(){
         List<LWC66_ListViewAgreement.OptionWrapper> lstPCC = LWC66_ListViewAgreement.getPCCAgreements();
        Test.startTest();
        System.assertEquals(1, lstPCC.size());
        Test.stopTest();
    }
}