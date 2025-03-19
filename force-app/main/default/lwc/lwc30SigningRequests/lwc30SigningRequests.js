/**
 * @description       :  
**/
import {LightningElement, track, wire, api} from 'lwc';import {refreshApex} from '@salesforce/apex';import {registerListener, fireEvent} from 'c/pubSub';import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';import {getObjectInfo } from 'lightning/uiObjectInfoApi';import {getPicklistValues} from 'lightning/uiObjectInfoApi';import {ShowToastEvent} from 'lightning/platformShowToastEvent';import closePreviousPhase from '@salesforce/apex/LWC30_SigningRequests.closePreviousPhase';import getSigningDetails from '@salesforce/apex/LWC30_SigningRequests.getSigningDetails';import getRequestResult from '@salesforce/apex/LWC30_SigningRequests.lstRequestResult';import getListIdOrginalRequestNotNull from '@salesforce/apex/LWC30_SigningRequests.getListIdOrginalRequestNotNull';import getListIdRequest from '@salesforce/apex/LWC30_SigningRequests.getListIdRequest';import updateSigningReqClosePrevPhase from '@salesforce/apex/LWC30_SigningRequests.updateSigningReqClosePrevPhase';import saveSigningRequest from '@salesforce/apex/LWC30_SigningRequests.saveSigningRequest';import updateWrittenSignedShare from '@salesforce/apex/LWC30_SigningRequests.updateWrittenSignedShare';import deleteSigningRequests from '@salesforce/apex/AP43_DeleteClonedRequests.deleteSigningRequests';import closeSigningNotifyWebXL from '@salesforce/apex/LWC30_SigningRequests.closeSigningNotifyWebXL';import reopenSigningRequest from '@salesforce/apex/LWC30_SigningRequests.reopenSigningRequest';import reopenPreviousPhase from '@salesforce/apex/LWC30_SigningRequests.reopenPreviousPhase';import getLookupAccountField from '@salesforce/apex/LWC30_SigningRequests.getLookupAccountField';import checkIfProgPhaseSigningHasDoc from '@salesforce/apex/LWC30_SigningRequests.checkIfProgPhaseSigningHasDoc';import checkIfLeadReqAreAnswered from '@salesforce/apex/LWC30_SigningRequests.checkIfLeadReqAreAnswered';import checkFXRATEifExists from '@salesforce/apex/LWC30_SigningRequests.checkFXRATEifExists';import BROKER_STATUS_FIELD from '@salesforce/schema/Request__c.BrokerStatus__c';import LOSS_DEPOSIT_MODE_FIELD from '@salesforce/schema/Request__c.LossDepositMode__c';import PREMIUM_DEPOSIT_FIELD from '@salesforce/schema/Request__c.PremiumDeposit__c';import REQUEST_OBJECT from '@salesforce/schema/Request__c';import getAgreements from '@salesforce/apex/LWC30_SigningRequests.getListAgreementIds';import checkValueOnGetSigningDetails from '@salesforce/apex/LWC30_SigningRequests.checkValueOnGetSigningDetails';
import saveSigningRequestFrombrokerStatus from '@salesforce/apex/LWC30_SigningRequests.saveSigningRequestFrombrokerStatus';
//import custom labels
import {label} from './lwc30SigningRequestsUtils';
import {showToast} from 'c/lwcUtilityCmp';
//BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
import {launchDisableMethod,secondaryLaunch} from 'c/lwc65GenericReadOnlyCmp';

export default class LWC30_SigningRequests extends NavigationMixin(LightningElement) {
    label = label;
    @api hideCheckbox = false ;clickBtnAskForValidation = false;valSignedShareEmpty;lstIdReqUpdatedLastVers = [];valueRiskCarrier;@api saveFromBrokerStatus=false;@api selectedTreaty = null;@api isGrayOutCloseSignWebXL=false;@api selectedBroker = null;@api selectIsDirect = false; @api selectedReinsurer = null;@api selectedReinsurerStatus = null;@api selectedProgram;
    @api uwYear; @api principalCedYear;@api allReadOnly = false;@track dataSigningRequest = [];@api lstIdRiskCarrierChanged = [];//RRA - Ticket 2304 - 12/02/2025
    @api lstReqIdEv; @track dataSigningRequestClosePreviousPhase = [];@track lstSelectedSigningRequest = [];@track lstSelectedSigningReqId = [];@track brokerStatusOpt = [];@track riskCarrierOpt = [];@track financialEntityOpt = [];@track lossDepositModeOpt = [];@track premiumDepositOpt = [];@track dataSigningPool = [];@track requestsSetup = [];@track disableThisButton =false;
    lstSelectedSigningRequest1;titleCountSigningRequest = 'Signing Requests (0)';isValueChange = false;setIdReq = new Set();lstReqId = [];lstIdReqOnChangeLossDeposit = []; lstIdReqOnChange = [];lstIdReqOnChangeSetup = [];  lstReqIdFinEnt = [];lstReqIdFinEntSetup  = [];lstReqIdRiskCarr = [];lstReqIdRiskCarrSetup = [];lossDepositModeGlob; 
    lossDepositGlob;isOpenConfirmation = false;programStageValueChange;isPhaseChange = false;spinnerSigningRequest = false;valueUWYear;buttonNameClick;reqId;disableBtnSigning;
    btnNameSendUpdateRemind;valuePrincipalCedComp;pcc;uwry;buttonSignPoolVisibility;isSave = false;isWrite = false; isValidate = false;isClose = false;isDelete = false;isReopen = false;
    isSign = false;isAskToSave = false;disableReopenPreviousPhase = false;isOpenSignForPoolModal = false; buttonDeleteVisbility; isProfileSuper = false;
    disableBtnSend;isSendUpdateRemindSigningReqOpenModal = false;titlePopUp;showClosePreviousPhaseBtn = false;disableUpdateRemind = true;
    marketSubVisible = false;totalCededPremiumEUR = 0;totalCededPremiumOther = 0;displayTwoFieldForPremium = false;selectedRequest;strPremiumOtherCurrencyLabel = '';allowAskForValidation = false;contractualDocSigningPresent = false; txtRiskCarrierLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    txtFinancialEntityLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click'; error;disabledCloseButton = false;closePreviousBtnClick = false;isRenderCallbackActionExecuted = false; CLM
    disableCopyRCToFC = true;@track idAgreements = ''; @api runSubflowsCLM = false;
    //AMI 01/06/22: W-0940
    isSetupIsAskValidationRequest = false ; //MRA 14/07/2022 : W-0940

    //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
    renderedCallback(){
        launchDisableMethod(this,'Generic');
    }
     //BBH 30.10.2024 - Dev ReadOnly W-2163:AUDIT - Create a Read only profile for all platform except Works tab
    get calcVisibility(){
        secondaryLaunch(this,'Generic');
        return '';
    }



    searchRiskCarrierLookUpField(event){
        let currentText = event.target.value;
        let eventId = event.target.id;
        let reqId = eventId.split('-')[0];
        let selectedReinsurer;
        this.setDataSigningRequestField(reqId,'RiskCarrierName',currentText);//HRA w-1418
        getLookupAccountField({value: currentText, requestId : reqId, lookupName: 'RiskCarrier'})
        .then(result => {
            this.txtRiskCarrierLookupClassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            let lstUpdDataSigningRequest = [];
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq.Id === reqId){
                    rowReq['loadingTextRisk'] = false;
                    rowReq['searchLookupRecordsRisk'] = result;
                    rowReq['displayRiskCarrierInfo'] = true;
                    selectedReinsurer = rowReq['Reinsurer__c'];
                    if(currentText.length > 0 && result.length == 0) {rowReq['messageFlagRisk'] = true;}
                    else {rowReq['messageFlagRisk'] = false;}
                }
                else{rowReq['displayRiskCarrierInfo'] = false;}
              lstUpdDataSigningRequest.push(rowReq);
            }
            if(currentText.length == 0){
                this.isValueChange = true;//1415
                lstUpdDataSigningRequest = [];
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    if(rowReq['Reinsurer__c'] == selectedReinsurer){
                        rowReq['RiskCarrier__c'] = null;
                        rowReq['RiskCarrierName'] = null;
                    }
                    lstUpdDataSigningRequest.push(rowReq);
                }
            }
            this.dataSigningRequest = lstUpdDataSigningRequest;
            this.updateCopyRCToFCVisibility();// HRA W-1289
            this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
        })
        .catch(error => {this.error = error;});
    }

    setSelectedRiskCarrierLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let reqId = event.currentTarget.title;
        let selectedReinsurerId;
        this.txtRiskCarrierLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let lstUpdDataSigningRequest = [];
        for(let i = 0; i < this.dataSigningRequest.length; i++){
            let rowReq = { ...this.dataSigningRequest[i] };
            if(rowReq.Id == reqId){
                this.isValueChange = true;
                rowReq['RiskCarrier__c'] = recId;
                rowReq['RiskCarrierName'] = selectName;
                selectedReinsurerId = rowReq['Reinsurer__c'];
            }
            lstUpdDataSigningRequest.push(rowReq);
        }
        //RRA - ticket 1759 - 20112023
        this.callGetListIdOrginalRequestNotNull(selectedReinsurerId, 'RiskCarrier');
        if(selectedReinsurerId != null){
            lstUpdDataSigningRequest = [];
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq['Reinsurer__c'] == selectedReinsurerId){
                    rowReq['RiskCarrier__c'] = recId;
                    rowReq['RiskCarrierName'] = selectName;
                    this.lstIdRiskCarrierChanged.push(rowReq.Id); //RRA - ticket 2304 - 12/02/2025
                }
                lstUpdDataSigningRequest.push(rowReq);
            }
            console.log('lstIdRiskCarrierChanged == ', this.lstIdRiskCarrierChanged);
        }

        this.dataSigningRequest = lstUpdDataSigningRequest;
        this.updateCopyRCToFCVisibility();// HRA W-1289
        this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
    }

    searchFinancialEntityLookUpField(event){
        
        sessionStorage.setItem('isValueFinancialEntityEmpty', false);//1417
        let currentText = event.target.value;
        let eventId = event.target.id;
        let reqId = eventId.split('-')[0];
        this.setDataSigningRequestField(reqId,'FinancialName',currentText);//HRA w-1418
        getLookupAccountField({value: currentText, requestId : reqId, lookupName: 'FinancialEntity'})
        .then(result => {
            this.txtFinancialEntityLookupClassName =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            let lstUpdDataSigningRequest = [];
            let selectedReinsurer;
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq.Id == reqId){
                    rowReq['loadingTextFinancial'] = false;
                    rowReq['searchLookupRecordsFinancial'] = result;
                    rowReq['displayFinancialInfo'] = true;
                    selectedReinsurer = rowReq['Reinsurer__c'];

                    if(currentText.length > 0 && result.length == 0) {rowReq['messageFlagFinancial'] = true;}
                    else {rowReq['messageFlagFinancial'] = false;}
                }
                else{rowReq['displayFinancialInfo'] = false;}
                lstUpdDataSigningRequest.push(rowReq);
            }
            if(currentText.length == 0){
                this.isValueChange = true;//1415
                lstUpdDataSigningRequest = [];
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    if(rowReq['Reinsurer__c'] == selectedReinsurer){
                        rowReq['FinancialEntity__c'] = null;
                        rowReq['FinancialName'] = null;
                    }
                    lstUpdDataSigningRequest.push(rowReq);
                }
            }
            this.dataSigningRequest = lstUpdDataSigningRequest;
            this.updateCopyRCToFCVisibility();// HRA W-1289
            this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
        })
        .catch(error => {this.error = error;});
    }

    setSelectedFinancialEntityLookupRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let selectName = event.currentTarget.dataset.name;
        let reqId = event.currentTarget.title;
        let selectedReinsurerId;
        this.txtFinancialEntityLookupClassName = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let lstUpdDataSigningRequest = [];

        for(let i = 0; i < this.dataSigningRequest.length; i++){
            let rowReq = { ...this.dataSigningRequest[i] };
            if(rowReq.Id == reqId){
                this.isValueChange = true;
                rowReq['FinancialEntity__c'] = recId;
                rowReq['FinancialName'] = selectName;
                selectedReinsurerId = rowReq['Reinsurer__c'];
            }
            lstUpdDataSigningRequest.push(rowReq);
        }
        //RRA - ticket 1759 - 20112023
        this.callGetListIdOrginalRequestNotNull(selectedReinsurerId, 'FinancialEntity');
        if(selectedReinsurerId != null){
            lstUpdDataSigningRequest = [];
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq['Reinsurer__c'] == selectedReinsurerId){
                    rowReq['FinancialEntity__c'] = recId;
                    rowReq['FinancialName'] = selectName;
                }
                lstUpdDataSigningRequest.push(rowReq);
            }
        }
        this.dataSigningRequest = [ ...lstUpdDataSigningRequest];
        this.updateCopyRCToFCVisibility();// HRA W-1289
        this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
    } 

    callGetListIdOrginalRequestNotNull(reinsurerId, listType){
        let lstReqIdSetup;
        let lstReqId; 
        let lossDepositLevel = this.dataSigningRequest[0].Program__r.LossDepositLevel__c != undefined ? this.dataSigningRequest[0].Program__r.LossDepositLevel__c : undefined; 
        let lossDeposit = this.dataSigningRequest[0].Program__r.LossDeposit__c != undefined ? this.dataSigningRequest[0].Program__r.LossDeposit__c : undefined; 
        if(listType == 'RiskCarrier'){
            lstReqIdSetup=this.lstReqIdRiskCarrSetup;
            lstReqId = this.lstReqIdRiskCarr
        }else if(listType=='FinancialEntity'){
            lstReqIdSetup=this.lstReqIdFinEntSetup;
            lstReqId = this.lstReqIdFinEnt
        }else{listType = 'void';}
        if(listType != 'void'){
            getListIdOrginalRequestNotNull({programId : this.selectedProgram, pcc : this.pcc, uwy : this.uwry, reinsurer : reinsurerId})
                .then(result => {
                   if(result.isLossDepositModeTreatySetup){
                       if (result.lstOrigReqNull.includes(reqId)){
                       lstReqIdSetup.push(reqId);
                       let removeDuplication = lstReqIdSetup.filter((item,index) => lstReqIdSetup.indexOf(item) === index);
                       lstReqIdSetup = removeDuplication;}
                   }else{
                       if (lossDeposit == '1'){
                           if (lossDepositLevel == 'Program'){
                               lstReqId.push(result.lstOrigReqNotNull);
                            }else if (lossDepositLevel == 'Treaty'){
                               lstReqId.push(reqId);
                               let removeDuplication = lstReqId.filter((item,index) => lstReqId.indexOf(item) === index);
                               lstReqId = removeDuplication;
                            }
                       }else if (lossDeposit == '2'){
                           lstReqId.push(reqId);
                           let removeDuplication = lstReqId.filter((item,index) => lstReqId.indexOf(item) === index);
                           lstReqId = removeDuplication;
                       }
                   }
            }).catch(error => {this.error = error;});
        }
    }


    setDataSigningRequestField(reqId,field,value){//HRA w-1418
        for(let i = 0; i < this.dataSigningRequest.length; i++){if(this.dataSigningRequest[i].Id == reqId){this.dataSigningRequest[i][field] = value;} }
    }

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
        registerListener('stageSigningChange', this.askSaveConfirmation, this);
        registerListener('closeSendUpdateRemindReqModal', this.closeSendUpdateRemindReqModal, this);
        registerListener('updateRequestReinsurer', this.updateRequestReinsurer, this);
        registerListener('refreshSigningData', this.refreshSigningData, this);

        let param = 'c__program';
        let paramValue = null;
        let url = this.pageRef.state;
        
        if(url != undefined && url != null){paramValue = url[param]; }

        if(paramValue != null){
            let parameters = paramValue.split("-");
            this.valueUWYear = parameters[1];
            this.valuePrincipalCedComp = parameters[2];
            if(parameters[4] != 'null' && parameters[4] != 'undefined'){
                this.valueTreaty = parameters[4];
                this.selectedTreaty = parameters[4];
            }
            if(parameters[5] != 'null' && parameters[5] != 'undefined'){this.selectedBroker = parameters[5];}
            if(parameters[6] != 'null' && parameters[6] != 'undefined'){this.selectedReinsurer = parameters[6];}
            if(parameters[7] != 'null' && parameters[7] != 'undefined'){this.selectedReinsurerStatus = parameters[7];}
        }
        registerListener('closeModal', this.handleCloseConfirmationModal, this);
        registerListener('year', this.getVal, this);
        registerListener('compChange', this.getCompChangePcc, this); 
        registerListener('yearChange', this.getCompChangeuwY, this);
        registerListener('comp', this.getComp, this);
        registerListener('valueTreaty', this.getValueTreaty, this);
        registerListener('valueBroker', this.getValueBroker, this);
        registerListener('isDirect', this.getIsDirect, this);//1091
        registerListener('valueReinsurer', this.getValueReinsurer, this);
        registerListener('valueReinsurerStatus', this.getValueReinsurerStatus, this);
        registerListener('valueProgram', this.getValueProgram, this);
        registerListener('closeMarketSubModal', this.handleCloseMarketSubModal, this);

        // RRA - Get pcc from onChange pcc on working scope
        if (this.pcc == undefined){this.pcc = this.valuePrincipalCedComp
        }else{this.pcc =  this.pcc;}

        // RRA - Get uwy from onChange uwy on working scope
        if ( this.uwry == undefined){this.uwry = this.uwYear
        }else{this.uwry =  this.uwry;}
    }

	renderedCallback() {
        if (this.isRenderCallbackActionExecuted){ return;}
        this.isRenderCallbackActionExecuted = true;
        const style = document.createElement('style');
        style.innerText = '.strongText input {font-weight: bold!important;}';
        this.template.querySelectorAll('[data-table-id="1"],tr[data-id="trId"],td[data-id="tdId"],div[data-id="divId"],lightning-combobox,div,lightning-base-combobox,div,div,input').forEach (function (node) {
            node.appendChild(style);
        });
    }
    refreshSigningData(val){
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }

    getUrlParamValue(url, key) {return new URL(url).searchParams.get(key);}

    getVal(val){
        this.valueUWYear = val;
        this.selectedProgram = null;
        this.selectedTreaty = null;
        this.selectedReinsurer = null;
        this.selectedBroker = null;
        this.selectedReinsurerStatus = null;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
     getCompChangePcc(val){
        this.pcc = val;
        this.selectedProgram = null;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getCompChangeuwY(val){
        this.uwry = val;
        this.selectedProgram = null;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getComp(val){
        this.valuePrincipalCedComp = val;
        this.selectedProgram = null;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getValueProgram(val){
        this.selectedProgram = val;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getValueTreaty(val){
        this.selectedTreaty = val;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getValueReinsurer(val){
        this.selectedReinsurer = val;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getValueBroker(val){
        this.selectedBroker = val;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getIsDirect(val){
        this.selectIsDirect = val;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }
    getValueReinsurerStatus(val){
        this.selectedReinsurerStatus = val;
        this.spinnerSigningRequest = true;
        this.getSigningDetails();
    }

    handleClosePreviousPhases(){
        //RRA - ticket 585 - 15032023
            this.spinnerSigningRequest = true;
            this.disabledCloseButton = true;
            checkIfLeadReqAreAnswered({ programId : this.selectedProgram})
            .then(result => {
                this.spinnerSigningRequest = true;
                if(result.hasOwnProperty('Error') && result.Error){
                    showToast(this, 'Error', 'error', result.Error);
                    this.spinnerSigningRequest = false;
                }
                else if(result.hasOwnProperty('Success')){
                    closePreviousPhase({ programId : this.selectedProgram})
                    .then(result => {
                        this.dataSigningRequestClosePreviousPhase = result.lstSigningRequests != undefined ? result.lstSigningRequests : this.dataSigningRequest;
                        this.closePreviousBtnClick = true;
                        showToast(this, 'Success', 'success', label.phasesClosed);
                        this.getSigningDetails();
                        fireEvent(this.pageRef, 'refreshReinsurerFilters', '') ;
                    })
                    .catch(error => {
                        showToast(this, 'Error', 'error', label.errorMsg);this.spinnerSigningRequest = false;
                    });
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.errorMsg, variant: 'error'}), );
                this.spinnerSigningRequest = false;
            });
    }

    getSigningDetails(){
        this.spinnerSigningRequest = true;
        this.isSetupIsAskValidationRequest = false ; //MRA 14/07/2022 : W-0940
        if(this.selectedProgram != null){
             //RRA - ticket 1091 - 15072024
            if (this.selectedBroker == 'All' || this.selectedBroker == null){this.selectedBroker = null;this.selectIsDirect = false;
            }else if (this.selectedBroker == 'direct'){this.selectedBroker = null;this.selectIsDirect = true;
            }else if (this.selectedBroker.includes('001')){this.selectedBroker = this.selectedBroker;this.selectIsDirect = false;}
            getSigningDetails({programId: this.selectedProgram, treatyId: this.selectedTreaty, reinsurerId: this.selectedReinsurer, brokerId: this.selectedBroker, reinsurerStatus: this.selectedReinsurerStatus, isClosePreviousBtnClick : this.closePreviousBtnClick, isDirect : this.selectIsDirect})
            .then(result => {
                this.spinnerSigningRequest = true;
                let profileName = result.userProfile;
                this.displayTwoFieldForPremium = result.displayTwoFieldForPremium;
                let updDataSigningRequest = [];
                let updDataSigningRequestClosePrev = [];
                let dataSigningRequest = result.lstSigningRequest;
                let mapIdReqReq = new Map();
                let mapTECH_RelatedLeadPlacementRequestReq = new Map();
                let compareDataSigning = new Map();
                let mapIdTreatyReq = new Map();
                let isDeactivatedProg = result.isDeactivatedProg;  //RRA - ticket 585 - 13032023
                if (this.closePreviousBtnClick){
                    if (this.dataSigningRequestClosePreviousPhase.length > 0 ){
                        for (let j=0;j<this.dataSigningRequestClosePreviousPhase.length;j++){
                            let rowClosePrev = {...this.dataSigningRequestClosePreviousPhase[j]}
                            mapIdReqReq.set(rowClosePrev.Id, rowClosePrev);
                            compareDataSigning.set(rowClosePrev.TECH_TreatyBrokerReinsurer__c, rowClosePrev); //RRA - 2008
                            mapTECH_RelatedLeadPlacementRequestReq.set(rowClosePrev.TECH_RelatedLeadPlacementRequest__c + '_' + rowClosePrev.Treaty__c, rowClosePrev);
                            mapIdTreatyReq.set(rowClosePrev.Treaty__c, rowClosePrev);
                        } 
                        for (let i=0;i<dataSigningRequest.length;i++){
                            let rowData = {...dataSigningRequest[i]};
                             //RRA - ticket 1414 - 31012023
                            if (mapIdReqReq.has(rowData.Id)){
                                rowData.SignedShare__c = mapIdReqReq.get(rowData.Id).SignedShare__c != null ? mapIdReqReq.get(rowData.Id).SignedShare__c : rowData.SignedShare__c;
                                rowData.WrittenShare__c = mapIdReqReq.get(rowData.Id).WrittenShare__c !=null ? mapIdReqReq.get(rowData.Id).WrittenShare__c : rowData.WrittenShare__c;
    
                            //RRA - ticket 1404 - 08022023
                            }else if (mapTECH_RelatedLeadPlacementRequestReq.has(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c)){
                                rowData.SignedShare__c = mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).SignedShare__c != null ? mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).SignedShare__c : rowData.SignedShare__c;
                                rowData.WrittenShare__c = mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).WrittenShare__c != null ? mapTECH_RelatedLeadPlacementRequestReq.get(rowData.TECH_RelatedLeadPlacementRequest__c + '_' + rowData.Treaty__c).WrittenShare__c : rowData.WrittenShare__c;
                            }
                            if (compareDataSigning.has(rowData.TECH_TreatyBrokerReinsurer__c) || (rowData.TECH_TreatyBrokerReinsurer__c.startsWith('a0E') &&rowData.TECH_TreatyBrokerReinsurer__c.endsWith('-'))){//RRA - 2008 and 2087
                                updDataSigningRequestClosePrev.push(rowData);
                            }
                        }
                        this.dataSigningRequest = updDataSigningRequestClosePrev;
                        updateSigningReqClosePrevPhase({ lstReqClosePrevPhase : this.dataSigningRequest, idProgram : this.selectedProgram})
                        .then(result => {window.location.reload();})
                        .catch(error => {
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.errorMsg, variant: 'error'}), );
                            this.spinnerSigningRequest = false;
                        });
                    }else{
                        for (let i=0;i<dataSigningRequest.length;i++){
                            let rowData = {...dataSigningRequest[i]};
                            if(rowData.TECH_RelLeadPlacReqReinsurer__c == 'Answered' || rowData.Pool__c != null){//RRA 2087
                                updDataSigningRequestClosePrev.push(rowData);
                            }
                        }
                        this.dataSigningRequest = updDataSigningRequestClosePrev;
                    }
                }else{
                    for (let i=0;i<dataSigningRequest.length;i++){
                        let rowData = {...dataSigningRequest[i]};
                        if(rowData.TECH_RelLeadPlacReqReinsurer__c == 'Answered' || rowData.Pool__c != null){//RRA 2087
                            updDataSigningRequestClosePrev.push(rowData);
                        }
                    } 
                    this.dataSigningRequest = updDataSigningRequestClosePrev;
                }
                let lstFilteredSigningRequest = result.lstFilteredSigningRequest;
                let setFilteredDataSigningReq = new Set();
                for(let i = 0; i < lstFilteredSigningRequest.length; i++){setFilteredDataSigningReq.add(lstFilteredSigningRequest[i].Id);}
                this.showClosePreviousPhaseBtn = result.showClosePreviousPhaseBtn;
                this.titleCountSigningRequest = this.dataSigningRequest.length > 0 ? 'Signing Requests' + ' (' + lstFilteredSigningRequest.length + ')' : 'Signing Requests (0)' ; //RRA - ticket 1091 - 16072024
                this.buttonSignPoolVisibility = result.isSignPoolVisible;
                this.buttonDeleteVisbility = result.isDeleteVisible;
                this.isProfileSuper = result.isDeleteVisible;
                this.disableBtnSend = false; 
                this.strPremiumOtherCurrencyLabel = 'Premium (' +result.currencyOtherLabel +')';
                this.totalCededPremiumOther = result.totalCededPremiumOther;
                this.totalCededPremiumEUR = result.totalCededPremiumEUR;
                this.allowAskForValidation = result.allowAskForValidation;
                this.contractualDocSigningPresent = result.contractualDocSigningPresent;
                let renewed = result.renewStatus;
                let isReinsurerStatusNotSetup = false;
                let isReinsurerStatusSetup = false;
                let updDataSigningPool = [];
                let isFlagOther = false;
                let isFlagSetup = false; 
                let lstSigningStatus = [];                 
                //AMI 01/06/22: W-0940
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    rowReq.disableFinancialEntity = false;
                    //1417
                    if (rowReq.BrokerStatus__c == '2'){
                            rowReq.disableFinancialEntity = true;
                        }else if (rowReq.BrokerStatus__c == '1'){
                            rowReq.disableFinancialEntity = false;
                        }
                    if (rowReq.ReinsurerStatus__c === 'Sent' || rowReq.ReinsurerStatus__c === 'Timeout' || rowReq.ReinsurerStatus__c === 'Signed' || rowReq.ReinsurerStatus__c === 'Signed By R.M.'){isFlagOther = true;
                    }else if (rowReq.ReinsurerStatus__c === 'Setup'){isFlagSetup = true;}                  
                     //RRA - ticket 1410 / 1411 - 13042023
                     if(rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c && isFlagSetup && isFlagOther === false){this.hideCheckbox = true;
                     }else if(rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c && isFlagSetup && isFlagOther){this.hideCheckbox = false;
                     }else if(rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c === false && isFlagSetup && isFlagOther === false){this.hideCheckbox = true ;//init Request
                     }else if(rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c === false && isFlagSetup && isFlagOther){this.hideCheckbox = false ;
                     }else if (rowReq.ExpectedResponseDate__c !== undefined && rowReq.isReopenPreviousPhase__c && isFlagOther && isFlagSetup){this.hideCheckbox = false ; 
                     }else if (rowReq.ExpectedResponseDate__c !== undefined && rowReq.isReopenPreviousPhase__c && isFlagOther && isFlagSetup === false){ this.hideCheckbox = false ; 
                     }else if (rowReq.ExpectedResponseDate__c !== undefined && rowReq.isReopenPreviousPhase__c === false && isFlagOther && isFlagSetup){this.hideCheckbox = false ; 
                     }else if (rowReq.ExpectedResponseDate__c !== undefined && rowReq.isReopenPreviousPhase__c === false && isFlagOther && isFlagSetup === false){this.hideCheckbox = false ; //1st Send
                     }else if (rowReq.ExpectedResponseDate__c === undefined && rowReq.isReopenPreviousPhase__c === false && isFlagSetup && isFlagOther){this.hideCheckbox = false; }
                    if(this.dataSigningRequest[i] && this.dataSigningRequest[i].ReinsurerStatus__c === 'Setup'){
                        this.isSetupIsAskValidationRequest = true ;//MRA 14/07/2022 : W-0940
                    }

                    //RRA - ticket 0940 - 16/01/2025
                    if(this.dataSigningRequest[i] && this.dataSigningRequest[i].isAskValidation__c){
                      this.isSetupIsAskValidationRequest = false;
                    }
                    console.log('isSetupIsAskValidationRequest getSigningDetails == ', this.isSetupIsAskValidationRequest);
                    lstSigningStatus.push(rowReq.SigningStatus__c );//1415
                    if(rowReq.TECH_RelatedLeadPlacementRequest__c != null && rowReq.TECH_RelatedLeadPlacementRequest__c != undefined){
                        if(rowReq.TECH_Recovery_RelatedLeadPlacementReq__c == 'Lead'){
                            rowReq['boldStyle'] = "font-weight: bold;";
                            rowReq['isLead'] = true;
                        }
                        else{
                            rowReq['boldStyle'] = "";
                            rowReq['isLead'] = false;
                        }
                    }
                    else{
                        rowReq['boldStyle'] = "";
                        rowReq['isLead'] = false;
                    }
                    rowReq['TreatyPlacementShare'] = (parseFloat(rowReq.Treaty__r.PlacementShare_Perc__c).toFixed(6).replace('.',',') !== 'NaN') ? parseFloat(rowReq.Treaty__r.PlacementShare_Perc__c).toFixed(6).replace('.',',') : parseFloat(rowReq.Treaty__r.CessionShare__c).toFixed(6).replace('.',','); //RRA - ticket 1966 - 23042024
                    if(setFilteredDataSigningReq.has(rowReq.Id)){rowReq['displayInTable'] = true;}
                    else{rowReq['displayInTable'] = false;}
                    rowReq['divId'] = rowReq.Id;
                    rowReq['divId2'] = rowReq.Id;
                    rowReq['WrittenShareVal'] = parseFloat(rowReq.WrittenShare__c).toFixed(6).replace('.',',');
                    rowReq['SignedShareVal'] = parseFloat(rowReq.SignedShare__c).toFixed(6).replace('.',',');
                    if(rowReq.RiskCarrier__r != undefined){
                        rowReq['RiskCarrierName'] = this.dataSigningRequest[i].RiskCarrier__r.Name;
                    }
                    if(rowReq.FinancialEntity__r != undefined){
                        rowReq['FinancialName'] = this.dataSigningRequest[i].FinancialEntity__r.Name;
                    }
                    rowReq['loadingTextRisk'] = false;
                    rowReq['searchLookupRecordsRisk'] = [];
                    rowReq['messageFlagRisk'] = false;
                    rowReq['loadingTextFinancial'] = false;
                    rowReq['searchLookupRecordsFinancial'] = [];
                    rowReq['messageFlagFinancial'] = false;

                    if(rowReq.Pool__c != null && rowReq.Pool__c != undefined){
                        rowReq['isRequestPool'] = true;
                        rowReq['disableSignedShare'] = true;
                        rowReq['ReinsurerPoolName'] = rowReq.Pool__r.Name;
                        rowReq['ReinsurerOrPoolName'] = rowReq.Pool__r.Name;
                    }
                    else{
                        if(rowReq.Broker__c == null || rowReq.Broker__c == undefined){rowReq['disableRetro'] = true;}
                        else{rowReq['disableRetro'] = false;}
                        rowReq['isRequestPool'] = false;
                        rowReq['ReinsurerPoolName'] = rowReq.TECH_ReinsurerName__c;
                        rowReq['ReinsurerName'] = rowReq.TECH_ReinsurerName__c;
                        rowReq['ReinsurerOrPoolName'] = rowReq.TECH_ReinsurerName__c;
                        rowReq['ReinsurerPoolName'] = 'MarketSubmission?c__program=' + this.selectedProgram + '-' + rowReq.Id;
                        rowReq['isPremiumDisable'] = true;
                    }
                    if(rowReq.isRequestPool == false || rowReq.isRequestPool == undefined || rowReq.isRequestPool == null){
                        if(rowReq.ReinsurerStatus__c != 'Setup' && profileName != 'System Administrator' && profileName != 'AGRE_System Admin' && profileName != 'AGRE_Delegated Admin'){
                            rowReq['disableSignedShare'] = true;
                            isReinsurerStatusNotSetup = true;
                        }
                        else{this.requestsSetup.push(rowReq);}
                    }

                    console.log('this.requestsSetup 11== ', this.requestsSetup);

                    if(rowReq.ReinsurerStatus__c == 'Setup' && (rowReq.isRequestPool == false || rowReq.isRequestPool == undefined || rowReq.isRequestPool == null)){
                        isReinsurerStatusSetup = true;
                        rowReq['disableSignedShare'] = false;
                    }
                    if((rowReq.Treaty__r.TypeofTreaty__c == '3' || rowReq.Treaty__r.TypeofTreaty__c == '4') && (rowReq.Treaty__r.PremiumDeposit__c == 'Yes')){ rowReq['isPremiumDisable'] = false;}
                    if(rowReq.Treaty__r.Deductions__c == '2'){rowReq['disableDeduction'] = true;}
                    else{rowReq['disableDeduction'] = false;}
                    let lossDepositModeReqOpt;
                    let lossDepositModeReqUpd = [];
                    if(rowReq.Program__r.LossDepositLevel__c != undefined){
                         //RRA - ticket 1421 - 06062023
                        if (this.isProfileSuper){
                            for(let j = 0; j < this.lossDepositModeOpt.length; j++){
                                let row = { ...this.lossDepositModeOpt[j] };
                                lossDepositModeReqUpd.push(row);
                            }
                            rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd;
                         }else{
                            if(rowReq.Program__r.LossDepositLevel__c == 'Program'){
                                //RRA - ticket 1421 - 06062023
                                if(rowReq.Program__r.LossDeposit__c == '2'){
                                    rowReq['disableLossDepositMode'] = true;
                                }else if(rowReq.Program__r.LossDeposit__c == '1'){
                                    rowReq['disableLossDepositMode'] = false;
                                }
                                 //RRA - ticket 1554 - 28082023
                                if (rowReq.TECH_isAdmin__c){
                                    if (rowReq.Program__r.LossDepositMode__c.includes(rowReq.LossDepositMode__c)){
                                        lossDepositModeReqOpt = rowReq.Program__r.LossDepositMode__c; // Keep data on LossDepositMode__c from program if value exists in conditions
                                    }else{
                                        lossDepositModeReqOpt = rowReq.LossDepositMode__c + ';' + rowReq.Program__r.LossDepositMode__c; // Keep data on LossDepositMode__c from request if value not exists in conditions
                                    }
                                }else{
                                    lossDepositModeReqOpt = rowReq.Program__r.LossDepositMode__c; // Keep data on LossDepositMode__c from conditions
                                }
                            }
                            else if(rowReq.Program__r.LossDepositLevel__c == 'Treaty'){
                                if(rowReq.Treaty__r.LossDeposit__c == '2'){
                                    rowReq['disableLossDepositMode'] = true;
                                }else if(rowReq.Treaty__r.LossDeposit__c == '1'){
                                    rowReq['disableLossDepositMode'] = false;
                                }
                                
                                 //RRA - ticket 1554 - 28082023
                                 if (rowReq.TECH_isAdmin__c){
                                    if (rowReq.Treaty__r.LossDepositMode__c.includes(rowReq.LossDepositMode__c)){
                                        lossDepositModeReqOpt = rowReq.Treaty__r.LossDepositMode__c; // Keep data on LossDepositMode__c from program if value exists in conditions
                                    }else{
                                        lossDepositModeReqOpt = rowReq.LossDepositMode__c + ';' + rowReq.Treaty__r.LossDepositMode__c; // Keep data on LossDepositMode__c from request if value not exists in conditions
                                    }
                                }else{
                                    lossDepositModeReqOpt = rowReq.Treaty__r.LossDepositMode__c; // Keep data on LossDepositMode__c from conditions
                                }
                            }
                        }
                    }else{
                        //RRA - ticket 1421 - 31072023
                        if (this.isProfileSuper){
                            if (rowReq.Program__r.LossDeposit__c == '2'){
                                for(let j = 0; j < this.lossDepositModeOpt.length; j++){
                                    let row = { ...this.lossDepositModeOpt[j] };
                                    lossDepositModeReqUpd.push(row);
                                }
                                rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd; 
                            }
                         }else{
                            if (rowReq.Program__r.LossDeposit__c == '2'){
                                let emptyList = [];
                                if (rowReq.TECH_isAdmin__c){
                                    lossDepositModeReqOpt = rowReq.LossDepositMode__c;
                                    rowReq['LossDepositModeOpt'] = lossDepositModeReqOpt; 
                                }else{
                                    rowReq['LossDepositModeOpt'] = emptyList;
                                }
                                rowReq['disableLossDepositMode'] = true;
                            }else if(rowReq.Program__r.LossDeposit__c == '1'){
                                //RRA - ticket 1554 - 28082023
                                if (rowReq.TECH_isAdmin__c){
                                    if (rowReq.Program__r.LossDepositMode__c.includes(rowReq.LossDepositMode__c)){
                                        rowReq['LossDepositModeOpt'] = rowReq.Program__r.LossDepositMode__c; // Keep data on LossDepositMode__c from program if value exists in conditions
                                    }else{
                                        rowReq['LossDepositModeOpt'] = rowReq.LossDepositMode__c + ';' + rowReq.Program__r.LossDepositMode__c; // Keep data on LossDepositMode__c from request if value not exists in conditions
                                    }
                                }else{
                                    rowReq['LossDepositModeOpt']  = rowReq.Program__r.LossDepositMode__c; // Keep data on LossDepositMode__c from conditions
                                }                      
                                rowReq['disableLossDepositMode'] = false; 
                            }
                         }
                    }
                    if(lossDepositModeReqOpt != undefined){
                        let lossDepositModeExisted = lossDepositModeReqOpt.split(';');
                        let lossDepositModeReqUpd = [];

                        for(let i = 0; i < lossDepositModeExisted.length; i++){
                            for(let j = 0; j < this.lossDepositModeOpt.length; j++){
                                let row = { ...this.lossDepositModeOpt[j] };
                                if(row.value == lossDepositModeExisted[i]){
                                    lossDepositModeReqUpd.push(row);
                                }
                            }
                        }
                        rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd; 
                    }
                    if(rowReq.Pool__c != null){
                        updDataSigningPool.push(rowReq);
                    }
                    // HRA W-1289
                    if(rowReq.RiskCarrier__c != null && rowReq.FinancialEntity__c == null && !rowReq.disableFinancialEntity){
                        this.disableCopyRCToFC = false;// HRA W-1289
                    }
                    updDataSigningRequest.push(rowReq);
                }
                //1415
                if (lstSigningStatus.includes('1') || lstSigningStatus.includes('2') || lstSigningStatus.includes('3')){
                    this.disableThisButton = false;
                }else{
                    this.disableThisButton = true;
                }
                this.dataSigningRequest = updDataSigningRequest;
                this.calculateTotalSignedWrittenShare();

                if(renewed == 'Identical Renew'){this.disableReopenPreviousPhase = false;}
                else if(isReinsurerStatusNotSetup == true && this.isProfileSuper == false){this.disableReopenPreviousPhase = true;}
                else{this.disableReopenPreviousPhase = false;}

                if(isReinsurerStatusSetup == true || this.dataSigningRequest.length == 0){ this.disableUpdateRemind = true;}
                else{ this.disableUpdateRemind = false;}
                if(this.dataSigningRequest.length == 0 && this.isProfileSuper == false){ this.disableReopenPreviousPhase = true;}
                this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
                this.dataSigningPool = updDataSigningPool;
                this.error = undefined;
                this.spinnerSigningRequest = false;

                //Program - RRA - ticket 585 - 14032023
                if (isDeactivatedProg){
                    this.disableBtnSigning = true; 
                    this.disableBtnSend = true; 
                    this.disableReopenPreviousPhase = true; 
                    //this.hideWrittenToSignBtn = true;
                     this.isSetupIsAskValidationRequest = false;
                    this.disableThisButton = true;
                }else {
                    this.disableBtnSigning = false; 
                    this.disableBtnSend = false; 
                    if(isReinsurerStatusNotSetup == true && this.isProfileSuper == false){
                        this.disableReopenPreviousPhase = true;
                    }else if(this.dataSigningRequest.length == 0 && this.isProfileSuper == false){
                        this.disableReopenPreviousPhase = true;
                    }else{
                        this.disableReopenPreviousPhase = false;
                    }
                    //this.hideWrittenToSignBtn = false;
                }
            })
            .catch(error => {
                this.error = error;
                this.spinnerSigningRequest = false;
                this.disableUpdateRemind = true;
                this.closePreviousBtnClick = false;
            });
        }
        else{
            this.dataSigningRequest = [];
            this.titleCountSigningRequest = 'Signing Requests (' + this.dataSigningRequest.length + ')';
            this.spinnerSigningRequest = false;
            this.closePreviousBtnClick = false;
        }
        this.spinnerSigningRequest = false;
    }

	//AMI 01/06/22: W-0940
	    get hideWrittenToSignBtn(){
         console.log('isSetupIsAskValidationRequest hideWrittenToSignBtn == ', this.isSetupIsAskValidationRequest);
          return !this.isSetupIsAskValidationRequest;//MRA 14/07/2022 : W-0940
	    }
	
	    //AMI 01/06/22: W-0940
	    updateComponent(){
	        this.getSigningDetails();//MRA 14/07/2022 : W-0940
	    }
    calculateTotalSignedWrittenShare(){
        let inputs = this.template.querySelectorAll('lightning-input');
        let mapDataInput = [];
        let updDataSigningRequest = [];
        for(let input of inputs){
            if(input.name == 'SignedShare__c'){
                let id = input.id.split("-")[0];
                mapDataInput.push({key:id, value:input.value});
            }
        }
        for(let i = 0; i < this.dataSigningRequest.length; i++){
            let rowReq = { ...this.dataSigningRequest[i] };
            for(let j = 0; j < mapDataInput.length; j++){
                let reqId = mapDataInput[j].key;
                let dataInputValue = mapDataInput[j].value;
                if(rowReq.Id == reqId){
                    rowReq['SignedShare__c'] = parseFloat(dataInputValue);
                }
            }

            updDataSigningRequest.push(rowReq);
        }

        let mapLstRequestByTreatyId = new Map();
        for(let i = 0; i < updDataSigningRequest.length; i++){
            let rowReq = { ...updDataSigningRequest[i] };
            let lstRequestByTreaty = [];
            if(mapLstRequestByTreatyId.has(rowReq.Treaty__c)){
                lstRequestByTreaty = mapLstRequestByTreatyId.get(rowReq.Treaty__c);
            }
            lstRequestByTreaty.push(rowReq);
            mapLstRequestByTreatyId.set(rowReq.Treaty__c, lstRequestByTreaty);
        }

        let lstUpdSumRow = [];
        for(let [key, value] of mapLstRequestByTreatyId) {
            let lstRequest = value;
            let totalSignedShare = 0;
            let totalWrittenShare = 0;
            for(let i = 0; i < lstRequest.length; i++){
                if(lstRequest[i].SignedShare__c != undefined && lstRequest[i].SignedShare__c != null && !isNaN(lstRequest[i].SignedShare__c)){
                    totalSignedShare = parseFloat(totalSignedShare + lstRequest[i].SignedShare__c);
                }
                if(lstRequest[i].WrittenShare__c != undefined && lstRequest[i].WrittenShare__c != null && !isNaN(lstRequest[i].WrittenShare__c)){
                    totalWrittenShare = parseFloat(totalWrittenShare + lstRequest[i].WrittenShare__c);
                }
            }
            let totalSumRow = {};
            totalSumRow['TreatyId'] = key;
            totalSumRow['TotalWrittenShare'] = parseFloat(totalWrittenShare).toFixed(6).replace('.', ',');
            totalSumRow['TotalSignedShare'] = parseFloat(totalSignedShare).toFixed(6).replace('.', ',');
            lstUpdSumRow.push(totalSumRow);
        }

        for(let i = 0; i < this.dataSigningRequest.length; i++){
            for(let j = 0; j < lstUpdSumRow.length; j++){
                if(this.dataSigningRequest[i].Treaty__c == lstUpdSumRow[j].TreatyId){
                    this.dataSigningRequest[i]['TotalWrittenShare'] = lstUpdSumRow[j].TotalWrittenShare;
                    this.dataSigningRequest[i]['TotalSignedShare'] = lstUpdSumRow[j].TotalSignedShare;

                    if(parseFloat(this.dataSigningRequest[i].Treaty__r.PlacementShare_Perc__c) == parseFloat(lstUpdSumRow[j].TotalSignedShare.replace(',', '.'))){
                        this.dataSigningRequest[i]['PlacementShareEqualSignedShare'] = true;
                    }else if (parseFloat(this.dataSigningRequest[i].Treaty__r.CessionShare__c) == parseFloat(lstUpdSumRow[j].TotalSignedShare.replace(',', '.'))){//1966
                        this.dataSigningRequest[i]['PlacementShareEqualSignedShare'] = true;
                    }else{this.dataSigningRequest[i]['PlacementShareEqualSignedShare'] = false;
                    }
                }
            }
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BROKER_STATUS_FIELD})
    setBrokerStatusPicklistOptions({error, data}) {
        if(data){this.brokerStatusOpt = data.values;}
        else{this.error = error;}
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOSS_DEPOSIT_MODE_FIELD})
    setLossDepositModePicklistOptions({error, data}) {
        if(data){
            this.lossDepositModeOpt = data.values;
            if(this.dataSigningRequest != undefined){
                let updDataSigningRequest = [];
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    let lossDepositModeReqOpt;
                    if(rowReq.Program__r.LossDepositLevel__c != undefined){
                        if(rowReq.Program__r.LossDepositLevel__c == 'Program'){lossDepositModeReqOpt = rowReq.Program__r.LossDepositMode__c;}
                        else if(rowReq.Program__r.LossDepositLevel__c == 'Treaty'){lossDepositModeReqOpt = rowReq.Treaty__r.LossDepositMode__c;}
                    }
                    if(rowReq.Program__r.LossDepositLevel__c == undefined || rowReq.Program__r.LossDepositLevel__c == null){
                        rowReq['disableLossDepositMode'] = true;
                    }
                    if(lossDepositModeReqOpt != undefined){
                        let lossDepositModeExisted = lossDepositModeReqOpt.split(';');
                        let lossDepositModeReqUpd = [];
                        for(let i = 0; i < lossDepositModeExisted.length; i++){
                            for(let j = 0; j < this.lossDepositModeOpt.length; j++){
                                let row = { ...this.lossDepositModeOpt[j] };
                                if(row.value == lossDepositModeExisted[i]){
                                    lossDepositModeReqUpd.push(row);
                                }
                            }
                        }
                        rowReq['LossDepositModeOpt'] = lossDepositModeReqUpd;
                    }
                    updDataSigningRequest.push(rowReq);
                }
                this.dataSigningRequest = updDataSigningRequest;
                this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
            }
        }
        else{
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PREMIUM_DEPOSIT_FIELD})
    setPremiumDepositPicklistOptions({error, data}) {
        if(data){this.premiumDepositOpt = data.values;}
        else{this.error = error;}
    }

    handleChangeValue(event){
        this.isValueChange = true;
        let fieldName = event.currentTarget.name;
        let eventId = event.currentTarget.id;
        let value = event.currentTarget.value;
        let reqId = eventId.split('-')[0];
        let updDataSigningRequest = [];
        let lossDepositLevel;
        let lossDeposit;
        let selectedRowReinsurerPool;
        let selectedRowBroker;
        let isRequestPooll;

        if(fieldName == 'LossDepositMode__c'){
            this.lstIdReqOnChangeLossDeposit.push(reqId); //RRA - Ticket 1866 - 11012023
            if(this.dataSigningRequest[0].Program__r.LossDepositLevel__c != undefined){
                lossDepositLevel = this.dataSigningRequest[0].Program__r.LossDepositLevel__c;
            }
            
            if(this.dataSigningRequest[0].Program__r.LossDeposit__c != undefined){
                lossDeposit = this.dataSigningRequest[0].Program__r.LossDeposit__c;
            }
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                isRequestPooll = rowReq.isRequestPool;
                if(rowReq.Id == reqId){
                    if(rowReq.Broker__c != null && rowReq.Broker__c != undefined){selectedRowBroker = rowReq.Broker__c;}
                    if(rowReq.isRequestPool == true){selectedRowReinsurerPool = rowReq.Pool__c;}
                    else{selectedRowReinsurerPool = rowReq.Reinsurer__c;}
                }
            }

            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };

                if(lossDepositLevel == 'Program'){
                    let rowReinsurerPool;
                    if(rowReq.isRequestPool == true){rowReinsurerPool = rowReq.Pool__c;}
                    else{rowReinsurerPool = rowReq.Reinsurer__c;}

                    if(selectedRowBroker != null && selectedRowBroker != undefined){
                        if(rowReq.isRequestPool == true && rowReq.Broker__c == selectedRowBroker && rowReq.Pool__c == selectedRowReinsurerPool){
                            rowReq[fieldName] = value;
                        }
                        else if(rowReq.isRequestPool == false && rowReq.Broker__c == selectedRowBroker && rowReq.Reinsurer__c == selectedRowReinsurerPool){
                            rowReq[fieldName] = value;
                        }
                    }
                    else{
                        if(rowReq.isRequestPool == true && rowReq.Pool__c == selectedRowReinsurerPool){
                            rowReq[fieldName] = value;
                        }
                        else if(rowReq.isRequestPool == false && rowReq.Reinsurer__c == selectedRowReinsurerPool){
                            rowReq[fieldName] = value;
                        }
                    }
                }
                else if(lossDepositLevel == 'Treaty'){
                    if(rowReq.Id == reqId){
                        rowReq[fieldName] = value;
                    }
                }
                updDataSigningRequest.push(rowReq);
            }
            
            this.dataSigningRequest = updDataSigningRequest;
            this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
            
             //1397
             getListIdOrginalRequestNotNull({programId : this.selectedProgram, pcc : this.pcc, uwy : this.uwry, reinsurer : selectedRowReinsurerPool})
             .then(result => {;
                 //1421
                 if(result.isLossDepositModeTreatySetup){
                    if (lossDeposit == '1'){ 
                        if (lossDepositLevel == 'Program'){
                            this.lstIdReqOnChangeSetup = result.lstOrigReqNull;
                        }else if (lossDepositLevel == 'Treaty'){
                            if (result.lstOrigReqNull.includes(reqId)){
                                this.lstIdReqOnChangeSetup.push(reqId);
                                let removeDuplication = this.lstIdReqOnChangeSetup.filter((item,index) => this.lstIdReqOnChangeSetup.indexOf(item) === index);
                                this.lstIdReqOnChangeSetup = removeDuplication;
                             }
                        }
                    }else if (lossDeposit == '2'){ 
                        if (result.lstOrigReqNull.includes(reqId)){
                            this.lstIdReqOnChangeSetup.push(reqId);
                            let removeDuplication = this.lstIdReqOnChangeSetup.filter((item,index) => this.lstIdReqOnChangeSetup.indexOf(item) === index);
                            this.lstIdReqOnChangeSetup = removeDuplication;
                         }
                    }
                    
                 }else{
                     //1421
                     if (lossDeposit == '1'){
                        if (lossDepositLevel == 'Program'){
                            this.lstIdReqOnChange.push(result.lstOrigReqNotNull);
                         }else if (lossDepositLevel == 'Treaty'){
                            this.lstIdReqOnChange.push(reqId);
                            let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                            this.lstIdReqOnChange = removeDuplication;
                         }
                     }else if (lossDeposit == '2'){
                        this.lstIdReqOnChange.push(reqId);
                        let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                        this.lstIdReqOnChange = removeDuplication;
                     }
                 }
             })
             .catch(error => {this.error = error; });
        }
        else if(fieldName == 'SignedShare__c'){
            this.valSignedShareEmpty = value;//1415
            this.calculateTotalSignedWrittenShare();
            //1421
            if(this.dataSigningRequest[0].Program__r.LossDepositLevel__c != undefined){lossDepositLevel = this.dataSigningRequest[0].Program__r.LossDepositLevel__c;}
            if(this.dataSigningRequest[0].Program__r.LossDeposit__c != undefined){lossDeposit = this.dataSigningRequest[0].Program__r.LossDeposit__c;}
            getRequestResult({requestId : reqId, programId : this.selectedProgram})
            .then(result => { 
                let selectedReinsurer = result[0].Reinsurer__c;
                 getListIdOrginalRequestNotNull({programId : this.selectedProgram, pcc : this.pcc, uwy : this.uwry, reinsurer : selectedReinsurer})
                 .then(result => {
                    if(result.isLossDepositModeTreatySetup){
                        if (result.lstOrigReqNull.includes(reqId)){
                        this.lstIdReqOnChangeSetup.push(reqId);
                        let removeDuplication = this.lstIdReqOnChangeSetup.filter((item,index) => this.lstIdReqOnChangeSetup.indexOf(item) === index);
                        this.lstIdReqOnChangeSetup = removeDuplication;
                        }
                    }else{
                        if (lossDeposit == '1'){
                            if (lossDepositLevel == 'Program'){
                                this.lstIdReqOnChange.push(result.lstOrigReqNotNull);
                            }else if (lossDepositLevel == 'Treaty'){
                                this.lstIdReqOnChange.push(reqId);
                                let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                                this.lstIdReqOnChange = removeDuplication;
                            }
                        }else if (lossDeposit == '2'){
                                this.lstIdReqOnChange.push(reqId);
                                let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                                this.lstIdReqOnChange = removeDuplication;
                        }
                        
                    }
                 })
                 .catch(error => {this.error = error;});
            })
            .catch(error => {this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );});
        }
        if (fieldName == 'BrokerStatus__c'){ 
            //1421
            if(this.dataSigningRequest[0].Program__r.LossDepositLevel__c != undefined){ lossDepositLevel = this.dataSigningRequest[0].Program__r.LossDepositLevel__c;}
            if(this.dataSigningRequest[0].Program__r.LossDeposit__c != undefined){lossDeposit = this.dataSigningRequest[0].Program__r.LossDeposit__c; }
            getRequestResult({requestId : reqId, programId : this.selectedProgram})
            .then(result => { 
                let selectedBroker = result[0].Broker__c;
                let selectedReinsurer = result[0].Reinsurer__c;
                 //1397
                 getListIdOrginalRequestNotNull({programId : this.selectedProgram, pcc : this.pcc, uwy : this.uwry, reinsurer : selectedReinsurer})
                 .then(result => {
                     //1421
                    if(result.isLossDepositModeTreatySetup){
                        if (result.lstOrigReqNull.includes(reqId)){
                        this.lstIdReqOnChangeSetup.push(reqId);
                        let removeDuplication = this.lstIdReqOnChangeSetup.filter((item,index) => this.lstIdReqOnChangeSetup.indexOf(item) === index);
                        this.lstIdReqOnChangeSetup = removeDuplication;
                        }
                    }else{
                        //1421
                        if (lossDeposit == '1'){
                            if (lossDepositLevel == 'Program'){
                                this.lstIdReqOnChange.push(result.lstOrigReqNotNull);
                             }else if (lossDepositLevel == 'Treaty'){
                                this.lstIdReqOnChange.push(reqId);
                                let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                                this.lstIdReqOnChange = removeDuplication;
                             }
                        }else if (lossDeposit == '2'){
                            this.lstIdReqOnChange.push(reqId);
                            let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                            this.lstIdReqOnChange = removeDuplication;
                        }
                       
                    }
                 })
                 .catch(error => {
                     this.error = error;
                 });
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    if(selectedBroker != null && selectedReinsurer != undefined){
                        if (rowReq.Broker__c == selectedBroker && rowReq.Reinsurer__c == selectedReinsurer){
                            rowReq[fieldName] = value;
                            //RRA - ticket 1417 - 08082024
                            if (value == '2'){
                                rowReq.disableFinancialEntity = true;
                            }else if (value == '1'){
                                rowReq.disableFinancialEntity = false;
                            }
                            rowReq['FinancialEntity__c']=null;
                            rowReq['FinancialName']=null;
                            this.isValueChange = true;
                            this.saveFromBrokerStatus = true;
                            sessionStorage.setItem('isValueFinancialEntityEmpty', true);
                            this.lstIdReqUpdatedLastVers.push(rowReq.Id);
                        }
                    }else if (selectedBroker == null && selectedReinsurer != undefined){
                        if (rowReq.Broker__c == null && rowReq.Reinsurer__c == selectedReinsurer){
                            this.template.querySelectorAll('[data-id="' + rowReq.Id + '"]').forEach(currentItem => {
                                currentItem.disabled = false;
                          });
                        }
                    }
                    updDataSigningRequest.push(rowReq);
                }
                this.dataSigningRequest = updDataSigningRequest;
                this.saveSigningFromStatusBroker(this.dataSigningRequest);
                this.updateCopyRCToFCVisibility();
            })
            .catch(error => {this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );});
        }
        if (fieldName == 'RetrocessionBrokerage__c' || fieldName == 'PremiumDeposit__c' || fieldName == 'Deductions__c'){  //1397
            //1421
            if(this.dataSigningRequest[0].Program__r.LossDepositLevel__c != undefined){lossDepositLevel = this.dataSigningRequest[0].Program__r.LossDepositLevel__c;}  
            if(this.dataSigningRequest[0].Program__r.LossDeposit__c != undefined){lossDeposit = this.dataSigningRequest[0].Program__r.LossDeposit__c;}                                                                                                                       
            getRequestResult({requestId : reqId, programId : this.selectedProgram})
            .then(result => { 
                let selectedReinsurer = result[0].Reinsurer__c;
                 getListIdOrginalRequestNotNull({programId : this.selectedProgram, pcc : this.pcc, uwy : this.uwry, reinsurer : selectedReinsurer})
                 .then(result => {
                     //1421
                    if(result.isLossDepositModeTreatySetup){
                        if (result.lstOrigReqNull.includes(reqId)){
                        this.lstIdReqOnChangeSetup.push(reqId);
                        let removeDuplication = this.lstIdReqOnChangeSetup.filter((item,index) => this.lstIdReqOnChangeSetup.indexOf(item) === index);
                        this.lstIdReqOnChangeSetup = removeDuplication;
                        }
                    }else{
                        //1421
                        if (lossDeposit == '1'){
                            if (lossDepositLevel == 'Program'){
                                this.lstIdReqOnChange.push(result.lstOrigReqNotNull);
                             }else if (lossDepositLevel == 'Treaty'){
                                this.lstIdReqOnChange.push(reqId);
                                let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                                this.lstIdReqOnChange = removeDuplication;
                             }
                        }else if (lossDeposit == '2'){
                            this.lstIdReqOnChange.push(reqId);
                            let removeDuplication = this.lstIdReqOnChange.filter((item,index) => this.lstIdReqOnChange.indexOf(item) === index);
                            this.lstIdReqOnChange = removeDuplication;
                        }
                    }
                 })
                 .catch(error => {this.error = error;});
            })
            .catch(error => {this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );});
        }
    }
    //AMI 01/07/22 W:0947
    handleAllRequestSelections(event){
        //get all check box input
        let toggleList = this.template.querySelectorAll('[data-name^="toggle"]');
        for (let toggleElement of toggleList) {
            toggleElement.checked = event.target.checked;
            toggleElement.dispatchEvent(new Event('change'));
        }
    }
    
    saveSigningFromStatusBroker(dataSigningRequest){
        this.spinnerSigningRequest = true; 
        saveSigningRequestFrombrokerStatus({ lstDataSigning : dataSigningRequest})
            .then(result => {
                showToast(this, 'Success', 'success', 'Signing Request saved successfully.');
                this.spinnerSigningRequest = false; 
                this.lstIdReqUpdatedLastVers = [];//1417
                this.isValueChange = false;
            })
            .catch(error => {this.error = error;});
    }
    handleChangeRequestCheckbox(event){
        let eventId = event.currentTarget.id;
        let reqId = eventId.split('-')[0];
        let checkValue = event.currentTarget.checked;
        let updDataSigningRequest = [];
        let updLstSelectedSigningRequest = [];
        let updLstSelectedSigningReqId = [];

        for(let i = 0; i < this.dataSigningRequest.length; i++){
            let rowReq = { ...this.dataSigningRequest[i] };
            if(rowReq.Id == reqId){
                rowReq['isChecked'] = checkValue;
            }
            if(rowReq.isChecked == true){
                updLstSelectedSigningRequest.push(rowReq);
                updLstSelectedSigningReqId.push(rowReq.Id);
            }
            updDataSigningRequest.push(rowReq);
        }

        this.dataSigningRequest = updDataSigningRequest;
        this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
        this.lstSelectedSigningRequest = updLstSelectedSigningRequest;
        this.lstSelectedSigningReqId = updLstSelectedSigningReqId;
    }
    async handleSaveSigningRequest(event){
        let lstReqId = [];
        let lstReqIdSetup = []; 
        let lstReqIdFinal = []; 
        let lstIdReq;
        this.buttonNameClick = (this.saveFromBrokerStatus == false) ? event.currentTarget.name : 'save';
        //1421
        if(this.dataSigningRequest[0].Program__r.LossDepositLevel__c != undefined){this.lossDepositModeGlob = this.dataSigningRequest[0].Program__r.LossDepositLevel__c;}
        if(this.dataSigningRequest[0].Program__r.LossDeposit__c != undefined){this.lossDepositGlob = this.dataSigningRequest[0].Program__r.LossDeposit__c;}
        //1397
        this.spinnerSigningRequest = true;
        if(this.isValueChange == false && this.buttonNameClick != 'validate'){
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoChanges, variant: 'error' }),);
            this.spinnerSigningRequest = false;
            return;
        }
        else{
            if (this.lossDepositGlob == '1'){
                if (this.lossDepositModeGlob == 'Treaty'){
                    if (this.lstIdReqOnChange.length > 0){ 
                        lstReqId = this.lstIdReqOnChange;
                    }else if (this.lstIdReqOnChangeSetup.length > 0){ //1421
                        lstReqIdSetup = this.lstIdReqOnChangeSetup;
                    }
                    if (this.lstReqIdFinEnt.length > 0){
                        lstReqId = this.lstReqIdFinEnt;
                    }else if (this.lstReqIdFinEntSetup.length > 0){ //1421
                        lstReqIdSetup = this.lstReqIdFinEntSetup;
                    }
                    if (this.lstReqIdRiskCarr.length > 0){
                        lstReqId = this.lstReqIdRiskCarr;
                    }else if (this.lstReqIdRiskCarrSetup.length > 0){ //1421
                        lstReqIdSetup = this.lstReqIdRiskCarrSetup;
                    }
                    
                }else if (this.lossDepositModeGlob == 'Program'){
                    if (this.lstIdReqOnChange.length > 0){ 
                        for (let i=0;i<this.lstIdReqOnChange.length;i++){
                            lstReqId.push(this.lstIdReqOnChange[i]);
                        }
                    }else if (this.lstIdReqOnChangeSetup.length > 0){ //1421
                        lstReqIdSetup = this.lstIdReqOnChangeSetup;
                    }
                    
                    if (this.lstReqIdFinEnt.length > 0){
                        for (let i=0;i<this.lstReqIdFinEnt.length;i++){
                            lstReqId.push(this.lstReqIdFinEnt[i]);
                        }
                    }else if (this.lstReqIdFinEntSetup.length > 0){ //1421
                        lstReqIdSetup = this.lstReqIdFinEntSetup;
                    }
                    
                    if (this.lstReqIdRiskCarr.length > 0){
                        for (let i=0;i<this.lstReqIdRiskCarr.length;i++){
                            lstReqId.push(this.lstReqIdRiskCarr[i]);
                        }
                    }else if (this.lstReqIdRiskCarrSetup.length > 0){ //1421
                        lstReqIdSetup = this.lstReqIdRiskCarrSetup;
                    }
                }
            }else if (this.lossDepositGlob == '2'){
                if (this.lstIdReqOnChange.length > 0){ // onChange on brokerSattus
                    lstReqId = this.lstIdReqOnChange;
                }else if (this.lstIdReqOnChangeSetup.length > 0){ //RRA - ticket 1421 - 08092023
                    lstReqIdSetup = this.lstIdReqOnChangeSetup;
                }
                if (this.lstReqIdFinEnt.length > 0){ // onChange on finacial entity
                    lstReqId = this.lstReqIdFinEnt;
                }else if (this.lstReqIdFinEntSetup.length > 0){ //RRA - ticket 1421 - 08092023
                    lstReqIdSetup = this.lstReqIdFinEntSetup;
                }
                if (this.lstReqIdRiskCarr.length > 0){ // onChange on risk Carrier
                    lstReqId = this.lstReqIdRiskCarr;
                }else if (this.lstReqIdRiskCarrSetup.length > 0){ //RRA - ticket 1421 - 08092023
                    lstReqIdSetup = this.lstReqIdRiskCarrSetup;
                }
            }

            if (this.lossDepositGlob == '1' && this.lossDepositModeGlob == 'Program'){
                    //RRA - ticket 1421 - 08092023
                if (lstReqId.length > 0){ 
                    for (let i=0;i<lstReqId.length;i++){
                        for (let j=0;j<lstReqId[i].length;j++){   
                            lstReqIdFinal.push(lstReqId[i][j]);
                        }
                    }
                }else if (lstReqIdSetup.length > 0){ 
                    lstReqIdFinal = lstReqIdSetup;
                }
            }else if ((this.lossDepositGlob == '1' && this.lossDepositModeGlob == 'Treaty') || this.lossDepositGlob == '2'){
                if (lstReqId.length > 0){
                        lstReqIdFinal = lstReqId;
                }else if (lstReqIdSetup.length > 0){ 
                    lstReqIdFinal = lstReqIdSetup;
                }
            }
            lstIdReq = JSON.parse(JSON.stringify(lstReqIdFinal));
            const allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
            if(allValid) {
                this.isSave = true;
                this.isAskToSave = false;
                let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
                let mapDataInput = [];
                let updDataSigningRequest = [];
                for(let input of inputs){
                    if(input.name != 'Checkbox'){
                        let id = input.id.split("-")[0];
                        let nameId = id + '-' + input.name;
                        mapDataInput.push({key:nameId, value:input.value});
                    }
                }
                for(let i = 0; i < this.dataSigningRequest.length; i++){
                    let rowReq = { ...this.dataSigningRequest[i] };
                    for(let j = 0; j < mapDataInput.length; j++){
                        let reqId = mapDataInput[j].key.split('-')[0];
                        let dataInputName = mapDataInput[j].key.split('-')[1];
                        let dataInputValue = mapDataInput[j].value;
                        if(rowReq.Id == reqId){
                            if(dataInputName == 'SignedShare__c' || dataInputName == 'Deductions__c' || dataInputName == 'RetrocessionBrokerage__c'){
                                rowReq[dataInputName] = parseFloat(dataInputValue);
                            }
                            else{
                                rowReq[dataInputName] = dataInputValue;
                            }
                        }
                    }

                    updDataSigningRequest.push(rowReq);
                }
                this.dataSigningRequest = updDataSigningRequest;
                this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');
                //RRA - ticket 1421 - 31082023 -  Get list Id for the same broker / reinsurer with treaty different
                await getListIdRequest({lstIdOriginalRequest : lstIdReq})
                .then( async result => {
                    let lstReqIdFinal = result;
                    //RRA - 1104 - 03/06/2022
                    await saveSigningRequest({ lstRequest : this.dataSigningRequest, lstIdReqId : lstIdReq, lstReqId : lstReqIdFinal, lossDepositMode : this.lossDepositModeGlob, lstIdReqOnChangeLossDep : this.lstIdReqOnChangeLossDeposit, lstIdReqFinRiskToUpdated : this.lstIdReqUpdatedLastVers, lstIdReqFromRiskCarrierChanged : this.lstIdRiskCarrierChanged}) //RRA - ticket 1421 - 31082023 - RRA - Ticket 1866 - 11012023 - 1417 - RRA - ticket 2304 - 12/02/2025
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                            this.spinnerSigningRequest = false;
                        }
                        else{
                            // SRA - ticket 860 => Refresh Signing - Bouton save
                            if(this.buttonNameClick == 'save' || this.buttonNameClick == 'yes'){
                                this.clickBtnAskForValidation = false;  //RRA - ticket 2229 - 26/12/2024
                                // SRA - ticket 860 
                                refreshApex(result.data);
                                showToast(this, 'Success', 'success', 'Signing Request saved successfully.');
                                this.spinnerSigningRequest = false;
                                if (this.valSignedShareEmpty == ''){window.location.reload();}//1415
                                this.setIdReq.clear(); // RRA 30/05/2022
                                this.lstIdReqUpdatedLastVers = [];//1417
                            }
                            else if(this.buttonNameClick == 'WrittenShareToSigned'){
                                this.clickBtnAskForValidation = false;  //RRA - ticket 2229 - 26/12/2024
                                this.updateWrittenSignedShare();
                                this.spinnerSigningRequest = false;
                                this.setIdReq.clear(); // RRA 30/05/2022
                            }
                            else if(this.buttonNameClick == 'Send' || this.buttonNameClick == 'Update' || this.buttonNameClick == 'Remind'){
                                this.clickBtnAskForValidation = false;
                                this.checkRequestBeforeSendUpdateRemind(this.buttonNameClick);
                            }
                            else if(this.buttonNameClick == 'ReopenPreviousPhases'){
                                this.clickBtnAskForValidation = false;  //RRA - ticket 2229 - 26/12/2024
                                let programStageValue =   this.selectedProgram + '-Placement';
                                fireEvent(this.pageRef, 'updateStageName', programStageValue);
                                this.reopenPreviousPhase();
                            }
                            else if(this.buttonNameClick == 'CloseSigningNotifyWebXL'){
                                this.clickBtnAskForValidation = false;  //RRA - ticket 2229 - 26/12/2024
                                this.closeSigningNotifyWebXL();
                            }
                            else if(this.buttonNameClick == 'ReopenSigning'){
                                this.clickBtnAskForValidation = false;  //RRA - ticket 2229 - 26/12/2024
                                this.reopenSigningRequest();
                            }
                            else{
                                this.spinnerSigningRequest = false;
                            }
                            this.buttonNameClick = null;
                            //init flow CLM Sync
                            getAgreements({programId : this.selectedProgram})
                            .then(result => {
                            });
                        }
                        this.lstIdReqOnChangeLossDeposit = []; //RRA - Ticket 1866 - 12012024
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.errorMsg, variant: 'error'}), );
                        this.spinnerSigningRequest = false;
                    });

                     //RRA - ticket 2229 - 26/12/2024 - Only for Ask for Validation
                    if (this.allowAskForValidation == true && this.clickBtnAskForValidation == true){
                      
                      let placementShareNotEqualtoSignedShare = false;
                      let cessionShareNotEqualtoSignedShare = false;
                       let totalSignedShare = 0;


                      /*for (let i=0;i<this.dataSigningRequest.length;i++){
                       
                        let rowReq = {...this.dataSigningRequest[i]};

                        totalSignedShare = totalSignedShare + rowReq.SignedShare__c;
                         console.log('totalSignedShare in == ', totalSignedShare);
                      }*/


                         let mapLstRequestByTreatyId = new Map();
                        let mapTreatyIdValueShare = new Map();
                        for(let i = 0; i < this.dataSigningRequest.length; i++){
                            let rowReq = { ...this.dataSigningRequest[i] };
                            let lstRequestByTreaty = [];

                            //RRA - ticekt 2229 - 024/01/2025
                            if (rowReq.Treaty__r.PlacementShare_Perc__c != undefined){
                                 mapTreatyIdValueShare.set(rowReq.Treaty__c, rowReq.Treaty__r.PlacementShare_Perc__c);
                            }
                            if(rowReq.Treaty__r.CessionShare__c != undefined){
                                mapTreatyIdValueShare.set(rowReq.Treaty__c, rowReq.Treaty__r.CessionShare__c);
                            }
                          
                            if(mapLstRequestByTreatyId.has(rowReq.Treaty__c)){
                                lstRequestByTreaty = mapLstRequestByTreatyId.get(rowReq.Treaty__c);
                            }
                            lstRequestByTreaty.push(rowReq);
                            mapLstRequestByTreatyId.set(rowReq.Treaty__c, lstRequestByTreaty);
                        }
                         
                         console.log('mapTreatyIdValueShare ext== ', mapTreatyIdValueShare);
                         console.log('mapLstRequestByTreatyId ext== ', mapLstRequestByTreatyId);

                        let lstUpdSumRow = [];//sum signedShare  by row signing req
                        for(let [key, value] of mapLstRequestByTreatyId) {
                            let lstRequest = value;
                            let totalSignedShare = 0;
                            for(let i = 0; i < lstRequest.length; i++){
                                if(lstRequest[i].SignedShare__c != undefined && lstRequest[i].SignedShare__c != null && !isNaN(lstRequest[i].SignedShare__c)){
                                    totalSignedShare = parseFloat(totalSignedShare + lstRequest[i].SignedShare__c);
                                }
                            }

                            console.log('totalSignedShare ext== ', totalSignedShare);
                            let totalSumRow = {};
                            totalSumRow['TreatyId'] = key;
                            totalSumRow['TotalSignedShare'] = totalSignedShare;
                            lstUpdSumRow.push(totalSumRow);
                        }

                         console.log('lstUpdSumRow ext== ', lstUpdSumRow);
                         console.log('placementShareNotEqualtoSignedShare bef== ', placementShareNotEqualtoSignedShare);
                         console.log('cessionShareNotEqualtoSignedShare bef== ', cessionShareNotEqualtoSignedShare);

                      if (lstUpdSumRow.length>0){
                         lstUpdSumRow.forEach(sumRowSignedShare => {
                          console.log('valueShare Placement Or Cession Share== ', mapTreatyIdValueShare.get(sumRowSignedShare.TreatyId));
                             //Step 1 :Check value of placement Share or/and Cession Share
                          if(mapTreatyIdValueShare.get(sumRowSignedShare.TreatyId) != undefined && mapTreatyIdValueShare.get(sumRowSignedShare.TreatyId) != sumRowSignedShare.TotalSignedShare){
                            placementShareNotEqualtoSignedShare = true;
                            return;
                          }else if (mapTreatyIdValueShare.get(sumRowSignedShare.TreatyId) != undefined && mapTreatyIdValueShare.get(sumRowSignedShare.TreatyId) != sumRowSignedShare.TotalSignedShare){
                              cessionShareNotEqualtoSignedShare = true;
                            return;
                          }
                        });
                    }

                      console.log('placementShareNotEqualtoSignedShare aft== ', placementShareNotEqualtoSignedShare);
                         console.log('cessionShareNotEqualtoSignedShare aft== ', cessionShareNotEqualtoSignedShare);

                      //Step2 : Display the error message if step1 exists
                      if(placementShareNotEqualtoSignedShare && cessionShareNotEqualtoSignedShare == false){
                          this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingPlacementS, variant: 'error',}), );
                      }else if(cessionShareNotEqualtoSignedShare && placementShareNotEqualtoSignedShare == false){
                          this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingCessionS, variant: 'error',}), );
                      }else if(cessionShareNotEqualtoSignedShare && placementShareNotEqualtoSignedShare){
                          this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingCessionPlacementS, variant: 'error',}), );
                      }else{
                        this.isOpenConfirmation = true;
                        this.isValidate = true;
                        this.closePreviousBtnClick ==  false;
                      } 
                    }
                })
                .catch(error => {
                    this.error = error;
                });
                if(this.isPhaseChange == true){
                    fireEvent(this.pageRef, 'updateStageName', this.programStageValueChange);
                }
                this.isSave = false;
            }
            else{
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.FormEntriesInvalid, variant: 'error'}), );
                this.spinnerSigningRequest = false;
            }
        }
        this.isValueChange = false;
        this.isOpenConfirmation = false;
        this.isPhaseChange = false;
    }
    handleOnClickWrittenSignedBtn(){
         this.buttonNameClick = 'WrittenShareToSigned';
        //RRA - 1397 - 06012023
        this.spinnerSigningRequest = true;
        if(this.isValueChange == true){
            this.isWrite = true;
            this.isOpenConfirmation = true;
            this.isAskToSave = true;
        }
        else{this.updateWrittenSignedShare();}
    }

    handleOpenSendUpdateRemindModal(event){
        this.buttonNameClick = event.currentTarget.name;
        this.btnNameSendUpdateRemind = event.currentTarget.name;
        if(this.isValueChange == true){
            this.isOpenConfirmation = true;
            this.isAskToSave = true;
            this.isSave = false;
        }
        else{
            this.checkRequestBeforeSendUpdateRemind(event.currentTarget.name);
        }
    }
    checkRequestBeforeSendUpdateRemind(btnNameClick){
        let doesReqNotSentForRemind = false;
        let doesSelectedRequestHasSetup = false;
        this.spinnerSigningRequest = true;
        this.closePreviousBtnClick =  false; //RRA - ticket 1397 - 17012023
        let isAskValidation; //RRA - ticket 01411 - 03042023
        let isAskValidationbyDeputyCEO; //RRA - ticket 01411 - 03042023

        if(btnNameClick == 'Send'){
            this.lstSelectedSigningRequest = this.dataSigningRequest;
            //to send request for only status 'Setup'
            let lstSigningRequestSetup = [];

            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                isAskValidation = rowReq.isAskValidation__c;//RRA - ticket 01411 - 03042023
                isAskValidationbyDeputyCEO = rowReq.isAskValidateByDirecteur__c;//RRA - ticket 01411 - 03042023
                if(rowReq.ReinsurerStatus__c == 'Setup'){
                    lstSigningRequestSetup.push(rowReq);
                }
            }
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq.ReinsurerStatus__c == 'Setup'){
                    lstSigningRequestSetup.push(rowReq);
                }
            }

            this.lstSelectedSigningRequest = lstSigningRequestSetup;
        }
        let selectedRequests = this.lstSelectedSigningRequest;
        let arr1 = [];

        for(var key in selectedRequests){
            let ele = selectedRequests[key];
            let obj = {};
            obj.Broker = ele.Broker__c;
            obj.Reinsurer = ele.Reinsurer__c;
            obj.brokerRein = ele.Broker__c+'-'+ele.Reinsurer__c;

            if(btnNameClick == 'Send' ||
               (btnNameClick == 'Update' && (ele.ReinsurerStatus__c == 'Sent' || ele.ReinsurerStatus__c == 'Timeout'))){
                arr1.push(obj);
            }
            else if(btnNameClick == 'Remind'){
                //You can't send a remind because at least one request is not 'Sent'
                if(ele.ReinsurerStatus__c != 'Sent'){
                    doesReqNotSentForRemind = true;
                }
                else{
                    arr1.push(obj);
                }
            }

            if(ele.ReinsurerStatus__c == 'Setup'){
                doesSelectedRequestHasSetup = true;
            }
        }

        if(btnNameClick == 'Send'){
            let requestHasNoSignedShareReq = false; //to check if all requests have signed share
            let mapLstRequestByTreatyId = new Map();
            let placementShareNotEqualtoSignedShare = false;
            let cessionShareNotEqualtoSignedShare = false
            let isFXrateExist = false;
            let lstRequestTreaty = [];

            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                let lstRequestByTreaty = [];
                if(rowReq.Treaty__c != null || rowReq.Treaty__c != undefined){
                    lstRequestTreaty.push(rowReq.Treaty__c)
                }
                if(rowReq.SignedShare__c == null || rowReq.SignedShare__c == undefined || Number.isNaN(rowReq.SignedShare__c) == true){
                    requestHasNoSignedShareReq = true;
                }
                if(mapLstRequestByTreatyId.has(rowReq.Treaty__c)){
                    lstRequestByTreaty = mapLstRequestByTreatyId.get(rowReq.Treaty__c);
                }
                lstRequestByTreaty.push(rowReq);
                mapLstRequestByTreatyId.set(rowReq.Treaty__c, lstRequestByTreaty);
            }
            for (let [key, value] of mapLstRequestByTreatyId) {
                let lstRequest = value;
                let totalSignedShare = 0;

                for(let i = 0; i < lstRequest.length; i++){
                    totalSignedShare = totalSignedShare + lstRequest[i].SignedShare__c;
                }
                totalSignedShare =  parseFloat(totalSignedShare).toFixed(6);
                if(lstRequest[0].Treaty__r.PlacementShare_Perc__c != totalSignedShare && lstRequest[0].Treaty__r.PlacementShare_Perc__c !== undefined){
                    placementShareNotEqualtoSignedShare = true;
                }else if(lstRequest[0].Treaty__r.CessionShare__c != totalSignedShare && lstRequest[0].Treaty__r.CessionShare__c !== undefined){//1966
                    cessionShareNotEqualtoSignedShare = true;
                }
            }
            //RRA - 1088
            checkFXRATEifExists({programId : this.selectedProgram, lstRequestTreatyId : lstRequestTreaty})
            .then(result => { 
                if (result != null){isFXrateExist = true}
                else {isFXrateExist;}
                if(arr1.length == 0){
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoSigningRequestSetupPresent, variant: 'error',}), );
                }
                else if(isFXrateExist == false){
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SigningRequestNoFXRate, variant: 'error',}), );
                }
                else if(requestHasNoSignedShareReq == true){
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SigningRequestNoSignedShare, variant: 'error',}), );
                }
                
                else if(placementShareNotEqualtoSignedShare && cessionShareNotEqualtoSignedShare == false){//1966
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingPlacementS, variant: 'error',}), );
                }else if(cessionShareNotEqualtoSignedShare && placementShareNotEqualtoSignedShare == false){//1966
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingCessionS, variant: 'error',}), );
                }else if(cessionShareNotEqualtoSignedShare && placementShareNotEqualtoSignedShare){//1966
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingCessionPlacementS, variant: 'error',}), );
                }
                else if(this.allowAskForValidation == true && (isAskValidation == false || isAskValidation) && isAskValidationbyDeputyCEO == false){//RRA - ticket 1827 - 07122023
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    // The Premium exceeds your authorization for signing, please click the 'Ask for Validation' button
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.Premium_exceeds_authorization_for_signing, variant: 'error',}), );
                }
                else if(this.contractualDocSigningPresent == false){
                    this.dataSigningRequest = [];
                    this.getSigningDetails();
                    this.lstSelectedSigningRequest = [];
                    // There is no contractual document attached, please add at least one
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoContractualDocumentAttached, variant: 'error',}), );
                }
                else{
                    this.isSendUpdateRemindSigningReqOpenModal = true;
                    this.titlePopUp = this.btnNameSendUpdateRemind + ' Signing Request(s)';
                    this.spinnerSigningRequest = false;
                }
            });
        }
        else{
            if(this.lstSelectedSigningRequest.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoSigningRequestSelected, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else if(btnNameClick == 'Update' && doesSelectedRequestHasSetup == true){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SigningRequestStatusSetup, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else if(btnNameClick == 'Update' && arr1.length == 0){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoSigningRequest_ReinsurerStatus_Sent_or_Timeout, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else if(btnNameClick == 'Remind' && doesReqNotSentForRemind == true){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.CannotRemind_RequestNotSent, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else{
                this.isSendUpdateRemindSigningReqOpenModal = true;
                this.lstSelectedSigningRequest1 =  arr1;
                this.titlePopUp = this.btnNameSendUpdateRemind + ' Signing Request(s)';
                this.spinnerSigningRequest = false;
            }
        }
        this.buttonNameClick = '';
    }
    //utils ?
    sendUpdateRemindSigningRequest(btnName){
        let arr1 = [];
        this.lstSelectedSigningRequest = this.dataSigningRequest;
        let selectedRequests = this.lstSelectedSigningRequest;
        for(var key in selectedRequests){
           let ele = selectedRequests[key];
           let obj = {};
           obj.Broker = ele.Broker__c;
           obj.Reinsurer = ele.Reinsurer__c;
           obj.brokerRein = ele.Broker__c+'-'+ele.Reinsurer__c;
           arr1.push(obj);
        }
        if(btnName == 'Send'){
            let requestHasNoSignedShareReq = false; //to check if all request has sign share
            let mapLstRequestByTreatyId = new Map();
            let placementShareNotEqualtoSignedShare = false;
            let cessionShareNotEqualtoSignedShare = false;
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                let lstRequestByTreaty = [];
                if(rowReq.SignedShare__c == null || rowReq.SignedShare__c == undefined || Number.isNaN(rowReq.SignedShare__c) == true){
                    requestHasNoSignedShareReq = true;
                }
                if(mapLstRequestByTreatyId.has(rowReq.Treaty__c)){
                    lstRequestByTreaty = mapLstRequestByTreatyId.get(rowReq.Treaty__c);
                }
                lstRequestByTreaty.push(rowReq);
                mapLstRequestByTreatyId.set(rowReq.Treaty__c, lstRequestByTreaty);
            }

            for (let [key, value] of mapLstRequestByTreatyId) {
                let lstRequest = value;
                let totalSignedShare = 0;
                for(let i = 0; i < lstRequest.length; i++){
                    totalSignedShare = totalSignedShare + lstRequest[i].SignedShare__c;
                }
                totalSignedShare =  parseFloat(totalSignedShare).toFixed(6);
                if(lstRequest[0].Treaty__r.PlacementShare_Perc__c != totalSignedShare){
                    placementShareNotEqualtoSignedShare = true;
                }else if (lstRequest[0].Treaty__r.CessionShare__c != totalSignedShare){//1966
                    cessionShareNotEqualtoSignedShare = true;
                }
            }
            if(requestHasNoSignedShareReq == true){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SigningRequestNoSignedShare, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else if(placementShareNotEqualtoSignedShare && cessionShareNotEqualtoSignedShare == false ){//1966
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingPlacementS , variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }else if(cessionShareNotEqualtoSignedShare && placementShareNotEqualtoSignedShare == false){//1966
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingCessionS , variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }else if(cessionShareNotEqualtoSignedShare && placementShareNotEqualtoSignedShare){//1966
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.SignedShareNotMatchingCessionPlacementS , variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else if(this.allowAskForValidation == true){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.Premium_exceeds_authorization_for_signing, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else if(this.contractualDocSigningPresent == false){
                // There is no contractual document attached, please add at least one
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoContractualDocumentAttached, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else{
                this.isSendUpdateRemindSigningReqOpenModal = true;
                this.lstSelectedSigningRequest1 =  arr1;
                this.titlePopUp = this.btnNameSendUpdateRemind + ' Signing Request(s)';
            }
        }
        else{
            this.isSendUpdateRemindSigningReqOpenModal = true;
            this.lstSelectedSigningRequest1 =  arr1;
            this.isAskToSave = false;
        }
    }
    

    closeSendUpdateRemindReqModal(val){
        this.isSendUpdateRemindSigningReqOpenModal = false;
        this.lstSelectedSigningRequest = [];
        this.send = false;
        this.update = false;
        this.isAskToSave = false;
        this.dataSigningRequest = [];

        //AMI 01/07/22 W:0947
        if (this.template.querySelector('[data-id="gToggle"]') !== undefined && this.template.querySelector('[data-id="gToggle"]') !== null) {//MRA W-1233
            this.template.querySelector('[data-id="gToggle"]').checked = false;
        }
        this.getSigningDetails();
    }

    handleCloseSendUpdateRemindModal(){
        this.isSendUpdateRemindSigningReqOpenModal = false; 
        this.lstSelectedSigningRequest = [];
        this.send = false;
        this.update = false;
        this.isAskToSave = false;
        this.dataSigningRequest = [];
        if (this.template.querySelector('[data-id="gToggle"]') !== undefined && this.template.querySelector('[data-id="gToggle"]') !== null)//MRA W-1233
        this.template.querySelector('[data-id="gToggle"]').checked = false;

        this.getSigningDetails();
    }

    async handleOnClickValidationBtn(event){
        let isAskValidation = false;
        this.clickBtnAskForValidation = true;
        if(this.allowAskForValidation == true){
            //1263
            if(this.contractualDocSigningPresent == false){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.NoContractualDocumentAttached, variant: 'error',}), );
                this.spinnerSigningRequest = false;
            }
            else{
                //1411
                for (let i=0;i<this.dataSigningRequest.length;i++){
                    let rowReq = {...this.dataSigningRequest[i]};
                    console.log('rowReq.isAskValidation__c == ', rowReq.isAskValidation__c);
                    if (rowReq.isAskValidation__c){
                        isAskValidation = true;
                    }
                }

                if (isAskValidation){
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.askValidationImpossible, variant: 'error',}), );
                }else{
                    //RRA - ticket 2229 - 26/12/2024
                    await this.handleSaveSigningRequest(event); // HRA 	W-1874                      
                }
            }
        }
        else{this.dispatchEvent(new ShowToastEvent({message: label.NoNeedToAskForValidation, variant: 'Info' }),);}
    }
         
    handleOnClickCloseSigningNotifyWebXLBtn(){
        if(this.isValueChange == true){
            this.isOpenConfirmation = true;
            this.isSave = false;
            this.isAskToSave = true;
        }
        else{this.closeSigningNotifyWebXL();}
    }

    closeSigningNotifyWebXL(){
        let lstSigningReqId = [];
        let lstIdReqLastVersion = [];
        let canClose = true;
        this.closePreviousBtnClick =  false;  
        for(let i = 0; i < this.dataSigningRequest.length; i++){
            lstIdReqLastVersion.push(this.dataSigningRequest[i].OriginalRequest__c);
            lstSigningReqId.push(this.dataSigningRequest[i].Id);
        } 
        checkValueOnGetSigningDetails({lstIdReqLastVers : lstIdReqLastVersion})
            .then(dataSigningRequest => {         
                for(let i = 0; i < dataSigningRequest.length; i++){                     
                    //1415
                    //Broker part 
                    if ((dataSigningRequest[i].Broker__c != null || dataSigningRequest[i].Broker__c != undefined) && //it's row of Broker
                        (dataSigningRequest[i].BrokerStatus__c != null || dataSigningRequest[i].BrokerStatus__c != undefined) && 
                        (dataSigningRequest[i].LossDeposit__c == '1' && (dataSigningRequest[i].Program__r.LossDepositLevel__c == undefined || dataSigningRequest[i].Program__r.LossDepositLevel__c == 'Program' || dataSigningRequest[i].Program__r.LossDepositLevel__c == 'Treaty') && 
                        (dataSigningRequest[i].LossDepositMode__c != null || dataSigningRequest[i].LossDepositMode__c != undefined))){//=> it's first case of LossDeposit (LossDep : Yes - LossLevel : Program - LossDepMode : Not Null)
                        if (dataSigningRequest[i].RiskCarrier__c == null || dataSigningRequest[i].RiskCarrier__c == undefined){canClose = false;
                            break;
                        }else{
                            if ((dataSigningRequest[i].FinancialEntity__c == null || dataSigningRequest[i].FinancialEntity__c == undefined) && dataSigningRequest[i].BrokerStatus__c == '1'){canClose = false;
                                break;
                            }else {
                                if (dataSigningRequest[i].SignedShare__c == null || dataSigningRequest[i].SignedShare__c == undefined ||(Number.isNaN(dataSigningRequest[i].SignedShare__c) == true)) {canClose = false;
                                    break;
                                }else{
                                    if (dataSigningRequest[i].Deductions__c == null || dataSigningRequest[i].Deductions__c == undefined ||(Number.isNaN(dataSigningRequest[i].Deductions__c) == true)){canClose = false;
                                        break;
                                    }else{
                                        if (dataSigningRequest[i].RetrocessionBrokerage__c == null || dataSigningRequest[i].RetrocessionBrokerage__c == undefined ||(Number.isNaN(dataSigningRequest[i].RetrocessionBrokerage__c) == true)){canClose = false;
                                            break;
                                        }else{
                                            if (dataSigningRequest[i].PremiumDeposit__c == null || dataSigningRequest[i].PremiumDeposit__c == undefined){
                                                if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '2' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '1'){
                                                    canClose = true; 
                                                }else if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '3' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '4' ||  dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '5'){canClose = false;
                                                    break;
                                                }
                                            }else{canClose = true;   
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else if ((dataSigningRequest[i].Broker__c != null || dataSigningRequest[i].Broker__c != undefined) && //it's row of Broker
                    (dataSigningRequest[i].BrokerStatus__c != null || dataSigningRequest[i].BrokerStatus__c != undefined) && 
                    (dataSigningRequest[i].LossDeposit__c == '2' && (dataSigningRequest[i].LossDepositMode__c == null || dataSigningRequest[i].LossDepositMode__c == undefined))){//=> it's third case of LossDeposit  (LossDep : No - LossDepMode : Null)
                        if (dataSigningRequest[i].RiskCarrier__c == null || dataSigningRequest[i].RiskCarrier__c == undefined){
                            canClose = false;
                            break;
                        }else{
                            if ((dataSigningRequest[i].FinancialEntity__c == null || dataSigningRequest[i].FinancialEntity__c == undefined) && dataSigningRequest[i].BrokerStatus__c == '1'){canClose = false;
                                break;
                            }else {
                                if (dataSigningRequest[i].SignedShare__c == null || dataSigningRequest[i].SignedShare__c == undefined ||(Number.isNaN(dataSigningRequest[i].SignedShare__c) == true)) {canClose = false;
                                    break;
                                }else{
                                    if (dataSigningRequest[i].Deductions__c == null || dataSigningRequest[i].Deductions__c == undefined ||(Number.isNaN(dataSigningRequest[i].Deductions__c) == true)) { canClose = false;
                                        break;
                                    }else{
                                        if (dataSigningRequest[i].RetrocessionBrokerage__c == null || dataSigningRequest[i].RetrocessionBrokerage__c == undefined ||(Number.isNaN(dataSigningRequest[i].RetrocessionBrokerage__c) == true)){canClose = false;
                                            break;
                                        }else{
                                            if (dataSigningRequest[i].PremiumDeposit__c == null || dataSigningRequest[i].PremiumDeposit__c == undefined){
                                                if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '2' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '1'){canClose = true; 
                                                }else if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '3' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '4' ||  dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '5'){canClose = false;
                                                    break;
                                                }
                                            }else{canClose = true; 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //RRA - ticket 1415 - 16022023
                    //Reinsurer Part
                    else if ((dataSigningRequest[i].BrokerStatus__c == null || dataSigningRequest[i].BrokerStatus__c == undefined) && //it's row of reinsurer
                            (dataSigningRequest[i].LossDeposit__c == '1' && (dataSigningRequest[i].Program__r.LossDepositLevel__c == undefined || dataSigningRequest[i].Program__r.LossDepositLevel__c == 'Program' || dataSigningRequest[i].Program__r.LossDepositLevel__c == 'Treaty') && (dataSigningRequest[i].LossDepositMode__c != null || dataSigningRequest[i].LossDepositMode__c != undefined))){//=> it's first case of LossDeposit (LossDep : Yes - LossLevel : Program - LossDepMode : Not Null)
                                if (dataSigningRequest[i].RiskCarrier__c == null || dataSigningRequest[i].RiskCarrier__c == undefined){
                                    canClose = false; 
                                    break;
                                }else{
                                    if (dataSigningRequest[i].FinancialEntity__c == null || dataSigningRequest[i].FinancialEntity__c == undefined){canClose = false;
                                        break;
                                    }else {
                                        if (dataSigningRequest[i].SignedShare__c == null || dataSigningRequest[i].SignedShare__c == undefined ||(Number.isNaN(dataSigningRequest[i].SignedShare__c) == true)) {canClose = false;
                                            break;
                                        }else{
                                            if (dataSigningRequest[i].Deductions__c == null || dataSigningRequest[i].Deductions__c == undefined ||(Number.isNaN(dataSigningRequest[i].Deductions__c) == true)){canClose = false;
                                                break;
                                            }else{
                                                if (dataSigningRequest[i].RetrocessionBrokerage__c == null || dataSigningRequest[i].RetrocessionBrokerage__c == undefined ||(Number.isNaN(dataSigningRequest[i].RetrocessionBrokerage__c) == true)){ canClose = false;
                                                    break;
                                                }else{
                                                    if (dataSigningRequest[i].PremiumDeposit__c == null || dataSigningRequest[i].PremiumDeposit__c == undefined){
                                                        if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '2' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '1'){canClose = true; 
                                                        }else if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '3' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '4' ||  dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '5'){canClose = false;
                                                            break;
                                                        }
                                                    }else{canClose = true; 
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                    }else if ((dataSigningRequest[i].BrokerStatus__c == null || dataSigningRequest[i].BrokerStatus__c == undefined) && //it's row of reinsurer
                    (dataSigningRequest[i].LossDeposit__c == '2' && (dataSigningRequest[i].LossDepositMode__c == null || dataSigningRequest[i].LossDepositMode__c == undefined))){//=> it's third case of LossDeposit  (LossDep : No - LossDepMode : Null)
                      console.log('### row reinsurer with LossDeposit__c = 2 ');
                        if (dataSigningRequest[i].RiskCarrier__c == null || dataSigningRequest[i].RiskCarrier__c == undefined){
                            console.log('### RiskCarrier__c');
                            canClose = false;
                            break;
                        }else{
                            if (dataSigningRequest[i].FinancialEntity__c == null || dataSigningRequest[i].FinancialEntity__c == undefined){canClose = false;
                              console.log('### FinancialEntity__c');
                                break;
                            }else {
                                if (dataSigningRequest[i].SignedShare__c == null || dataSigningRequest[i].SignedShare__c == undefined ||(Number.isNaN(dataSigningRequest[i].SignedShare__c) == true)) { canClose = false;
                                  console.log('### SignedShare__c');  
                                  break;
                                }else{
                                    if (dataSigningRequest[i].Deductions__c == null || dataSigningRequest[i].Deductions__c == undefined ||(Number.isNaN(dataSigningRequest[i].Deductions__c) == true)) {canClose = false;
                                      console.log('### Deductions__c');    
                                      break;
                                    }else{
                                        if (dataSigningRequest[i].RetrocessionBrokerage__c == null || dataSigningRequest[i].RetrocessionBrokerage__c == undefined ||(Number.isNaN(dataSigningRequest[i].RetrocessionBrokerage__c) == true)){canClose = false;
                                           console.log('### RetrocessionBrokerage__c');    
                                          break;
                                        }else{
                                            if (dataSigningRequest[i].PremiumDeposit__c == null || dataSigningRequest[i].PremiumDeposit__c == undefined){
                                                console.log('### PremiumDeposit__c');    
                                                if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '2' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '1'){canClose = true; 
                                                }else if (dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '3' || dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '4' ||  dataSigningRequest[i].Treaty__r.TypeofTreaty__c == '5'){canClose = false;
                                                     console.log('### TypeofTreaty__c == 3');      
                                                  break;
                                                }
                                            }else{canClose = true; 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                 console.log('### canClose ==', canClose);   
                if(canClose == false){
                    showToast(this, 'Error', 'error', label.CloseSigningErrorMsg);
                    this.spinnerSigningRequest = false;
                }
                else if (canClose){
                    closeSigningNotifyWebXL({ programId : this.selectedProgram, lstSigningRequestId : lstSigningReqId })
                    .then(result => {
                        if(result.hasOwnProperty('Error') && result.Error){
                            showToast(this, 'Error', 'error', result.Error);
                            this.spinnerSigningRequest = false;
                        }
                        else{
                            showToast(this, 'Success', 'success', label.emailSent);
                            this.buttonNameClick = null;
                            this.disableThisButton = true; 
                        }
                    })
                    .catch(error => {
                        showToast(this, 'Error', 'error', label.errorMsg);
                        this.spinnerSigningRequest = false;
                    });
                }
            })
            .catch(error => {this.dispatchEvent(new ShowToastEvent({title: 'Error', message: error.message, variant: 'error'}), );});
    }

    handleOnClickDeleteBtn(){
        this.isDelete = true; this.isOpenConfirmation = true;this.closePreviousBtnClick =  false;
    }

    handleOnClickReopenBtn(event){
        if(this.lstSelectedSigningReqId.length > 0){
            this.buttonNameClick = event.currentTarget.name;
            if(this.isValueChange == true){
                this.isReopen = true;
                this.isOpenConfirmation = true;
                this.isSave = false;
                this.isAskToSave = true;
            }
            else{this.reopenSigningRequest();}
        }
        else{showToast(this, 'Error', 'error', label.requestSelected);}
    }

    reopenSigningRequest(){
        this.closePreviousBtnClick =  false; 
        reopenSigningRequest({ lstSigningRequestId : this.lstSelectedSigningReqId })
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                showToast(this, 'Error', 'error', result.Error);
                this.spinnerSigningRequest = false;
            }
            else{showToast(this, 'Success', 'success', label.requestReopened);}
            
        })
        .catch(error => {showToast(this, 'Error', 'error', label.errorMsg);this.spinnerSigningRequest = false;});
    }

    handleOnClickSignForPoolBtn(event){
        this.buttonNameClick = event.currentTarget.name;
        if(this.isValueChange == true){
            this.isSign = true;
            this.isOpenConfirmation = true;
            this.isAskToSave = true;
        }
        else{ this.isOpenSignForPoolModal = true; this.closePreviousBtnClick =  false; 
        }
    }

    handleCloseSignForPoolModal(){this.isOpenSignForPoolModal = false;this.closePreviousBtnClick ==  false;}

    handleReopenPreviousPhases(event){
        this.buttonNameClick = event.currentTarget.name;
        if(this.isValueChange == true){ this.isOpenConfirmation = true;this.isAskToSave = true;}
        else{let programStageValue =   this.selectedProgram + '-Placement';
            fireEvent(this.pageRef, 'updateStageName', programStageValue);
            this.reopenPreviousPhase();
        }
    }

    reopenPreviousPhase(){
        this.closePreviousBtnClick ==  false;
        reopenPreviousPhase({programId : this.selectedProgram})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSigningRequest = false;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.errorMsg, variant: 'error'}), );
            this.spinnerSigningRequest = false;
        });
    }

    handleCloseConfirmationModal(){
        if(this.isPhaseChange == true){
            fireEvent(this.pageRef, 'updateStageName', this.programStageValueChange);
        }

        if(this.buttonNameClick == 'WrittenShareToSigned'){
            this.updateWrittenSignedShare();
            this.isValueChange = false;
        }
        else if(this.buttonNameClick == 'Send' || this.buttonNameClick == 'Update' || this.buttonNameClick == 'Remind'){this.checkRequestBeforeSendUpdateRemind(this.buttonNameClick);}
        else if(this.buttonNameClick == 'ReopenPreviousPhases'){
            let programStageValue =   this.selectedProgram + '-Placement';
            fireEvent(this.pageRef, 'updateStageName', programStageValue);
            this.reopenPreviousPhase();
        }
        else if(this.buttonNameClick == 'CloseSigningNotifyWebXL'){this.closeSigningNotifyWebXL();}
        else if(this.buttonNameClick == 'ReopenSigning'){this.reopenSigningRequest();}

        this.isOpenConfirmation = false;
        this.isPhaseChange = false;
        this.buttonNameClick = null;
        this.buttonSignPoolVisibility;
        this.isSave = false;
        this.isWrite = false;
        this.isValidate = false;
        this.isClose = false;
        this.isDelete = false;
        this.isReopen = false;
        this.isSign = false;
        this.isAskToSave = false;
    }

    askSaveConfirmation(val){
        this.programStageValueChange = val;
        this.isPhaseChange = true;
        if(this.isValueChange == true){this.isOpenConfirmation = true;this.isAskToSave = true;}
        else{fireEvent(this.pageRef, 'updateStageName', val);}
    }

    updateWrittenSignedShare(){
        let updDataSigningRequest = [];
        this.spinnerSigningRequest = true;
        this.closePreviousBtnClick =  false; //RRA - ticket 1397 - 17012023

        for(let i = 0; i < this.dataSigningRequest.length; i++){
            let rowReq = { ...this.dataSigningRequest[i] };
            if(rowReq.WrittenShare__c != undefined){
                rowReq['SignedShare__c'] = rowReq.WrittenShare__c;
            }
            updDataSigningRequest.push(rowReq);
        }

        this.dataSigningRequest = [ ...updDataSigningRequest ];
        this.sortData('TECH_Layer__c', 'TECH_TreatyName__c', 'ReinsurerOrPoolName', 'asc');

        updateWrittenSignedShare({ lstRequest : this.dataSigningRequest })
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSigningRequest = false;
            }
            else{this.dispatchEvent(new ShowToastEvent({title: 'Success', message: label.writtenShare, variant: 'success' }),);}
            this.dataSigningRequest = [];
            this.getSigningDetails();
        })
        .catch(error => { this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.errorMsg, variant: 'error'}), );});
    }

    handleDeleteRequests(){
        this.spinnerSigningRequest = true;
        deleteSigningRequests({programId : this.selectedProgram})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
                this.spinnerSigningRequest = false;
            }
            else{
                this.spinnerSigningRequest = false;
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: label.requestDeleted, variant: 'success'  }),);
                window.location.href = '../n/TreatyPlacement?c__program='+this.selectedProgram+'-'+this.valueUWYear+'-'+this.principalCedYear+'-Placement-'+this.selectedTreaty+'-'+this.selectedBroker+'-'+this.selectedReinsurer+'-'+this.selectedReinsurerStatus;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: label.errorMsg, variant: 'error'}), );
            this.spinnerSigningRequest = false;
        })
    }

    sortData(fieldName, fieldName2, fieldName3, sortDirection) {
        let sortResult = Object.assign([], this.dataSigningRequest);
        this.dataSigningRequest = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
            else{
                if(a[fieldName2] < b[fieldName2])
                    return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName2] > b[fieldName2])
                    return sortDirection === 'asc' ? 1 : -1;
                else{
                    if(a[fieldName3] < b[fieldName3])
                        return sortDirection === 'asc' ? -1 : 1;
                    else if(a[fieldName3] > b[fieldName3])
                        return sortDirection === 'asc' ? 1 : -1;
                    else
                        return 0;
                }
            }
        })
        let mapDisplayRowByTreaty = new Map();
        for(let i = 0; i < this.dataSigningRequest.length;i++){
            if(this.dataSigningRequest[i].displayInTable == true){
                mapDisplayRowByTreaty.set(this.dataSigningRequest[i].Treaty__c, this.dataSigningRequest[i].Id);
            }
        }

        for(let i = 0; i < this.dataSigningRequest.length;i++){          
            this.dataSigningRequest[i]['displayTotalSumRow'] = false;

            if(mapDisplayRowByTreaty.has(this.dataSigningRequest[i].Treaty__c) == true){
                if(mapDisplayRowByTreaty.get(this.dataSigningRequest[i].Treaty__c) == this.dataSigningRequest[i].Id){
                    this.dataSigningRequest[i]['displayTotalSumRow'] = true;
                }
            }
        }
    }

    handleReinsurerNameSelected(event){
        this.selectedRequest = event.target.dataset.id;
        this.marketSubVisible = true;
    }

    handleCloseMarketSubModal(){
        this.marketSubVisible = false;
        this.getSigningDetails();
    }

    checkIfProgPhaseSigningHasDoc(){
        checkIfProgPhaseSigningHasDoc({programId : this.selectedProgram})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                showToast(this,'Error', 'error', result.Error);
                this.spinnerSigningRequest = false;
            }
            else{
            }
        })
        .catch(error => {
            showToast(this,'Error', 'error', label.errorMsg);
            this.spinnerSigningRequest = false;
        })
    }

    updateRequestReinsurer(val){
        let reinsurerId = val.split('-')[0];
        let recId = val.split('-')[1];
        let selectName = val.split('-')[2];
        let type = val.split('-')[3];
        let lstUpdDataSigningRequest = [];

        if(type == 'Risk'){
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq['Reinsurer__c'] == reinsurerId){
                    rowReq['RiskCarrier__c'] = recId;
                    rowReq['RiskCarrierName'] = selectName;
                }
                lstUpdDataSigningRequest.push(rowReq);
            }
        }
        else{
            for(let i = 0; i < this.dataSigningRequest.length; i++){
                let rowReq = { ...this.dataSigningRequest[i] };
                if(rowReq['Reinsurer__c'] == reinsurerId){
                    rowReq['FinancialEntity__c'] = recId;
                    rowReq['FinancialName'] = selectName;
                }
                lstUpdDataSigningRequest.push(rowReq);
            }
        }
        this.dataSigningRequest = lstUpdDataSigningRequest;
    }
    async handleCopyRCToFC(event){ // HRA W-1289
        this.clickBtnAskForValidation = false;//RRA - ticket 2229 - 26/12/2024
        let rowsChanged = 0;
        this.dataSigningRequest.forEach(signingRequest => {
            if(signingRequest.RiskCarrier__c != null && signingRequest.FinancialEntity__c == null && !signingRequest.disableFinancialEntity){
                signingRequest.FinancialEntity__c = signingRequest.RiskCarrier__c;
                signingRequest.FinancialName = signingRequest.RiskCarrierName;
                rowsChanged ++;
            }
        });
        if(rowsChanged > 0){
            this.disableCopyRCToFC = true;
            this.isValueChange = true;
            await this.handleSaveSigningRequest(event);
        this.dispatchEvent(new ShowToastEvent({title: 'Success', message:rowsChanged+' rows Copied', variant: 'success' }),);
        }
    }

    updateCopyRCToFCVisibility(){ // HRA W-1289
        this.dataSigningRequest.every(signingRequest => {
            if(signingRequest.RiskCarrier__c != null && signingRequest.FinancialEntity__c == null && !signingRequest.disableFinancialEntity){
                this.disableCopyRCToFC = false;return false;
            }
            else{this.disableCopyRCToFC = true; return true;
            }
        });
    }
}