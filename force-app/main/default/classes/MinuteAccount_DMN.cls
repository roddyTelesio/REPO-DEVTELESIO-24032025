public with sharing class MinuteAccount_DMN {

    public static void reworkConcatFields(List<MinuteAccount__c> oldList){

        Set<ID> minutesToUpdate = new Set<Id>(); 
        Map<Id, Minute__c> mapMinsUpdate = new Map<Id, Minute__C>(); 


        // retrieve all minutes to update
        for(MinuteAccount__c iter : oldList){
            System.debug('reworkConcatFields etrieve all minutes to update ' + iter.Id);
            minutesToUpdate.add(iter.Minute__c); 
            mapMinsUpdate.put(iter.Minute__c, new Minute__c(Id = iter.Minute__c, ContactAccountParents__c= '', ConcatAccounts__c=''));
        }

        // retrieve all Minute Accounts 
        if(!minutesToUpdate.isEmpty()){
            for(MinuteAccount__c min: [SELECT Id, Company__c, Company__r.ParentId, Minute__c FROM MinuteAccount__c WHERE Minute__c IN :minutesToUpdate AND isDeleted = false]){
                if(mapMinsUpdate.containsKey(min.Minute__c)){
                    mapMinsUpdate.get(min.minute__c).ConcatAccounts__c = mapMinsUpdate.get(min.minute__c).ConcatAccounts__c + ',' + min.Company__c; 
                    mapMinsUpdate.get(min.minute__c).ContactAccountParents__c = mapMinsUpdate.get(min.minute__c).ContactAccountParents__c + ',' + min.Company__r.ParentId; 
                }else{
                    mapMinsUpdate.put(min.minute__c, new Minute__c(Id= min.Minute__c, ConcatAccounts__c = min.Company__c)); 
                    mapMinsUpdate.get(min.minute__c).ContactAccountParents__c = min.Company__r.ParentId; 
                }
            }
        }


        if(!mapMinsUpdate.isEmpty()){
            System.debug('reworkConcatFields: mapMinsUpdate mapNotEmpty, updating');
            update mapMinsUpdate.values(); 
        }
    }

    public static void deleteMinuteContacts(List<MinuteAccount__c> oldList){


        Set<ID> minutesToUpdate = new Set<Id>(); 
        Set<Id> contactIds = new Set<id>(); 
        Set<Id> accountIdsToDelete = new set<Id>(); 
        Map<Id, MinuteContacts__c> toDelete = new Map<Id, MinuteContacts__c>();


        Map<String, MinuteContacts__c> MinContactToUpdate = new Map<String, MinuteContacts__c>(); 
        Map<id, List<MinuteContacts__c>> minContactsPerMinute = new Map<id, List<MinuteContacts__c>>(); 

        Map<Id, List<MinuteAccount__c>> minAccsPerMinute = new Map<Id, List<MinuteAccount__c>>(); 

        List<MinuteContacts__c> contactMinuteList = new List<MinuteContacts__c>(); 

        Map<Id, Set<Id>> mapAcrs = new Map<Id, set<Id>>(); 


        // retrieve all minutes to update
        for(MinuteAccount__c iter : oldList){
            System.debug('deleteMinuteContacts:: retrieve all minutes to update ' + iter.Id);
            minutesToUpdate.add(iter.Minute__c);
            accountIdsToDelete.add(iter.Company__c); // user deleted this account
            

            if(minAccsPerMinute.containsKey(iter.Minute__C)){
                minAccsPerMinute.get(iter.Minute__C).add(iter);
            }else{
                minAccsPerMinute.put(iter.Minute__C, new List<MinuteAccount__C>{iter});
            }
        }

        System.debug('minAccsPerMinute :: ' + minAccsPerMinute);
        // get contact minutes : 
        for(MinuteContacts__c minContact : [
            SELECT ID, Minute__c, Contact__c, Contact__r.AccountId FROM MinuteContacts__c WHERE Minute__c IN :minutesToUpdate
        ]){
            System.debug('deleteMinuteContacts : minute Contacts to update : ' + minContact.Id);
            MinContactToUpdate.put(minContact.Contact__c , minContact);
            contactIds.add(minContact.Contact__c);

            // keep mapping of contact minutes for each minute
            if(minContactsPerMinute.containsKey(minContact.Minute__c)){
                minContactsPerMinute.get(minContact.Minute__c).add(minContact); 
            }else{
                minContactsPerMinute.put(minContact.Minute__c, new List<MinuteContacts__c>{minContact});
            }
        }

        System.debug('minContactsPerMinute :: ' + minContactsPerMinute);

        // retrieve  ACRS
        for(AccountContactRelation acr : [SELECT ID, AccountId, ContactId FROM AccountContactRelation WHERE AccountId IN :accountIdsToDelete]){
            if(mapAcrs.containsKey(acr.accountId)){
                mapAcrs.get(acr.accountId).add(acr.ContactId);
            }else{
                mapAcrs.put(acr.accountId, new Set<Id>{acr.ContactId});
            }
        }

        System.debug('mapAcrs built: ' + mapAcrs);
        

        for(Id minId : minAccsPerMinute.keySet()){

            for(MinuteAccount__c minAccCurrent : minAccsPerMinute.get(minId)){
                System.debug('iterating per minAccount + ' + minAccCurrent);
                // iterate all contact Minutes
                if(minContactsPerMinute.containsKey(minId)){
                    
                    List<MinuteContacts__c> mincontactsForMinute = minContactsPerMinute.get(minId);
                    for(MinuteContacts__c currentMinContact : mincontactsForMinute){
                        System.debug('verifying current contact: '+ currentMinContact);
                        System.debug('Verifying contact with account: ' + minAccCurrent);
                        // get Contacts for company in current minute: 
                        Set<Id> contactIdsForAccounts = mapAcrs.get(minAccCurrent.Company__c);

                        if(contactIdsForAccounts != null && contactIdsForAccounts.contains(currentMinContact.Contact__c)){
                            toDelete.put(currentMinContact.Id, currentMinContact);
                        }
                    }
                }
            }   
            
        }

        if(!toDelete.isEmpty()){
            System.debug('MinuteAccounts To delete: ' + toDelete);
            delete toDelete.values();
        }
    }
}