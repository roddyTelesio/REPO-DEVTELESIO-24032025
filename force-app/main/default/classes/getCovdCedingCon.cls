public with sharing class getCovdCedingCon {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Record Id SA' )
        public Id recordId;
    }
    
    public class Result{
        @InvocableVariable(required=true label='message')
        public String message;    
        
        public Result(){
        }
        
        public Result(String message){
            this.message = message;
        }
    }
    
    /***
    * @description	// 
    * @param	    NONE
    * @return		//
    * @exception   	None
    ***/   
    @InvocableMethod(label='Get AccountContactRelation From current SA' description='' callout=false)
    public static List<Result> getCoveredCedingContact(List<ObjectContext> objs){
        Map<String, Object> mapResults = new Map<String, Object>();
            List<Account> lstAccount = new List<Account>();
            List<Result> listResults = new List<Result>();
            Result results = new Result();
            List<Group> lstGroup = new List<Group>();
            List<String> lstEmailContactOnCeding = new List<String>();
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            //Set<Id> setUserOrGroupId = new Set<Id>();
            Set<String> setContactEmail = new Set<String>();
            List<String> lstReferentialId = new List<String>();
            List<String> lstGroupId = new List<String>();
            //RRA - ticket 1839 - 12062024
            Map<Id, List<Id>> mapIdUserIdGroup = new Map<Id, List<Id>>();
            List<Id> lstIdObj = new List<Id>();
            map<Id, List<String>> mapIdParentListConEmail = new map<Id, List<String>>();
            List<String> lstAddressEmailCon = new List<String>();
            Id emailTempReminderSAId;
            Id userId = UserInfo.getUserId();
            String message;
            
            //Sending Email
            Network networkCedingPortalObj = [SELECT Id FROM Network WHERE Name = :System.Label.Actor_ceding_portal_name];
            String urlCedingPortal = Network.getLoginUrl(networkCedingPortalObj.Id);
            List <String> urlArrCedingPortal = urlCedingPortal.split('login');
            String htmlInternetLink;
            List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mReqRemindSAVal = new Messaging.SingleEmailMessage();
            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            Id requestId;
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
            List<EmailTemplate> lstEmailTempReminderSA= [SELECT Id, Name FROM EmailTemplate WHERE Name = 'ANG - SA Reminder 30 Days Before SPA expiry Date'];
            if (lstEmailTempReminderSA.size()>0){
                emailTempReminderSAId = lstEmailTempReminderSA[0].Id;
            }
            System.debug(LoggingLevel.DEBUG, 'emailTempReminderSAId: ' + emailTempReminderSAId);
            System.debug('objsSize==' + objs.size());
            System.debug('objs==' + objs);
            
            //System.debug('listResults.SIZE: ' + listResults.size());  
            
            for(ObjectContext eachObj : objs){
                lstIdObj.add(eachObj.recordId);
            }
            System.debug('lstIdObj==' + lstIdObj);
            List<SpecialAcceptance__c> lstSA = [SELECT Id, CoveredCedingCompany__c, SpecialAcceptanceName__c, Program__r.PrincipalCedingCompany__c, PrincipalCedingCompany__r.EmailSA__c, Program__r.UwYear__c, Program__r.name, PrincipalCedingCompany__c, Program__c FROM SpecialAcceptance__c WHERE Id IN:lstIdObj];    
            
            List<SpecialAcceptance__Share> lstSAShare = [SELECT Id, ParentId, Parent.SpecialAcceptanceName__c, Parent.Program__c, Parent.Program__r.name, Parent.Program__r.UwYear__c, Parent.PrincipalCedingCompany__r.EmailSA__c, Parent.Program__r.PrincipalCedingCompany__c, Parent.CoveredCedingCompany__c, Parent.CoveredCedingCompany__r.Name, Parent.PrincipalCedingCompany__c, Parent.PrincipalCedingCompany__r.Name, UserOrGroupId FROM SpecialAcceptance__Share WHERE ParentId IN:lstIdObj];  
            
            System.debug('lstSAShare ==' + lstSAShare);
            
            if(lstSAShare.size()>0){
                for (SpecialAcceptance__Share saShare : lstSAShare){
                    
                    if (mapIdParentListConEmail.containsKey(saShare.ParentId)){
                        mapIdParentListConEmail.get(saShare.ParentId).add(saShare.UserOrGroupId);
                    }else{
                        mapIdParentListConEmail.put(saShare.ParentId, new List<Id>{saShare.UserOrGroupId});
                    }
            }
            
            System.debug('mapIdParentListConEmail ==' + mapIdParentListConEmail);

            if (emailTempReminderSAId != null){
                mReqRemindSAVal = Messaging.renderStoredEmailTemplate(emailTempReminderSAId, userId, null);
            }
            
            for (SpecialAcceptance__c sa : lstSA){
                    System.debug('lstEmail ==' + lstEmailCedingContact(mapIdParentListConEmail.get(sa.Id)));
                    if (!Test.isRunningTest()){
                        lstAddressEmailCon.addAll(lstEmailCedingContact(mapIdParentListConEmail.get(sa.Id)));
                    }else{
                        lstAddressEmailCon.add('test@unknown.com');
                    }
                    System.debug(LoggingLevel.DEBUG, 'lstAddressEmailCon 11: ' + lstAddressEmailCon);
                    m.setSaveAsActivity(false);
                    m.setTemplateId(emailTempReminderSAId);
                    m.setWhatId(requestId);
                    m.setTargetObjectId(userId);
                    
                    String htmlBody = mReqRemindSAVal.htmlBody;
                    mail.setToAddresses(lstAddressEmailCon);
                    mail.setSubject(mReqRemindSAVal.getSubject());
                    if (owea.size()>0) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mail.emailPriority = 'Highest';
                    htmlBody = htmlBody.replace('{NameSA}', sa.SpecialAcceptanceName__c);
                    htmlBody = htmlBody.replace('{underWrittenYearOnProgram}', sa.Program__r.UwYear__c);
                    htmlBody = htmlBody.replace('{NameProgram}', sa.Program__r.name);
                    htmlBody = htmlBody.replace('{EmailSAOnPCC}', sa.PrincipalCedingCompany__r.EmailSA__c);
                    htmlInternetLink = ' <a href="' + urlArrCedingPortal[0] +'">ACTOR Page</a>';
                    htmlBody = htmlBody.replace('{HomePageLink}', htmlInternetLink); 
                    String saUrlportal = urlArrCedingPortal[0] + 'SADetail?s__id=' + sa.Id + '-' + sa.Program__r.UwYear__c + '-' + sa.Program__r.PrincipalCedingCompany__c + '-' + sa.Program__c;
                    String saLinkPortal = ' <a href="' + saUrlportal +'">Link of Special Acceptance</a>';
                    htmlBody = htmlBody.replace('{LinkPortalSA}', saLinkPortal);
                    mail.setHtmlBody(htmlBody); 
                    lstMailsToSend.add(mail);
                    System.debug(LoggingLevel.DEBUG, 'lstMailsToSend: ' + lstMailsToSend);
                    Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                    lstAddressEmailCon = new List<String>();
                    lstMailsToSend = new List<Messaging.SingleEmailMessage>();
            }
            results = new Result(message);
            System.debug('results = ' + results);
            //The number of results does not match the number of interviews that were executed in a single bulk execution request. (RRA - return one result for each result)
            for(ObjectContext objCtxt : objs){ // This will not throw the error
                listResults.add(results);
            }
            
            System.debug(LoggingLevel.DEBUG, 'lstAddressEmailCon 22: ' + lstAddressEmailCon);
            System.debug(LoggingLevel.DEBUG, 'lstMailsToSend.size: ' + lstMailsToSend.size());
            System.debug(LoggingLevel.DEBUG, 'message: ' + message);            
    }
    return  listResults;
  }
            
    public static List<String> lstEmailCedingContact (List<Id> lstIdUser){
        List<String> lstEmailCon = new List<String>();
        for ( User usr : [SELECT Id, ContactId, AccountId, Contact.RecordType.Name, Contact.Email, IsActive, Account.IsActive__c
                         FROM User 
                         WHERE Id 
                         IN : lstIdUser
                         AND IsActive = true 
                         AND Account.IsActive__c = true
                         AND Contact.RecordType.Name = 'Ceding Contact' 
                         AND Contact.Email != NULL]){
                lstEmailCon.add(usr.Contact.Email);
            }
            return lstEmailCon;
        }
                
}