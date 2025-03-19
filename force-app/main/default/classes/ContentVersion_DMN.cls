public with sharing class ContentVersion_DMN {
    
    public static void notifyCRMUsers(List<ContentVersion> iter){
        System.debug('ContentVersion_DMN. notifyCRMUsers : Start ');


        List<ContentVersion> contentVersionsToNotify = new List<ContentVersion>(); 


        // retrieve content document details: 
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>([SELECT 
                                                        Id, ContentDocument.Title, ReasonForChange 

                                                        FROM ContentVersion 
                                                        WHERE Id IN :Iter]);
 


        if(!contentVersionMap.isEmpty()){

            // Loop through the map using keyset
            for (Id key : contentVersionMap.keySet()) {
                ContentVersion cv = contentVersionMap.get(key);
                // Perform operations with the ContentVersion record
                System.debug('cv.ContentDocument.Title : ' + cv.ContentDocument.Title);
                if(cv.ContentDocument.Title == ContentVersion_CST.secRatingListDocumentTitle){
                    System.debug('ContentVersion_DMN.Notifyusers add to send security list notifications'); 
                    contentVersionsToNotify.add(cv); 
                }
                // Add more operations as needed
            }
        }


        if(!contentVersionsToNotify.isEmpty()){
            System.debug('ContentVersion_DMN > contentVersionsToNotify > Notify through flow');
            for(ContentVersion cv: contentVersionsToNotify){

                // Define the parameters you want to pass to the subflow
                Map<String, Object> params = new Map<String, Object>();
                params.put('MessageBody', cv.ReasonForChange);

                // Launch the subflow
                if(!test.isRunningTest()) {Flow.Interview.CRM_NotifyClientsSecurityList subflow = new Flow.Interview.CRM_NotifyClientsSecurityList(params);subflow.start();}

                // Start the subflow
                
            }
        }

        System.debug('ContentVersion_DMN.notifyCRMUsers : End ');
    }
}