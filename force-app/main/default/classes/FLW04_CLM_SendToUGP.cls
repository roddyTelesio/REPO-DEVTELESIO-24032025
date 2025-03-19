public with sharing class FLW04_CLM_SendToUGP {
    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }
    }

    public class InputVariables{
        @InvocableVariable(required=false label='Id Agreements' )
        public String AgreementId;
    }

    @InvocableMethod(label='Send Email To UGP' description='Sends email to UGP from Agreement button')
    public static List<Result> processAndSendEmail(List<InputVariables> inputVars) {

        List<Result> lstResult = new List<Result>();
        List<String> AgreementIds = new List<String>();
        for(InputVariables inputVar: inputVars){
           AgreementIds.add(inputVar.AgreementId);
        }
        List<Apttus__APTS_Agreement__c> lstAgreements = new List<Apttus__APTS_Agreement__c>();

        Map<Id,Apttus__DocumentVersionDetail__c> mapAgreeDvd = new Map<Id,Apttus__DocumentVersionDetail__c>();

        List<Messaging.SingleEmailMessage> lstEmailsToSend = new List<Messaging.SingleEmailMessage>();
        List<String> recepients = System.label.CLM_SendToUGP_EmailAddresses.split(';');

        OrgWideEmailAddress owea = new OrgWideEmailAddress();
                owea = [SELECT Id, Address, DisplayName FROM 
                        OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];

        try {
            lstAgreements = [SELECT 
            Id,toLabel(Program__r.Macro_L_O_B__c),Program__r.PrincipalCedingCompany__r.Name, Program__r.Name,
            Name, Program__r.PrincipalCedingCompany__r.EmailPCLife__c, Owner.Name,Program__c,Program__r.PrincipalCedingCompany__c,OwnerId
            from Apttus__APTS_Agreement__c 
            where id IN :AgreementIds]; 

            
    
            for(Apttus__DocumentVersionDetail__c dvd :  [SELECT Id,Name,TECH_AgreementId__c,CreatedDate from Apttus__DocumentVersionDetail__c 
            WHERE TECH_AgreementId__c IN :AgreementIds ORDER BY CreatedDate ASC]){
                if(!mapAgreeDvd.containsKey(dvd.TECH_AgreementId__c) || dvd.CreatedDate > mapAgreeDvd.get(dvd.TECH_AgreementId__c).CreatedDate){
                    mapAgreeDvd.put(dvd.TECH_AgreementId__c, dvd); //store latest version
                }
            }
            
            String emailDeveloperName = 'CLM_AgreementSendToUGP';
            EmailTemplate emailTemplate = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName = :emailDeveloperName LIMIT 1];
            if(emailTemplate!=null){
                // String emailBody = emailTemplate.Body;
                
                // Loop through the queried fields and replace merge fields
                for (Apttus__APTS_Agreement__c agreement : lstAgreements) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, null);
                    if(String.isNotBlank(agreement.Program__r.PrincipalCedingCompany__r.EmailPCLife__c)){
                        List<String> lstStringCC = agreement.Program__r.PrincipalCedingCompany__r.EmailPCLife__c.split(';');
                        mail.setCcAddresses(lstStringCC);
                        if(lstStringCC.size()>1){
                            agreement.Program__r.PrincipalCedingCompany__r.EmailPCLife__c = String.join(lstStringCC,',');
                        }
                    }
                    buildFieldMap(agreement);
                    //FIELD PROCESSING - START
                    String processedEmailBody = replaceMergeFields(mail.htmlBody, null,null);
                    String processedSubject = replaceMergeFields(mail.getSubject(), null,null);

                    String url = pageUrl(agreement.Id);
                    //DVD Version:
                    processedEmailBody = replaceMergeFields(processedEmailBody,'versionNumber',mapAgreeDvd.containsKey(agreement.Id) ? mapAgreeDvd.get(agreement.Id)?.Name : '');
                    // url 
                    processedEmailBody = replaceMergeFields(processedEmailBody,'agreementLink',String.isNotBlank(url) ? url : ''); 
    
                    processedEmailBody = replaceEmptyFields(processedEmailBody);
                    processedSubject = replaceEmptyFields(processedSubject);
                    //FIELD PROCESSING - END
                    mail.setSaveAsActivity(false);
                    mail.setTemplateId(emailTemplate.Id);
                    // mail.setWhatId(agreement.Id);
                    mail.setToAddresses(recepients);
                    
                    mail.setSubject(processedSubject); 
                    mail.setHtmlBody(processedEmailBody); 
                    if ( owea != null) {
                        mail.setOrgWideEmailAddressId(owea.Id);
                    }
                    lstEmailsToSend.add(mail);
    
                    
                }
            }
    
            if(!lstEmailsToSend.isEmpty()){
                // Send the email
                Messaging.SendEmailResult[] mailRslt = Messaging.sendEmail(lstEmailsToSend);
                for(Messaging.SendEmailResult rslt  : mailRslt){
                    lstResult.add(new Result(rslt.IsSuccess(), !rslt.getErrors().isEmpty() ? rslt.getErrors()[0].getMessage() : 'Success'));
                }
             
            }
            
        } catch (Exception e) {
            for(InputVariables inputVar: inputVars){
                lstResult.add(new Result(false, e.getMessage()+' '+e.getStackTraceString()+' ')); //The number of results must match the number of interviews that were executed in a single bulk execution request.
            }
        }

        return lstResult;
     
    }


    public static Map<String, Object> allFields = new Map<String, Object>();


    public static void buildFieldMap(Apttus__APTS_Agreement__c agreement){
        for (String fieldName : agreement.getPopulatedFieldsAsMap().keySet()) {
            try {
                allFields.put(fieldName, agreement.get(fieldName));
            } catch (Exception e) {
                system.debug('Parent fields');
            }
        }
        
        // Add fields from the parent Program__r
        if (agreement.Program__c != null) {
            for (String fieldName : agreement.Program__r.getPopulatedFieldsAsMap().keySet()) {
                try {
                    allFields.put('Program__r.' + fieldName, agreement.Program__r.get(fieldName));
                }
                catch (Exception e) {
                    system.debug('Parent fields');
                }
            }
            
            // Add fields from the grandparent PrincipalCedingCompany__r
            if (agreement.Program__r.PrincipalCedingCompany__c != null) {
                for (String fieldName : agreement.Program__r.PrincipalCedingCompany__r.getPopulatedFieldsAsMap().keySet()) {
                    allFields.put('Program__r.PrincipalCedingCompany__r.' + fieldName, agreement.Program__r.PrincipalCedingCompany__r.get(fieldName));
                }
            }
        }
        
        // Add fields from the Owner
        if (agreement.OwnerId != null && !Test.isRunningTest()) {
            for (String fieldName : agreement.Owner.getPopulatedFieldsAsMap().keySet()) {
                allFields.put('Owner.' + fieldName, agreement.Owner.get(fieldName));
            }
        }
    }

    public static string pageUrl(Id recordId){
        // Get the base URL of the Salesforce organization
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();

            // Construct the full record page URL
            String recordPageUrl = baseUrl + '/' + recordId;
            return recordPageUrl;
    }
    
    public static String replaceMergeFields(String emailBody,String fieldName,Object fieldValue) {
        String mergeField;
        if(fieldName == null){
            // Loop through the fields and replace merge fields
            for (String recfieldName : allFields.keySet()) {
                mergeField = '{' + recfieldName + '}';
                system.debug('BBH mergefield : '+ mergeField);
                if (emailBody.containsIgnoreCase(mergeField)) {
                    Object recfieldValue = allFields.get(recfieldName);
                    emailBody = emailBody.replace(mergeField, recfieldValue != null ? String.valueOf(recfieldValue) : '');
                }
            }
        }
        else{
            mergeField = '{' + fieldName + '}';
            if (emailBody.contains(mergeField)) {
                emailBody = emailBody.replace(mergeField, fieldValue != null ? String.valueOf(fieldValue) : '');
            }
        }

        
        return emailBody;
    }

    public static String replaceEmptyFields(String body){
         // replace empty fields by blank 
         Pattern p = Pattern.compile('\\{.*?\\}');
         Matcher m = p.matcher(body);
         if(m.find()){
             body = m.replaceAll('');
         }

         return body;
    }

}