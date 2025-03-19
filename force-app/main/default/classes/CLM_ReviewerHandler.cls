/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 30-05-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   28-05-2024   Patrick Randrianarisoa   Initial Version
**/
public class CLM_ReviewerHandler {
    public void handleAfterUpdate(List<Apttus__Reviewer__c> lstReviewerOld,List<Apttus__Reviewer__c> lstReviewerNew) {
        List<Id> lstReviewer = new List<Id>();
        for (Integer i = 0; i < lstReviewerOld.size(); i++) {
            if(lstReviewerOld[i].Apttus__ReviewStatus__c <> lstReviewerNew[i].Apttus__ReviewStatus__c && lstReviewerNew[i].Apttus__ReviewStatus__c == 'Completed'){
                lstReviewer.add(lstReviewerNew[i].id);
            }            
        }

        if(lstReviewer.size() > 0){
            NotifyCEOnReviewFinished(lstReviewer);
        }
    }

    @future(callout=true)
    public static void NotifyCEOnReviewFinished(List<Id> lstReviewerId){
        EmailTemplate template = [ SELECT id, name, body, subject ,HtmlValue
                                    FROM EmailTemplate WHERE developername = 'CLM_NotifieCEReviewFinish' Limit 1];

        String emailTemplateId = template <> null ?  template.Id : null;

        if(emailTemplateId <> null){
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress where Address = 'actor.po@axa.com' LIMIT 1];
            for(Apttus__Reviewer__c rev : [SELECT id,Apttus__EndReviewDocumentVersion__r.Apttus__DocumentVersionId__r.Apttus__AgreementId__c,Apttus__EndReviewDocumentVersion__r.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Account__r.EmailPCLife__c from Apttus__Reviewer__c WHERE id in :lstReviewerId ]){
                String AgreementId = rev.Apttus__EndReviewDocumentVersion__r.Apttus__DocumentVersionId__r.Apttus__AgreementId__c;
                List<String> emailPCLIFE = new List<String>{rev.Apttus__EndReviewDocumentVersion__r.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Account__r.EmailPCLife__c};
                try {
                    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, AgreementId);
                    mail.setSubject(mail.getSubject());
                    mail.sethtmlBody(mail.gethtmlBody());
                    mail.SetToAddresses(emailPCLIFE);
                    mail.saveAsActivity = false;
                    if(owea.size() > 0){
                        mail.setOrgWideEmailAddressId(owea[0].Id);
                    }
                    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{ mail };
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages,false);
                    if (results[0].success) {
                        System.debug('The email NotifyCEOnReviewFinished was sent successfully.');
                    } else {
                        System.debug('The email NotifyCEOnReviewFinished failed to send: '
                              + results[0].errors[0].message);
                    }
                } catch (Exception e) {
                    System.debug('CLM_ReviewerHandler error ' + e);
                    System.debug('CLM_ReviewerHandler error recordId' + rev.Id);
                }
            }
        }
    }
}