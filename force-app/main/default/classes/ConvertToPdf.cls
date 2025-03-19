/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 10-04-2024
 * @last modified by  : Bhavesh Bhuckory
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   13-09-2023   Patrick Randrianarisoa   Initial Version
**/
public without sharing class ConvertToPdf {

    @future(callout=true)
    public static void ConvertToPdf(String contentId, String title, String dvdId) {
            Id docId = contentId;
            String filename = title;
            Boolean addWatermark = false;
            Boolean removeWatermark = true;
            String headerText ;
            String footerText ;
            String apiServerURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
            String apiSessionId = UserInfo.getSessionId();
            Id convertedDocId;
            if(!Test.isRunningTest()){
                convertedDocId = Apttus.MergeWebService.convertWordDocToPDF(docId, fileName,
                addWatermark, removeWatermark, headerText, footerText, apiSessionId, apiServerURL);

                // convertedDocId = Apttus.MergeWebService.convertWordDocToPDF2(docId,fileName,dvdId,'Full Access',addWatermark,removeWatermark,headerText,footerText,apiSessionId,apiServerURL);

                System.debug('convertedDocId : ' + convertedDocId);
                //BBU W-2137: When we try to download a pdf version inside an agreement, the document which is downloaded is the Word version and not the PDF -START
                ContentVersion documentVersion = [SELECT Id  FROM ContentVersion WHERE ContentDocumentId= :convertedDocId];
                update new Apttus__DocumentVersionDetail__c(Id = dvdId,Apttus__ContentVersionId__c = documentVersion.Id);
               
                
            }else{
                convertedDocId = '0015E000037awhLQAQ';
            }
    }
   
}