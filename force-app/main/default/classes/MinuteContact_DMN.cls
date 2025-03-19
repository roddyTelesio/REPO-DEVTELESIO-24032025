public with sharing class MinuteContact_DMN {
    

    public static void reworkConcatFields(List<MinuteContacts__c> oldList){
        System.debug('MinuteContact_DMN.reworkConcatFields : ');
        Set<ID> minutesToUpdate = new Set<Id>(); 
        Map<Id, Minute__c> mapMinsUpdate = new Map<Id, Minute__C>(); 


        // retrieve all minutes to update
        for(MinuteContacts__c iter : oldList){
            System.debug('MinuteContact_DMN.reworkConcatFields : iter' + + iter.Id);
            minutesToUpdate.add(iter.Minute__c); 
            mapMinsUpdate.put(iter.Minute__c, new Minute__c(Id = iter.Minute__c, ContactsConcat__c = ''));
        }

        // retrieve all Minute Accounts 
        if(!minutesToUpdate.isEmpty()){
            System.debug('MinuteContact_DMN.reworkConcatFields : executing logic');
            for(MinuteContacts__c min: [SELECT Id, Contact__c, Minute__c FROM MinuteContacts__c WHERE Minute__c IN :minutesToUpdate AND isDeleted = false]){
                System.debug('MinuteContact_DMN.reworkConcatFields processing: '+ min);
                if(mapMinsUpdate.containsKey(min.Minute__c)){mapMinsUpdate.get(min.minute__c).ContactsConcat__c = mapMinsUpdate.get(min.minute__c).ContactsConcat__c + ',' + min.Contact__c; }else{mapMinsUpdate.put(min.minute__c, new Minute__c(Id= min.Minute__c, ContactsConcat__c = min.Contact__c)); }
            }
        }


        if(!mapMinsUpdate.isEmpty()){
            System.debug('MinuteContact_DMN.reworkConcatFields: mapMinsUpdate mapNotEmpty, updating' + mapMinsUpdate);
            update mapMinsUpdate.values(); 
        }
    }

}