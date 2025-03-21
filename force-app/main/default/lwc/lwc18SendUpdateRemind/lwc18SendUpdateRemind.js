/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 25-10-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   25-10-2023   Patrick Randrianarisoa   W-1575
**/
import {LightningElement, track, wire, api} from 'lwc';
import {registerListener, unregisterAllListeners, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {refreshApex} from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getPrograms from '@salesforce/apex/LWC18_SendUpdateRemind.getPrograms';
import getDocuments from '@salesforce/apex/LWC18_SendUpdateRemind.getDocuments';
import updateContenVersion from '@salesforce/apex/LWC18_SendUpdateRemind.updateContenVersion';
import updateAllContenVersionRenew from '@salesforce/apex/LWC18_SendUpdateRemind.updateAllContenVersionRenew';
import contentVersionOnContractRenew from '@salesforce/apex/LWC18_SendUpdateRemind.contentVersionOnContractRenew';
import getContact from '@salesforce/apex/LWC18_SendUpdateRemind.getContact';
import checkActiveAccounts from '@salesforce/apex/LWC18_SendUpdateRemind.checkActiveAccounts';
import getPoolAssignedTo from '@salesforce/apex/LWC18_SendUpdateRemind.getPoolAssignedTo';
import sendUpdateRequest from '@salesforce/apex/LWC18_SendUpdateRemind.sendUpdateRequest';
import sendReminderForRequest from '@salesforce/apex/LWC18_SendUpdateRemind.sendReminderForRequest';
import getEmailTemplate from '@salesforce/apex/LWC18_SendUpdateRemind.getEmailTemplate';

//import field Request
import COMMENTS_FIELD from '@salesforce/schema/Request__c.Comments__c';
import EXP_ANS_DATE_FIELD from '@salesforce/schema/Request__c.ExpectedResponseDate__c';
import CONTENT_VERSION from '@salesforce/schema/ContentVersion';//RRA - ticket 2149 - 10102024

//import fields contentVersion
import GROUP_TYPE_FIELD from '@salesforce/schema/ContentVersion.GroupType__c';
import FROM_THEMIS from '@salesforce/schema/ContentVersion.FromThemis__c';
import DOCUMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.DocumentType__c';
import CONTENT_DOCMENT_ID from '@salesforce/schema/ContentVersion.ContentDocumentId';
import CONTENTVERSION_ID from '@salesforce/schema/ContentVersion.Id';
import PHASE_FIELD from '@salesforce/schema/ContentVersion.Phase__c';
import TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import VERSIONNUMB_FIELD from '@salesforce/schema/ContentVersion.VersionNumber';
import TECH_SELECTEDBR_SIZE_FIELD from '@salesforce/schema/ContentVersion.TECH_SelectedBRLength__c';
import TECH_SELECTEDBR_FIELD from '@salesforce/schema/ContentVersion.TECH_SelectedBrokerRein__c';


//Custom Label
import SelectedBRInactive from '@salesforce/label/c.SelectedBRInactive';
import NoAssignedEmailForPool from '@salesforce/label/c.NoAssignedEmailForPool';
import EnterExpectedAnswerDate from '@salesforce/label/c.EnterExpectedAnswerDate';
import RemindEmailSendSuccessfully from '@salesforce/label/c.RemindEmailSendSuccessfully';
import NoContactAvailable from '@salesforce/label/c.NoContactAvailable';
import errorMsg from '@salesforce/label/c.errorMsg';
import documentNotAssigned from '@salesforce/label/c.DocumentNotAssigned';

const columnsQuoteRequest = [
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Section / Option', fieldName: 'TECH_SectionName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'},
    { label: 'Request Type', fieldName: 'QuoteType__c' }
];

const columnsLeadSigningRequest = [
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'}
];

const columnsPlacementRequestSend = [
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'},
    { label: 'Written share', type: 'number', fieldName: 'WrittenShare__c', editable: true, cellAttributes: { alignment: 'left' }, typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'}},
];

const columnsPlacementRequestUpdateRemind = [
    { label: 'Treaty', fieldName: 'TECH_TreatyName__c' },
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'},
    { label: 'Written share', type: 'number', fieldName: 'WrittenShare__c', cellAttributes: { alignment: 'left' }, typeAttributes: {minimumFractionDigits: '6', maximumFractionDigits: '6'}},
];

const columnsContact = [
    { label: 'Broker / Reinsurer', fieldName: 'AccountName' },
    { label: 'Last Name', fieldName: 'ContactLastName' },
    { label: 'First Name', fieldName: 'ContactFirstName' },
    { label: 'Email address', fieldName: 'ContactEmail'}
];

const columnsBrokerReinsurer = [
    { label: 'Broker', fieldName: 'TECH_BrokerName__c' },
    { label: 'Reinsurer', fieldName: 'TECH_ReinsurerName__c'},
];

export default class LWC18_SendUpdateRemind extends LightningElement {
    label = {
        SelectedBRInactive,
        NoAssignedEmailForPool,
        EnterExpectedAnswerDate,
        RemindEmailSendSuccessfully,
        NoContactAvailable,
        errorMsg
    }
    @track isDialogVisible = false; //MRA W-822 Confirmation Modal 24/08/2022
    @track originalMessage;//MRA W-822 Confirmation Modal 24/08/2022
    @api uwYear;
    @api contactSelected = [];
    @api accSelected = [];
    @api contactCheckedSelected = [];
    @api principleCedComp;
    @api program;
    @api stage;
    @api selectedDataRequest = [];
    @api selectedDataRequestss;
    @api brokerReinId = [];
    @api brokerReinId2 = [];
    @api btnNameClick;
    @track lstContractualDoc = [];
    @track lstSelectedRequestId = [];
    @track lstCheckboxChangeContractualDoc = [];
    @track lstRenewalDoc = [];
    @track lstCheckboxChangeRenewalDoc = [];
    @track dataBrokerReinsurer = [];
    @track selectedBrokerReinsurer = [];
    @track dataContact = [];
    @track dataContactFinal = [];
    @track preSelectedContact = [];
    @track lstSelectedDataRequestId = [];
    @track lstPoolsData = [];
    @track lstPoolIdToTreatyId = [];
    @track lstAssignedUsers = [];
    @track lstTreatyIds = [];
    @track applyToDataRequest = [];
    @track bypassDocAssignment = false ; //MRA W-822 Confirmation Modal 24/08/2022
    //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
    @track bypassContactAssignment = false ;
    @track isContactMissing = false ;
    lstBrokerReinsurerNameApplyTo = [] ;
    lstBrokerReinsurerNameOnContact = [] ;
    isSaveOnBR = false;
    confirmMessage = '' ;
    confirmLabel = '' ;
    cancelLabel = '' ;
    mapValueToAPI = new Map(); //RRA - ticket 2149 - 09102024
    mapDocType = new Map(); //RRA - ticket 2149 - 09102024
    programOpt;
    columnsQuoteRequest = columnsQuoteRequest;
    columnsLeadSigningRequest = columnsLeadSigningRequest;
    columnsPlacementRequestSend = columnsPlacementRequestSend;
    columnsPlacementRequestUpdateRemind = columnsPlacementRequestUpdateRemind;
    columnsBrokerReinsurer = columnsBrokerReinsurer;
    isSelectModalOpen = false;
    documentName;
    selectedDocument;
    preSelectedBrokerReins;
    groupTypeContractual = '1';
    groupTypeRenewal = '2';
    groupType;
    columnsContact = columnsContact;
    programMacroLob;
    programNature;
    commentValue = null;
    @api expectedAnsDateValue = null;
    mapListBrokerReinsByContentVersionIdContractual = new Map();
    mapListBrokerReinsByContentVersionIdRenewal = new Map();
    wiredprograms;
    wiredContact;
    wiredActive;
    availableBrokerReinsurerIds = new Set();
    btnNameLabel;
    isContactNull = true;
    isRemindBtnClick = false;
    displayQuoteColumns = false;
    displayLeadSigningColumns = false;
    displayPlacementSendColumns = false;
    displayPlacementUpdateRemindColumns = false;
    displayPools = false;
    poolTitle = 'Pools';
    displaySpinner = false;
    emailTemp1;
    emailTemp2;
    emailTemp3;
    emailTemp4;
    emailTemp5;
    emailTempLabel1;
    emailTempLabel2;
    emailTempLabel3;
    emailTempLabel4;
    emailTempLabel5;
    updateRemindTempForBrokRein;
    updateRemindTempForSignForPool;
    updateRemindTempForBrokReinLabel;
    updateRemindTempForSignForPoolLabel;
    displayFourEmailTemp = false;
    displayEmailTemp5 = false;
    isSendBtnClick = false;
    isUpdateRemindBtnClick = false;
    isSigningEmailTemp = false;

    @track objRequest = {
        Comments__c : COMMENTS_FIELD,
        ExpectedResponseDate__c : EXP_ANS_DATE_FIELD
    }

    @wire(CurrentPageReference) pageRef;
    //RRA - ticket 2149 - 09102024
    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION })
    objectInfoCV;
    connectedCallback(){
        this.displaySpinner = true;
        if(this.stage == 'Quote'){
            this.displayQuoteColumns = true;
        }
        else if(this.stage == 'Lead' || this.stage == 'Signing'){
            this.displayLeadSigningColumns = true;
        }
        else if(this.stage == 'Placement' && this.btnNameClick == 'Send'){
            this.displayPlacementSendColumns = true;
        }
        else if(this.stage == 'Placement' && (this.btnNameClick == 'Remind'|| this.btnNameClick == 'Update')){
            this.displayPlacementUpdateRemindColumns = true;
        }

        if(this.btnNameClick == 'Send' && (this.stage == 'Quote' || this.stage == 'Lead' || this.stage == 'Placement' || this.stage == 'Signing')){     
            if(this.stage == 'Quote'){
                this.emailTempLabel1 = 'Broker - For Information email to be sent';
                this.emailTempLabel2 = 'Reinsurer - For Information email to be sent';
                this.emailTempLabel3 = 'Broker - For Quote email to be sent';
                this.emailTempLabel4 = 'Reinsurer - For Quote email to be sent';
                this.displayFourEmailTemp = true;
            }
            else if(this.stage == 'Lead'){
                this.emailTempLabel1 = 'Retained Broker email to be sent';
                this.emailTempLabel2 = 'Retained Reinsurer email to be sent';
                this.emailTempLabel3 = 'Non Retained Broker email to be sent';
                this.emailTempLabel4 = 'Non Retained Reinsurer email to be sent';
                this.displayFourEmailTemp = true;
            }
            else if(this.stage == 'Placement'){
                this.emailTempLabel1 = 'Broker email to be sent';
                this.emailTempLabel2 = 'Reinsurer email to be sent';
            }
            else if(this.stage == 'Signing'){
                this.emailTempLabel1 = 'Broker email to be sent';
                this.emailTempLabel2 = 'Reinsurer email to be sent';
                this.emailTempLabel3 = 'Broker Signed Share Zero email to be sent';
                this.emailTempLabel4 = 'Reinsurer Signed Share Zero email to be sent';
                this.emailTempLabel5 = 'Signed for Pool email to be sent';
                this.displayEmailTemp5 = true;
                this.displayFourEmailTemp = true;
            }
        }
        else if(this.btnNameClick == 'Update' || this.btnNameClick == 'Remind'){
            this.updateRemindTempForBrokReinLabel = 'Broker/Reinsurer email to be sent';
            this.updateRemindTempForSignForPoolLabel = 'Signed for Pool email to be sent';
        }

        this.displayPools = ( (this.btnNameClick == 'Send' || this.btnNameClick == 'Remind' || this.btnNameClick == 'Update') && this.stage == 'Signing')? true : false;

        let brokerRein;
        this.brokerReinId = [];
        this.getDocuments();

        if(this.btnNameClick == 'Send'){
            this.btnNameLabel = 'Send';
            this.isSendBtnClick = true;
        }
        else if(this.btnNameClick == 'Update'){
            this.btnNameLabel = 'Send';
            this.isUpdateRemindBtnClick = true;
        }
        else if(this.btnNameClick == 'Remind'){
            //To display working scope, program(no expected date), apply to, contact, not to display contractual/renewal
            this.btnNameLabel = 'Send Reminder';
            this.isRemindBtnClick = true;
            this.isUpdateRemindBtnClick = true;
        }

        if(this.stage == 'Signing'){
            this.isSigningEmailTemp = true;
        }

        let lstApplyToDataRequest = [];
        let lstOnlyBroker = [] ;//MRA 1/09/2022 : W-0797 - Tri champ "Apply to" pop up d'envoi
        let lstOnlyReinsurer = [] ;//MRA 1/09/2022 : W-0797 - Tri champ "Apply to" pop up d'envoi
        let lstOnlyPool = [] ;// MRA 1281/1290 Hotfix
        let lstOnlyTreaty = [] ; //RRA - ticket 1564 - 28082023 

        this.selectedDataRequest = this.selectedDataRequest.map(row => {
            this.lstSelectedRequestId.push(this.selectedDataRequest.Id);
            
            brokerRein = row.Treaty__c + '-' + row.Broker__c + '-' + row.Reinsurer__c; 
            this.lstSelectedDataRequestId.push(row.Id);
            if(row.Broker__c != null){
                this.brokerReinId.push(row.Broker__c);
            }
            else{
                this.brokerReinId.push(row.Reinsurer__c);
            }
            //MRA 1/09/2022 : W-0797 - Tri champ "Apply to" pop up d'envoi : START
            if (row.TECH_BrokerName__c !== undefined && row.TECH_ReinsurerName__c !== undefined) {
                lstOnlyBroker.push({...row , brokerRein}) ;

                if(!this.lstBrokerReinsurerNameApplyTo.includes(row.TECH_BrokerName__c))
                    this.lstBrokerReinsurerNameApplyTo.push(row.TECH_BrokerName__c) ;
            }
            else if(row.TECH_BrokerName__c === undefined && row.TECH_ReinsurerName__c !== undefined){
                lstOnlyReinsurer.push({...row , brokerRein}) ;

                if(!this.lstBrokerReinsurerNameApplyTo.includes(row.TECH_ReinsurerName__c))
                    this.lstBrokerReinsurerNameApplyTo.push(row.TECH_ReinsurerName__c) ;

            } else if(row.TECH_TreatyName__c === undefined && row.TECH_TreatyName__c !== undefined){
                lstOnlyTreaty.push({...row , brokerRein}) ;//RRA - ticket 1564 - 28082023 
            }
            else if(row.Pool__c !== undefined){// MRA 1281/1290 Hotfix
                lstOnlyPool.push({...row , brokerRein}) ;
            }
            return {...row , brokerRein}
        });
        lstOnlyBroker = lstOnlyBroker.sort((a,b) => (a.TECH_BrokerName__c.localeCompare(b.TECH_BrokerName__c)) || (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
        lstOnlyReinsurer = lstOnlyReinsurer.sort((a,b) => (a.TECH_ReinsurerName__c.localeCompare(b.TECH_ReinsurerName__c))) ;
        lstOnlyTreaty = lstOnlyTreaty.sort((a,b) => (a.TECH_TreatyName__c.localeCompare(b.TECH_TreatyName__c))) ;
        this.selectedDataRequest = lstOnlyBroker.concat(lstOnlyReinsurer).concat(lstOnlyTreaty).concat(lstOnlyPool) ;//RRA - ticket 1564 - 28082023 
        
        this.selectedDataRequest.forEach(row => {
            if(row.Pool__c == null || row.Pool__c == undefined){
                lstApplyToDataRequest.push(row);
            }
        }) ;
        console.log('lstApplyToDataRequest == ', lstApplyToDataRequest);
        //MRA 1/09/2022 : W-0797 - Tri champ "Apply to" pop up d'envoi : END
        let lstUniqueApplyDataRequest = this.getUniqueData(lstApplyToDataRequest, 'brokerRein'); //RRA - ticket 1564 - 30082023  //avoid displaying duplication of account (broker /  reinsurer) 
        console.log('lstUniqueApplyDataRequest == ', lstUniqueApplyDataRequest);
        this.applyToDataRequest = lstUniqueApplyDataRequest;
        
        //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
        if(this.stage == 'Lead' || this.stage == 'Signing'){
            this.lstBrokerReinsurerNameApplyTo = [] ;
            this.applyToDataRequest.forEach(row => {
                if (row.TECH_BrokerName__c !== undefined && row.TECH_BrokerName__c !== '') {
                    this.lstBrokerReinsurerNameApplyTo.push(row.TECH_BrokerName__c) ;
                }
                else{
                    this.lstBrokerReinsurerNameApplyTo.push(row.TECH_ReinsurerName__c) ;
                }
            }) ;
        }

        if(this.btnNameClick != 'Remind'){
            let dataReqWithoutPool = [];

            for(let i = 0; i < this.selectedDataRequest.length; i++){
                let row = {...this.selectedDataRequest[i]};
                if(row.Reinsurer__c != undefined && row.Reinsurer__c != null){
                    dataReqWithoutPool.push(row);
                }
            }

            let brokerRein2;
            this.brokerReinId2 = [];
            this.dataBrokerReinsurer = this.getUniqueData(dataReqWithoutPool, 'brokerRein');
            let updDataBrokerReinsurer = [];
            let updDataBrokerReinsurerUnique = [];//RRA - ticket 1564 - 30082023
            let updAvailableBrokerReinsurerIds = new Set();

            for(let i = 0; i < this.dataBrokerReinsurer.length; i++){
                let row = { ...this.dataBrokerReinsurer[i] };
                updDataBrokerReinsurer.push(row);

                //MBE - 03/11/2020 2149
                if(row.Broker__c != null && row.Broker__c != undefined){
                    updAvailableBrokerReinsurerIds.add(row.TECH_BrokerReferentialId__c + '-' + row.TECH_ReinsurerReferentialId__c);
                }
                else{
                    updAvailableBrokerReinsurerIds.add('undefined-' + row.TECH_ReinsurerReferentialId__c);
                }
            }

            this.availableBrokerReinsurerIds = updAvailableBrokerReinsurerIds;
            updDataBrokerReinsurerUnique = this.getUniqueData(updDataBrokerReinsurer, 'TECH_BrokerReinsurer__c');//RRA - ticket 1564 - 30082023
            this.dataBrokerReinsurer = updDataBrokerReinsurerUnique; //RRA - ticket 1564 - 30082023
            this.preSelectedBrokerReins = this.selectedDataRequestss;
            this.brokerReinId = this.brokerReinId.filter((x, i, a) => a.indexOf(x) == i);

            if(this.btnNameClick == 'Update' && this.selectedDataRequest.length > 0){
                let maxExpectedAnswerDate = this.selectedDataRequest[0].ExpectedResponseDate__c;
                let sameExpectedAnswerDate = true;

                if(this.selectedDataRequest.length > 1){
                    for(let i = 0; i < this.selectedDataRequest.length; i++){
                        if(this.selectedDataRequest[i].ExpectedResponseDate__c != maxExpectedAnswerDate){
                            sameExpectedAnswerDate = false;
                        }
                    }
                }

                if(this.selectedDataRequest.length == 1){
                    //if only one row request is selected -> display Expected Answer Date of that row for update
                    this.expectedAnsDateValue = maxExpectedAnswerDate;
                }
                else if(this.selectedDataRequest.length > 1 && sameExpectedAnswerDate == true){
                    //if more than one row request are selected with same Expected Answer Date -> display Expected Answer Date for update
                    this.expectedAnsDateValue = maxExpectedAnswerDate;
                }
                else{
                    //if more than one row request are selected with different Expected Answer Date -> Expected Answer Date should be null for update and allow user to add a value
                    this.expectedAnsDateValue = null;
                }
            }
        }

        if(this.displayPools){
            this.generatePoolsData();
        }
        else{
            this.displaySpinner = false;
        }

        this.getEmailTemplate();
         console.log('okok == ');
    }
    //RRA - ticket 2149 - 09102024
    @wire(getPicklistValues, { recordTypeId: '$objectInfoCV.data.defaultRecordTypeId', fieldApiName: PHASE_FIELD})
    setPhasePicklistOpt({error, data}) {
        if(data){
            for(var i = 0; i < data.values.length; i++){
                this.mapValueToAPI.set(data.values[i].label, data.values[i].value);
            }
        }
        else{
            this.error = error;
        }
    }
    
     //RRA - ticket 2149 - 09102024
    @wire(getPicklistValues, { recordTypeId: '$objectInfoCV.data.defaultRecordTypeId', fieldApiName: DOCUMENT_TYPE_FIELD})
    setDocumentTypePicklistOptions({error, data}) {
        if(data){
            for(var i = 0; i < data.values.length; i++){
                this.mapDocType.set(data.values[i].label, data.values[i].value);
            }

        }
        else{
            this.error = error;
        }
    }
    getEmailTemplate(){
        let selectedReqId = this.selectedDataRequest[0].Id;

        getEmailTemplate({btnNameSendUpdateRemind : this.btnNameClick, reqId : selectedReqId, stageType : this.stage })
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }
            else{
                this.emailTemp1 = result.emailTemp1;
                this.emailTemp2 = result.emailTemp2;
                this.emailTemp3 = result.emailTemp3;
                this.emailTemp4 = result.emailTemp4;
                this.emailTemp5 = result.emailTemp5;
                this.updateRemindTempForBrokRein = result.updateRemindTempForBrokRein;
                this.updateRemindTempForSignForPool = result.updateRemindTempForSignForPool;
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.errorMsg, variant: 'error'}), );
        });
    }

    generatePoolsData(){
        getPoolAssignedTo()
        .then(result => {
            if(result){
                for(let i = 0; i < result.length; i ++){
                    var opt = {};
                    opt.label = result[i]['Email'];
                    opt.value = result[i]['Email'];
                    this.lstAssignedUsers.push(opt);
                }

                let lstPoolNames = [];

                for(let i = 0; i < this.selectedDataRequest.length; i++){
                    var req = this.selectedDataRequest[i];
                    if(req['Pool__r']){
                        var pool = JSON.parse(JSON.stringify(req['Pool__r']));
                        var poolIdToTreatyId = pool['Id']+ '|' + req['Treaty__r']['Id'];
                        this.lstPoolIdToTreatyId.push(poolIdToTreatyId);
                        this.lstTreatyIds.push(req['Treaty__r']['Id']);

                        if(this.isRemindBtnClick || this.btnNameClick == 'Update'){
                            if(lstPoolNames.indexOf(pool['Name']) == -1){
                                lstPoolNames.push(pool['Name']);
                                pool.Email = req['TECH_ValidatorEmail__c'];
                                this.lstPoolsData.push(pool);
                            }
                        } 
                        else if(this.btnNameClick == 'Send'){
                            if(pool.AssignedTo__r != undefined && pool.AssignedTo__r != null){
                                if(pool.AssignedTo__r.Email != undefined && pool.AssignedTo__r.Email != null){
                                    pool.Email = pool.AssignedTo__r.Email;
                                }
                            }

                            if(lstPoolNames.indexOf(pool['Name']) == -1){
                                lstPoolNames.push(pool['Name']);
                                this.lstPoolsData.push(pool);
                            }
                        }
                    }
                }
                this.poolTitle = 'Pools ('+ this.lstPoolsData.length + ')';
                this.displaySpinner = false;
            }
        })
        .catch(error => {
            this.displaySpinner = false;
            this.dispatchEvent(new ShowToastEvent({title: 'Error',message: this.label.errorMsg,variant: 'error'}),
            );
        });
    }

    handleOnChangeEmail(event){
        let eventId = event.currentTarget.id;
        let poolId = eventId.split('-')[0];
        let selectedEmail = event.currentTarget.value;
        let lstUpdPool = [];
 
        for(let i = 0; i < this.lstPoolsData.length; i++){
            let rowPool = { ...this.lstPoolsData[i] };
            if(rowPool.Id == poolId){
                rowPool['Email'] = selectedEmail;
            }
            lstUpdPool.push(rowPool);
        }
 
        this.lstPoolsData = lstUpdPool;
    }

    @wire(checkActiveAccounts, {lstAccountId: '$brokerReinId'})
    wiredCheckAccounts(result){
        this.wiredActive = result;
        if(result.data == false){
            //At least one Broker/Reinsurer selected is inactive
            this.dispatchEvent(new ShowToastEvent({title: 'Info',message: this.label.SelectedBRInactive,variant: 'info'}),);
        }
        else if(result.error){
            this.error = result.error;
        }
    }

    // RRA -955 method to retrieve the list of contact selected by chekbox when button Send/Update/Remind is clicked
    getContactSelected(event){
        let currentRowsChecked = event.detail.selectedRows;     
        if (currentRowsChecked != null || currentRowsChecked != undefined){
            this.contactSelected = currentRowsChecked;
        }else {
            this.contactSelected = null;
        }
    }

    @wire(getContact, {lstAccountId: '$brokerReinId', macroLOBFromProgram: '$programMacroLob', natureFromProgram: '$programNature', prinCedComFromProgram: '$principleCedComp'})
    wiredGetContact(result){ 
        this.wiredContact = result;
        if(result.data){
            this.dataContact = result.data;
            let lstUpdDataContact = [];
            let lstIdDataContact = [];
            //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
            let lstBrokerContact = [] ;
            let lstReinsurerContact = [] ;

            for(let i = 0; i < this.dataContact.length; i++){
                let row = {...this.dataContact[i]};
                if(row.Contact != undefined){
                    if(row.Contact.Email != undefined && row.Contact.Email != null){
                                row['AccountName'] = row.Account.Name;
                                row['ContactLastName'] = row.Contact.LastName;
                                row['ContactFirstName'] = row.Contact.FirstName;
                                row['ContactEmail'] = row.Contact.Email;
                        lstUpdDataContact.push(row);
                    }
                    //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
                    if(!this.lstBrokerReinsurerNameOnContact.includes(this.dataContact[i].Account.Name)) ;
                        this.lstBrokerReinsurerNameOnContact.push(this.dataContact[i].Account.Name) ;
                }
                lstIdDataContact.push(this.dataContact[i].Id)
            }
             //RRA - 955
            this.preSelectedContact = lstIdDataContact;
            this.dataContact = lstUpdDataContact;
            this.contactSelected = lstUpdDataContact;

            //AMI 18/07/22: W-0798 - Tri champ "Contacts" pop up d'envoi 
            //MRA 1/09/2022 : W-0798 - Tri champ "Contacts" pop up d'envoi : START
            //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
            //this.dataContact = this.dataContact.sort((a, b) => (a.Contact.AccountType__c.localeCompare(b.Contact.AccountType__c)) || (a.ContactLastName.localeCompare(b.ContactLastName)) || (a.ContactFirstName.localeCompare(b.ContactFirstName)));
             this.dataContact.forEach(element => {
                if (element.Contact.AccountType__c === 'Broker') {
                    lstBrokerContact.push(element) ;
                }
                else if(element.Contact.AccountType__c === 'Reinsurer'){
                    lstReinsurerContact.push(element) ;
                }
             }) ;

            lstBrokerContact = lstBrokerContact.sort((a,b) => (a.Account.Name.localeCompare(b.Account.Name)) || (a.ContactLastName.localeCompare(b.ContactLastName)) || (a.ContactFirstName.localeCompare(b.ContactFirstName))) ;
            lstReinsurerContact = lstReinsurerContact.sort((a,b) => (a.Account.Name.localeCompare(b.Account.Name)) || (a.ContactLastName.localeCompare(b.ContactLastName)) || (a.ContactFirstName.localeCompare(b.ContactFirstName))) ;
            this.dataContact = lstBrokerContact.concat(lstReinsurerContact) ;
            //MRA 1/09/2022 : W-0798 - Tri champ "Contacts" pop up d'envoi : END    
            let containPoolReq = false;

            if(this.dataContact.length == 0){
                if(this.stage == 'Signing'){
                    for(let i = 0; i < this.selectedDataRequest.length; i++){
                        if(this.selectedDataRequest[i].isRequestPool == true){
                            containPoolReq = true;
                        }
                    }

                    if(containPoolReq == false){
                        this.isContactNull = true;
                        this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoContactAvailable, variant: 'error'}),);
                    }
                    else{
                        this.isContactNull = false;
                    }
                }
                else{
                    this.isContactNull = true;
                    this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoContactAvailable, variant: 'error'}),);
                }
            }
            else{
                this.isContactNull = false;
            }
        }
        else if(result.error){
            this.error = result.error;
        }
    }

    @wire(getPrograms, {valueUWYear: '$uwYear', valuePrincipalCedComp: '$principleCedComp', valueStage: '$stage', programId: '$program'})
    wiredGetPrograms(result){
        this.wiredprograms = result;
        if(result.data){
            this.programOpt = result.data.lstPrograms;
            this.programMacroLob = result.data.programMacroLOB;
            this.programNature = result.data.programNature;
        }
        else if(result.error){
            this.error = result.error;
        }
    }

    refreshData() {
        return refreshApex(this.wiredprograms);
    }

    getDocuments(){      
       /* var lstContentVersionUpdated = [];
            for (var i = 0; i < lstBrokerReins.length; i++){
                var objDocument = {
                    DocumentType__c : DOCUMENT_TYPE_FIELD,
                    ContentDocumentId : CONTENT_DOCMENT_ID,
                    FromThemis__c : FROM_THEMIS,
                    Id : CONTENTVERSION_ID,
                    GroupType__c : GROUP_TYPE_FIELD,
                    Phase__c : PHASE_FIELD,
                    Title : TITLE_FIELD,
                    VersionNumber : VERSIONNUMB_FIELD,
                    TECH_SelectedBRLength__c : TECH_SELECTEDBR_SIZE_FIELD,
                    TECH_SelectedBrokerRein__c : TECH_SELECTEDBR_FIELD
                }

                objDocument.DocumentType__c = lstBrokerReins[i].DocumentType__c;
                objDocument.ContentDocumentId = lstBrokerReins[i].ContentDocumentId;
                objDocument.FromThemis__c =lstBrokerReins[i].FromThemis__c;;
                objDocument.GroupType__c = lstBrokerReins[i].GroupType__c;
                objDocument.Title = lstBrokerReins[i].Title;
                objDocument.Id = lstBrokerReins[i].Id;
                objDocument.Phase__c =  lstBrokerReins[i].Phase__c; 
                objDocument.VersionNumber = lstBrokerReins[i].VersionNumber;
                objDocument.TECH_SelectedBRLength__c =  lstBrokerReins[i].selectedBRLength; 
                objDocument.TECH_SelectedBrokerRein__c = lstBrokerReins[i].selectedBrokerRein;
                lstContentVersionUpdated.push(objDocument);
            }
            console.log('lstContentVersionUpdated 22 == ', lstContentVersionUpdated);*/
        getDocuments({ programId : this.program,  groupType : '1', programStage : this.stage})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.displaySpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }),
                );
            }
            else{
                let mapConvertIdRefToIdSDFCForContract = new Map();
                if(result.lstContentVersions.length>0){
                    this.lstContractualDoc = result.lstContentVersions;
                if(this.lstContractualDoc){
                    this.mapListBrokerReinsByContentVersionIdContractual = result.mapListOfCompanyByContentVersionId; 
                    let lstUpdContractualDoc = [];
                    let newListBrokerReinsurer = [];
                    console.log('lstContractualDoc xx == ',this.lstContractualDoc);
                    console.log('mapListBrokerReinsByContentVersionIdContractual == ',this.mapListBrokerReinsByContentVersionIdContractual);
                    
                    for(let i = 0; i < this.lstContractualDoc.length; i++){
                        let row = { ...this.lstContractualDoc[i] };
                        newListBrokerReinsurer = [];
                        if(this.mapListBrokerReinsByContentVersionIdContractual){
                            if(this.mapListBrokerReinsByContentVersionIdContractual[row.Id] != undefined || this.mapListBrokerReinsByContentVersionIdContractual[row.Id] != null){
        
                                //for(let a = 0; a < this.dataBrokerReinsurer.length; a++){
                                
                                    //let tempBrokerReinsurer = this.dataBrokerReinsurer[a].Broker__c + '-' + this.dataBrokerReinsurer[a].Reinsurer__c;
        
                                    //if(this.mapListBrokerReinsByContentVersionIdContractual[row.Id].includes(tempBrokerReinsurer)){
                                        let lstBrokerReinsurer = [ ...this.mapListBrokerReinsByContentVersionIdContractual[row.Id] ];
                                        let finalBrokerReinsurer = [];
                                        let lstKeyBrokerReinsurer = [];
                                        let selectedBR = 0;
        
                                        console.log('lstBrokerReinsurer == ', lstBrokerReinsurer);
        
                                        for(let j = 0; j < lstBrokerReinsurer.length; j++){
                                            if(this.availableBrokerReinsurerIds.has(lstBrokerReinsurer[j])){
                                                finalBrokerReinsurer.push(lstBrokerReinsurer[j]);
                                            }
                                        }
                                      
                                        
                                        for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                            if (this.dataBrokerReinsurer[j].Broker__c != null && this.dataBrokerReinsurer[j].ReinsurerStatus__c != null){
                                                mapConvertIdRefToIdSDFCForContract.set(this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c + '-' + this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c, this.dataBrokerReinsurer[j].Broker__c + '-' + this.dataBrokerReinsurer[j].Reinsurer__c);
                                            }else if (this.dataBrokerReinsurer[j].Broker__c == null && this.dataBrokerReinsurer[j].ReinsurerStatus__c != null){
                                                mapConvertIdRefToIdSDFCForContract.set('undefined-' + this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c, 'undefined-' + this.dataBrokerReinsurer[j].Reinsurer__c);
                                            }
                                        }
                                        
                                        for(let k = 0; k < finalBrokerReinsurer.length; k++){
                                            lstKeyBrokerReinsurer.push(mapConvertIdRefToIdSDFCForContract.get(finalBrokerReinsurer[k]));
                                        }
                                        

                                        for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                            for(let k = 0; k < finalBrokerReinsurer.length; k++){
                                                let broker = finalBrokerReinsurer[k].split('-')[0];
                                                let reinsurer = finalBrokerReinsurer[k].split('-')[1];
                                                //if(broker == 'undefined' && this.dataBrokerReinsurer[j].Broker__c == undefined && this.dataBrokerReinsurer[j].Reinsurer__c == reinsurer){
                                                  if(broker == 'undefined' && this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c == undefined && this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c == reinsurer){
                                                    selectedBR = selectedBR + 1;
                                                }
                                                //else if(this.dataBrokerReinsurer[j].Broker__c == broker && this.dataBrokerReinsurer[j].Reinsurer__c == reinsurer){
                                                else if(this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c == broker && this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c == reinsurer){
                                                    selectedBR = selectedBR + 1;
                                                }
                                            }
                                        }
                                        
                                        row['selectedBrokerRein'] = lstKeyBrokerReinsurer;
                                        row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                        row['selectedBRLength'] = selectedBR;
                                        
                                        //RRA - ticket 2149 - 16102024
                                        /*if (finalBrokerReinsurer.length>0){
                                            let valueFinal = finalBrokerReinsurer[0];
                                            let valueFinalSplit = valueFinal.split('-');
                                            let idSFDC = valueFinalSplit[0];
                                            
                                            if (idSFDC.trim().length == 15 || idSFDC.trim().length == 18){
                                                row['selectedBrokerRein'] = finalBrokerReinsurer;
                                            }else if (idSFDC.trim().length < 15){
                                                row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                            }
                                            row['selectedBRLength'] = selectedBR;
                                        }else{
                                            row['selectedBrokerRein'] = finalBrokerReinsurer;
                                            row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                            row['selectedBRLength'] = selectedBR;
                                        }*/

                                    /*}else{
                                        newListBrokerReinsurer.push(tempBrokerReinsurer);
                                        row['selectedBrokerRein'] = newListBrokerReinsurer;
                                        row['selectedBRLength'] = newListBrokerReinsurer.length; 
                                    }*/
                                //}
                            }
                            else{
                                row['selectedBrokerRein'] = null;
                                row['selectedBrokerReinsByRefId'] = null; //RRA - ticket 2149 - 16102024
                                row['selectedBRLength'] = 0;
                            }
                        }
                        console.log('documentType == ',  row['DocumentType__c']);
                        console.log('documentType TECH_DocTypeText__c == ',  row['TECH_DocTypeText__c']);
                        
                        //RRA - ticket 2149 - 10102024
                        if(row['TECH_DocTypeText__c'] == undefined &&  row['DocumentType__c'] == 'Acceptance - Special conditions'){
                            row['TECH_DocTypeText__c'] = 'Acceptance - Special Conditions'
                            row['documentType'] = row.TECH_DocTypeText__c;
                        }else{
                            row['documentType'] = row.TECH_DocTypeText__c;
                        }
                        lstUpdContractualDoc.push(row);
                    }
                    console.log('lstUpdContractualDoc getDocument COntractual == ',lstUpdContractualDoc);
                    this.lstContractualDoc = lstUpdContractualDoc;
                    this.lstCheckboxChangeContractualDoc = this.lstContractualDoc;
                }
                this.displaySpinner = false;
                }
            }
        })
        .catch(error => {
            this.displaySpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error error',
                    message: this.label.error,
                    variant: 'error'
                }),
            );
        });

        getDocuments({ programId : this.program,  groupType : '2', programStage : this.stage})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error'
                    }),
                );
            }
            else{
                if (result.lstContentVersions.length>0){
                    let mapConvertIdRefToIdSDFCForRenew = new Map();
                    this.lstRenewalDoc = result.lstContentVersions;
                    this.mapListBrokerReinsByContentVersionIdRenewal = result.mapListOfCompanyByContentVersionId;
                    console.log('mapListBrokerReinsByContentVersionIdRenewal == ',this.mapListBrokerReinsByContentVersionIdRenewal);
                    let selectedBR;
                    let lstUpdRenewalDoc = [];
                    let newListBrokerReinsurer = [];
                    
                    let lstAvailableBrokerReinsurerIds = Array.from(this.availableBrokerReinsurerIds);
                    for(let i = 0; i < this.lstRenewalDoc.length; i++){
                        let row = { ...this.lstRenewalDoc[i] };
                        newListBrokerReinsurer = [];
                        //RRA - ticket 1512 - 23042023
                        if(this.mapListBrokerReinsByContentVersionIdRenewal[row.Id] != undefined){
                            //AMI 17/06/22 W:0946
                            //default renewal docs selections for all reinsurers
                            //added looping function for all broker/reinsurer present on requests so as to check against newly added broker/reinsurer
                            //for(let a = 0; a < this.dataBrokerReinsurer.length; a++){

                                //let tempBrokerReinsurer = this.dataBrokerReinsurer[a].Broker__c + '-' + this.dataBrokerReinsurer[a].Reinsurer__c;

                                //AMI 17/06/22 W:0946
                                //default renewal docs selections for all reinsurers
                                //added include statement to maintain previous implemented logic
                                //if(this.mapListBrokerReinsByContentVersionIdRenewal[row.Id].includes(tempBrokerReinsurer)){

                                    let selectedBR = 0;
                                    let lstBrokerReinsurer = [ ...this.mapListBrokerReinsByContentVersionIdRenewal[row.Id] ];
                                    let finalBrokerReinsurer = [];
                                    let autoSelectedRecord = [];
                                    let lstKeyBrokerReinsurer = [];
                                    let lstKeyAutoSelectBrokerReinsurer = [];

                                    for(let j = 0; j < lstBrokerReinsurer.length; j++){
                                        if(this.availableBrokerReinsurerIds.has(lstBrokerReinsurer[j])){
                                            finalBrokerReinsurer.push(lstBrokerReinsurer[j]);
                                        }
                                    }
                                    
                                    for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                        if (this.dataBrokerReinsurer[j].Broker__c != null && this.dataBrokerReinsurer[j].ReinsurerStatus__c != null){
                                            mapConvertIdRefToIdSDFCForRenew.set(this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c + '-' + this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c, this.dataBrokerReinsurer[j].Broker__c + '-' + this.dataBrokerReinsurer[j].Reinsurer__c);
                                        }else if (this.dataBrokerReinsurer[j].Broker__c == null && this.dataBrokerReinsurer[j].ReinsurerStatus__c != null){
                                            mapConvertIdRefToIdSDFCForRenew.set('undefined-' + this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c, 'undefined-' + this.dataBrokerReinsurer[j].Reinsurer__c);
                                        }
                                    }
                                    
                                    for(let k = 0; k < finalBrokerReinsurer.length; k++){
                                        lstKeyBrokerReinsurer.push(mapConvertIdRefToIdSDFCForRenew.get(finalBrokerReinsurer[k]));
                                    }
                                    
                                    for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                        for(let k = 0; k < finalBrokerReinsurer.length; k++){
                                            let broker = finalBrokerReinsurer[k].split('-')[0];
                                            let reinsurer = finalBrokerReinsurer[k].split('-')[1];

                                            if(broker == 'undefined' && this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c == undefined && this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c == reinsurer){ //RRA - ticket 2149 - 17102024
                                                selectedBR = selectedBR + 1;
                                            }
                                            else if(this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c == broker && this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c == reinsurer){ //RRA - ticket 2149 - 17102024
                                                selectedBR = selectedBR + 1;
                                            }
                                        }
                                    }
                                      //get records selceted automaticaly
                                      for(let j = 0; j < lstAvailableBrokerReinsurerIds.length; j++){
                                        if(!finalBrokerReinsurer.includes(lstAvailableBrokerReinsurerIds[j])){
                                            autoSelectedRecord.push(lstAvailableBrokerReinsurerIds[j]);
                                            lstKeyAutoSelectBrokerReinsurer.push(mapConvertIdRefToIdSDFCForRenew.get(lstAvailableBrokerReinsurerIds[j]));
                                        }
                                    }
                                    
                                    console.log('selectedBR r== ', selectedBR);
                                    console.log('autoSelectedRecord r== ', autoSelectedRecord);
                                    if (finalBrokerReinsurer.length>0 && autoSelectedRecord.length>0){
                                        row['selectedBrokerRein'] = lstKeyBrokerReinsurer.concat(lstKeyAutoSelectBrokerReinsurer);
                                        row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer.concat(autoSelectedRecord);
                                        row['TECH_SelectedBrokerRein__c'] = finalBrokerReinsurer.length > 0 && autoSelectedRecord.length >0 ? finalBrokerReinsurer.toString() + ',' + autoSelectedRecord.toString() : null;
                                        row['selectedBRLength'] = selectedBR + autoSelectedRecord.length;
                                        row['TECH_SelectedBRLength__c'] = selectedBR + autoSelectedRecord.length;
                                    }else if (finalBrokerReinsurer.length>0 && autoSelectedRecord.length == 0){
                                        row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                        row['selectedBrokerRein'] = lstKeyBrokerReinsurer;
                                        row['TECH_SelectedBrokerRein__c'] = finalBrokerReinsurer.length > 0 ? finalBrokerReinsurer.toString() : null;
                                        row['selectedBRLength'] = selectedBR;
                                        row['TECH_SelectedBRLength__c'] = selectedBR;
                                    }else if (finalBrokerReinsurer.length==0 && autoSelectedRecord.length>0){
                                        row['selectedBrokerReinsByRefId'] = autoSelectedRecord;
                                        row['selectedBrokerRein'] = lstKeyAutoSelectBrokerReinsurer;
                                        row['TECH_SelectedBrokerRein__c'] = autoSelectedRecord.length > 0 ? autoSelectedRecord.toString() : null;
                                        row['selectedBRLength'] = selectedBR + autoSelectedRecord.length;
                                        row['TECH_SelectedBRLength__c'] = selectedBR + autoSelectedRecord.length;
                                    }
                                    //row['selectedBrokerRein'] = finalBrokerReinsurer;
                                    //row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                    //row['selectedBRLength'] = selectedBR;
                                    
                                    //RRA - ticket 2149 - 16102024
                                    /*if (finalBrokerReinsurer.length>0){
                                        let valueFinal = finalBrokerReinsurer[0];
                                        let valueFinalSplit = valueFinal.split('-');
                                        let idSFDC = valueFinalSplit[0];
                                        if (idSFDC.trim().length == 15 || idSFDC.trim().length == 18){
                                            row['selectedBrokerRein'] = finalBrokerReinsurer;
                                        }else if (idSFDC.trim().length < 15){
                                            row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                        }
                                        row['selectedBRLength'] = selectedBR;
                                    }else{
                                        row['selectedBrokerRein'] = finalBrokerReinsurer;
                                        row['selectedBrokerReinsByRefId'] = finalBrokerReinsurer;
                                        row['selectedBRLength'] = selectedBR;
                                    }*/
                                   

                            /*}else{
                                    //AMI 17/06/22 W:0946
                                    //default renewal docs selections for all reinsurers
                                    //added else part to cater for newly created request with new broker/reinsurer
                                    newListBrokerReinsurer.push(tempBrokerReinsurer);
                                    row['selectedBrokerRein'] = newListBrokerReinsurer;
                                    row['selectedBRLength'] = newListBrokerReinsurer.length; 
                                }*/
                            //}
                        }
                        else{
                            //AMI 17/06/22 W:0946
                            //default renewal docs selections for all reinsurers
                            let listBrokerInsurer = [];
                            let listBrokerInsurerByRefId = [];
                            

                            for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                listBrokerInsurer.push(this.dataBrokerReinsurer[j].Broker__c + '-' + this.dataBrokerReinsurer[j].Reinsurer__c);
                                listBrokerInsurerByRefId.push(this.dataBrokerReinsurer[j].TECH_BrokerReferentialId__c + '-' + this.dataBrokerReinsurer[j].TECH_ReinsurerReferentialId__c);
                            }
                            
                            row['selectedBrokerRein'] = listBrokerInsurer;
                            row['selectedBrokerReinsByRefId'] = listBrokerInsurerByRefId; //RRA - ticket 2149 - 16102024
                            row['selectedBRLength'] = listBrokerInsurer.length; 
                        }
                        
                        //RRA - ticket 2149 - 10102024
                        row['documentType'] = row.TECH_DocTypeText__c;
                        row.DocumentType__c = this.mapDocType.get(row['documentType']);
                        if (row.selectedBrokerReinsByRefId != null){
                          if ((row.selectedBrokerReinsByRefId.toString() != null || row.selectedBrokerReinsByRefId.toString() != undefined)){
                            row.TECH_SelectedBrokerRein__c = row.TECH_SelectedBrokerRein__c != null ? row.TECH_SelectedBrokerRein__c.toString() : row.selectedBrokerReinsByRefId.toString();
                            row.TECH_SelectedBRLength__c = row.TECH_SelectedBRLength__c > 0 ? row.TECH_SelectedBRLength__c : row.selectedBRLength;
                          }
                        }
                        lstUpdRenewalDoc.push(row);
                    } 
                    console.log('lstUpdRenewalDoc getDocument renewal == ',lstUpdRenewalDoc);
                    this.lstRenewalDoc = lstUpdRenewalDoc;
                    this.updateAllContenVersionRenew(this.lstRenewalDoc);
                    
                    this.lstCheckboxChangeRenewalDoc = this.lstRenewalDoc;
                    this.displaySpinner = false;
                }
            }
        })
        .catch(error => {
          console.log('error == ', error.message);
            this.displaySpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.label.errorMsg,
                    variant: 'error'
                }),
            );
        });

    }

    handleOpenSelectModal(event){
        this.selectedDocument = event.currentTarget.name;
        console.log('this.selectedDocument ' , this.selectedDocument);
        this.groupType = this.selectedDocument.GroupType__c;
        this.isSelectModalOpen = true;
        let selectedBrokerReinsurer = [];
        let mapListBrokerReinsByContentVersionId = new Map();

        if(this.groupType == this.groupTypeContractual){
            mapListBrokerReinsByContentVersionId = this.mapListBrokerReinsByContentVersionIdContractual;
        }
        else if(this.groupType == this.groupTypeRenewal){
            mapListBrokerReinsByContentVersionId = this.mapListBrokerReinsByContentVersionIdRenewal;
        }
        console.log ('mapListBrokerReinsByContentVersionId == ', mapListBrokerReinsByContentVersionId);
        console.log ('mapListBrokerReinsByContentVersionId.selectedDocument == ', mapListBrokerReinsByContentVersionId[this.selectedDocument.Id]);
        if(mapListBrokerReinsByContentVersionId[this.selectedDocument.Id] != undefined){
            let updDataBrokerReinsurer = [];
            let updDataBrokerReinsurerUnique = []; //RRA - ticket 1564 - 30082023
            let lstBrokerReinsurer = [ ...mapListBrokerReinsByContentVersionId[this.selectedDocument.Id]];
            let setBrokerReinsurer = new Set();

            for(let j = 0; j < lstBrokerReinsurer.length; j++){
                setBrokerReinsurer.add(lstBrokerReinsurer[j]);
            }
            console.log ('setBrokerReinsurer == ', setBrokerReinsurer );
            console.log ('this.dataBrokerReinsurer == ', this.dataBrokerReinsurer );
            for(let i = 0; i < this.dataBrokerReinsurer.length; i++){
                let row = { ...this.dataBrokerReinsurer[i] };

                if((this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c != null && this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c != undefined)){
                    
                    if(this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c != null && this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c != undefined){ //RRA - ticket 2149 - 17102024
                        console.log ('bro == ', this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c + this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c );
                        if(setBrokerReinsurer.has(this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c + '-' + this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c) && this.dataBrokerReinsurer[i].ReinsurerStatus__c != 'Setup'){ //RRA - ticket 2149 - 17102024
                            row['isDisabled'] = true;
                        }
                    }
                    else{
                        console.log ('rea == ', 'undefined-' + this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c );
                        if(setBrokerReinsurer.has('undefined-' + this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c) && this.dataBrokerReinsurer[i].ReinsurerStatus__c != 'Setup'){//RRA - ticket 2149 - 17102024
                            row['isDisabled'] = true;
                        }
                    }
                    updDataBrokerReinsurer.push(row);
                }
            }
            updDataBrokerReinsurerUnique = this.getUniqueData(updDataBrokerReinsurer, 'TECH_BrokerReinsurer__c'); //RRA - ticket 1564 - 30082023
            console.log ('updDataBrokerReinsurer 11== ', updDataBrokerReinsurerUnique);
            this.dataBrokerReinsurer = updDataBrokerReinsurerUnique;  //RRA - ticket 1564 - 30082023
        }
        console.log ('dataBrokerReinsurer 11== ', this.dataBrokerReinsurer);
        console.log ('selectedDocument 11== ', this.selectedDocument);
        if(this.selectedDocument.selectedBrokerReinsByRefId != undefined){
            let updDataBrokerReinsurer = [];
            let updDataBrokerReinsurerUnique = []; //RRA - ticket 1564 - 30082023
            let selectedBrokerReinsByRefId = this.selectedDocument.selectedBrokerReinsByRefId; //RRA - ticket 2149 - 17102024
            console.log ('selectedBrokerReinsByRefId == ', selectedBrokerReinsByRefId);
            for(let i = 0; i < this.dataBrokerReinsurer.length; i++){
                let row = { ...this.dataBrokerReinsurer[i] };
                for(let j = 0; j < selectedBrokerReinsByRefId.length; j++){

                    let broker = selectedBrokerReinsByRefId[j].split('-')[0];
                    let reinsurer = selectedBrokerReinsByRefId[j].split('-')[1];
                    
                    if (this.selectedDocument.GroupType__c == '1'){
                        if(broker == 'undefined' && this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c == undefined && this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c == reinsurer){ //RRA - ticket 2149 - 17102024
                            row['isChecked'] = true;
                        }
                        else if(this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c == broker && this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c == reinsurer){//RRA - ticket 2149 - 17102024
                            row['isChecked'] = true;
                        }
                    }else if (this.selectedDocument.GroupType__c == '2'){
                        if(broker == 'undefined' && this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c == undefined && this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c == reinsurer){ //RRA - ticket 2149 - 17102024
                            row['isChecked'] = true;
                        }
                        else if(this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c == broker && this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c == reinsurer){//RRA - ticket 2149 - 17102024
                            row['isChecked'] = true;
                        }
                    }

                   
                }
                updDataBrokerReinsurer.push(row);
            }
            updDataBrokerReinsurerUnique = this.getUniqueData(updDataBrokerReinsurer, 'TECH_BrokerReinsurer__c'); //RRA - ticket 1564 - 30082023
            console.log ('updDataBrokerReinsurerUnique 22== ', updDataBrokerReinsurerUnique);
            this.dataBrokerReinsurer = updDataBrokerReinsurerUnique; //RRA - ticket 1564 - 30082023
            console.log ('dataBrokerReinsurer 22== ', this.dataBrokerReinsurer);
        }
    }

    handleCloseSelectModal(){
        this.isSelectModalOpen = false;
        let updDataBrokerReinsurer = [];

        for(let i = 0; i < this.dataBrokerReinsurer.length; i++){
            let row = { ...this.dataBrokerReinsurer[i] };
            row['isChecked'] = false;
            row['isDisabled'] = false;
            updDataBrokerReinsurer.push(row);
        }

        this.dataBrokerReinsurer = updDataBrokerReinsurer;
        this.lstCheckboxChangeRenewalDoc = this.lstRenewalDoc;
        this.lstCheckboxChangeContractualDoc = this.lstContractualDoc;
    }

    handleRowSelectionBrokerRein(event){
        this.selectedBrokerReinsurer = event.detail.selectedRows;
    }

    handleSaveBrokerReins(){
        if(this.groupType == this.groupTypeContractual){
            this.lstContractualDoc = [ ...this.lstCheckboxChangeContractualDoc ];
        }
        else if(this.groupType == this.groupTypeRenewal){
            this.lstRenewalDoc = [ ...this.lstCheckboxChangeRenewalDoc ];
        }
        //RRA - ticket 1512 - 23042023 - if button Save is ticked, update contentVersion on Contract and Renew Docs
        this.isSaveOnBR = true;
        if (this.isSaveOnBR){
            let lstContentVersionUpdatedContractual = JSON.parse(sessionStorage.getItem('lstCVUpdatedContractual'));
            let lstContentVersionUpdatedRenewal = JSON.parse(sessionStorage.getItem('lstCVUpdatedRenew'));
            console.log('lstContentVersionUpdatedContractual 11== ', lstContentVersionUpdatedContractual);
            console.log('lstContentVersionUpdatedRenewal 11== ', lstContentVersionUpdatedRenewal);
            this.updateContenVersions(lstContentVersionUpdatedContractual, lstContentVersionUpdatedRenewal, this.selectedDocument.ContentDocumentId,false);
        }
        
        this.handleCloseSelectModal();
    }
    
    handleOnClickSelectAll(event){
        let selectedRow = event.currentTarget.name;
        let preSelection = [];
        let preSelectionRefId = [];
        let preSelectionUnique = []; //RRA - ticket 1564 - 30082023
        let preSelectionUniqueRefId = []; 
        this.groupType = selectedRow.GroupType__c;
        this.selectedDocument = event.currentTarget.name;

        //MBE - 03/11/2020
        let preSelectionBrokerRein = [];
        let preSelectionBrokerReinByRefId = []; //RRA - ticket 2149 - 16102024
        let preSelectionBrokerReinUnique = []; //RRA - ticket 1564 - 30082023
        let preSelectionBrokerReinByRefIdUnique = []; //RRA - ticket 2149 - 16102024
        for(let i = 0; i < this.dataBrokerReinsurer.length; i++){
            preSelectionBrokerRein.push(this.dataBrokerReinsurer[i].Broker__c + '-' + this.dataBrokerReinsurer[i].Reinsurer__c);
            preSelectionBrokerReinByRefId.push(this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c + '-' + this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c);
            if(this.dataBrokerReinsurer[i].Broker__c != null){
                preSelection.push(this.dataBrokerReinsurer[i].Broker__c)
                preSelectionRefId.push(this.dataBrokerReinsurer[i].TECH_BrokerReferentialId__c);
            }
            else{
                preSelection.push(this.dataBrokerReinsurer[i].Reinsurer__c);
                preSelectionRefId.push(this.dataBrokerReinsurer[i].TECH_ReinsurerReferentialId__c);
            }
        }
        //RRA - ticket 1564 - 30082023
        //**Get all unique value in list */
        //**value --> item in array
        //**index --> index of item
        //**array --> array reference, (in this case "list")*/
        preSelectionBrokerReinUnique = preSelectionBrokerRein.filter((value, index, array) => array.indexOf(value) === index);
        preSelectionBrokerReinByRefIdUnique = preSelectionBrokerReinByRefId.filter((value, index, array) => array.indexOf(value) === index);
        preSelectionUnique = preSelection.filter((value, index, array) => array.indexOf(value) === index);
        preSelectionUniqueRefId = preSelectionRefId.filter((value, index, array) => array.indexOf(value) === index);
        if(this.groupType == this.groupTypeContractual){
            console.log('lstContractualDoc selectAll == ', this.lstContractualDoc);
            contentVersionOnContractRenew({contentDocId : this.selectedDocument.ContentDocumentId})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                }
                else{
                    var lstUpdContractualDoc = [];
                    for(let i = 0; i < this.lstContractualDoc.length; i++){
                        let row = this.lstContractualDoc[i];
                        if(this.lstContractualDoc[i].ContentDocumentId == this.selectedDocument.ContentDocumentId){
                            //MBE - 03/11/2020
                            row['selectedBRLength'] = preSelectionBrokerReinUnique.length; //RRA - ticket 1564 - 30082023
                            row['selectedBrokerRein'] = preSelectionBrokerReinUnique; //RRA - ticket 1564 - 30082023
                            row['selectedBrokerReinsByRefId'] = preSelectionBrokerReinByRefIdUnique; 
        
                            //RRA - ticket 2149 - 10102024
                            if (result.TECH_SelectedBrokerRein__c != null){
                                if (row.selectedBrokerRein != null ){
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                }else{
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                }          
                            }else{
                                if (row.selectedBrokerRein != null){
                                    row.TECH_SelectedBrokerRein__c = row.selectedBrokerReinsByRefId.toString();
                                    row.TECH_SelectedBRLength__c = row.selectedBRLength;
                                }else{
                                    row.TECH_SelectedBrokerRein__c = null;
                                    row.TECH_SelectedBRLength__c = 0;
                                }
                               
                            }             
                        }else{
                            if (result.TECH_SelectedBrokerRein__c != null ){
                                if (row.selectedBrokerRein != null){
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                     
                                }else{
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                }
                            }else {
                                if (row.selectedBrokerRein != null){
                                    row.TECH_SelectedBrokerRein__c = row.selectedBrokerReinsByRefId.toString();
                                    row.TECH_SelectedBRLength__c = row.selectedBRLength;
                                }else{
                                    row.TECH_SelectedBrokerRein__c = null;
                                    row.TECH_SelectedBRLength__c = 0;
                                }
                            }
                        }
                        
                         //RRA - ticket 2149 - 10102024
                         if ( row.Phase__c == 'Quote' || row.Phase__c == 'Lead' || row.Phase__c == 'Placement' || row.Phase__c == 'Signing' || row.Phase__c == 'Conditions' || row.Phase__c == 'All'){
                            row['Phase__c'] =  this.mapValueToAPI.get(row.Phase__c); 
                        }else{
                            row['Phase__c']  = row.Phase__c;
                        }
                         //RRA - ticket 2149 - 10102024
                        if(row['TECH_DocTypeText__c'] == undefined &&  row['DocumentType__c'] == 'Acceptance - Special conditions'){
                            row['TECH_DocTypeText__c'] = 'Acceptance - Special Conditions'
                        }
                        row['documentType'] = row.TECH_DocTypeText__c;
                        row.DocumentType__c = this.mapDocType.get(row['documentType']);
                        console.log('documentType22 == ',  row['DocumentType__c']);
                        lstUpdContractualDoc.push(row);
                    }
                    this.lstContractualDoc = lstUpdContractualDoc;
                    console.log('lstContractualDoc 11== ', this.lstContractualDoc);                  
                    this.updateContenVersions(this.lstContractualDoc, null, this.selectedDocument.ContentDocumentId, true); //RRA - Ticket 2149 - 09102024
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error updateContenVersions contract == ', error);
                this.displaySpinner = false;
            });
        }
        else if(this.groupType == this.groupTypeRenewal){
            var lstUpdRenewalDoc = [];
            contentVersionOnContractRenew({contentDocId : this.selectedDocument.ContentDocumentId})
            .then(result => {
                console.log('ok result contentVersionOnContractRenew Renew', result );
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                }
                else{
                    for(let i = 0; i < this.lstRenewalDoc.length; i++){
                        let row = this.lstRenewalDoc[i];
                        if(this.lstRenewalDoc[i].ContentDocumentId == this.selectedDocument.ContentDocumentId){
                            row['selectedBRLength'] = preSelectionUnique.length; //RRA - ticket 1564 - 30082023
                            row['selectedBrokerRein'] = preSelectionUnique; //RRA - ticket 1564 - 30082023
                            row['selectedBrokerReinsByRefId'] = preSelectionUniqueRefId;
        
                             //MBE - 03/11/2020
                             row['selectedBRLength'] = preSelectionBrokerReinUnique.length; //RRA - ticket 1564 - 30082023
                             row['selectedBrokerRein'] = preSelectionBrokerReinUnique; //RRA - ticket 1564 - 30082023
                             row['selectedBrokerReinsByRefId'] = preSelectionBrokerReinByRefIdUnique;
                             
                            //RRA - ticket 2149 - 10102024
                            if (result.TECH_SelectedBrokerRein__c != null ){
                                if (row.selectedBrokerRein !=null){
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                }else{
                                        let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                        row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                        row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                }          
                            }else{
                                if (row.selectedBrokerRein != null){
                                    row.TECH_SelectedBrokerRein__c = row.selectedBrokerReinsByRefId.toString();
                                    row.TECH_SelectedBRLength__c = row.selectedBRLength;
                                }else{
                                    row.TECH_SelectedBrokerRein__c = null;
                                    row.TECH_SelectedBRLength__c = 0;
                                }
                               
                            }             
                        }else{
                            console.log('Other' );
                            console.log('(result.TECH_SelectedBrokerRein__c',result.TECH_SelectedBrokerRein__c);
                            console.log('(row.selectedBrokerReinsByRefId',row.selectedBrokerReinsByRefId.toString());
                            if (result.TECH_SelectedBrokerRein__c != null){
                                if (row.TECH_SelectedBrokerRein__c != null && row.selectedBrokerReinsByRefId != null){
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                     
                                }else{
                                    let checkData = this.checkDataAndRemoveDuplicate(result.TECH_SelectedBrokerRein__c.toString(),  row.selectedBrokerReinsByRefId.toString());
                                    row.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                    row.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                }
                            }else {
                                if (row.selectedBrokerRein != null){
                                    row.TECH_SelectedBrokerRein__c = row.selectedBrokerReinsByRefId.toString();
                                    row.TECH_SelectedBRLength__c = row.selectedBRLength;
                                }else{
                                    row.TECH_SelectedBrokerRein__c = null;
                                    row.TECH_SelectedBRLength__c = 0;
                                }
                            }
                        }
                        
                         //RRA - ticket 2149 - 10102024
                         if ( row.Phase__c == 'Quote' || row.Phase__c == 'Lead' || row.Phase__c == 'Placement' || row.Phase__c == 'Signing' || row.Phase__c == 'Conditions' || row.Phase__c == 'All'){
                            row['Phase__c'] =  this.mapValueToAPI.get(row.Phase__c); 
                        }else{
                            row['Phase__c']  = row.Phase__c;
                        }
                         
                         //RRA - ticket 2149 - 10102024
                        if(row['TECH_DocTypeText__c'] == undefined &&  row['DocumentType__c'] == 'Acceptance - Special conditions'){
                            row['TECH_DocTypeText__c'] = 'Acceptance - Special Conditions'
                        }
                        row['documentType'] = row.TECH_DocTypeText__c;
                        row.DocumentType__c = this.mapDocType.get(row['documentType']);
                        lstUpdRenewalDoc.push(row);
                    }
                    this.lstRenewalDoc = lstUpdRenewalDoc;
                    console.log('lstRenewalDoc == ', this.lstRenewalDoc );               
                    this.updateContenVersions(null, this.lstRenewalDoc, this.selectedDocument.ContentDocumentId, true); //RRA - Ticket 2149 - 09102024
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error updateContenVersions renew == ', error);
                this.displaySpinner = false;
            }); 
        }
    }
                                        
    getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }

    handleCloseSendUpdateRemindReqModal(){
        fireEvent(this.pageRef, 'refreshReq', 'refresh');
        fireEvent(this.pageRef, 'closeSendUpdateRemindReqModal', false);
    }

    handleSendUpdateRemindRequest(){
        this.displaySpinner = true;
        if(this.btnNameClick == 'Send' || this.btnNameClick == 'Update'){
            this.sendUpdateRequest();
        }
        else if(this.btnNameClick == 'Remind'){
            this.sendReminderForRequest();
        }
    }

    sendUpdateRequest(){
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        let lstUpdSelectedRequest = [];

        for(let i = 0; i < this.selectedDataRequest.length; i++){
            let row = { ...this.selectedDataRequest[i] };
            row['WrittenShare__c'] = parseFloat(row.WrittenShare__c);
            lstUpdSelectedRequest.push(row);
        }

        this.selectedDataRequest = lstUpdSelectedRequest;

        //AMI 30/06/22 W:0822
        //propperty to check if at least one request is broker/reinsurer
        let isFullPool = false;

        if(this.displayPools){
            //MRA 19/08/2022 W-0822 : check if at least one request is broker/reinsurer
            var hasOneNonPoolReq = this.selectedDataRequest.find(iter => {
                return (iter.isRequestPool === false && parseInt(iter.SignedShareVal) !== 0 && iter.SignedShareVal !==undefined && iter.SignedShareVal !==null);
            });
               
            isFullPool = hasOneNonPoolReq === undefined ? true : false;
        }

        if(allValid) {
            let lstDocVisibilityToInsert = [];
            let lstSelectedContractualDoc = [];
            let lstSelectedRenewalDoc = [];
            let today = new Date();
            //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
            this.confirmMessage = documentNotAssigned ;
            this.confirmLabel = 'Send the request(s)' ;
            this.cancelLabel = 'Stay on the Current Page' ;
            if(this.lstContractualDoc != undefined){
                //AMI 30/06/22 W:0822
                //prevent send/update if at least one document has not been attached to at least one reinsurer
                let contractualDocWOAssignee = this.lstContractualDoc.find(iter => {
                    return iter.selectedBRLength === 0 || iter.selectedBRLength === undefined || iter.selectedBRLength === null;
                });

                //AMI 30/06/22 W:0822
                //prevent send/update by throwing error message
                //MRA W-822 Confirmation Modal 24/08/2022
                if(contractualDocWOAssignee !== undefined && isFullPool === false && this.bypassDocAssignment === false){
                    //this.originalMessage = documentNotAssigned;
                    this.isDialogVisible = true;
                    return ;
                }else{
                    for(let i = 0; i < this.lstContractualDoc.length; i++){
                        if(this.lstContractualDoc[i].selectedBrokerRein != undefined){
                            for(let j = 0; j < this.lstContractualDoc[i].selectedBrokerRein.length; j++){
    
                                let objDocVisibilityContractual = {};
                                let broker = this.lstContractualDoc[i].selectedBrokerRein[j].split('-')[0];
                                let reinsurer = this.lstContractualDoc[i].selectedBrokerRein[j].split('-')[1]; 
                                objDocVisibilityContractual.DocumentUpdateDate__c = today;
                                objDocVisibilityContractual.ContentVersionId__c = this.lstContractualDoc[i].Id;
                                objDocVisibilityContractual.Program__c = this.program;
                                objDocVisibilityContractual.Reinsurer__c = reinsurer;
    
                                if(broker != 'undefined'){
                                    objDocVisibilityContractual.Broker__c = broker;
                                }
    
                                lstDocVisibilityToInsert.push(objDocVisibilityContractual);
                            }
                        }
                        if(this.lstContractualDoc[i].selectedBRLength > 0){
                            lstSelectedContractualDoc.push(this.lstContractualDoc[i]);
                        }
                    }
                }
            }

            if(this.lstRenewalDoc != undefined){
                //AMI 30/06/22 W:0822
                //prevent send/update if at least one document has not been attached to at least one reinsurer
                let renewalDocWOAssignee = this.lstRenewalDoc.find(iter => {
                    return iter.selectedBRLength === 0 || iter.selectedBRLength === undefined || iter.selectedBRLength === null;
                });

                //AMI 30/06/22 W:0822
                //prevent send/update by throwing error message
                //MRA W-822 Confirmation Modal 24/08/2022
                if(renewalDocWOAssignee !== undefined && isFullPool === false && this.bypassDocAssignment === false){
                    //this.originalMessage = documentNotAssigned;
                    this.isDialogVisible = true;
                    return ;
                }else{
                    for(let i = 0; i < this.lstRenewalDoc.length; i++){
                        if(this.lstRenewalDoc[i].selectedBrokerRein != undefined){
                            for(let j = 0; j < this.lstRenewalDoc[i].selectedBrokerRein.length; j++){
    
                                let objDocVisibilityRenew = {};
                                let broker = this.lstRenewalDoc[i].selectedBrokerRein[j].split('-')[0];
                                let reinsurer = this.lstRenewalDoc[i].selectedBrokerRein[j].split('-')[1];
                                objDocVisibilityRenew.DocumentUpdateDate__c = today;
                                objDocVisibilityRenew.ContentVersionId__c = this.lstRenewalDoc[i].Id;
                                objDocVisibilityRenew.Program__c = this.program;
                                objDocVisibilityRenew.Reinsurer__c = reinsurer;
    
                                if(broker != 'undefined'){
                                    objDocVisibilityRenew.Broker__c = broker;
                                }
                                lstDocVisibilityToInsert.push(objDocVisibilityRenew);
                            }
                        }
    
                        if(this.lstRenewalDoc[i].selectedBRLength > 0){
                            lstSelectedRenewalDoc.push(this.lstRenewalDoc[i]);
                        }
                    }
                }
            }

            //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact: START
            if(this.checkContactsOnReinsurerBroker())
            return ;
            //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact: END

            this.objRequest.Comments__c = this.commentValue;
            this.objRequest.ExpectedResponseDate__c = this.expectedAnsDateValue;
            let lstPoolIdToEmail = [];
            let emailEmpty = false;

            if(this.displayPools && this.lstPoolsData != null){
                for(let x = 0; x < this.lstPoolsData.length; x++){
                    if(this.lstPoolsData[x]['Email'] == null || this.lstPoolsData[x]['Email'] == undefined){
                        emailEmpty == true
                    }
                    else{
                        var poolToEmail = this.lstPoolsData[x]['Id']+ '|'+this.lstPoolsData[x]['Email'];
                        lstPoolIdToEmail.push(poolToEmail);
                    }
                }
            }

            if( (this.displayPools == true && emailEmpty == false) || this.displayPools == false){
                //RRA - 955 add only contact selected (contactSelected) on title Send/Update 
                //RRA - 1104 - 03/06/2022
                sendUpdateRequest({dateEntryExpectedDate : this.expectedAnsDateValue, lstRequests : this.selectedDataRequest, lstDocVisibility : lstDocVisibilityToInsert, lstRequestId : this.lstSelectedDataRequestId, stageType : this.stage
                    , requestCommentExpectedAnsDate : this.objRequest, lstAccountContact :this.contactSelected
                    , lstContractDoc : lstSelectedContractualDoc, lstRenewDoc : lstSelectedRenewalDoc, btnNameSendUpdateRemind : this.btnNameClick
                    , sendPools : this.displayPools, lstPoolIdToTreatyId : this.lstPoolIdToTreatyId, lstPoolIdToEmail : lstPoolIdToEmail, lstTreatyIds : this.lstTreatyIds, programId : this.program})
                .then(result => {
                    if(result.hasOwnProperty('Error') && result.Error){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: result.Error,
                                variant: 'error'
                            }),
                        );
                        this.displaySpinner = false;
                    }
                    else{
                        if(this.btnNameClick == 'Send'){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: this.stage+' Request Sent Successfully.',
                                    variant: 'success'
                                })
                            ,);
                            this.displaySpinner = false;

                            //AMI 01/06/22: W-0940
                            //notify parent component of successful update to refresh latter
                            this.dispatchEvent(
                                new CustomEvent('signingsent')
                            );
                        }
                        else if(this.btnNameClick == 'Update'){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: this.stage+' Request Updated Successfully.',
                                    variant: 'success'
                                })
                            ,);
                            this.displaySpinner = false;
                        }
                        this.handleCloseSendUpdateRemindReqModal();
                    }
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'ERROR',
                            message: this.label.errorMsg,
                            variant: 'error'
                        }),
                    );
                    this.displaySpinner = false;
                });
            }
            else{
                //Atleast one pool does not have an assigned Email address
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.NoAssignedEmailForPool, variant: 'error'}), );
            }
        }
        else{
            //Please enter a value for Expected Answer Date.
            this.dispatchEvent(new ShowToastEvent({title: 'Error', message: this.label.EnterExpectedAnswerDate, variant: 'error'}), );
            this.displaySpinner = false;
        }
    }
    //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact: START
    checkContactsOnReinsurerBroker(){
        this.lstBrokerReinsurerNameApplyTo  = [...new Set(this.lstBrokerReinsurerNameApplyTo)];
        this.lstBrokerReinsurerNameOnContact  = [...new Set(this.lstBrokerReinsurerNameOnContact)];
        let lstNoContactReinBro = '' ; 
        let i = 0 ;
        this.lstBrokerReinsurerNameApplyTo.forEach(element => {
            if (!this.lstBrokerReinsurerNameOnContact.includes(element)) {
                i++ ;
                if(lstNoContactReinBro === '')
                lstNoContactReinBro = element ;
                else
                lstNoContactReinBro = lstNoContactReinBro + ' ,' + element ;
            }
        });
        if (this.lstBrokerReinsurerNameApplyTo.length !== this.lstBrokerReinsurerNameOnContact.length && this.isContactMissing === false) {
            if(this.displaySpinner === true)
            this.displaySpinner = false ;
            let doDoes = i>1?'do':'does' ;
            this.confirmMessage = lstNoContactReinBro + doDoes +' not have a contact associated. Do you want to continue?' ;
            this.confirmLabel = 'Yes';
            this.cancelLabel = 'No' ;
            this.isContactMissing = true ;
            this.isDialogVisible = true;
            return true;
        }
        else 
            return false ;
    }
    //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact: END

    sendReminderForRequest(){
        let lstPoolIdToEmail = [];
        if(this.displayPools && this.lstPoolsData != null){
            for(let x = 0; x < this.lstPoolsData.length; x++){
                 var poolToEmail = this.lstPoolsData[x]['Id']+ '|'+this.lstPoolsData[x]['Email'];
                lstPoolIdToEmail.push(poolToEmail);
            }
        }
        //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact: START
        this.bypassDocAssignment = true ;
        if(this.checkContactsOnReinsurerBroker())
        return ;
        //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact: END


        //RRA - 955 add only contact selected (contactSelected) on title Reminder
        sendReminderForRequest({lstAccountContact : this.contactSelected, lstApplyToRequestId: this.lstSelectedDataRequestId, selectedProgramId : this.program, stageName : this.stage, lstPoolIdToTreatyId : this.lstPoolIdToTreatyId, lstPoolIdToEmail : lstPoolIdToEmail, lstRequestData : this.selectedDataRequest})
        .then(result => {
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Error,
                        variant: 'error',
                    }),
                );
                this.displaySpinner = false;
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                         title: 'Success',
                         message: this.label.RemindEmailSendSuccessfully,
                         variant: 'success',
                    }),
                );
                this.displaySpinner = false;

                this.handleCloseSendUpdateRemindReqModal();
            }
        })
        .catch(error => {
            this.error = error;
            this.displaySpinner = false;
        });
    }

    handleOnChangeComment(event){
        this.commentValue = event.currentTarget.value;
    }

    handleOnChangeExpectedAnsDate(event){
        this.expectedAnsDateValue = event.currentTarget.value;
    }

    handleChangeBrokerReinsurerCheckbox(event){
        let brokerRein = event.currentTarget.name;
        let checkValue = event.currentTarget.checked;
        let updDataBrokerReinsurer = [];
        let brokerReinId;
        let brokerReinRefId;      

        if(brokerRein.Broker__c != undefined && brokerRein.Broker__c != null){
            brokerReinId = brokerRein.Broker__c + '-' + brokerRein.Reinsurer__c;
        }
        else{
            brokerReinId = 'undefined-' + brokerRein.Reinsurer__c;
        }
        
        if(brokerRein.TECH_BrokerReferentialId__c != undefined && brokerRein.TECH_BrokerReferentialId__c != null){
            brokerReinRefId = brokerRein.TECH_BrokerReferentialId__c + '-' + brokerRein.TECH_ReinsurerReferentialId__c;
        }
        else{
            brokerReinRefId = 'undefined-' + brokerRein.TECH_ReinsurerReferentialId__c;
        }
        
        
        
        

        if(this.groupType == this.groupTypeContractual){
            //Contractual Document
            let lstUpdContractualDoc = [];

            for(let i = 0; i < this.lstCheckboxChangeContractualDoc.length; i++){
                let row = { ...this.lstCheckboxChangeContractualDoc[i] };
                if(this.selectedDocument.Id == row.Id){
                    if(row.selectedBrokerRein != undefined){
                        let preSelection = [ ...row.selectedBrokerRein ];
                        //RRA - ticket 2149 - 16102024
                        let preSelectionRefId = [ ...row.selectedBrokerReinsByRefId ];;
                        if(checkValue == true){
                            let updPreSelection = [];
                            let updPreSelectionRefId = [];

                            for(let j = 0; j < preSelection.length; j++){
                                updPreSelection.push(preSelection[j]);
                            }
                            
                            for(let j = 0; j < preSelectionRefId.length; j++){
                                updPreSelectionRefId.push(preSelectionRefId[j]);
                            }

                            updPreSelection.push(brokerReinId);
                            updPreSelectionRefId.push(brokerReinRefId);
                            
                            console.log('updPreSelection == ', updPreSelection);
                            console.log('updPreSelectionRefId == ', updPreSelectionRefId);
                            preSelection = updPreSelection;
                            preSelectionRefId = updPreSelectionRefId;
                            let selectedBR = 0;

                            for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                for(let k = 0; k < updPreSelection.length; k++){
                                    let broker = updPreSelection[k].split('-')[0];
                                    let reinsurer = updPreSelection[k].split('-')[1];

                                    if(broker == 'undefined' && this.dataBrokerReinsurer[j].Broker__c == undefined && this.dataBrokerReinsurer[j].Reinsurer__c == reinsurer){
                                        selectedBR = selectedBR + 1;
                                    }
                                    else if(this.dataBrokerReinsurer[j].Broker__c == broker && this.dataBrokerReinsurer[j].Reinsurer__c == reinsurer){
                                        selectedBR = selectedBR + 1;
                                    }
                                }
                            }

                            row['selectedBrokerRein'] = preSelection;
                            row['selectedBrokerReinsByRefId'] = preSelectionRefId;
                            row['selectedBRLength'] = selectedBR;
                        }
                        else{
                            //RRA - ticket 2149 - 16102024
                            let updPreSelection = [];
                            let updPreSelectionRefId = [];

                            for(let j = 0; j < preSelection.length; j++){
                                if(preSelection[j] != brokerReinId){
                                    updPreSelection.push(preSelection[j]);
                                }
                            }
                            
                            for(let j = 0; j < preSelectionRefId.length; j++){
                                if(preSelectionRefId[j] != brokerReinRefId){
                                    updPreSelectionRefId.push(preSelectionRefId[j]);
                                }
                            }

                            preSelection = updPreSelection;
                            preSelectionRefId = updPreSelectionRefId;
                            row['selectedBrokerRein'] = preSelection;
                            row['selectedBrokerReinsByRefId'] = preSelectionRefId;
                            row['selectedBRLength'] = preSelection.length;
                        }

                    }
                    else{
                        let preSelection = [];
                        let preSelectionRefId = [];
                        preSelection.push(brokerReinId);
                        preSelectionRefId.push(brokerReinRefId);
                        row['selectedBrokerRein'] = preSelection;
                        row['selectedBrokerReinsByRefId'] = preSelectionRefId;
                        row['selectedBRLength'] = preSelection.length;
                    }
                }

                lstUpdContractualDoc.push(row);
            }
            console.log('lstUpdContractualDoc handleChangeBrokerReinsurerCheckbox == ',lstUpdContractualDoc);

            //RRA - ticket 1512 - 23042023 _ get the contentVersion Id and update new fields TECH_SelectedBRLength__c and TECH_SelectedBrokerRein__c in the database
            var lstContentVersionUpdatedContractual = [];
            for (var i = 0; i < lstUpdContractualDoc.length; i++){
                //
                var objDocument = {
                    //DocumentType__c : DOCUMENT_TYPE_FIELD,
                    ContentDocumentId : CONTENT_DOCMENT_ID,
                    FromThemis__c : FROM_THEMIS,
                    Id : CONTENTVERSION_ID,
                    GroupType__c : GROUP_TYPE_FIELD,
                    Phase__c : PHASE_FIELD,
                    Title : TITLE_FIELD,
                    VersionNumber : VERSIONNUMB_FIELD,
                    TECH_SelectedBRLength__c : TECH_SELECTEDBR_SIZE_FIELD,
                    TECH_SelectedBrokerRein__c : TECH_SELECTEDBR_FIELD
                }
                //objDocument.DocumentType__c = lstUpdContractualDoc[i].DocumentType__c;
                objDocument.ContentDocumentId = lstUpdContractualDoc[i].ContentDocumentId;
                objDocument.FromThemis__c =lstUpdContractualDoc[i].FromThemis__c;;
                objDocument.GroupType__c = lstUpdContractualDoc[i].GroupType__c;
                objDocument.Title = lstUpdContractualDoc[i].Title;
                objDocument.Id = lstUpdContractualDoc[i].Id;
                //objDocument.Phase__c =  lstUpdContractualDoc[i].Phase__c; 
                //RRA - ticket 2149 09102024
                if ( lstUpdContractualDoc[i].Phase__c == 'Quote' || lstUpdContractualDoc[i].Phase__c == 'Lead' || lstUpdContractualDoc[i].Phase__c == 'Placement' || lstUpdContractualDoc[i].Phase__c == 'Signing' || lstUpdContractualDoc[i].Phase__c == 'Conditions' || lstUpdContractualDoc[i].Phase__c == 'All'){
                    objDocument.Phase__c =  this.mapValueToAPI.get(lstUpdContractualDoc[i].Phase__c); 
                }else{
                    objDocument.Phase__c = lstUpdContractualDoc[i].Phase__c;
                }
               
                objDocument.VersionNumber = lstUpdContractualDoc[i].VersionNumber;

                //Section : Selection of B/R on current Document - RRA - ticket 2149 09102024
                if (this.selectedDocument.ContentDocumentId == lstUpdContractualDoc[i].ContentDocumentId){
                    console.log('this.selectedDocument Contractual == ',this.selectedDocument);        
                    if (lstUpdContractualDoc[i].selectedBrokerReinsByRefId != null){
                        if (lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c != null){
                            let key =  lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c + ',' + lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString();
                            let selectedRow = this.selectedDocument.TECH_SelectedBrokerRein__c + ',' + this.selectedDocument.selectedBrokerReinsByRefId.toString();
                            if (key !== selectedRow){
                                console.log('mandalo lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c', lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c);
                                console.log('mandalo lstUpdContractualDoc[i].selectedBrokerReinsByRefId', lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString());
                                let checkData = this.checkDataAndRemoveDuplicate(lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c.toString(),  lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString());
                                objDocument.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                objDocument.TECH_SelectedBRLength__c = checkData.lengthxObj;
                                
                            }else{
                                let checkData = this.checkDataAndRemoveDuplicate(lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c.toString(),  lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString());
                                objDocument.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                objDocument.TECH_SelectedBRLength__c = checkData.lengthxObj;
                            }
                        }else{
                            objDocument.TECH_SelectedBrokerRein__c = lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString() != null ? lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString() : null;
                            objDocument.TECH_SelectedBRLength__c =  lstUpdContractualDoc[i].selectedBRLength > 0 ? lstUpdContractualDoc[i].selectedBRLength : 0;
                        }
                    }else{
                        objDocument.TECH_SelectedBrokerRein__c = null;
                        objDocument.TECH_SelectedBRLength__c = 0;
                    }
                //Section : get B/R on Other Document - RRA - ticket 2149 09102024
                }else{
                    console.log('Other Contractual Doc');   
                    if (lstUpdContractualDoc[i].selectedBrokerReinsByRefId == null){
                        objDocument.TECH_SelectedBrokerRein__c = null;
                        objDocument.TECH_SelectedBRLength__c = 0;
                    }else{
                        if (lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c != null){
                                let checkData = this.checkDataAndRemoveDuplicate(lstUpdContractualDoc[i].TECH_SelectedBrokerRein__c.toString(),  lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString());
                                objDocument.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                objDocument.TECH_SelectedBRLength__c = checkData.lengthxObj;
                        }else{
                            objDocument.TECH_SelectedBrokerRein__c = lstUpdContractualDoc[i].selectedBrokerReinsByRefId.toString();
                            objDocument.TECH_SelectedBRLength__c =  lstUpdContractualDoc[i].selectedBRLength;
                        }
                    }
                }
                //objDocument.TECH_SelectedBrokerRein__c = lstUpdContractualDoc[i].selectedBrokerRein !=null ? lstUpdContractualDoc[i].selectedBrokerRein.toString() : null;
                lstContentVersionUpdatedContractual.push(objDocument);
            }
            console.log('lstContentVersionUpdatedContractual == ', JSON.parse(JSON.stringify(lstContentVersionUpdatedContractual)));
            sessionStorage.setItem('lstCVUpdatedContractual', JSON.stringify(lstContentVersionUpdatedContractual));

            this.lstCheckboxChangeContractualDoc = [ ...lstUpdContractualDoc ];

        }
        else if(this.groupType == this.groupTypeRenewal){
            //Renewal Document
            let lstUpdRenewalDoc = [];
            for(let i = 0; i < this.lstCheckboxChangeRenewalDoc.length; i++){
                let row = { ...this.lstCheckboxChangeRenewalDoc[i] };
                if(this.selectedDocument.Id == row.Id){
                    if(row.selectedBrokerRein != undefined){
                        let preSelection = [ ...row.selectedBrokerRein ];
                        //RRA - ticket 2149 - 16102024
                        let preSelectionRefId = [ ...row.selectedBrokerReinsByRefId ];;
                        if(checkValue == true){
                            let updPreSelection = [];
                            let updPreSelectionRefId = [];

                            for(let j = 0; j < preSelection.length; j++){
                                updPreSelection.push(preSelection[j]);
                            }
                            
                            for(let j = 0; j < preSelectionRefId.length; j++){
                                updPreSelectionRefId.push(preSelectionRefId[j]);
                            }

                            updPreSelection.push(brokerReinId);
                            updPreSelectionRefId.push(brokerReinRefId);
                            preSelection = updPreSelection;
                            preSelectionRefId = updPreSelectionRefId;
                            let selectedBR = 0;

                            for(let j = 0; j < this.dataBrokerReinsurer.length; j++){
                                for(let k = 0; k < updPreSelection.length; k++){
                                    let broker = updPreSelection[k].split('-')[0];
                                    let reinsurer = updPreSelection[k].split('-')[1];

                                    if(broker == 'undefined' && this.dataBrokerReinsurer[j].Broker__c == undefined && this.dataBrokerReinsurer[j].Reinsurer__c == reinsurer){
                                        selectedBR = selectedBR + 1;
                                    }
                                    else if(this.dataBrokerReinsurer[j].Broker__c == broker && this.dataBrokerReinsurer[j].Reinsurer__c == reinsurer){
                                        selectedBR = selectedBR + 1;
                                    }
                                }
                            }

                            row['selectedBrokerRein'] = preSelection;
                            row['selectedBrokerReinsByRefId'] = preSelectionRefId;
                            row['selectedBRLength'] = selectedBR;
                        }
                        else{
                            let updPreSelection = [];
                            let updPreSelectionrefId = [];

                            for(let j = 0; j < preSelection.length; j++){
                                if(preSelection[j] != brokerReinId){
                                    updPreSelection.push(preSelection[j]);
                                }
                            }
                            
                            for(let j = 0; j < preSelectionRefId.length; j++){
                                if(preSelectionRefId[j] != brokerReinRefId){
                                    updPreSelectionrefId.push(preSelectionRefId[j]);
                                }
                            }

                            preSelection = updPreSelection;
                            preSelectionRefId = updPreSelectionrefId;
                            row['selectedBrokerRein'] = preSelection;
                            row['selectedBrokerReinsByRefId'] = preSelectionRefId;
                            row['selectedBRLength'] = preSelection.length;
                        }
                    }
                    else{
                        let preSelection = [];
                        let preSelectionRefId = [];
                        preSelection.push(brokerReinId);
                        preSelectionRefId.push(brokerReinRefId);
                        row['selectedBrokerRein'] = preSelection;
                        row['selectedBrokerReinsByRefId'] = preSelectionRefId;
                        row['selectedBRLength'] = preSelection.length;
                    }
                }

                lstUpdRenewalDoc.push(row);
            }
            console.log('lstUpdRenewalDoc handleChangeBrokerReinsurerCheckbox== ',lstUpdRenewalDoc);

            //RRA - ticket 1512 - 23042023 _ get the contentVersion Id and update new fields TECH_SelectedBRLength__c and TECH_SelectedBrokerRein__c in the database
            var lstContentVersionUpdatedRenewal = [];
            for (var i = 0; i < lstUpdRenewalDoc.length; i++){
                var objDocument = {
                    //DocumentType__c : DOCUMENT_TYPE_FIELD,
                    ContentDocumentId : CONTENT_DOCMENT_ID,
                    FromThemis__c : FROM_THEMIS,
                    Id : CONTENTVERSION_ID,
                    GroupType__c : GROUP_TYPE_FIELD,
                    Phase__c : PHASE_FIELD,
                    Title : TITLE_FIELD,
                    VersionNumber : VERSIONNUMB_FIELD,
                    TECH_SelectedBRLength__c : TECH_SELECTEDBR_SIZE_FIELD,
                    TECH_SelectedBrokerRein__c : TECH_SELECTEDBR_FIELD
                }
                //objDocument.DocumentType__c = lstUpdRenewalDoc[i].DocumentType__c;
                objDocument.ContentDocumentId = lstUpdRenewalDoc[i].ContentDocumentId;
                objDocument.FromThemis__c =lstUpdRenewalDoc[i].FromThemis__c;;
                objDocument.GroupType__c = lstUpdRenewalDoc[i].GroupType__c;
                objDocument.Title = lstUpdRenewalDoc[i].Title;
                objDocument.Id = lstUpdRenewalDoc[i].Id;
                //objDocument.Phase__c =  lstUpdRenewalDoc[i].Phase__c; 
                objDocument.VersionNumber = lstUpdRenewalDoc[i].VersionNumber;
                
                //RRA - ticket 2149 09102024
                if ( lstUpdRenewalDoc[i].Phase__c == 'Quote' || [i].Phase__c == 'Lead' || lstUpdRenewalDoc[i].Phase__c == 'Placement' || lstUpdRenewalDoc[i].Phase__c == 'Signing' || lstUpdRenewalDoc[i].Phase__c == 'Conditions' || lstUpdRenewalDoc[i].Phase__c == 'All'){
                    objDocument.Phase__c =  this.mapValueToAPI.get(lstUpdRenewalDoc[i].Phase__c); 
                }else{
                    objDocument.Phase__c = lstUpdRenewalDoc[i].Phase__c;
                }
                
                if (this.selectedDocument.ContentDocumentId == lstUpdRenewalDoc[i].ContentDocumentId){
                    console.log('this.selectedDocument Renew == ',this.selectedDocument);        
                    if (lstUpdRenewalDoc[i].selectedBrokerReinsByRefId != null){
                        if (lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c != null || lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c != undefined){
                            let key =  lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString();
                            let selectedRow = this.selectedDocument.selectedBrokerReinsByRefId.toString();
                            if (key !== selectedRow && checkValue){
                                console.log('mandalo lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c', lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c);
                                console.log('mandalo lstUpdRenewalDoc[i].selectedBrokerReinsByRefId', lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString());
                                let checkData = this.checkDataAndRemoveDuplicate(lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c.toString(), lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString());
                                objDocument.TECH_SelectedBrokerRein__c = checkData.xObjUnique;
                                objDocument.TECH_SelectedBRLength__c = checkData.lengthxObj;
                            }else{
                                objDocument.TECH_SelectedBrokerRein__c = lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString();
                                objDocument.TECH_SelectedBRLength__c = lstUpdRenewalDoc[i].selectedBRLength;
                            }
                        }else{
                            console.log('OK renew Doc');
                            objDocument.TECH_SelectedBrokerRein__c = lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString() != null ? lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString() : null;
                            console.log('objDocument.TECH_SelectedBrokerRein__c Renew == ',objDocument.TECH_SelectedBrokerRein__c);    
                            objDocument.TECH_SelectedBRLength__c =  lstUpdRenewalDoc[i].selectedBRLength > 0 ? lstUpdRenewalDoc[i].selectedBRLength : 0;
                        }
                    }else{
                        objDocument.TECH_SelectedBrokerRein__c = null;
                        objDocument.TECH_SelectedBRLength__c = 0;
                    }
                //Section : get B/R on Other Document - RRA - ticket 2149 09102024
                }else{
                    console.log('Other renew Doc');      
                    if (lstUpdRenewalDoc[i].selectedBrokerReinsByRefId == null){
                        objDocument.TECH_SelectedBrokerRein__c = null;
                        objDocument.TECH_SelectedBRLength__c = 0;
                    }else{
                        objDocument.TECH_SelectedBrokerRein__c = lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c != null ? lstUpdRenewalDoc[i].TECH_SelectedBrokerRein__c : lstUpdRenewalDoc[i].selectedBrokerReinsByRefId.toString();
                        objDocument.TECH_SelectedBRLength__c =  lstUpdRenewalDoc[i].TECH_SelectedBRLength__c > 0 ?  lstUpdRenewalDoc[i].TECH_SelectedBRLength__c : lstUpdRenewalDoc[i].selectedBRLength;
                    }
                }
                lstContentVersionUpdatedRenewal.push(objDocument);
            }
            console.log('lstContentVersionUpdatedRenewal == ', JSON.parse(JSON.stringify(lstContentVersionUpdatedRenewal)));
            sessionStorage.setItem('lstCVUpdatedRenew', JSON.stringify(lstContentVersionUpdatedRenewal));
            this.lstCheckboxChangeRenewalDoc = [ ...lstUpdRenewalDoc ];
        }

    }
    //RRA - ticket 2149 - 15102024 - Get Data and remove duplicate before insert in DB
    checkDataAndRemoveDuplicate (dataBrokerInbase, selectedBrokerReinsByRefId){
        let xObj =  dataBrokerInbase + ',' + selectedBrokerReinsByRefId;
        let xObSplit = xObj.split(',');
        let xObjUnique = xObSplit.filter(function(value, index, self) {  return self.indexOf(value) === index;}).join(',');
        let xObjUniqueRemoveDoubleComma = xObjUnique.replace(',,', ',');
        let lengthxObjUnique = xObjUniqueRemoveDoubleComma.split(',');
        let lengthxObj = lengthxObjUnique.length;
        return {
            xObjUnique: xObjUnique,
            lengthxObj: lengthxObj
        };
    }


    handlePlacementDataTableChange(event){
        let writtenShareValue = event.detail.draftValues[0].WrittenShare__c;
        let reqId = event.detail.draftValues[0].Id;
        let lstUpdSelectedRequest = [];

        for(let i = 0; i < this.selectedDataRequest.length; i++){
            let row = { ...this.selectedDataRequest[i] };
            if(row.Id == reqId){
                row['WrittenShare__c'] = writtenShareValue;
            }
            lstUpdSelectedRequest.push(row);
        }

        this.selectedDataRequest = lstUpdSelectedRequest;
    }

    //MRA W-822 Confirmation Modal 24/08/2022
    //MRA W-956 8/9/2022 Transvsersal - Send/Update/Remind - Message prévenant qu'un réassureur n'a pas de contact
    handleConfirmationModal(event){
        if(event.target.name === 'confirmModal'){
            if(event.detail !== 1){
                if(event.detail.status === 'confirm') {
                    if(this.isContactMissing === false)
                       this.bypassDocAssignment = true ;

                    this.displaySpinner = true;
                    this.isDialogVisible = false;
                    if (this.btnNameClick == 'Remind') 
                        this.sendReminderForRequest() ;
                    else if(this.btnNameClick == 'Send' || this.btnNameClick == 'Update')
                        this.sendUpdateRequest() ;  
                }
                else if(event.detail.status === 'cancel' && this.isContactMissing === true){
                    this.displaySpinner = false;
                    this.isDialogVisible = false;
                    this.isContactMissing = false;
                    this.bypassDocAssignment = false ;
                }
                else if(event.detail.status === 'cancel' && this.isContactMissing === false){
                    this.displaySpinner = false;
                    this.isDialogVisible = false;
                }
            }
            else{
                this.displaySpinner = false;
            }
        }
    }
    //RRA - Ticket 2149 - 09102024
    updateContenVersions (lstContentVersionUpdatedContractual, lstContentVersionUpdatedRenewal, selectedCurrentRecord, isAllSelect){
        updateContenVersion({lstupdateCVContract : lstContentVersionUpdatedContractual, lstupdateCVRenew : lstContentVersionUpdatedRenewal, selectedCurrentCV :selectedCurrentRecord, isSelectAll : isAllSelect})
            .then(result => {
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                }
                else{
                    console.log('result contractual / Renew == ', result);
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error updateContenVersions == ', error);
                this.displaySpinner = false;
            });
    }
    
     //RRA - Ticket 2149 - 09102024
     updateAllContenVersionRenew (lstContentVersionUpdatedRenewal){
        updateAllContenVersionRenew({lstupdateCVRenew : lstContentVersionUpdatedRenewal})
            .then(result => {
                console.log('result contractual / Renew 222== ', result);
                if(result.hasOwnProperty('Error') && result.Error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Error,
                            variant: 'error',
                        }),
                    );
                }
                else{
                    console.log('result All Renew == ', result);
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error updateContenVersions Renewal == ', error);
                this.displaySpinner = false;
            });
    }
    
}