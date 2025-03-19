public without sharing class reportExportSharingDetails {
    public reportExportSharingDetails() {
 
    }
    @AuraEnabled
    public static List<Id> getPrograms(){
        try {
            Map<Id,Program__c> mapProg = new Map<Id,Program__c>((List<Program__c>)Database.query(System.label.Report_CAT_Programs));
            return new List<Id>(mapProg.keySet());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
   @AuraEnabled
   public static boolean checkBtnVisibility(){
    try {
        Set<String> setStr = new Set<String>{'System Administrator','AGRE_System Admin'};
        if(!setStr.contains([SELECT Name FROM Profile WHERE Id=: UserInfo.getProfileId() LIMIT 1].Name)){
            return false;
        }else
            return true;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
   }
    @AuraEnabled(cacheable=true)
    public static List<SharingDetails> getContentDocLinkData(List<Id> lstProgIds){
       
        Map<Id,List<DocumentVisibility__c>> mapDocVis = new Map<Id,List<DocumentVisibility__c>>();
        List<SharingDetails> lstResults = new List<SharingDetails>();
       
        set<Id> sharedWithUserIds = new Set<Id>();
        Map<Id,Set<Contact>> mapAccContacts = new Map<Id,Set<Contact>>();

        Map<Id,User> mapConUser = new Map<Id,user>();

        // ALGO : 
        // FIND REQUEST SHARE 
        // USE REQUEST SHARE USER ID TO FIND CONTACT IDS 
        // FIND ACCOUNT IDS WHICH WORK WITH CONTACT IDS 
        // INTERSECT THIS ACCOUNT ID WITH DOCUMENT VISIBILITY ACCOUNT IDS


        //2. FIND WHICH CONTACTS HAVE ACCESS TO THIS PROGRAM'S REQUEST
        for (AggregateResult reqShare : [
            SELECT count(Id),UserOrGroupId from request__share 
            where Parent.Program__c IN :lstProgIds GROUP BY UserOrGroupId
        ]) {
            Id userId = (Id)reqShare.get('UserOrGroupId');
            sharedWithUserIds.add(userId); //collect shared user id
        }

        //3. WITH THE USER IDS, FIND CONTACT IDS RELATED TO THE USER
        if(!sharedWithUserIds.isEmpty()){
            for(User expUser : [
                SELECT Id, name, ContactId, IsActive,Email 
                FROM User 
                WHERE Id IN :sharedWithUserIds AND ContactId!=NULL]){
                mapConUser.put(expUser.ContactId,expUser); //STORE CONTACT IDS
            }
        }

        
        //4. USING THE CONTACT IDS
        for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, Account.RecordTypeId, Contact.Account.RecordTypeId, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c,Contact.Name  FROM AccountContactRelation
                                                            WHERE ContactId IN :mapConUser.keySet()
                                                            AND IsActive = TRUE
                                                            AND Contact.MacroLoB__c != null
                                                            AND Contact.Nature__c != null
                                                            AND Account.IsActive__c = TRUE
                                                            ]){
    
            if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                if(mapAccContacts.containsKey(accContactRelation.AccountId)){
                    mapAccContacts.get(accContactRelation.AccountId).add(new Contact(LastName=accContactRelation.Contact.Name,
                    Id=accContactRelation.ContactId));
                }
                else{
                    mapAccContacts.put(accContactRelation.AccountId,new Set<Contact>{new Contact(LastName=accContactRelation.Contact.Name,
                        Id=accContactRelation.ContactId)});
                }
            }
        }

        //1. FIND RECORDS OF DOCUMENT VISIBILITY TO KNOW WHICH CONTENT VERSION WAS SHARED WITH WITH BROKER/REINSURER
        for (DocumentVisibility__c docVis : [
        SELECT Id,Reinsurer__r.Name,ContentVersionId__c,Reinsurer__c,Broker__c,Broker__r.Name,Program__r.Name,Program__c,Program__r.PrincipalCedingCompany__r.name,toLabel(Program__r.Macro_L_O_B__c),CreatedBy.Name //ContentVersionId__c is a text field instead of lookup 😢
        FROM DocumentVisibility__c
        WHERE Program__c IN :lstProgIds //ON A PARTICULAR PROGRAM
        // AND ContentVersionId__c IN :lstConVersionId
        // AND Tech_ContentDocumentId__c IN :lstConDocIds
        ]){
            if(mapDocVis.containsKey(docVis.ContentVersionId__c)){
                mapDocVis.get(docVis.ContentVersionId__c).add(docVis);
            }
            else{
                mapDocVis.put(docVis.ContentVersionId__c,new List<DocumentVisibility__c>{docVis});
            }
        }
           
		List<Id> lstIds = new List<Id>(mapDocVis.keySet());
        //FETCH CONTENT DOCUMENT TITLES FROM CONTENT VERSION OBJECT
        String queryString = 'SELECT Id,ContentDocument.Title,ContentDocumentId FROM ContentVersion WHERE Id IN :lstIds ';
        if(!Test.isRunningTest()){
            queryString+=' and DocumentType__c =\'12\' ';
        }
        for(ContentVersion version : Database.query(queryString)){
            Set<String> contactsIncluded = new Set<String>();
            for (DocumentVisibility__c docVisibility :  mapDocVis.get(version.Id)) {
                if(mapAccContacts.containsKey(docVisibility.Reinsurer__c)){
                    
                    for (Contact reinsurer : mapAccContacts.get(docVisibility.Reinsurer__c)) {
                        if(!contactsIncluded.contains(reinsurer.Id+'-'+docVisibility.Reinsurer__c)){
                            SharingDetails s = new SharingDetails(
                                version.ContentDocument.Title,
                                docVisibility.Reinsurer__r.Name,
                                mapConUser.containsKey(reinsurer.Id) ? mapConUser.get(reinsurer.Id).Email : '',
                                'Reinsurer'
                                );
                            s.setProgDetails(docVisibility.Program__c,docVisibility.Program__r.Name,docVisibility.Program__r.PrincipalCedingCompany__r.name,docVisibility.Program__r.Macro_L_O_B__c,docVisibility.CreatedBy.Name);
                            s.setFileId(version.ContentDocumentId);
                            s.contactName = mapConUser.containsKey(reinsurer.Id) ? mapConUser.get(reinsurer.Id).Name : '';
                            lstResults.add(s); 
                            contactsIncluded.add(reinsurer.Id+'-'+docVisibility.Reinsurer__c);
                        }
                    }

                     
                }
                 //add broker contact (if any)
                if(docVisibility.Broker__c!=null && mapAccContacts.containsKey(docVisibility.Broker__c)){
                    for (Contact broker : mapAccContacts.get(docVisibility.Broker__c)) {
                        if(!contactsIncluded.contains(broker.Id+'-'+docVisibility.Broker__c)){
                            SharingDetails s = new SharingDetails(
                                version.ContentDocument.Title,
                                docVisibility.Broker__r.Name,
                                mapConUser.containsKey(broker.Id) ? mapConUser.get(broker.Id).Email : '',
                                'Broker'
                            );
                            s.setProgDetails(docVisibility.Program__c,docVisibility.Program__r.Name,docVisibility.Program__r.PrincipalCedingCompany__r.name,docVisibility.Program__r.Macro_L_O_B__c,docVisibility.CreatedBy.Name);
                            s.setFileId(version.ContentDocumentId);
                            s.contactName = mapConUser.containsKey(broker.Id) ? mapConUser.get(broker.Id).Name : '';
                            lstResults.add(s); 
                            contactsIncluded.add(broker.Id+'-'+docVisibility.Broker__c);
                        }
                    }
                  }
            }
            
        }

        //SALESFORCE USERS
        // for(ContentDocumentLink cnt : [
        //     SELECT Id,LinkedEntity.Profile.Name,ContentDocument.Title,LinkedEntity.Name,LinkedEntity.Email 
        //     FROM ContentDocumentLink 
        //     WHERE ContentDocumentId 
        //           IN :lstConDocIds ]){
            
        //     if(cnt.LinkedEntity.Profile.Name!=null){
        //         lstResults.add(new SharingDetails(
        //             cnt.ContentDocument.Title,
        //             cnt.LinkedEntity.Name,
        //             cnt.LinkedEntity.Email,
        //             cnt.LinkedEntity.Profile.Name
        //         ));
        //     }
        // }
        // for(ContentVersionHistory cv : [SELECT Id,CreatedBy.name,ContentVersion.Title from ContentVersionHistory where CreatedBy.name!='Bhavesh Bhuckory']){
        //     system.debug('cv - '+cv.ContentVersion.Title);
        // }
        return lstResults;
    }

    public class SharingDetails{
        @AuraEnabled 
        public String fileName;
        @AuraEnabled 
        public String fileId;
        @AuraEnabled 
        public String sharedWith;
        @AuraEnabled 
        public String emailAddress;
        @AuraEnabled 
        public String userType;
        @AuraEnabled 
        public String programId;
        @AuraEnabled 
        public String progName;
        @AuraEnabled 
        public String pcc;
        @AuraEnabled 
        public String macrolob;
        @AuraEnabled 
        public String sentby;
        @AuraEnabled 
        public String contactName;

        public SharingDetails(String fileName,String sharedWith, String emailAddress,String userType){
            this.fileName = fileName;
            this.sharedWith = sharedWith;
            this.emailAddress = emailAddress;
            this.userType= userType;
        }

        public void setProgDetails(String programId,String progName,String pcc,String macrolob,String sentby){
            this.programId = programId;
            this.progName = progName;
            this.pcc = pcc;
            this.macrolob = macrolob;
            this.sentby = sentby;
        }

        public void setFileId(String fileId){
            this.fileId = fileId;
        }
    }

}