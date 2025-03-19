/*
  @description       : 
  @author            : Telesio - RRA
  @group             : 
  @last modified on  : 08-11-2024
  Ticket id          : W- 2171
  Ver   Date         Author                   Modification
  1.0   08-11-2024   RRA    Initial Version
*/
import {LightningElement, wire, api} from 'lwc';
import PROGRAM_OBJECT from '@salesforce/schema/Program__c';
//import UWYEAR_FIELD from '@salesforce/schema/Program__c.UwYear__c';
//import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

//import Apex
//import getAcc from '@salesforce/apex/LWC01_WorkingScope.getPrincipalCedingAcc';
import getProfiles from '@salesforce/apex/LWC14_Documents.getProfiles';
import getUWYAgreements from '@salesforce/apex/LWC66_ListViewAgreement.getUWYAgreements';
import getPCCAgreements from '@salesforce/apex/LWC66_ListViewAgreement.getPCCAgreements';
import isProfileAdmin from '@salesforce/apex/LWC30_SigningRequests.getDeleteButtonVisibility'; 
import getPrograms from '@salesforce/apex/LWC66_ListViewAgreement.getPrograms';
import deleteAgreementsSelected from '@salesforce/apex/LWC66_ListViewAgreement.deleteAgreementsSelected';  
import getRecordTypeName from '@salesforce/apex/LWC66_ListViewAgreement.getRecordTypeName';
import getAgreements from '@salesforce/apex/LWC66_ListViewAgreement.getAgreements'; 
import fetchDataAgreements from '@salesforce/apex/LWC66_ListViewAgreement.fetchDataAgreements';
import getSigningStatus from '@salesforce/apex/LWC66_ListViewAgreement.getSigningStatus';


//import custom labels
import Actions from '@salesforce/label/c.Actions';
import WorkingScope from '@salesforce/label/c.WorkingScope';
import UWYear from '@salesforce/label/c.UWYear';
import PrincipalCedingCompany from '@salesforce/label/c.PrincipalCedingCompany';
import errorMsg from '@salesforce/label/c.errorMsg';
import Edit from '@salesforce/label/c.Edit';
import New from '@salesforce/label/c.New';
import Delete from '@salesforce/label/c.Delete';
import deleteOneChoiceAgreement from '@salesforce/label/c.deleteOneChoiceAgreement';
import deleteMultipleChoiceAgreementPartI from '@salesforce/label/c.deleteMultipleChoiceAgreementPartI';
import deleteMultipleChoiceAgreementPartII from '@salesforce/label/c.deleteMultipleChoiceAgreementPartII';
import DeleteAgreementNotPermit from '@salesforce/label/c.DeleteAgreementNotPermit';
import maxResultLimitAgreement from '@salesforce/label/c.maxResultLimitAgreement';

//import function
import {sortObjectsByFields} from 'c/lwcUtilityCmp'

const actions = [
   // { label: Edit, name: 'edit'},
    { label: Delete, name: 'delete'}
];

const columnsAgreement = [
    { label: 'Underwriting Year', fieldName: 'UnderwritingYear__c' },
    { label: 'Agreement Name', fieldName: 'nameUrlAgreement', type: 'url', typeAttributes: {label: {fieldName: 'Name'}, target: '_blank'} },
    { label: 'Agreement Number', fieldName: 'Apttus__Agreement_Number__c' },
    { label: 'treaty Ref', fieldName: 'treaty_ref__c' },
    { label: 'Last Modified Date', fieldName: 'LastModifiedDate' },
    { label: 'Account Name', fieldName: 'nameUrlAccount', type: 'url', typeAttributes: {label: {fieldName: 'TECH_AccountName__c'}, target: '_blank'} },
    {fieldName: 'statusSigning', type: 'image', typeAttributes: { height: 20, width: 40, alt: 'Alerte Image'}, initialWidth: 50},  
    { label: 'Signing Status', fieldName: 'nameStatusSigning'},                        
    { label: 'Program Phase', fieldName: 'TECH_ProgramStage__c'},
    { label: 'Owner Last Name', fieldName: 'nameUrlOwnerLastName', type: 'url', typeAttributes: {label: {fieldName: 'TECH_OwnerLastName__c'}, target: '_blank'} },
    { label: 'Status', fieldName: 'Apttus__Status__c'},
    { label: 'Status Category', fieldName: 'Apttus__Status_Category__c'},
    { label: Actions, type: 'action', fixedWidth: 70, typeAttributes: {rowActions: actions, menuAlignment:'auto'}}
];

export default class Lwc66ListViewPageAgreements extends NavigationMixin(LightningElement) {
   label = {
        WorkingScope,
        UWYear,
        PrincipalCedingCompany,
        errorMsg,
        Edit,
        Delete,
        New,
        deleteOneChoiceAgreement ,
        deleteMultipleChoiceAgreementPartI,
        deleteMultipleChoiceAgreementPartII,
        DeleteAgreementNotPermit,
        maxResultLimitAgreement
    };
  
   @api selectedYear;
   @api selectedComp;
   @api valueProgram;
   @api valueRecordType;
   @api valueSigningStatus;
   @api programOptions = [];
   @api searchString = '';
   currSelect_valueUWY;
   currSelect_valuePCC;
   currSelect_valuePrg;
   currSelect_valueRT;
   currSelect_valueSigningStatus;
   uwYearOpt;
   cedingAccOpt;
   recordTypeOptions;
   signingStatusOptions;
   spinner = false;
   wiredprograms;
   dataAgreement;
   data = [];
   columnsAgreement = columnsAgreement;
   delMsgTitle;
   selectedAgreement
   delMessage;
   error;
   isDataExists = false;
   titleAgreement = 'Agreements (0)';
   pageSizeOptions = [2000, 4000, 6000]; //Page size options
   totalRecords = 0; //Total no.of records
   pageSize; //No.of records to be displayed per page
   totalPages; //Total no.of pages
   pageNumber = 1; //Page number    
   recordsToDisplay = []; //Records to be displayed on the page
   disableProgram = false;
   initialRecords;
   msgNoRecords;
   test=0;
   offsetRow = 0;
   rowLimit = 50;
   enableInfiniteLoading = false;
   sumDataAgreements=0;
   filterAgreements;
   isLoadMoreData = false;
   isChangedUWY = false;
   isChangedPCC = false;
   isChangedPrg = false;
   isChangedRT = false;
   isChangedSigningStatus = false;   
   recordData = [];
  

   @wire(CurrentPageReference) pageRef;
   
   connectedCallback(){
      registerListener('yearOnAgreement', this.getChangeUWYVal, this);
      registerListener('offset', this.getOffSet, this);
      registerListener('IsChangedUWY', this.getIsChangedUWY, this);
      registerListener('IsChangedPCC', this.getIsChangedPCC, this);
      registerListener('IsChangedPrg', this.getIsChangedPrg, this);
      registerListener('IsChangedRT', this.getIsChangedRT, this); 
      registerListener('isChangedSigningStatus', this.getIsChangedSigningStatus, this); 
      registerListener('pccOnAgreement', this.getChangePCC, this);
      registerListener('valuePrograms', this.getChangePrograms, this);
      registerListener('valueInitPrograms', this.getInitPrograms, this);
      registerListener('valueRecordTypes', this.getChangeRecordType, this);
      registerListener('valueSigningStatuss', this.getChangeSigningStatus, this);
      this.getAgreements();
      //this.loadGetAgreements();
    
    }
   
  @wire(getUWYAgreements)
    setUWYPicklistOptions({error, data}) {
        if(data != undefined){
          let allUWYPicklist = [];
          let allUWY = [];
          let addAllValue = [{label:'--All--', value:'--All--'}];
          data.forEach(key => {
                allUWYPicklist.push({
                label : key.label,
                value:  key.value
            })
          });
          allUWY = allUWYPicklist.concat(addAllValue);
          this.uwYearOpt = allUWY;
          if(this.selectedYear == null){
                this.selectedYear = data[data.length - 1].value;
                fireEvent(this.pageRef, 'yearOnAgreement', this.selectedYear);  
                fireEvent(this.pageRef, 'offSet', 0);  
                fireEvent(this.pageRef, 'isChangedUWY', true);  
            }
            this.getAgreements();
        }
        else{
            this.error = error;
        }
        this.getAgreements();
    }

    
    @wire(getPCCAgreements)
    setAccPicklistOptions({error, data}) {
        if(data){
          let allPCC = [{label:'--All--', value:'--All--'}];
          data.forEach(key => {
            allPCC.push({
                label : key.label,
                value:  key.value
            })
          });
          this.cedingAccOpt = allPCC;
          if(this.selectedComp == null){
              this.selectedComp = allPCC[0].value;
              this.disableProgram = true;
                fireEvent(this.pageRef, 'pccOnAgreement', this.selectedComp);
          }
        }
        else{
            this.error = error;
        }
        this.getAgreements();
        //this.loadGetAgreements();
    }

        /*@wire(getObjectInfo, { objectApiName: PROGRAM_OBJECT })
    objectInfoProgram;

   @wire(getPicklistValues, { recordTypeId: '$objectInfoProgram.data.defaultRecordTypeId', fieldApiName: UWYEAR_FIELD})
    setPicklistOptions({error, data}) {
        if(data){
            let allUWYPicklist = [];
            let allUWY = [];
            let addAllValue = [{label:'--All--', value:'--All--'}];
             data.values.forEach(key => {
                allUWYPicklist.push({
                    value : key.value,
                    label:  key.label
                })
            });
             allUWY = allUWYPicklist.concat(addAllValue);
            this.uwYearOpt = allUWY;
            if(this.selectedYear == null){
                this.selectedYear = data.values[data.values.length - 1].value;
                fireEvent(this.pageRef, 'yearOnAgreement', this.selectedYear);  
                fireEvent(this.pageRef, 'offSet', 0);  
                fireEvent(this.pageRef, 'isChangedUWY', true);  
            }
            this.getAgreements();
            //this.loadGetAgreements();
        }
        else{
            this.error = error;
        }
    }*/
    /*@wire(getAcc)
    setAccPicklistOptions({error, data}) {
        if(data){
          let allPCC = [{label:'--All--', value:'--All--'}];
          data.forEach(key => {
            allPCC.push({
                label : key.label,
                value:  key.value
            })
          });
          this.cedingAccOpt = allPCC;
          if(this.selectedComp == null){
              this.selectedComp = allPCC[0].value;
              this.disableProgram = true;
                fireEvent(this.pageRef, 'pccOnAgreement', this.selectedComp);
          }
        }
        else{
            this.error = error;
        }
        this.getAgreements();
        //this.loadGetAgreements();
    }*/
    
    @wire(getPrograms, {valueUWYear: '$selectedYear', valuePrincipalCedComp: '$selectedComp'})
    wiredGetPrograms(result){
        this.spinner = true;
        if (result.data != undefined){
          if (result.data.length > 0){
           let allPrg = [{label:'--All--', value:'--All--'}];
            result.data.forEach(key => {
                allPrg.push({
                    value : key.Id,
                    label:  key.Name
                })
            });
            
             this.wiredprograms = result.data;
             this.programOptions = allPrg;
              if(this.valueProgram == undefined){
                  this.valueProgram = allPrg[0].value;
                  fireEvent(this.pageRef, 'valueInitPrograms', this.valueProgram); 
                  
              }else{
                 this.valueProgram = allPrg[0].value;
                  fireEvent(this.pageRef, 'valuePrograms', this.valueProgram); 
              }
              this.getAgreements();
              //this.loadGetAgreements();
        }else{
            this.programOptions = [];
        }
        this.spinner = false;
    }
  }
    
    @wire(getRecordTypeName)
    wiredGetRecordType(result) {
        if (result.data != undefined){
          if (result.data.length > 0){
             let allRT = [{label:'--All--', value:'--All--'}];
                result.data.forEach(key => {
                    allRT.push({
                        label : key.label,
                        value: key.value
                    })
                });
             
            this.recordTypeOptions = allRT;
            if(this.valueRecordType == undefined){
                this.valueRecordType = this.recordTypeOptions[0].value;
                 fireEvent(this.pageRef, 'valueRecordTypes', this.valueRecordType); 
            }
            this.getAgreements();
            //this.loadGetAgreements();
          }
        }
        else{
            this.error = result.error;
        }
    }

     @wire(getSigningStatus)
    wiredGetSigningDetails(result) {
        if (result.data != undefined){
          if (result.data.length > 0){
             let allSigningStatus = [{label:'--All--', value:'--All--'}];
                result.data.forEach(key => {
                    allSigningStatus.push({
                        label : key.label,
                        value: key.value
                    })
                });
             
            this.signingStatusOptions = allSigningStatus;
            if(this.valueSigningStatus == undefined){
                this.valueSigningStatus = this.signingStatusOptions[0].value;
                 fireEvent(this.pageRef, 'valueSigningStatuss', this.valueSigningStatus); 
            }
            this.getAgreements();
            //this.loadGetAgreements();
          }
        }
        else{
            this.error = result.error;
        }
    }
    
    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    
    getChangeUWYVal(val){
        this.currSelect_valueUWY = val;
    }

    getChangePCC(val){
        this.currSelect_valuePCC = val;
    }
    
    getChangePrograms(val){
        this.currSelect_valuePrg = val;
    }
    
    getInitPrograms(val){
        this.currSelect_valuePrg = val;
    }
    
    getChangeRecordType(val){
        this.currSelect_valueRT = val;
    }  

    getChangeSigningStatus(val){
        this.currSelect_valueSigningStatus = val;
    }

    getOffSet(val){
      this.offsetRow = val;
    }

    getIsChangedUWY(val){
      this.isChangedUWY = val;
    }

     getIsChangedPCC(val){
      this.isChangedPCC = val;
    }

     getIsChangedPrg(val){
      this.isChangedPrg = val;
    }

     getIsChangedRT(val){
      this.isChangedRT = val;
    }

    getIsChangedSigningStatus(val){
      this.isChangedSigningStatus = val;
    }
    
     refreshData() {
        return refreshApex(this.wiredprograms);
    }
     
     
    handleChangeUWYr(event) {
      this.selectedYear = event.detail.value;
      if (this.selectedYear == '--All--' || this.selectedComp == '--All--'){
          this.disableProgram = true;
      }else{
        getProfiles()
        .then(resultProfile => {
            if (resultProfile == 'SF_PlatformReadOnly'){
                 this.disableProgram = true;
            }else{
               this.disableProgram = false;
            }
        })
        .catch(error => {
            this.error = error;
        }); 
      }
       this.isLoadMoreData = false;
       fireEvent(this.pageRef, 'yearOnAgreement', this.selectedYear);
       fireEvent(this.pageRef, 'offSet', 0);  
       fireEvent(this.pageRef, 'isChangedUWY', true);  
       this.offsetRow = 0;
       this.getAgreements();
    }
    
     handleChangeCedingComp(event) {
        this.selectedComp = event.detail.value;
         if (this.selectedYear == '--All--' || this.selectedComp == '--All--'){
              this.disableProgram = true;
        }else{
              //this.disableProgram = false;
          getProfiles()
          .then(resultProfile => {
              if (resultProfile == 'SF_PlatformReadOnly'){
                  this.disableProgram = true;
              }else{
                this.disableProgram = false;
              }
          })
          .catch(error => {
              this.error = error;
          });
        }
        this.isLoadMoreData = false;
         fireEvent(this.pageRef, 'pccOnAgreement', this.selectedComp);
         fireEvent(this.pageRef, 'offSet', 0);  
         fireEvent(this.pageRef, 'isChangedPCC', true);
         this.offsetRow = 0;
         this.getAgreements();    
    }
     
    handleChangeProgram(event) {
      this.valueProgram = event.detail.value;
      this.isLoadMoreData = false;
      fireEvent(this.pageRef, 'valuePrograms', this.valueProgram);
      fireEvent(this.pageRef, 'offSet', 0);  
      fireEvent(this.pageRef, 'isChangedPrg', true); 
      this.offsetRow = 0;
      this.getAgreements();
     
   }
    
    handleChangeRecordType(event) {
      this.valueRecordType = event.detail.value;
      this.isLoadMoreData = false;
      fireEvent(this.pageRef, 'valueRecordTypes', this.valueRecordType);
      fireEvent(this.pageRef, 'offSet', 0);  
      fireEvent(this.pageRef, 'isChangedRT', true); 
      this.offsetRow = 0;
      this.getAgreements();
     
    }

    handleChangeSigningStatus(event){
      this.isLoadMoreData = false;
      this.valueSigningStatus = event.detail.value;
      fireEvent(this.pageRef, 'valueSigningStatuss', this.valueSigningStatus);
      fireEvent(this.pageRef, 'offSet', 0);  
      fireEvent(this.pageRef, 'isChangedSigningStatus', true); 
      this.offsetRow = 0;
      this.getAgreements();
      this.offsetRow = 0;
    }
    
    async getAgreements(){
        console.log('offsetRow 11 == ', this.offsetRow);
       try {
          let baseUrl= 'https://'+ location.host;
          this.currSelect_valueUWY = this.selectedYear != undefined ? this.selectedYear : null ;
          this.currSelect_valuePCC = this.selectedComp != undefined ? this.selectedComp : null ;
          this.currSelect_valuePrg = this.valueProgram != undefined ? this.valueProgram : null;
          this.currSelect_valueRT = this.valueRecordType != undefined ? this.valueRecordType : null;     
          this.currSelect_valueSigningStatus = this.valueSigningStatus != undefined ? this.valueSigningStatus : null;       
              
          this.filterAgreements = {
            uwy : this.currSelect_valueUWY,
            pcc : this.currSelect_valuePCC,
            prg : this.currSelect_valuePrg,
            rt  : this.currSelect_valueRT,
            sigstat: this.currSelect_valueSigningStatus
          };
          console.log('filterAgreements == ', this.filterAgreements);
          console.log('rowLimit == ', this.rowLimit);
          console.log('offsetRow 22== ', this.offsetRow);
           console.log('enableInfiniteLoading 11== ', this.enableInfiniteLoading);

          if (this.isChangedUWY || this.isChangedPCC || this.isChangedPrg || this.isChangedRT || this.isChangedSigningStatus){
            this.offsetRow = 0;
          }
      
        await getAgreements({filterAgreement : this.filterAgreements, limitSize : this.rowLimit, offset : this.offsetRow})
        .then(result => {
          console.log('result == ', result);
          this.spinner = true;
          if (this.filterAgreements.uwy != null && this.filterAgreements.pcc != null){
            let nameUrlAgreement;
            let nameUrlAccount;
            let nameUrlOwnerLastName;
            let nameStatusSigning;
            let statusSigning;
            if (result.length > 0){
                this.isDataExists = true;
                this.dataAgreement = result.map(row => {
                    nameUrlAgreement = baseUrl + '/lightning/r/Apttus__APTS_Agreement__c/' + row.Id + '/view';
                    nameUrlAccount =  baseUrl + '/lightning/r/Account/' + row.Apttus__Account__c + '/view';
                    nameUrlOwnerLastName = baseUrl + '/lightning/r/User/' + row.OwnerId + '/view';
                    if (row.Statut__c == 'To be signed'){
                      statusSigning = baseUrl + '/resource/colorCircle/rouge.png';
                      nameStatusSigning = 'To be signed'; 
                    }else if (row.Statut__c == 'Signed'){
                        statusSigning = baseUrl + '/resource/colorCircle/vert.png';
                        nameStatusSigning = 'Signed'; 
                    }else if (row.Statut__c == 'In Progress'){
                        statusSigning = baseUrl + '/resource/colorCircle/orange.png';
                        nameStatusSigning = 'In Progress'; 
                    }else if (row.Statut__c == 'Will not be signed'){
                        statusSigning = baseUrl + '/resource/colorCircle/gris.png';
                        nameStatusSigning = 'Will not be signed'; 
                    }
                    return {...row , nameUrlAgreement, nameUrlAccount, nameUrlOwnerLastName,statusSigning, nameStatusSigning };
                });
                let sum = this.dataAgreement.length;
                this.titleAgreement = 'Agreements (' + sum +')'; 
                this.totalRecords = sum; // update total records count                 
                this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option 
                this.recordsToDisplay = this.dataAgreement;
                this.recordsToDisplay = sortObjectsByFields(this.recordsToDisplay, 'UnderwritingYear__c', 'Name');
                this.initialRecords = this.recordsToDisplay;
                this.enableInfiniteLoading = true;
                //this.paginationHelper(); // call helper menthod to update pagination logic 
                this.spinner = false;
            }else{
                  this.titleAgreement = 'Agreements (0)';
                  this.isDataExists = false;
                  this.msgNoRecords ='No Record(s) available';
            }
            this.spinner = false;
          }
      })
      .catch(error => {
          this.error = error;
      });
       } catch (error) {
          console.log('error==', error.message);
       }
    }
    


    async loadGetAgreements(){
       try {
          let baseUrl= 'https://'+ location.host;
          this.currSelect_valueUWY = this.selectedYear != undefined ? this.selectedYear : null ;
          this.currSelect_valuePCC = this.selectedComp != undefined ? this.selectedComp : null ;
          this.currSelect_valuePrg = this.valueProgram != undefined ? this.valueProgram : null;
          this.currSelect_valueRT = this.valueRecordType != undefined ? this.valueRecordType : null;     
          this.currSelect_valueSigningStatus = this.valueSigningStatus != undefined ? this.valueSigningStatus : null;       
              
          this.filterAgreements = {
            uwy : this.currSelect_valueUWY,
            pcc : this.currSelect_valuePCC,
            prg : this.currSelect_valuePrg,
            rt  : this.currSelect_valueRT,
            sigstat: this.currSelect_valueSigningStatus
          };

           console.log('filterAgreements loadGetAgreements== ', this.filterAgreements);
          console.log('rowLimit loadGetAgreements== ', this.rowLimit);
          console.log('offsetRow loadGetAgreements== ', this.offsetRow);
           console.log('enableInfiniteLoading loadGetAgreements== ', this.enableInfiniteLoading);
        
        /* if (this.isChangedUWY || this.isChangedPCC || this.isChangedPrg || this.isChangedRT || this.isChangedSigningStatus){
            this.offsetRow = 0;
          }*/

        await getAgreements({filterAgreement : this.filterAgreements, limitSize : this.rowLimit, offset : this.offsetRow})
        .then(result => {
          console.log('result loadGetAgreements == ', result);
            //this.spinner = true;this.
          if (this.filterAgreements.uwy != null && this.filterAgreements.pcc != null){
            let nameUrlAgreement;
            let nameUrlAccount;
            let nameUrlOwnerLastName;
            let nameStatusSigning;
            let statusSigning;
            if (result.length > 0){
                this.isDataExists = true;
                this.dataAgreement = result.map(row => {
                    nameUrlAgreement = baseUrl + '/lightning/r/Apttus__APTS_Agreement__c/' + row.Id + '/view';
                    nameUrlAccount =  baseUrl + '/lightning/r/Account/' + row.Apttus__Account__c + '/view';
                    nameUrlOwnerLastName = baseUrl + '/lightning/r/User/' + row.OwnerId + '/view';
                    if (row.Statut__c == 'To be signed'){
                      statusSigning = baseUrl + '/resource/colorCircle/rouge.png';
                      nameStatusSigning = 'To be signed'; 
                    }else if (row.Statut__c == 'Signed'){
                        statusSigning = baseUrl + '/resource/colorCircle/vert.png';
                        nameStatusSigning = 'Signed'; 
                    }else if (row.Statut__c == 'In Progress'){
                        statusSigning = baseUrl + '/resource/colorCircle/orange.png';
                        nameStatusSigning = 'In Progress'; 
                    }else if (row.Statut__c == 'Will not be signed'){
                        statusSigning = baseUrl + '/resource/colorCircle/gris.png';
                        nameStatusSigning = 'Will not be signed'; 
                    }
                    return {...row , nameUrlAgreement, nameUrlAccount, nameUrlOwnerLastName,statusSigning, nameStatusSigning };
                });

                let sum = this.dataAgreement.length + this.offsetRow;
                 this.titleAgreement = 'Agreements (' + sum +')';   
                //console.log('titleAgreement== ', this.titleAgreement);
                 this.totalRecords = sum; // update total records count                 
                 console.log('totalRecords== ', this.totalRecords);
                //this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option 
                this.enableInfiniteLoading = true;
                this.recordData = [...this.recordsToDisplay, ...this.dataAgreement];
                this.recordsToDisplay = sortObjectsByFields(this.recordsToDisplay, 'UnderwritingYear__c', 'Name');
                this.paginationHelper(this.recordData); // call helper menthod to update pagination logic 
                //this.spinner = false;
            }else{
               this.enableInfiniteLoading = false;
            }
            this.spinner = false;
          }
      })
      .catch(error => {
          this.error = error;
      });
       } catch (error) {
          console.log('error==', error.message);
       }
    }

    async loadMoreDataAgreement(event) {
      let target = event.target;
      target.isLoading = true;
      this.offsetRow = this.offsetRow + this.rowLimit;
      console.log('offsetRow loadMoreDataAgreement', this.offsetRow);
      await this.loadGetAgreements();
      target.isLoading = false;
    }
    

    
     agreementHandleRowSelection(event){
        var actionName = event.detail.action.name;
        this.selectedAgreement = event.detail.row.Id;
        switch (actionName) {
            case 'edit':
                this.editAgreement(this.selectedAgreement);
                break;

            case 'delete':
              isProfileAdmin()
              .then(result => {
                if (result){
                    this.deleteAgreement(this.selectedAgreement);
                }else{
                  this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.DeleteAgreementNotPermit, variant: 'error'}), );
                }
              })
              .catch(error => {
                this.error = error;
              }); 
            break;
          }
           
    }
     //Edit
     editAgreement (idAgreementSelected){
        this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: idAgreementSelected,
                    actionName: "edit"
                }
            });
     }
     
     //Delete
     async deleteAgreement(idAgreementSelected){ 
      const result = await LightningConfirm.open({
          message: this.label.deleteOneChoiceAgreement,
          variant: "default", 
          label: "Delete a record Agreement",
          theme: "warning",
          header: "Delete Confirmation",
          cancelLabel: "No",
          confirmLabel: "Yes"
      });
      if (result) {
        this.spinner = true;
         deleteAgreementsSelected({selectedAgreement : idAgreementSelected})
        .then(successMessage => {
          try {
            if (successMessage != null){
              this.dispatchEvent(new ShowToastEvent({title: 'Success', message: successMessage, variant: 'error'}), );
            }
          } catch (error) {
            console.log('error delete agreement ', error.message);
          }
        })
        .catch(error => {
          this.error = error;
        }); 
        this.spinner = false;
      }
     }
     //****NOT WORKING BUT TO CONSERVE FOR THE FUTURE ACTION***** */
    /*async handleRemoveAgreementInMass (event){
       var selectedRecords =  this.template.querySelector('c-Lwc66-Extented-Data-Table').getSelectedRows();
       let listIdSelectedAgreement = [];
       let listNameSelectedAgreement = [];
       if(selectedRecords.length > 0){
         selectedRecords.forEach(currentItem => {
           listIdSelectedAgreement.push(currentItem.Id);
           listNameSelectedAgreement.push(currentItem.Name);
         });
         
         const result = await LightningConfirm.open({
          message: this.label.deleteMultipleChoiceAgreementPartI + listNameSelectedAgreement + this.label.deleteMultipleChoiceAgreementPartII,
          variant: "default", 
          label: "Delete in mass record(s) Agreement(s)",
          theme: "warning",
          header: "Delete In Masss Confirmation",
          cancelLabel: "No",
          confirmLabel: "Yes"
          });
         if (result) {
           this.spinner = true;
            deleteAgreementsInMass({lstIdAgreements : listIdSelectedAgreement})
            .then(successMessage => {
            try {
              if (successMessage != null){
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: successMessage, variant: 'error'}), );
              }
            } catch (error) {
              console.log('error delete agreement in mass ', error.message);
            }
          })
          .catch(error => {
            this.error = error;
          }); 
            this.spinner = false
         }
       }else{
         this.dispatchEvent(new ShowToastEvent({title: 'Success', message: 'Please Select at least one record', variant: 'error'}), );
       }
     }*/
     
     handleCreateAgreementModal(){
        this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
            objectApiName : 'Apttus__APTS_Agreement__c',
            actionName: 'new'
        },
        state: {
            useRecordTypeCheck: 'true'
        }
      });
     }
     //Change size of recordsToDisplay in the datatable
     handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper(this.recordData);
    }
     
    //button previous page
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper(this.recordData);
    }
    
    //button next page
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper(this.recordData);
    }
    
    //button first page
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper(this.recordData);
    }
    
    //button last page
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper(this.recordData);
    }
    
    // JS function to handel pagination logic 
    paginationHelper(recordData) {
        //this.spinner = true;
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
          if (i === this.totalRecords) {
              break;
          }
          //dataToSorted.push(this.dataAgreement[i]);
          this.recordsToDisplay = recordData;
           this.recordsToDisplay = sortObjectsByFields(this.recordsToDisplay, 'UnderwritingYear__c', 'Name');
        }
        //let lstSortDataAgreements = sortObjectsByFields(dataToSorted, 'UnderwritingYear__c', 'Name');
        //this.recordsToDisplay = lstSortDataAgreements;
        this.initialRecords =  this.recordsToDisplay;
        this.spinner = false;
    }
    
    handleSearch(event) {
      this.searchString = event.target.value;
      console.log('searchString handleSearch ==', this.searchString);
      
        if (this.searchString.length >=2){
          let baseUrl= 'https://'+ location.host;
          let nameUrlAgreement;
          let nameUrlAccount;
          let nameUrlOwnerLastName;
          let nameStatusSigning;
          let statusSigning;
          console.log('selectedYear handleSearch ==', this.selectedYear);
      console.log('selectedComp handleSearch ==', this.selectedComp); 
           fetchDataAgreements({searchKey : this.searchString, uwy : this.selectedYear, pcc : this.selectedComp, offsets : 0})
           .then(result => {
              console.log('result handleSearch ==', result);
               console.log('result handleSearch length==', result.length);
            
            if (result.length > 0){
              this.spinner = true;
               this.dataAgreement = result.map(row => {
                    nameUrlAgreement = baseUrl + '/lightning/r/Apttus__APTS_Agreement__c/' + row.Id + '/view';
                    nameUrlAccount =  baseUrl + '/lightning/r/Account/' + row.Apttus__Account__c + '/view';
                    nameUrlOwnerLastName = baseUrl + '/lightning/r/User/' + row.OwnerId + '/view';
                    if (row.Statut__c == 'To be signed'){
                      statusSigning = baseUrl + '/resource/colorCircle/rouge.png';
                      nameStatusSigning = 'To be signed'; 
                    }else if (row.Statut__c == 'Signed'){
                        statusSigning = baseUrl + '/resource/colorCircle/vert.png';
                        nameStatusSigning = 'Signed'; 
                    }else if (row.Statut__c == 'In Progress'){
                        statusSigning = baseUrl + '/resource/colorCircle/orange.png';
                        nameStatusSigning = 'In Progress'; 
                    }else if (row.Statut__c == 'Will not be signed'){
                        statusSigning = baseUrl + '/resource/colorCircle/gris.png';
                        nameStatusSigning = 'Will not be signed'; 
                    }
                    return {...row , nameUrlAgreement, nameUrlAccount, nameUrlOwnerLastName,statusSigning, nameStatusSigning };
                });
                this.titleAgreement = 'Agreements (' + this.dataAgreement.length +')'; 
                console.log('titleAgreement== ', this.titleAgreement);
                this.totalRecords = this.dataAgreement.length; // update total records count                 
                 this.enableInfiniteLoading = true;             
                 console.log('totalRecords== ', this.totalRecords);
                this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option 
                
                this.recordsToDisplay = [];
                this.recordsToDisplay = this.dataAgreement;
                this.isDataExists = true;
                this.msgNoRecords = null;
                this.recordsToDisplay = sortObjectsByFields(this.recordsToDisplay, 'UnderwritingYear__c', 'Name');
                this.enableInfiniteLoading = false;
                this.spinner = false;
            }else{
                this.msgNoRecords = 'No Record(s) available';
                this.isDataExists = false;
            }
            this.spinner = false;
          })
          .catch(error => {
            this.error = error;
          });
        }
        
         if (this.searchString == '' ){
          this.offsetRow = 0;
          this.getAgreements();       
        }
    } 
    
    /*handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        console.log('Search String is ' + searchKey);
        if (searchKey) {
            console.log('Agreements Records are ' + JSON.stringify(this.recordsToDisplay));         
            if (this.recordsToDisplay) {
                let resultSearchAgreements = [];                
                for (let rec of this.recordsToDisplay) {
                    console.log( 'Rec is ' + JSON.stringify(rec) );
                    let valuesArray = Object.values(rec);
                    console.log('valuesArray is ' + JSON.stringify(valuesArray));
                    for ( let val of valuesArray ) {
                        console.log( 'val is ' + val );
                        let strVal = String(val);                      
                        if (strVal) {
                            if (strVal.toLowerCase().includes(searchKey)) {
                                resultSearchAgreements.push( rec );
                                break;                       
                            }
                        }
                    }                   
                }
                console.log('Matched Agreements are ' + JSON.stringify(resultSearchAgreements) );
                this.recordsToDisplay = resultSearchAgreements;
             }
 
        } else {
            this.recordsToDisplay = [...this.recordsToDisplay, ...this.dataAgreement];
        }        
    }*/
    
    /*handleSearch(event) {
      console.log('recordsToDisplay  handleSearch== ', this.recordsToDisplay); 
      console.log('recordsToDisplay  handleSearch length== ', this.recordsToDisplay.length);

        const searchKey = event.target.value.toLowerCase();
        if (searchKey) {
            if (this.recordsToDisplay) {
                let searchRecords = [];
                for (let record of this.recordsToDisplay) {
                    let valuesArray = Object.values(record);
                    for (let val of valuesArray) {
                        let strVal = String(val);
                        if (strVal) {
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
                this.recordsToDisplay = searchRecords;
            }
        } else {
           this.offsetRow = 0; 
           this.getAgreements();
        }
    }*/
}