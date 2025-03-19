public with sharing class FLW05_PortalEmailVerificationReminder {

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
        @InvocableVariable(required=false label='Id user')
        public String userId;
    }

    static String emailDeveloperName = 'AGRe_Portal_Custom_Email_Verification';
    static EmailTemplate emailTemplate = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName = :emailDeveloperName LIMIT 1];

    @InvocableMethod(label='Send Email Reminder' description='Sends Verification Reminder')
    public static List<Result> sendEmailVerificationByFlow(List<InputVariables> inputVars) {
        List<Result> lstResult = new List<Result>();
        List<String> userIds = new List<String>();
        for(InputVariables inputVar: inputVars){
            userIds.add(inputVar.userId);
        }
        List<NetworkMember> networkMembers = new List<NetworkMember>();
        networkMembers = getNetworkMembers(userIds[0],null);
        if(networkMembers.isEmpty()){
            System.UserManagement.sendAsyncEmailConfirmation(
                userIds[0], // member ID
                null, // Email Template ID
                null, // Network ID
                null
            );
            lstResult.add(new Result(true,'Verification url sent to non portal user✅'));
            return lstResult;
        }
        return asyncMailConfirmation(new List<NetworkMember>{networkMembers[0]});
    }

    public static List<Result> asyncMailConfirmation(List<NetworkMember> networkMembers){
        List<String> sentEmails = new List<String>();
        List<Result> lstResult = new List<Result>();
        Boolean isSuccess;
        for (NetworkMember mem : networkMembers) {
            try {
                if(mem.NetworkId != null){
                    isSuccess = System.UserManagement.sendAsyncEmailConfirmation(
                        mem.MemberId, // member ID
                        emailTemplate.Id, // Email Template ID
                        mem.NetworkId, // Network ID
                        null
                    );
                   
                    // Boolean isSuccess = true;
                    lstResult.add(new Result(true,'Verification url sent to '+ mem.Member.Name + ' via email✅'));
                    sentEmails.add('Verification email sent to: ' + mem.Member.Username + ' (User ID: ' + mem.MemberId + ', Network ID: ' + mem.NetworkId + ')');
                }
            } catch (Exception e) {
                lstResult.add(new Result(false, e.getMessage()+' '+e.getStackTraceString()+' ')); //The number of results must match the number of interviews that were executed in a single bulk execution request.
                System.debug('Failed to send verification email to: ' + mem.Member.Username + ' - ' + e.getMessage());
            }
        }

        // // Generate the report content
        // String reportContent = 'Verification Emails Report\n\n';
        // for (String emailInfo : sentEmails) {
        //     reportContent += emailInfo + '\n';
        // }

        // // Send the email to the admin
        // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // String[] toAddresses = new String[] {'bhavesh.bhuckory@telesio.fr'}; // Replace with the admin's email address
        // OrgWideEmailAddress owea = new OrgWideEmailAddress();
        // owea = [SELECT Id, Address, DisplayName FROM 
        //         OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
        // mail.setToAddresses(toAddresses);
        // mail.setSubject('Verification Emails Report');
        // mail.setPlainTextBody(reportContent);
        // if ( owea != null) {
        //     mail.setOrgWideEmailAddressId(owea.Id);
        // }

        // try {
        //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        //     System.debug('Email sent to admin with the report.');
        // } catch (Exception e) {
        //     System.debug('Failed to send email to admin - ' + e.getMessage());
        // }

        return lstResult;

    }

    public static List<NetworkMember> getNetworkMembers(Id userId,String customCriteria){
        List<NetworkMember> netMembers = new List<NetworkMember>();
        String queryString='SELECT NetworkId, MemberId,member.Username,member.Name FROM NetworkMember WHERE Member.IsActive = true ';
        if(userId == null){
            queryString += 'AND (Member.Profile.Name = \'AGRE_Community Internal User\' OR Member.Profile.Name = \'AGRE_Community External User\') ';
        }
        else{
            queryString += 'AND MemberId = :userId ';
        }
        if(String.isNotBlank(customCriteria)){
            queryString+= customCriteria;
        }
        netMembers = Database.query(queryString);
        return netMembers;
    }



    // public static void verifyAllUsers(String customCriteria){
    //     // Execute Anonymous Block
    //     List<NetworkMember> networkMembers = getNetworkMembers(null,customCriteria);
    //     asyncMailConfirmation(networkMembers);
       
    // }
}