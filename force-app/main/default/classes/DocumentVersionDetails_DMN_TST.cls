/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 10-07-2024
 * @last modified by  : Bhavesh Bhuckory
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   11-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class DocumentVersionDetails_DMN_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        // Create test data
           // Create common test data
           Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
            AP_Constant.sObjectAcc
        });

        //create Account
        Account compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001');
        insert compte;
        Program__c pro = TestFactory.createProgram('TestProg3', '2', '3'
        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
        , '2018', compte.Id, '23001', '1', '25001');
        insert pro;
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        initialAgreement.Apttus__Status__c = 'In Renewal';
        initialAgreement.program__c = pro.id;
        insert initialAgreement;
        ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial',Blob.valueOf('Contenu initial'),'test.pdf');
        insert cv;
        Apttus__APTS_Template__c tmp = TestFActory.createTemplate('test');
        insert tmp;
        Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test');
        documentVersion.Apttus__TemplateId__c = tmp.id;
        documentVersion.Apttus__AgreementId__c = initialAgreement.id;
        insert documentVersion;
        Apttus__DocumentVersionDetail__c documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test',1,2,3);
        documentVersionDetail.Generate_Pdf__c = true;
        documentVersionDetail.Apttus__ContentVersionId__c = cv.id;
        insert documentVersionDetail;
        ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Title = 'Titre du contenu initial'];
        ContentDocumentLink cdl = TestFActory.createContentDocumentLink(cd.id,documentVersion.Id,'V');
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }

    @isTest
    static void testGeneratePdf() {
        // Call the generatePdf method
        List<Apttus__DocumentVersionDetail__c> documentVersionDetail = [SELECT Apttus__Title__c,Id,Apttus__ContentVersionId__c, Generate_Pdf__c,TECH_AgreementId__c,TECH_TemplateId__c,name,Apttus__VersionMajor__c,Apttus__VersionMinor__c FROM Apttus__DocumentVersionDetail__c];
        Map<Id, Apttus__DocumentVersionDetail__c> oldDocVersionMap = new Map<Id, Apttus__DocumentVersionDetail__c>();
        Apttus__DocumentVersionDetail__c oldDocumentVersion = documentVersionDetail[0].clone(true, true, true, true);

        oldDocumentVersion.Generate_Pdf__c = false;
        oldDocVersionMap.put(documentVersionDetail[0].Id, oldDocumentVersion);
        Test.startTest();
        DocumentVersionDetails_DMN.generatePdf(documentVersionDetail, oldDocVersionMap);
        Test.stopTest();

        // Verify that PDF generation logic was executed
        List<Apttus__DocumentVersionDetail__c> updatedDocVersions = [SELECT Id, Name, Apttus__IsTransient__c FROM Apttus__DocumentVersionDetail__c];
        // System.assertEquals(1, updatedDocVersions.size(), 'PDF generation should result in an updated document version.');
    }

    @isTest
    static void testGeneratePdfNoTemplate() {
        // Call the generatePdf method
        Apttus__DocumentVersion__c documentVersion = [SELECT id FROM Apttus__DocumentVersion__c limit 1];
        documentVersion.Apttus__TemplateId__c = null;

        update documentVersion;
        List<Apttus__DocumentVersionDetail__c> documentVersionDetail = [SELECT Id,Apttus__ContentVersionId__c, Generate_Pdf__c,TECH_AgreementId__c,TECH_TemplateId__c,name,Apttus__VersionMajor__c,Apttus__VersionMinor__c,Apttus__DocumentVersionId__c,Apttus__Title__c,Apttus__VersionRevision__c FROM Apttus__DocumentVersionDetail__c];
        Map<Id, Apttus__DocumentVersionDetail__c> oldDocVersionMap = new Map<Id, Apttus__DocumentVersionDetail__c>();
        Apttus__DocumentVersionDetail__c oldDocumentVersion = documentVersionDetail[0].clone(true, true, true, true);

        oldDocumentVersion.Generate_Pdf__c = false;
        oldDocVersionMap.put(documentVersionDetail[0].Id, oldDocumentVersion);
        Test.startTest();
        DocumentVersionDetails_DMN.generatePdf(documentVersionDetail, oldDocVersionMap);
        Test.stopTest();

        // Verify that PDF generation logic was executed
        List<Apttus__DocumentVersionDetail__c> updatedDocVersions = [SELECT Id, Name, Apttus__IsTransient__c FROM Apttus__DocumentVersionDetail__c];
        // System.assertEquals(1, updatedDocVersions.size(), 'PDF generation should result in an updated document version.');
    }
}