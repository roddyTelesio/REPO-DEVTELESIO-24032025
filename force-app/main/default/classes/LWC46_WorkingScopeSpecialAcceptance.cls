public with sharing class LWC46_WorkingScopeSpecialAcceptance {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc46WorkingScopeSpecialAcceptance
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 09-OCT-2020  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

/**
    * @description Method to get Programs for the UW year and Principle Ceding Company 
    * @param String valueUWYear, String valuePrincipalCedComp
    * @return List<OptionWrapper>
    */
    @AuraEnabled
    public static List<OptionWrapper> getPrograms(String valUWYear, String valPrincipalCedComp, String valNature, Boolean isCE){
        Map<Id,OptionWrapper> mapPrograms = new  Map<Id,OptionWrapper>();  //HRA W-1839 - Visibility

        List<Id> lstProgramId = new List<Id>();
        Map<Id, Set<Id>> mapLstCovCedComByProgId = new Map<Id, Set<Id>>();
        Map<Id, String> mapProgramIdByProgId = new Map<Id, String>();

        for(Program__c program : [SELECT Id, Name, toLabel(Nature__c)
                            FROM Program__c
                            WHERE UwYear__c = :valUWYear AND PrincipalCedingCompany__c = :valPrincipalCedComp]){

            if((valNature != null && program.Nature__c == valNature) || valNature == null){
                lstProgramId.add(program.Id);
                mapProgramIdByProgId.put(program.Id, program.Name);

                if(isCE == true){
                    mapPrograms.put(program.Id,new OptionWrapper(program.Name, program.Id));  //HRA W-1839 - Visibility
                }
            }
        }

        if(isCE == false){
            //HRA W-1839 - Visibility
            Set<String> groupMembershipDevName = new Set<String> ();
            Map<Id,String> mapRefIdbyCedingAcc = new Map <Id,String>();

            for(CoveredCedingCompany__c covCedCom : [SELECT Id, Name, Account__c,Account__r.TECH_ReferentialId__c,Program__c FROM CoveredCedingCompany__c WHERE Program__c IN :lstProgramId]){
                Set<Id> lstCovCedCom = new Set<Id>();
                if(mapLstCovCedComByProgId.containsKey(covCedCom.Program__c)){
                    lstCovCedCom = mapLstCovCedComByProgId.get(covCedCom.Program__c);
                }
                lstCovCedCom.add(covCedCom.Account__c);
                mapLstCovCedComByProgId.put(covCedCom.Program__c, lstCovCedCom);
                mapRefIdbyCedingAcc.put(covCedCom.Account__c,covCedCom.Account__r.TECH_ReferentialId__c);
            }
    
            for(GroupMember groupMember : [SELECT Id, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName IN :mapRefIdbyCedingAcc.values() AND UserOrGroupId = :UserInfo.getUserId()]){
                groupMembershipDevName.add(groupMember.Group.DeveloperName);        
            }

            for(Id programId : mapLstCovCedComByProgId.keySet()){
                Set<Id> setCovCedComByProgId  = new Set<Id>(mapLstCovCedComByProgId.get(programId));
               for(Id cedingAcc : setCovCedComByProgId) {
                   if( mapRefIdbyCedingAcc.containsKey(cedingAcc) 
                       && groupMembershipDevName.contains(mapRefIdbyCedingAcc.get(cedingAcc))){
                       mapPrograms.put(programId,new OptionWrapper(mapProgramIdByProgId.get(programId), programId));
                   }
               }
            }
        }
        List <OptionWrapper> lstPrograms = mapPrograms.values();
        //HRA W-1839 - Visibility - END
        lstPrograms.sort();
        return lstPrograms;
    }

    /**
    * @description Method to get Nature of Program
    * @param String programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getProgramNature(String programId){
        Map<String, Object> mapResults = new Map<String, Object>();
        String natureProgram;
        String nameProgram;

        List<Program__c> lstProgram =  [SELECT Id, Name, toLabel(Nature__c), PrincipalCedingCompany__r.Name, toLabel(Macro_L_O_B__c), UwYear__c, PrincipalCedingCompany__c
                                        FROM Program__c
                                        WHERE Id = :programId];

        if(lstProgram.size() > 0){
            natureProgram = lstProgram[0].Nature__c;
            nameProgram = lstProgram[0].Name;
        }

        mapResults.put('natureProgram', natureProgram);
        mapResults.put('nameProgram', nameProgram);
        return mapResults;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo){
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }
}