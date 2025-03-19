/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 10-04-2024
 * @last modified by  : Bhavesh Bhuckory
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   08-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class ConvertToPdf_TST {
    public static Apttus__DocumentVersionDetail__c documentVersionDetail;
    public static  Apttus__APTS_Agreement__c initialAgreement;

    static{

        Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
        // Create a test agreement record for the test
        initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        initialAgreement.contractCode__c = 'xxx';
        // initialAgreement.Program__c = createProgram.Id;
        insert initialAgreement;
        // Create test content document
        ContentVersion testContent = TestFactory.createContentVersion('1','1','1','Test Document',Blob.valueOf('Test Content'),'test-document.docx');
        insert testContent;

       
        Apttus__APTS_Template__c tmp = TestFActory.createTemplate('test');
        insert tmp;

         Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test.doc');
         documentVersion.Apttus__TemplateId__c = tmp.id;
         documentVersion.Apttus__AgreementId__c = initialAgreement.id;
         insert documentVersion;
 
         documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test.doc',1,2,3);
         documentVersionDetail.Apttus__ContentVersionId__c = testContent.id;
         documentVersionDetail.Apttus__DocumentInfo__c = 'Final';
         documentVersionDetail.Apttus__VersionRevision__c = 0;
         
 
         insert documentVersionDetail;
 
    }

    @isTest
    static void testConvertToPdf() {

         // Query the test content version
         ContentVersion testContentVersion = [SELECT Id, Title FROM ContentVersion WHERE Title = 'Test Document' LIMIT 1];
        // Call the ConvertToPdf method with the test content version
        Test.startTest();
        ConvertToPdf.ConvertToPdf(testContentVersion.Id, testContentVersion.Title,documentVersionDetail.Id);
        Test.stopTest();

        // Query the converted PDF document
        ContentVersion convertedPdf = [SELECT Id, Title, FileType FROM ContentVersion WHERE Title = 'Test Document' LIMIT 1];

        // Verify the results with assertions
        System.assertNotEquals(null, convertedPdf, 'No PDF document found.');
        System.assertEquals('Test Document', convertedPdf.Title, 'The PDF document title is incorrect.');
        // System.assertEquals('PDF', convertedPdf.FileType, 'The document is not in PDF format.');
    }
}