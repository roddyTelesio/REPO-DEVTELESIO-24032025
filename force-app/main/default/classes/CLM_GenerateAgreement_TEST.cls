@isTest
public with sharing class CLM_GenerateAgreement_TEST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
    @testSetup
    static void setupTestData() { 
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;
        
         // Créez un enregistrement Apttus__DocumentVersionDetail__c pour les tests
        ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial.pdf',Blob.valueOf('Contenu initial'),'test.pdf');
        insert cv;

        Apttus__APTS_Template__c tmp = TestFActory.createTemplate('test');
        insert tmp;

        Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test');
        documentVersion.Apttus__TemplateId__c = tmp.id;
        documentVersion.Apttus__AgreementId__c = initialAgreement.id;
        insert documentVersion;

        Apttus__DocumentVersionDetail__c documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test',1,2,3);
        documentVersionDetail.Apttus__ContentVersionId__c = cv.id;
        documentVersionDetail.Apttus__DocumentInfo__c = 'Final';
        documentVersionDetail.TECH_GeneratePDFByBatch__c = true;

        insert documentVersionDetail;
    }

    @isTest
    static void testCreateAmmendment() {
            CLM_GenerateAgreement.ObjectContext objContext = new CLM_GenerateAgreement.ObjectContext();
            Apttus__APTS_Agreement__c agre= [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1 ];
            objContext.agreementId = agre.Id;
        	objContext.templateName = 'test';
            List<CLM_GenerateAgreement.Result> results = CLM_GenerateAgreement.createAmmendment(new List<CLM_GenerateAgreement.ObjectContext>{objContext});
    }

	@isTest
    static void testCreateAmmendmentFailure() {
            CLM_GenerateAgreement.ObjectContext objContext = new CLM_GenerateAgreement.ObjectContext();
            List<CLM_GenerateAgreement.Result> results = CLM_GenerateAgreement.createAmmendment(new List<CLM_GenerateAgreement.ObjectContext>{objContext});
            CLM_GenerateAgreement.Result result = new CLM_GenerateAgreement.Result(true,null,'null');
    }
}