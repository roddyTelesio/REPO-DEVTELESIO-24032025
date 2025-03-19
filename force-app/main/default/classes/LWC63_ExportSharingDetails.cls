public with sharing class LWC63_ExportSharingDetails {
    @AuraEnabled(cacheable=true)
    public static List<SharingDetails> getContentDocLinkData(List<String> lstConVersionId,String programId){
       
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
        for (Request__Share reqShare : [
            SELECT Id,Parent.name,UserOrGroup.name,UserOrGroupId,parent.Program__c from request__share 
            where Parent.Program__c = :programId
        ]) {
            sharedWithUserIds.add(reqShare.UserOrGroupId); //collect shared user id
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
        SELECT Id,Reinsurer__r.Name,ContentVersionId__c,Reinsurer__c,Broker__c,Broker__r.Name //ContentVersionId__c is a text field instead of lookup 😢
        FROM DocumentVisibility__c
        WHERE Program__c = :programId //ON A PARTICULAR PROGRAM
        AND ContentVersionId__c IN :lstConVersionId
        // AND Tech_ContentDocumentId__c IN :lstConDocIds
        ]){
            if(mapDocVis.containsKey(docVis.ContentVersionId__c)){
                mapDocVis.get(docVis.ContentVersionId__c).add(docVis);
            }
            else{
                mapDocVis.put(docVis.ContentVersionId__c,new List<DocumentVisibility__c>{docVis});
            }
        }
           

        //FETCH CONTENT DOCUMENT TITLES FROM CONTENT VERSION OBJECT
        for(ContentVersion version : [
            SELECT Id,ContentDocument.Title,ContentDocumentId 
            FROM ContentVersion
            WHERE Id IN :mapDocVis.keySet()
            ]){
            Set<String> contactsIncluded = new Set<String>();
            for (DocumentVisibility__c docVisibility :  mapDocVis.get(version.Id)) {
                if(mapAccContacts.containsKey(docVisibility.Reinsurer__c)){
                    
                    for (Contact reinsurer : mapAccContacts.get(docVisibility.Reinsurer__c)) {
                        if(!contactsIncluded.contains(reinsurer.Id+'-'+docVisibility.Reinsurer__c)){
                            lstResults.add(new SharingDetails(
                            version.ContentDocument.Title,
                            reinsurer.LastName+'('+docVisibility.Reinsurer__r.Name+')',
                            mapConUser.containsKey(reinsurer.Id) ? mapConUser.get(reinsurer.Id).Email : '',
                            'Contact'
                            )); 
                            contactsIncluded.add(reinsurer.Id+'-'+docVisibility.Reinsurer__c);
                        }
                    }

                     
                }
                 //add broker contact (if any)
                if(docVisibility.Broker__c!=null && mapAccContacts.containsKey(docVisibility.Broker__c)){
                    for (Contact broker : mapAccContacts.get(docVisibility.Broker__c)) {
                        if(!contactsIncluded.contains(broker.Id+'-'+docVisibility.Broker__c)){
                            lstResults.add(new SharingDetails(
                            version.ContentDocument.Title,
                            broker.LastName+'('+docVisibility.Broker__r.Name+')',
                            mapConUser.containsKey(broker.Id) ? mapConUser.get(broker.Id).Email : '',
                            'Contact'
                            )); 
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
        return lstResults;
    }

    public class SharingDetails{
        @AuraEnabled 
        public String fileName;
        @AuraEnabled 
        public String sharedWith;
        @AuraEnabled 
        public String emailAddress;
        @AuraEnabled 
        public String userType;

        public SharingDetails(String fileName,String sharedWith, String emailAddress,String userType){
            this.fileName = fileName;
            this.sharedWith = sharedWith;
            this.emailAddress = emailAddress;
            this.userType= userType;
        }
    }

}