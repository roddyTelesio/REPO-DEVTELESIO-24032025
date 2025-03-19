/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 14-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   07-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class ApprovalRecall_SVC_TST {
    public static Id companygroupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Principal Ceding Company').getRecordTypeId();
	public static Apttus__APTS_Template__c tmp;
    public static User testUserAdmin;
    public static List<ProcessInstanceWorkitem> lstApp;
    static{
           // Créez un enregistrement Apttus__DocumentVersionDetail__c pour les tests
        ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial.pdf',Blob.valueOf('Contenu initial'),'test.pdf');
        insert cv;
        tmp = TestFActory.createTemplate('test');
        tmp.Status__c = null;
        tmp.Apttus__IsActive__c = false;
        insert tmp;
        Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test');
        documentVersion.Apttus__TemplateId__c = tmp.id;
        insert documentVersion;
        Apttus__DocumentVersionDetail__c documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test',1,2,3);
        documentVersionDetail.Apttus__ContentVersionId__c = cv.id;
        insert documentVersionDetail;
        Account company = TestFactory.createAccount(companygroupRecordTypeId,'Test Account','TestReferentiel');
        insert company;
        Program__c createProgram = TestFactory.createProgram('Test program','1','1',System.today(),System.today().addYears(1),'1',System.today(),System.today().addYears(3),String.valueOf(System.today().year()),String.valueOf(company.id),'23002','2','25010');
        insert createProgram;
		testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());      
        insert testUserAdmin;
          // Create an approval request for the account
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setProcessDefinitionNameOrId('CLM_Approve_Clause');
        req.setComments('Submitting request for approval.');
        req.setObjectId(tmp.Id);
        req.setNextApproverIds(new List<Id>{testUserAdmin.Id});
        // Submit the approval request
        Approval.ProcessResult result = Approval.process(req);
        // Check if the request was successful
        lstApp = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem];

    }
    
    @isTest
    static void testRecallApproval() {
        ApprovalRecall_SVC.recallApproval(new List<Id>{lstApp[0].Id});
    }
    
     @isTest
    static void testLogApproval() {
        ApprovalRecall_SVC.recallApproval(new List<Id>{null});
    }
    
    
}