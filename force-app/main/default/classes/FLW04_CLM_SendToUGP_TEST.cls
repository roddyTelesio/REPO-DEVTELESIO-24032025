@isTest
public with sharing class FLW04_CLM_SendToUGP_TEST {
    public static Id companygroupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Principal Ceding Company').getRecordTypeId();
    public static  Apttus__APTS_Agreement__c initialAgreement;
    public static  Apttus__DocumentVersionDetail__c documentVersionDetail;
    static User testUserAdmin;
    static User testUserCE;

    // Test setup to create necessary test data
    static {

     	 //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests;AP42_DeleteDocumentVisibility';
        insert testUserCE;
        
        Account company = TestFactory.createAccount(companygroupRecordTypeId,'Test Account','TestReferentiel');
        company.EmailPCLife__c = 'test@email.cc';
        
        insert company;
        Program__c createProgram = TestFactory.createProgram('Test program','1','1',System.today(),System.today().addYears(1),'1',System.today(),System.today().addYears(3),String.valueOf(System.today().year()),String.valueOf(company.id),'23002','2','25010');
        insert createProgram;
        
           Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
        // Create a test agreement record for the test
        initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        initialAgreement.contractCode__c = 'xxx';
        initialAgreement.Program__c = createProgram.Id;
        insert initialAgreement;


        // Créez un enregistrement Apttus__DocumentVersionDetail__c pour les tests
        ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial',Blob.valueOf('Contenu initial'),'test.doc');
        insert cv;

        Apttus__APTS_Template__c tmp = TestFActory.createTemplate('test');
        insert tmp;

        Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test.doc');
        documentVersion.Apttus__TemplateId__c = tmp.id;
        documentVersion.Apttus__AgreementId__c = initialAgreement.id;
        insert documentVersion;

        documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test.doc',1,2,3);
        documentVersionDetail.Apttus__ContentVersionId__c = cv.id;
        documentVersionDetail.Apttus__DocumentInfo__c = 'Final';
        documentVersionDetail.Apttus__VersionRevision__c = 0;
        

        insert documentVersionDetail;
        
    }

    @isTest
    static void unitTestMethod() {
        System.runAs(testUserCE) {
          	Test.startTest();
            FLW04_CLM_SendToUGP.InputVariables inputVar = new FLW04_CLM_SendToUGP.InputVariables();
            inputVar.AgreementId = initialAgreement.id;
            FLW04_CLM_SendToUGP.processAndSendEmail(new List <FLW04_CLM_SendToUGP.InputVariables>{inputVar});
            Test.stopTest();   
        }
    }
}