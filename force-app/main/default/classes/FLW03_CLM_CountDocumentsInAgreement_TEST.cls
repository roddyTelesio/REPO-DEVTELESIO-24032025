@isTest
public with sharing class FLW03_CLM_CountDocumentsInAgreement_TEST {
    public static Id companygroupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Principal Ceding Company').getRecordTypeId();
    public static  Apttus__APTS_Agreement__c initialAgreement;
    public static  Apttus__DocumentVersionDetail__c documentVersionDetail;

    // Test setup to create necessary test data
    static {

        Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
        // Create a test agreement record for the test
        initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        initialAgreement.contractCode__c = 'xxx';
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
        Account company = TestFactory.createAccount(companygroupRecordTypeId,'Test Account','TestReferentiel');
        
        insert company;
        Program__c createProgram = TestFactory.createProgram('Test program','1','1',System.today(),System.today().addYears(1),'1',System.today(),System.today().addYears(3),String.valueOf(System.today().year()),String.valueOf(company.id),'23002','2','25010');
        insert createProgram;
        
    }

    @isTest
    static void unitTestMethod() {
        Test.startTest();
        FLW03_CLM_CountDocumentsInAgreement.InputVariables inputVar = new FLW03_CLM_CountDocumentsInAgreement.InputVariables();
        inputVar.AgreementId = initialAgreement.id;
        FLW03_CLM_CountDocumentsInAgreement.countDocs(new List <FLW03_CLM_CountDocumentsInAgreement.InputVariables>{inputVar});
        Test.stopTest();

    }

    @isTest
    static void unitTestDeleteMethod() {
        Test.startTest();
            delete documentVersionDetail;
        Test.stopTest();

    }
}