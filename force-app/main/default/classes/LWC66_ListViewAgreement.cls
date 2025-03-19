/*
  @description       :
  @author            : Telesio - RRA
  @group             :
  @last modified on  : 08-11-2024
  Ticket id          : W- 2171
  Ver   Date         Author                   Modification
  1.0   08-11-2024   RRA    Initial Version
*/

public with sharing class LWC66_ListViewAgreement {
   private final static Integer LIMIT_RESULTS = Integer.valueOf(System.label.maxResultLimitAgreement);

  /**
    * @description Method to get Program(s) from selected UW Year and Principal Ceding Company
    * @param String valueUWYear, String valuePrincipalCedComp
    * @return List<Program__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<Program__c> getPrograms(String valueUWYear, String valuePrincipalCedComp){
         return [SELECT Id, Name, UwYear__c, PrincipalCedingCompany__c FROM Program__c WHERE UwYear__c = :valueUWYear AND PrincipalCedingCompany__c = :valuePrincipalCedComp ORDER BY Name];

    }

    /**
    * @description Method to get UW Year of Agreements
    * @param 
    * @return List<String>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getUWYAgreements(){
       List<OptionWrapper> lstUWY = new List<OptionWrapper>();
        if(Apttus__APTS_Agreement__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Apttus__APTS_Agreement__c.fields.UnderwritingYear__c.isAccessible()){
             for(AggregateResult agreement : [SELECT  UnderwritingYear__c uwy FROM Apttus__APTS_Agreement__c WHERE UnderwritingYear__c != NULL GROUP BY UnderwritingYear__c ORDER BY UnderwritingYear__c]){
                    lstUWY.add(new OptionWrapper((String) agreement.get('uwy'), (String) agreement.get('uwy')));
                    System.debug('lstUWY == ' + lstUWY);
             }
         }
      return lstUWY;
    }

    /**
    * @description Method to get PCC of Agreements
    * @param 
    * @return List<String>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getPCCAgreements(){
        List<OptionWrapper> lstPCC = new List<OptionWrapper>();
         if(Apttus__APTS_Agreement__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Apttus__APTS_Agreement__c.fields.PrincipalCedingCompany__c.isAccessible()){
             for(AggregateResult agreement : [SELECT PrincipalCedingCompany__c IdPcc, PrincipalCedingCompany__r.Name namePcc FROM Apttus__APTS_Agreement__c GROUP BY PrincipalCedingCompany__c, PrincipalCedingCompany__r.Name ORDER BY PrincipalCedingCompany__r.Name]){ //RRA - ticket 2210 - 09/12/2024
                if(agreement.get('IdPcc') != null){
                    lstPCC.add(new OptionWrapper((String) agreement.get('IdPcc'), (String) agreement.get('namePcc')));
                }
             }
         }
        return lstPCC;
    }

    /**
    * @description Method to get Record Type Name of agreement
    * @param null
    * @return List<OptionWrapper>
    */
     @AuraEnabled(cacheable=true)
    public static List<OptionWrapper> getRecordTypeName(){
        List<OptionWrapper> lstRecType = new List<OptionWrapper>();
        if(RecordType.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.RecordType.fields.DeveloperName.isAccessible()){
           for(RecordType recType : [SELECT Id, DeveloperName FROM RecordType
                                     WHERE sObjectType = 'Apttus__APTS_Agreement__c'
                                     AND IsActive = true
                                     ORDER BY DeveloperName]){
            lstRecType.add(new OptionWrapper(recType.Id, recType.DeveloperName));
          }
        }
        return lstRecType;
    }

    /**
    * @description Method to get Signing Status Name agreement
    * @param null
    * @return List<OptionWrapper>
    */
     @AuraEnabled(cacheable=true)
     public static List<OptionWrapper> getSigningStatus(){
       List<OptionWrapper> lstSigningStatus = new List<OptionWrapper>();
      Map<String, String> mapValueLabelSigningStatus = new Map<String, String>
      {
          'To be signed' => 'To be signed',
          'In Progress' => 'In Progress',
          'Signed' => 'Signed',
          'Will not be signed' => 'Will not be signed'
     };
      for (String str : mapValueLabelSigningStatus.keySet()){
         lstSigningStatus.add(new OptionWrapper(str, mapValueLabelSigningStatus.get(str)));
      }
        return lstSigningStatus;
    }

     /**
    * @description Method to get Agreement(s) frpm  selected UWYear / Principal Ceding Company / Program / RecorType
    * @param FilterAgreementsWrapper class
    * @return List<Program__c>
    */
   @AuraEnabled(Cacheable = true)
    public static List<Apttus__APTS_Agreement__c> getAgreements(FilterAgreementsWrapper filterAgreement, Integer limitSize, Integer offset){
      System.debug('filterAgreement== ' + filterAgreement);
      System.debug('uwy== ' + filterAgreement.uwy);
      String query = null;
      List<Apttus__APTS_Agreement__c> lstAgreements = new  List<Apttus__APTS_Agreement__c>();
      Profile profileObj = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
      Map<String, Object> filterBinds = new Map<String, Object>
      {
          'uwyAgreement' => filterAgreement.uwy,
          'pccAgreement' => filterAgreement.pcc,
          'prgAgreement' => filterAgreement.prg,
          'rtAgreement' => filterAgreement.rt,
          'sigStatAgreement' => filterAgreement.sigstat,
          'offsets' => offset,
          'limitSizes' => limitSize
     };
        System.debug('filterBinds== ' + filterBinds);
          System.debug('LIMIT_RESULTS== ' + LIMIT_RESULTS);

        if (filterAgreement.uwy == '--All--' && filterAgreement.pcc == '--All--'){
          if(filterAgreement.rt == '--All--' && filterAgreement.sigstat == '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c != NULL '
            + ' AND PrincipalCedingCompany__c != NULL '
            + ' AND RecordTypeId != NULL '
            + ' AND Statut__c != NULL '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt != '--All--' && filterAgreement.sigstat == '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c != NULL '
            + ' AND PrincipalCedingCompany__c != NULL '
            + ' AND RecordTypeId =: rtAgreement '
            + ' AND Statut__c != NULL '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt == '--All--' && filterAgreement.sigstat != '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c != NULL '
            + ' AND PrincipalCedingCompany__c != NULL '
            + ' AND RecordTypeId != NULL '
            + ' AND Statut__c =: sigStatAgreement '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt != '--All--' && filterAgreement.sigstat != '--All--'){ //RRA - Ticket 2220 - 03032024
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c =: uwyAgreement '
            + ' AND PrincipalCedingCompany__c != NULL'
            + ' AND RecordTypeId =: rtAgreement '
            + ' AND Statut__c =: sigStatAgreement '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }
         }else if (filterAgreement.uwy == '--All--' && filterAgreement.pcc != '--All--'){
            if(filterAgreement.rt == '--All--' && filterAgreement.sigstat == '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c != NULL'
            + ' AND PrincipalCedingCompany__c = : pccAgreement'
            + ' AND RecordTypeId != NULL '
            + ' AND Statut__c != NULL '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt != '--All--' && filterAgreement.sigstat == '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c != NULL'
            + ' AND PrincipalCedingCompany__c = : pccAgreement'
            + ' AND RecordTypeId =: rtAgreement '
            + ' AND Statut__c != NULL '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt == '--All--' && filterAgreement.sigstat != '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c != NULL'
            + ' AND PrincipalCedingCompany__c = : pccAgreement'
            + ' AND RecordTypeId != NULL '
            + ' AND Statut__c =: sigStatAgreement '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt != '--All--' && filterAgreement.sigstat != '--All--'){ //RRA - Ticket 2220 - 03032024
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c =: uwyAgreement '
            + ' AND PrincipalCedingCompany__c != NULL'
            + ' AND RecordTypeId =: rtAgreement '
            + ' AND Statut__c =: sigStatAgreement '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }
        }else if (filterAgreement.uwy != '--All--' && filterAgreement.pcc == '--All--'){
          if(filterAgreement.rt == '--All--' && filterAgreement.sigstat == '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c =: uwyAgreement '
            + ' AND PrincipalCedingCompany__c != NULL'
            + ' AND RecordTypeId != NULL '
            + ' AND Statut__c != NULL '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt != '--All--' && filterAgreement.sigstat == '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c =: uwyAgreement '
            + ' AND PrincipalCedingCompany__c != NULL'
            + ' AND RecordTypeId =: rtAgreement '
            + ' AND Statut__c != NULL '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt == '--All--' && filterAgreement.sigstat != '--All--'){
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c =: uwyAgreement '
            + ' AND PrincipalCedingCompany__c != NULL'
            + ' AND RecordTypeId != NULL '
            + ' AND Statut__c =: sigStatAgreement '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }else if(filterAgreement.rt != '--All--' && filterAgreement.sigstat != '--All--'){ //RRA - Ticket 2220 - 03032024
            query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
            + ' WHERE UnderwritingYear__c =: uwyAgreement '
            + ' AND PrincipalCedingCompany__c != NULL'
            + ' AND RecordTypeId =: rtAgreement '
            + ' AND Statut__c =: sigStatAgreement '
            + ' ORDER BY UnderwritingYear__c, Name'
            + ' LIMIT: limitSizes '
            + ' OFFSET: offsets';
          }
        }else if (filterAgreement.uwy != '--All--' && filterAgreement.pcc != '--All--'){
           if (filterAgreement.rt == '--All--' && filterAgreement.prg == '--All--' && filterAgreement.sigstat == '--All--'){
              query =  (profileObj.Name != 'Salesforce Platform_read only') ? 
              'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
              + ' WHERE UnderwritingYear__c = : uwyAgreement'
              + ' AND PrincipalCedingCompany__c =: pccAgreement'
              + ' AND Program__c != NULL'
              + ' AND RecordTypeId != NULL '
              + ' AND Statut__c != NULL '
              + ' ORDER BY UnderwritingYear__c, Name'
              + ' LIMIT: limitSizes '
              + ' OFFSET: offsets'
              : 
              'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
              + ' WHERE UnderwritingYear__c = : uwyAgreement'
              + ' AND PrincipalCedingCompany__c =: pccAgreement'
              + ' AND RecordTypeId != NULL '
              + ' AND Statut__c != NULL '
              + ' ORDER BY UnderwritingYear__c, Name'
              + ' LIMIT: limitSizes '
              + ' OFFSET: offsets';
            }else if (filterAgreement.rt == '--All--' && filterAgreement.prg != '--All--' && filterAgreement.sigstat == '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
              'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
              + ' WHERE UnderwritingYear__c = : uwyAgreement'
              + ' AND PrincipalCedingCompany__c =: pccAgreement'
              + ' AND Program__c =: prgAgreement'
              + ' AND RecordTypeId != NULL '
              + ' AND Statut__c != NULL '
              + ' ORDER BY UnderwritingYear__c, Name'
              + ' LIMIT: limitSizes '
              + ' OFFSET: offsets'
              :
              'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
              + ' WHERE UnderwritingYear__c = : uwyAgreement'
              + ' AND PrincipalCedingCompany__c =: pccAgreement'
              + ' AND RecordTypeId != NULL '
              + ' AND Statut__c != NULL '
              + ' ORDER BY UnderwritingYear__c, Name'
              + ' LIMIT: limitSizes '
              + ' OFFSET: offsets';
            }else if (filterAgreement.rt == '--All--' && filterAgreement.prg == '--All--' && filterAgreement.sigstat != '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c = : uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND Program__c != NULL'
                + ' AND RecordTypeId != NULL '
                + ' AND Statut__c =: sigStatAgreement '
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets'
                :
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c = : uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND RecordTypeId != NULL '
                + ' AND Statut__c =: sigStatAgreement '
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets';
            }else if (filterAgreement.rt != '--All--' && filterAgreement.prg == '--All--' && filterAgreement.sigstat == '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c = : uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND Program__c != NULL'
                + ' AND RecordTypeId =: rtAgreement '
                + ' AND Statut__c != NULL '
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets'
                :
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c = : uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND RecordTypeId =: rtAgreement '
                + ' AND Statut__c != NULL '
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets';
            }else if(filterAgreement.rt != '--All--' && filterAgreement.prg != '--All--' && filterAgreement.sigstat != '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c=: uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND Program__c =: prgAgreement'
                + ' AND RecordTypeId =: rtAgreement'
                + ' AND Statut__c =: sigStatAgreement'
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets'
                :
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c=: uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND RecordTypeId =: rtAgreement'
                + ' AND Statut__c =: sigStatAgreement'
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets';
            }else if(filterAgreement.rt != '--All--' && filterAgreement.prg != '--All--' && filterAgreement.sigstat == '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c=: uwyAgreement'
                  + ' AND PrincipalCedingCompany__c =: pccAgreement'
                  + ' AND Program__c =: prgAgreement'
                  + ' AND RecordTypeId =: rtAgreement'
                  + ' AND Statut__c != NULL'
                  + ' ORDER BY UnderwritingYear__c, Name'
                  + ' LIMIT: limitSizes '
                  + ' OFFSET: offsets'
                :
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c=: uwyAgreement'
                  + ' AND PrincipalCedingCompany__c =: pccAgreement'
                  + ' AND RecordTypeId =: rtAgreement'
                  + ' AND Statut__c != NULL'
                  + ' ORDER BY UnderwritingYear__c, Name'
                  + ' LIMIT: limitSizes '
                  + ' OFFSET: offsets';
            }else if(filterAgreement.rt != '--All--' && filterAgreement.prg == '--All--' && filterAgreement.sigstat != '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c=: uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND Program__c != NULL'
                + ' AND RecordTypeId =: rtAgreement'
                + ' AND Statut__c =: sigStatAgreement'
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets'
                :
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                + ' WHERE UnderwritingYear__c=: uwyAgreement'
                + ' AND PrincipalCedingCompany__c =: pccAgreement'
                + ' AND RecordTypeId =: rtAgreement'
                + ' AND Statut__c =: sigStatAgreement'
                + ' ORDER BY UnderwritingYear__c, Name'
                + ' LIMIT: limitSizes '
                + ' OFFSET: offsets';
            }else if(filterAgreement.rt == '--All--' && filterAgreement.prg != '--All--' && filterAgreement.sigstat != '--All--'){
              query = (profileObj.Name != 'Salesforce Platform_read only') ? 
                'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, Program__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c=: uwyAgreement'
                  + ' AND PrincipalCedingCompany__c =: pccAgreement'
                  + ' AND Program__c =: prgAgreement'
                  + ' AND RecordTypeId != NULL '
                  + ' AND Statut__c =: sigStatAgreement'
                  + ' ORDER BY UnderwritingYear__c, Name'
                  + ' LIMIT: limitSizes '
                  + ' OFFSET: offsets'
                  :
                  'SELECT Id, Name, Statut__c, UnderwritingYear__c,PrincipalCedingCompany__c, RecordTypeId, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, Alerte__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c, OwnerId FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c=: uwyAgreement'
                  + ' AND PrincipalCedingCompany__c =: pccAgreement'
                  + ' AND RecordTypeId != NULL '
                  + ' AND Statut__c =: sigStatAgreement'
                  + ' ORDER BY UnderwritingYear__c, Name'
                  + ' LIMIT: limitSizes '
                  + ' OFFSET: offsets';
            }
     }
      System.debug('query== ' + query);
      if (!String.isBlank(query) && !String.isEmpty(query)){
          lstAgreements = Database.queryWithBinds(query, filterBinds, AccessLevel.USER_MODE);
      }
      System.debug('lstAgreements 22 == ' +lstAgreements);
      System.debug('lstAgreements size 22 == ' +lstAgreements.size());
      return lstAgreements;

  }

    /*@AuraEnabled
    public static String deleteAgreementsInMass(List<Id> lstIdAgreements) {
      List<Apttus__APTS_Agreement__c> lstAgreements = new List<Apttus__APTS_Agreement__c> ();
      String message;
      if(Apttus__APTS_Agreement__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Apttus__APTS_Agreement__c.fields.Id.isAccessible()){
          lstAgreements = [SELECT Id FROM Apttus__APTS_Agreement__c WHERE Id=:lstIdAgreements];
      }
      if (lstAgreements.size()>0){
          if(Apttus__APTS_Agreement__c.SObjectType.getDescribe().isDeletable()){
              delete lstAgreements;
              message = 'Agreement(s) deleted In Mass Successfully';
          }
      }
      return message;
  }*/

    @AuraEnabled
    public static String deleteAgreementsSelected(Id selectedAgreement) {
      String message;
      Apttus__APTS_Agreement__c agreement;
      if(Apttus__APTS_Agreement__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Apttus__APTS_Agreement__c.fields.Id.isAccessible()){
          agreement = [SELECT Id FROM Apttus__APTS_Agreement__c WHERE Id=:selectedAgreement];
      }

      if (agreement != null){
         if(Apttus__APTS_Agreement__c.SObjectType.getDescribe().isDeletable()){
            delete agreement;
         }
        message = 'Agreement deleted Successfully';
      }
      return message;
    }

    /*@AuraEnabled
    public static List<Id> fetchDataAgreements(String searchKey) {
       system.debug('## searchKey ' + searchKey);
      //String searchTerm = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
      String searchTerm = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
      String query;
      List<Id> lstIdResults = new List<Id> ();hjy
      //String regex = '[0-9]{0,2}/[0-9]{0,2}/[0-9]{4} [0-9]{0,2}:[0-9]{0,2}';
      //Matcher matcher=Pattern.compile(regex).matcher(searchTerm);

      //Boolean ckeckDateInEnterValue= matcher.find();
      //String strDate = matcher.group(0);
      //System.debug('strDate is = '+strDate);
       Map<String, Object> filterBind = new Map<String, Object>{'searchKeys' => searchTerm};
      if (String.isNotBlank(searchTerm) && String.isNotEmpty(searchTerm)){
       /* if (ckeckDateInEnterValue){
          query = 'SELECT Id, format(LastModifiedDate) FROM Apttus__APTS_Agreement__c WHERE LastModifiedDate LIKE :searchKey ' ;
        }else{*/
         /*System.debug('## searchTerm ' + searchTerm);
          query = 'SELECT Id FROM Apttus__APTS_Agreement__c '
                  + ' WHERE Name LIKE :searchKeys '
                  + ' OR Name LIKE :searchKeys '
                  + ' OR UnderwritingYear__c LIKE :searchKeys '
                  + ' OR Apttus__Agreement_Number__c LIKE :searchKeys '
                  + ' OR treaty_ref__c LIKE :searchKeys '
                  + ' OR TECH_AccountName__c LIKE :searchKeys '
                  + ' OR TECH_ProgramStage__c LIKE :searchKeys '
                  + ' OR TECH_OwnerLastName__c LIKE :searchKeys '
                  + ' OR Apttus__Status__c LIKE :searchKeys '
                  + ' OR Apttus__Status_Category__c LIKE :searchKeys ';
        //}
          System.debug('## query ' + query);
        List<Apttus__APTS_Agreement__c> lstAgreements = Database.queryWithBinds(query, filterBind, AccessLevel.USER_MODE);
        System.debug('## lstAgreements ' + lstAgreements);
        if(lstAgreements.size() > 0){
              for (Apttus__APTS_Agreement__c agr : lstAgreements){
                  lstIdResults.add(agr.Id);
              }
        }
          
      }else{
         query = 'SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 2000';
          List<Apttus__APTS_Agreement__c> lstAgreements = Database.query(query);
          if(lstAgreements.size() > 0){
              for (Apttus__APTS_Agreement__c agr : lstAgreements){
                  lstIdResults.add(agr.Id);
              }
        }
      }

      System.debug('## lstIdResults ' + lstIdResults);
      System.debug('## lstIdResults.size ' + lstIdResults.size());
      return lstIdResults;
    }*/

     @AuraEnabled
    public static List<Apttus__APTS_Agreement__c> fetchDataAgreements(String searchKey, String uwy, String pcc, Integer offsets) {
       system.debug('## searchKey ' + searchKey);
       system.debug('## offsets ' + offsets);
       system.debug('## uwy ' + uwy);
       system.debug('## pcc ' + pcc);
      //String searchTerm = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
      String searchTerm = '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
      String query = null;
      List<Apttus__APTS_Agreement__c> lstAgreements = new List<Apttus__APTS_Agreement__c>();
      if (String.isNotBlank(searchTerm) && String.isNotEmpty(searchTerm)){
         System.debug('## searchTerm ' + searchTerm);
         if (uwy != '--All--' && pcc == '--All--'){
          query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c, PrincipalCedingCompany__c, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c '
                  + ' FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c =:uwy '
                  + ' AND PrincipalCedingCompany__c != NULL '
                  + ' AND (Name LIKE :searchTerm '
                  + ' OR UnderwritingYear__c LIKE :searchTerm '
                  + ' OR Apttus__Agreement_Number__c LIKE :searchTerm '
                  + ' OR treaty_ref__c LIKE :searchTerm   '
                  + ' OR TECH_AccountName__c LIKE :searchTerm '
                  + ' OR TECH_ProgramStage__c LIKE :searchTerm '
                  + ' OR TECH_OwnerLastName__c LIKE :searchTerm '
                  + ' OR Apttus__Status__c LIKE :searchTerm '
                  + ' OR Apttus__Status_Category__c LIKE :searchTerm )';
         }else if (uwy == '--All--' && pcc == '--All--'){
          query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c, PrincipalCedingCompany__c, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c '
                  + ' FROM Apttus__APTS_Agreement__c '
                  + ' WHERE (Name LIKE :searchTerm '
                  + ' OR UnderwritingYear__c LIKE :searchTerm '
                  + ' OR Apttus__Agreement_Number__c LIKE :searchTerm '
                  + ' OR treaty_ref__c LIKE :searchTerm   '
                  + ' OR TECH_AccountName__c LIKE :searchTerm '
                  + ' OR TECH_ProgramStage__c LIKE :searchTerm '
                  + ' OR TECH_OwnerLastName__c LIKE :searchTerm '
                  + ' OR Apttus__Status__c LIKE :searchTerm '
                  + ' OR Apttus__Status_Category__c LIKE :searchTerm )'
                  + ' OFFSET: offsets';
         }else if (uwy == '--All--' && pcc != '--All--'){
          query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c, PrincipalCedingCompany__c, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c '
                  + ' FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c != NULL '
                  + ' AND PrincipalCedingCompany__c =: pcc'
                  + ' AND (Name LIKE :searchTerm '
                  + ' OR UnderwritingYear__c LIKE :searchTerm '
                  + ' OR Apttus__Agreement_Number__c LIKE :searchTerm '
                  + ' OR treaty_ref__c LIKE :searchTerm   '
                  + ' OR TECH_AccountName__c LIKE :searchTerm '
                  + ' OR TECH_ProgramStage__c LIKE :searchTerm '
                  + ' OR TECH_OwnerLastName__c LIKE :searchTerm '
                  + ' OR Apttus__Status__c LIKE :searchTerm '
                  + ' OR Apttus__Status_Category__c LIKE :searchTerm )';
         }else if (uwy != '--All--' && pcc != '--All--'){
          query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c, PrincipalCedingCompany__c, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c '
                  + ' FROM Apttus__APTS_Agreement__c '
                  + ' WHERE UnderwritingYear__c =: uwy '
                  + ' AND PrincipalCedingCompany__c =: pcc'
                  + ' AND (Name LIKE :searchTerm '
                  + ' OR UnderwritingYear__c LIKE :searchTerm '
                  + ' OR Apttus__Agreement_Number__c LIKE :searchTerm '
                  + ' OR treaty_ref__c LIKE :searchTerm   '
                  + ' OR TECH_AccountName__c LIKE :searchTerm '
                  + ' OR TECH_ProgramStage__c LIKE :searchTerm '
                  + ' OR TECH_OwnerLastName__c LIKE :searchTerm '
                  + ' OR Apttus__Status__c LIKE :searchTerm '
                  + ' OR Apttus__Status_Category__c LIKE :searchTerm )';
         }
          
          
      }else{
         query = 'SELECT Id, Name, Statut__c, UnderwritingYear__c, PrincipalCedingCompany__c, Apttus__Agreement_Number__c, treaty_ref__c, format(LastModifiedDate), TECH_AccountName__c, TECH_ProgramStage__c, TECH_OwnerLastName__c, Apttus__Account__c, Apttus__Status__c, Apttus__Status_Category__c '
         + ' FROM Apttus__APTS_Agreement__c '
         + ' WHERE UnderwritingYear__c != NULL '
         + ' AND PrincipalCedingCompany__c != NULL '
         + ' OFFSET: offsets';
      }
      System.debug('## query ' + query);
      if (String.isNotBlank(query) && String.isNotEmpty(query)){
         lstAgreements = Database.query(query);
      }
      

      System.debug('## lstAgreements ' + lstAgreements);
      System.debug('## lstAgreements.size ' + lstAgreements.size());
      return lstAgreements;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String value, String label) {
            this.value = value;
            this.label = label;
        }

        public Integer compareTo(Object compareTo)
        {
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label){
              return 0;
            }
            if (label > optWrapper.label) {
              return 1;
            }
            return -1;
        }
    }

    public class FilterAgreementsWrapper {
        @AuraEnabled
        public String uwy {get; set;}
        @AuraEnabled
        public String pcc {get; set;}
        @AuraEnabled
        public String prg {get; set;}
        @AuraEnabled
        public String rt {get; set;}
        @AuraEnabled
        public String sigstat {get; set;}
    }
}