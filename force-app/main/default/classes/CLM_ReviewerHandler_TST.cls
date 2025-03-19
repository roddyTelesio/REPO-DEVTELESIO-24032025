/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 28-05-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   28-05-2024   Patrick Randrianarisoa   Initial Version
**/
@IsTest
public class CLM_ReviewerHandler_TST {
    @TestSetup
    static void makeData(){
        Apttus__APTS_Agreement__c Agr = new Apttus__APTS_Agreement__c(name = 'Test Agreement');
        insert Agr;
        Apttus__DocumentVersion__c dv = TestFactory.createDocumentVersion('Document version detail','1.0.0','Document version detail');
        insert dv;
        Apttus__DocumentVersionDetail__c dvd = TestFactory.createDocumentVersionDetail('1.0.0',dv.id,'Title', 1, 1, 1);
        insert dvd;
        Apttus__ReviewCycle__c revc = new Apttus__ReviewCycle__c(name = 'review cycle');
        revc.Apttus__OriginalDocumentVersionDetail__c = dvd.id;
        insert revc;
        Apttus__Reviewer__c rev = new Apttus__Reviewer__c();
        rev.Apttus__EndReviewDocumentVersion__c = dvd.id;
        rev.Apttus__ReviewStatus__c = 'In Progress';
        rev.Apttus__ReviewCycle__c = revc.id;
        insert rev;
    }

    @IsTest
    static void handleAfterUpdate_test() {
        Apttus__Reviewer__c rev = [SELECT id,Apttus__ReviewStatus__c from Apttus__Reviewer__c LIMIT 1 ];
        rev.Apttus__ReviewStatus__c = 'Completed';
        Test.startTest();
        update rev;
        Test.stopTest();
    }
}