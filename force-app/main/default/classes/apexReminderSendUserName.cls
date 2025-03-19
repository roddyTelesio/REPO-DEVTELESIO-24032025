public with sharing class apexReminderSendUserName {
    public static void sendMailMethod(List<String> lstRecipients) {
        System.debug('lstRecipients == ' + lstRecipients);
    
        Messaging.SingleEmailMessage mReqRemindSAVal = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
        Id emailTempReminderSAId;
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
        Id userId = UserInfo.getUserId();
        List<EmailTemplate> lstEmailTempReminderUserName= [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Template Reminder Portal reinBroker from List User Id'];
        if (lstEmailTempReminderUserName.size()>0){
            emailTempReminderSAId = lstEmailTempReminderUserName[0].Id;
        }
        if (emailTempReminderSAId != null){
            mReqRemindSAVal = Messaging.renderStoredEmailTemplate(emailTempReminderSAId, userId, null);
        }
        List<User> lstUser = [SELECT Id, UserName, Email, Profile.Name, isActive FROM User WHERE Id IN:lstRecipients AND (Profile.Name = 'AGRE_Community Internal User' OR Profile.Name = 'AGRE_Community External User') AND isActive = true];
        System.debug('lstUser == ' + lstUser);
        
        // Step 1: Create a new Email
        
        
        for (User usr : lstUser){           
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> lstEmailUser = new List<String>();
            mail.setSubject('ACTOR NEW GEN - Reminder about your Username');
            mail.setTemplateId(emailTempReminderSAId);
            mail.setSaveAsActivity(false);
            if (owea.size()>0) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            String htmlBody = mReqRemindSAVal.htmlBody;
            lstEmailUser.add(usr.Email);
            mail.setToAddresses(lstEmailUser);
            System.debug('UserName == ' + usr.UserName);
            if (!Test.isRunningTest()){
                htmlBody = htmlBody.replace('{nameUser}', usr.UserName);
            }
            mail.setHtmlBody(htmlBody);
            lstMailsToSend.add(mail);
            System.debug('lstMailsToSend == ' + lstMailsToSend);
        }
        
        Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
    }
}