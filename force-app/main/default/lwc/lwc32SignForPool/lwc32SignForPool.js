import {LightningElement, track, wire, api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {registerListener, fireEvent} from 'c/pubSub';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getDocuments from '@salesforce/apex/LWC32_SignForPool.getDocuments';
import getLeadRequestDetails from '@salesforce/apex/LWC32_SignForPool.getLeadRequestDetails';
import getButtonVisibility from '@salesforce/apex/LWC32_SignForPool.getButtonVisibility';
import signPools from '@salesforce/apex/LWC32_SignForPool.signPools';
import getSigningReqDetails from '@salesforce/apex/LWC32_SignForPool.getSigningReqDetails'; 
import getSignForPoolVisibility from '@salesforce/apex/LWC32_SignForPool.getSignForPoolVisibility'; 
import getProgramName from '@salesforce/apex/LWC32_SignForPool.getProgramName'; 
import CURRENCY_FIELD from '@salesforce/schema/Section__c.Currency__c';
import SECTION_OBJECT from '@salesforce/schema/Section__c';
import signForPoolSuccess from '@salesforce/label/c.signForPoolSuccess';
import errorMsg from '@salesforce/label/c.errorMsg';

export default class LWC32_SignForPool extends NavigationMixin(LightningElement) {
    label = {
        signForPoolSuccess,
        errorMsg
    }

    @track lstDocuments = [];
    @track lstTreaties = [];
    @track lstSectionRequestByTreatyId = [];
    @track mapReinstatement = [];
    @track lstLeaderFollowers = [];
    @track lstAllRequestSection = [];
    @track mapParentRequestByTreaty = [];
    @track lstParentLeadRequest = [];
    @track lstSigningReqIds = [];
    @track programOptions = [];
    @track lstSigningReqDetails = [];
    OpenDocumentModal = false;
    error;
    SFPbtnVisible = true;
    btnSignForPool = false;
    poolSigned = true;
    titleLeaderFollower = 'Leader(s) (0)';
    phaseType;
    isPhaseTypeLead = false;
    isPhaseTypeQuote = false;
    isPhaseTypePlacement = false;
    inceptionDateValue;
    expiryDateValue;
    phaseStatus;
    disableLeadPlacementInfo = false;
    displaySpinner = false;
    programId;
    uwYear;
    programName;
    cedCompany;
    signingLabel = '';
    poolId;
    currencyOpt;
    signingTitle = '';
    //RRA - Ticket 2239 - 04/03/2025
    displayTwoFieldForPremium = false; 
    notDisplayPremiumEUR = false; 
     displayPremiumFormatEUR = false;
    mapCurrencyLabelCurrencyAPIName; 
    displayTotalCededPremOther = false;
    lstCededPremiumTotalOtherEUR;
    lstAvailableCurrency = [];

    @wire(getObjectInfo, { objectApiName: SECTION_OBJECT })
    objectInfo;

    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        this.displaySpinner = true;

        //window.location.href --- old line 
        //Changes done due to issues after Summer '21
        let url = this.pageRef.state;
        console.log('url pool = ', url);
        let param = 'c__program';
        let paramValue = null;

        if(url != undefined && url != null){
            paramValue = url[param];
        }
        console.log('paramValue pool = ', paramValue);
        if(paramValue != null){
            let paramArr = [];
            paramArr = paramValue.split('-');
            this.programId = paramArr[0];
            this.cedCompany = paramArr[1];
            this.uwYear = paramArr[2];
            this.poolId = paramArr[3];

            this.getProgramName();
            this.getSigningReqDetails();
            this.getProgramDocuments();
            this.getLeadRequestDetails();
            this.getSignForPoolVisibility();
        }

        this.displaySpinner = false;
    }

       getSignForPoolVisibility(){
        getSignForPoolVisibility({})
        .then(result => {
            console.log('result getSignForPoolVisibility == ',result);
            this.btnSignForPool = result.isVisibleButton;
            this.disableDocuments = result.isVisibleDocuments;
        })
        .catch(error => {
            this.error = error;
        });
    }


    getProgramName(){
        getProgramName({programId: this.programId})
        .then(result => {
            this.programName = result;
            var opt = {};
            opt.label = this.programName;
            opt.value = this.programName;
            this.programOptions.push(opt);
        })
        .catch(error => {
            this.error = error;
        });
    }

    getSigningReqDetails(){
        console.log('poolId = ', this.poolId);
        getSigningReqDetails({poolId: this.poolId, programId: this.programId})
        .then(result => {
            this.lstSigningReqDetails = result;
            this.getSFPbtnVisibility();
        })
        .catch(error => {
            this.error = error;
        });
    }

    getSFPbtnVisibility(){
        getButtonVisibility({lstSigningReqs: this.lstSigningReqDetails})
        .then(result => {
            console.log('result getButtonVisibility == ', result);
             console.log('ReinsurerStatus__c getButtonVisibility == ', this.lstSigningReqDetails[0]['ReinsurerStatus__c']);
            this.SFPbtnVisible = result;
            if(this.lstSigningReqDetails.length != 0){
                if(result == false && this.lstSigningReqDetails[0]['ReinsurerStatus__c'] == 'Signed By R.M.'){
                    this.signingLabel = 'Signed by ' + this.lstSigningReqDetails[0]['SigningRegionalManager__r']['Name'] + ' on ' + this.lstSigningReqDetails[0]['TECH_DateSigned__c'];
                //RRA - ticket 2225 - 20/12/2025 
                }else if (result == false && this.lstSigningReqDetails[0]['ReinsurerStatus__c'] == 'Sent'){
                  this.SFPbtnVisible = true;
                }
            }
        })
        .catch(error => {
            this.error = error;
        });

    }

    handleOpenModal(event){
        this.OpenDocumentModal = true;
    }
    handleCloseModal(event){
        this.OpenDocumentModal = false;
    }
    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }
    
    getProgramDocuments(){
        getDocuments({programId : this.programId})//RRA - ticket 1089 - 08052023
        .then(result => {
            this.lstDocuments = [];
            this.error = undefined;
            var lstNewDocuments = [];
            let lstProgramDocuments = result.lstContentVersion;
            let mapDocThemisDateByContentVersionId = result.mapDocThemisDateByContentVersionId;
            
            console.log('lstProgramDocuments == ', lstProgramDocuments);
            console.log('mapDocThemisDateByContentVersionId== ', mapDocThemisDateByContentVersionId);

            for(var i = 0; i < lstProgramDocuments.length; i++){
                var document = {};
                document['Name'] = lstProgramDocuments[i].Title;
                document['Phase'] = lstProgramDocuments[i].Phase__c; //RRA - ticket 1089 - 08052023
                document['Id'] = lstProgramDocuments[i].Id;

                // RRA - ticket 1089 - 0802023
                if(mapDocThemisDateByContentVersionId != undefined && mapDocThemisDateByContentVersionId != null){
                    if(mapDocThemisDateByContentVersionId[document.Id] != undefined){
                        document['LastModifiedDate'] = mapDocThemisDateByContentVersionId[document.Id];
                    }
                }
                
                document['DocumentUrl']="../r/ContentDocument/"+ lstProgramDocuments[i].ContentDocumentId + "/view";
               
                lstNewDocuments.push(document);
            }
            this.lstDocuments = lstNewDocuments;
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({title: 'ERROR', message: this.label.errorMsg, variant: 'error'}),);
        });
    }
     // RRA - 1074 et 1076
    //RRA - ticket 2225 - 19122024
    getLeadRequestDetails(){
        getLeadRequestDetails({programId: this.programId, poolId: this.poolId})
        .then(result => {
            //let signedShare;
            let mapIdToRequestData = result;
            let lstDisplayedTreatiesId = [];

            console.log ('mapIdToRequestData ==' , mapIdToRequestData);              
                if(mapIdToRequestData.length != 0){

                   // for (let requestId in mapIdToRequestData) {
                        let brokerName = '';
                        let reinsurerName = '';
                        let updateCurrencyOther = [];
                        //let mapRequestData = mapIdToRequestData[requestId];
                        //let signingRequest = mapRequestData ['SigningRequest'];
                        let signingRequest = result.SigningRequest;
                        let signingRequestForPool = result.SigningRequestForPool;

                        //RRA - Ticket 2239 - 04/03/2025
                        let signingRequestCededPremiumDetails = result.lstCededPremiumOtherEUR;
                        this.lstCededPremiumTotalOtherEUR = result.lstCededPremiumTotalOtherEUR;
                        let lstAvailableCurr =  result.lstAvailableCurrency;
                        let lstAvailableAllCurr =  result.lstAvailableAllCurrency;  

                        //Check if all / partial values on tab are the same ex : EUR only or JPY only etc
                        let isSameValueOnAllArray = this.checkAllArrayValuesEqual (lstAvailableAllCurr);
                        let isSameValueOnAvailableArray = this.checkAllArrayValuesEqual (lstAvailableCurr);                     
                        console.log ('lstAvailabaleCurr ==' , lstAvailableCurr);
                        console.log ('lstAvailableAllCurr ==' , lstAvailableAllCurr);
                        console.log ('isSameValueOnAllArray ==' , isSameValueOnAllArray);
                        console.log ('isSameValueOnAvailableArray ==' , isSameValueOnAvailableArray);

                        //if same values 
                        if (isSameValueOnAllArray && isSameValueOnAvailableArray){
                          if (lstAvailableAllCurr.length == lstAvailableCurr.length){
                            //Display total Other and total EUR
                            this.displayTotalCededPremOther = true;
                          }else{
                             //Not Display only EUR
                            this.displayTotalCededPremOther = false;
                          }
                        }else{
                          this.displayTotalCededPremOther = false;
                        }
                        //Only for displaying of total currency Other
                        if (isSameValueOnAllArray && !lstAvailableAllCurr.includes('9052')){
                            this.displayCurrencyTotalCededPremOther = 'Total Premium (' + this.mapCurrencyLabelCurrencyAPIName.get(lstAvailableCurr[0]) + ')';
                        }else if (isSameValueOnAllArray == false && !lstAvailableAllCurr.includes('9052')){
                          this.displayCurrencyTotalCededPremOther = 'Total Premium (Other)';
                        } 

                        //RRA - ticket 2225 - 20/122024
                        if (signingRequestForPool.length == 0 ){
                            this.btnSignForPool = true; 
                        }

                        console.log ('signingRequestForPool ==' , signingRequestForPool);
                        console.log ('signingRequestCededPremiumDetails ==' , signingRequestCededPremiumDetails); 
                        console.log ('lstCededPremiumTotalOtherEUR ==' , this.lstCededPremiumTotalOtherEUR);
                          let answerDate = signingRequest.ExpectedResponseDate__c;
                        let mapTreatyIdToPlacementShare = mapIdToRequestData.mapTreatyIdToPlacementShare;
                        //let mapChildRequestIdToWrittenShare = mapRequestData.mapChildRequestIdToWrittenShare;
                        let mapChildRequestIdToWrittenShare = result.mapChildRequestIdToWrittenShare;
                        //this.lstAllRequestSection = mapRequestData.lstRequestAll;
                        this.lstAllRequestSection = result.lstRequestAll;
                        //this.lstTreaties = this.getUniqueData(mapRequestData.lstTreaties, 'value');
                        this.lstTreaties = this.getUniqueData(result.lstTreaties, 'value');

                        //let mapSectionReqByTreaty = mapRequestData.mapSectionRequestByTreatyId;
                        let mapSectionReqByTreaty = result.mapSectionRequestByTreatyId;
                        //this.mapReinstatement = mapRequestData.mapReinstatementBySectionId;
                        this.mapReinstatement = result.mapReinstatementBySectionId;
                        //this.mapParentRequestByTreaty = mapRequestData.mapParentRequestByTreatyId;
                        this.mapParentRequestByTreaty  = result.mapParentRequestByTreatyId;
                        //this.lstParentLeadRequest = mapRequestData.lstParentLeadRequest;
                        this.lstParentLeadRequest = result.lstParentLeadRequest;
                       

                        if(result.lstRequestAll.length > 0){
                            this.selectedProgramId = result.lstRequestAll[0].Program__c;
                            this.selectedPrincipleCedingCom = result.lstRequestAll[0].Program__r.PrincipalCedingCompany__c;
                            this.selectedUWYear = result.lstRequestAll[0].Program__r.UwYear__c;
                            this.selectedStatus = result.lstRequestAll[0].Program__r.TECH_StageName__c;
                        }else{
                            let requestPhase = result.requestPhaseType;
                            this.selectedProgramId = result.selectedRequestDetail.Program__c;
                            this.selectedPrincipleCedingCom = result.selectedRequestDetail.Program__r.PrincipalCedingCompany__c;
                            this.selectedUWYear = result.selectedRequestDetail.Program__r.UwYear__c;
                            this.selectedStatus = result.selectedRequestDetail.Program__r.TECH_StageName__c;
                            if(requestPhase != '3'){
                                this.disableLeadPlacementInfo = true;
                            }
                        }
            
                        this.phaseType = result.requestPhaseType;
                        if(this.phaseType == '4'){
                            this.isPhaseTypeLead = true;
                            this.isPhaseTypeQuote = false;
                            this.isPhaseTypePlacement = false;
                            this.phaseStatus = 'Lead';
                        }
                        else if(this.phaseType == '3'){
                            this.isPhaseTypeQuote = true;
                            this.isPhaseTypeLead = false;
                            this.isPhaseTypePlacement = false;
                            this.phaseStatus = 'Quote';
                        }
                        else if(this.phaseType == '5'){
                            this.isPhaseTypePlacement = true;
                            this.isPhaseTypeLead = false;
                            this.isPhaseTypeQuote = false;
                            this.phaseStatus = 'Placement';
                        }
                    
                        //set broker and reinsurer SAU
                        let lstUpdReq = [];

                        console.log('mapSectionReqByTreaty ', mapSectionReqByTreaty);
                        for(let key in mapSectionReqByTreaty){
                            for(let i = 0; i < this.lstTreaties.length; i++){
                              console.log('###key 33 == ', key);  
                                if(this.lstTreaties[i].value == key && lstDisplayedTreatiesId.indexOf(key) == -1){
                                    lstDisplayedTreatiesId.push(key);
                                    let lstSectionRequest = mapSectionReqByTreaty[key];
                                    let lstUpdSectionsRequest = [];
                                    let numReinsurerStatusNotSetupRemind = 0;
                                     console.log('###key 44 == ', key);  
                                    for(let j = 0; j < lstSectionRequest.length; j++){
                                        let rowSection = { ...lstSectionRequest[j] };
                                        let disablePriceStructureDetails = false;
            
                                        if(rowSection.ReinsurerStatus__c == 'Setup' || rowSection.ReinsurerStatus__c == 'Timeout'){
                                            disablePriceStructureDetails = true;
                                            rowSection['errorMsg'] = 'Price Structure Detail is not available because this ' +this.phaseStatus+ ' request is in status '+rowSection.ReinsurerStatus__c;
                                        }
                                        else{
                                            numReinsurerStatusNotSetupRemind = numReinsurerStatusNotSetupRemind + 1;
                                        }
            
                                        rowSection['disablePriceStructureDetails'] = disablePriceStructureDetails;
                                        rowSection['SectionNumber'] =  rowSection['Section__r']['SectionNumber__c'];
                                        rowSection['Name'] = rowSection['Section__r']['SectionNumber__c'] + ' ' + rowSection['TECH_SectionName__c'];
                                        rowSection = this.setTypeOfTreatyQuoteValue(rowSection);
                                        lstUpdSectionsRequest.push(rowSection);
                                    }
                                    lstUpdSectionsRequest = this.sortData('SectionNumber', 'asc', lstUpdSectionsRequest);
                                      console.log('###key 55 == ', key);  
                                    let rowTreaty = {};
                                    
                                    if(lstSectionRequest.length > 0){
                                        rowTreaty['Deductions_Perc__c'] = lstSectionRequest[0].Treaty__r.Deductions_Perc__c;
                                        rowTreaty['PremiumDeposit__c'] = lstSectionRequest[0].Treaty__r.PremiumDeposit__c;
                                        rowTreaty['LossDeposit__c'] = lstSectionRequest[0].Treaty__r.LossDeposit__c;
                                    }

                                    if(this.mapParentRequestByTreaty[key] != undefined){

                                      let rowParentRequest = { ...this.mapParentRequestByTreaty[key] };
                                      if(numReinsurerStatusNotSetupRemind > 0){ 
                                            rowParentRequest['disableInfo'] = false;
                                      }
                                      else{
                                            rowParentRequest['disableInfo'] = true;
                                      }

                                      if(lstSectionRequest[0].Treaty__r.LossDeposit__c == '1'){
                                          this.lstTreaties[i]['LossDept'] = 'Yes';
                                      }
                                      else{
                                          this.lstTreaties[i]['LossDept'] = 'No';
                                      }
                                    
                                      let treatyLayer = lstUpdSectionsRequest[0]['Treaty__r']['Layer__c'];  
                                        console.log('###key 66 == ', key);  
                                      
                                      //RRA - ticket 2225 - 19122024
                                      let lstPool=[];
                                      let lstBrokerReins =[];
                                      let lstCededPremiumOtherEUR = [];
                                      signingRequestForPool.forEach(element => {
                                          let keySplit = key.split('_');
                                          let keyReplace = key.replace(keySplit[1], 'undefined'); 
                                          let keyUpdate = keyReplace.toString().replace(',','_');
                                          if(element.Treaty__c + '_' + element.Section__c + '_null' == keyUpdate){
                                              lstPool.push({poolName : element.TECH_PoolName__c,signedShare : parseFloat(element.SignedShare__c).toFixed(6).replace('.',',') + ' %' , writtenShare:element.WrittenShare__c});
                                          }
                                      });
                                      console.log('###lstPool  == ', lstPool);  
                                    //RRA - Ticket 2239 - 04/03/2025
                                    signingRequestCededPremiumDetails.forEach(element => {
                                        //let keySplit = key.split('_');
                                        //let keyUpdate = key.replace(keySplit[2], ''); 
                                        //let keyUpdate = keyReplace.toString().replace(',','_');
                                        console.log('###elementkey' , element.key + '_null', '===> ' ,'keyUpdate = ', key); 
                                        if(element.key + '_null' == key){
                                          console.log('###OKOK');  
                                          console.log('###element.cededOther' , element.cededOther); 
                                          console.log('###element.cededEUR' , element.cededEUR); 
                                           console.log('###element.currencyLabel' , element.currencyLabel); 
                                           console.log('###element.Label' , this.mapCurrencyLabelCurrencyAPIName.get(element.currencyLabel)); 

                                          if (element.cededOther != 0 && element.cededEUR != 0){
                                            this.displayTwoFieldForPremium = true;
                                              lstCededPremiumOtherEUR.push({CededOther : element.cededOther, CededEUR : element.cededEUR, currencyLabel : ' Premium (' + this.mapCurrencyLabelCurrencyAPIName.get(element.currencyLabel) + ')'} );
                                          }else if (element.cededOther == 0 && element.cededEUR != 0){
                                            //this.notDisplayPremiumEUR = true;
                                              lstCededPremiumOtherEUR.push({CededEUR : element.cededEUR, currencyLabel : ''});
                                          }
                                        }
                                     });
                                       //console.log('###notDisplayPremiumEUR' , this.notDisplayPremiumEUR); 

                                     
                                      console.log('###displayTwoFieldForPremium  == ',  this.displayTwoFieldForPremium);  
                                      console.log('###displayPremiumFormatOther  == ',  this.displayPremiumFormatOther);  
                                      console.log('###displayPremiumFormatEUR  == ', this.displayPremiumFormatEUR);  
                                      console.log('###lstCededPremiumOtherEUR  == ', lstCededPremiumOtherEUR);  

                                      //RRA - ticket 2225 - 19122024
                                      if(answerDate != undefined){
                                          this.signingTitle = 'Signing Information - ' + answerDate;
                                      }
                                      else{
                                          this.signingTitle = 'Signing Information';
                                      }
                                         console.log('###key 77 == ', key);  
                                      //RRA - ticket 2225 - 19122024
                                      for(let k = 0; k < this.lstParentLeadRequest.length; k++){
                                          let keySplit = key.split('_');
                                          let keyReplace = key.replace(keySplit[1], 'undefined'); 
                                          let keyUpdate = keyReplace.toString().replace(',','_'); 
                                          if(keyUpdate == this.lstParentLeadRequest[k].Treaty__c + '_' + this.lstParentLeadRequest[k].Section__c +'_null'){
                                              let row = {...this.lstParentLeadRequest[k]};
                                              if(row.Broker__c != undefined){
                                                  lstBrokerReins.push({Id : row.Id, brokerName : row.TECH_BrokerName__c, reinsurerName : row.TECH_ReinsurerName__c, techTreatyBrokerRein :row.TECH_TreatyBrokerReinsurer__c}); //RRA - ticket 2244 - 09012025
                                              }
                      
                                              if(row.Reinsurer__c != undefined){
                                                  lstBrokerReins.push({Id : row.Id, brokerName : null, reinsurerName : row.TECH_ReinsurerName__c, techTreatyBrokerRein :row.TECH_TreatyBrokerReinsurer__c});//RRA - ticket 2244 - 09012025
                                              }
                                          }
                                      }
                                      console.log('lstBrokerReins == ', lstBrokerReins);  
                                      let  lstBrokerReinsUnique = this.getUniqueDataComp(lstBrokerReins, 'techTreatyBrokerRein');//RRA - ticket 2244 - 09012025
                                      console.log('lstBrokerReinsUnique == ', lstBrokerReinsUnique);  
                                      this.lstSectionRequestByTreatyId.push({value:lstUpdSectionsRequest, key:this.lstTreaties[i], parentRequest: rowParentRequest, treatyDetail : rowTreaty,treatyLayer: treatyLayer, brokerName: brokerName, reinsurerName:reinsurerName,lstPool : lstPool, lstBrokerReinsUnique:lstBrokerReinsUnique, lstCededPremiumOtherEUR : lstCededPremiumOtherEUR}); //RRA - Ticket 2239 - 04/03/2025
                                      console.log('lstSectionRequestByTreatyId == ', this.lstSectionRequestByTreatyId);  
                                    }
                                }
                            }
                        }
            
                        for(let i = 0; i < this.lstAllRequestSection.length; i++){
                            let rowReqSection = { ...this.lstAllRequestSection[i] };
                            rowReqSection['checkIfPercentbadInput'] = false;
                            lstUpdReq.push(rowReqSection);
                        }
            
                        if(this.lstAllRequestSection.length > 0){
                            if(this.lstAllRequestSection[0].Program__r != undefined){
                                this.inceptionDateValue = this.lstAllRequestSection[0].Program__r.InceptionDate__c;
                                this.expiryDateValue = this.lstAllRequestSection[0].Program__r.Expirydate__c;
            
                                if(this.inceptionDateValue != undefined){
                                    let incepDate = new Date(this.inceptionDateValue+'T00:00').getDate();
                                    if(incepDate < 10){
                                       incepDate = '0'+incepDate;
                                    }
            
                                    let incepMonth = new Date(this.inceptionDateValue+'T00:00').getMonth() + 1;
                                    if(incepMonth < 10){
                                       incepMonth = '0'+incepMonth;
                                    }
            
                                    this.inceptionDateValue = incepDate + '/' + incepMonth + '/' + new Date(this.inceptionDateValue+'T00:00').getFullYear();
                                }
            
                                if(this.expiryDateValue != undefined){
                                    let expDate = new Date(this.expiryDateValue+'T00:00').getDate();
                                    if(expDate < 10){
                                       expDate = '0'+expDate;
                                    }
            
                                    let expMonth = new Date(this.expiryDateValue+'T00:00').getMonth() + 1;
                                    if(expMonth < 10){
                                       expMonth = '0'+expMonth;
                                    }
            
                                    this.expiryDateValue = expDate + '/' + expMonth + '/' + new Date(this.expiryDateValue+'T00:00').getFullYear();
                                }
                            }
                        }
                        this.lstAllRequestSection = lstUpdReq;
                    //}

                }
                this.lstSectionRequestByTreatyId = this.sortData('treatyLayer', 'asc', this.lstSectionRequestByTreatyId);
                this.displaySpinner = false;

        })
        .catch(error => {
            this.error = error;
        });
    }
    //RRA - Ticket 2239 - 05/03/2025
    checkAllArrayValuesEqual (listCurrencyAvailable){
      let isEqual = true;
      for (const element of listCurrencyAvailable) {
          if (element !== listCurrencyAvailable[0]) {
              isEqual = false;
              break;
          }
      }
      return isEqual;
    }
      //RRA - ticket 2244 - 10012025
      getUniqueDataComp(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }
    /*getUniqueData(arr, comp) {
        const unique = arr.map(e => e[comp])
                          .map((e, i, final) => final.indexOf(e) === i && i)
                          .filter(e => arr[e]).map(e => arr[e]);
        return unique;
    }*/

    // RRA - 1074 
    getUniqueData(arr) {
        const unique = arr.filter((v, i, a) => a.indexOf(v) === i);
        return unique;
    }

    setTypeOfTreatyQuoteValue(rowSection){
        let typeOfTreaty;
        let typeOfQuote;
        let ltaProgram;

        if(rowSection.Quote__c == '1'){
            rowSection['isQuoteYes'] = true;
            rowSection['isQuoteNo'] = false;
            rowSection['ReasonRefusal__c'] = '';
        }
        else if(rowSection.Quote__c == '2'){
            rowSection['isQuoteYes'] = false;
            rowSection['isQuoteNo'] = true;
        }

        if(rowSection.OrUnlimited__c == true){
            rowSection['disableLossCarryingForward'] = true;
        }
        else{
            rowSection['disableLossCarryingForward'] = false;
        }

        if(rowSection.NoClaimBonusAmount__c == null || rowSection.NoClaimBonusAmount__c == '' || rowSection.NoClaimBonusAmount__c == undefined){
            rowSection['disableNoClaimBonusPerc'] = false;
        }
        else{
            rowSection['disableNoClaimBonusPerc'] = true;
        }

        if(rowSection.NoClaimBonus__c == null || rowSection.NoClaimBonus__c == '' || rowSection.NoClaimBonus__c == undefined){
            rowSection['disableNoClaimBonusAmount'] = false;
        }
        else{
            rowSection['disableNoClaimBonusAmount'] = true;
        }

        if((rowSection.DepoPremium__c == null || rowSection.DepoPremium__c == '' || rowSection.DepoPremium__c == undefined) && (rowSection.MinPremium__c == null || rowSection.MinPremium__c == '' || rowSection.MinPremium__c == undefined)){
            rowSection['disableMDP'] = false;
        }
        else{
            rowSection['disableMDP'] = false;
        }

        if(rowSection.MDP__c == null || rowSection.MDP__c == '' || rowSection.MDP__c == undefined){
            rowSection['disableMinPremium'] = false;
            rowSection['disableDepoPremium'] = false;
        }
        else{
            rowSection['disableMinPremium'] = true;
            rowSection['disableDepoPremium'] = true;
        }

        if(rowSection.Treaty__r != undefined){
           typeOfTreaty = rowSection.Treaty__r.TypeofTreaty__c;
        }

        if(rowSection.Section__r != undefined){
            typeOfQuote = rowSection.Section__r.QuoteType__c;
        }

        if(rowSection.Section__r != undefined){
            ltaProgram = rowSection.Program__r.LTA__c;
        }

        if(typeOfTreaty == '3'){
            rowSection['isTreatyTypeQS'] = true;
            rowSection['isTreatyTypeAXAXLQS'] = false;
        }
        else if(typeOfTreaty == '5'){/*1966*/
            rowSection['isTreatyTypeAXAXLQS'] = true;
            rowSection['isTreatyTypeQS'] = false;
        }
        else if(typeOfTreaty == '4'){
            rowSection['isTreatyTypeSurplus'] = true;
        }
        else if(typeOfTreaty == '2'){
            rowSection['isTreatyTypeXL'] = true;
        }
        else if(typeOfTreaty == '1'){
            rowSection['isTreatyTypeSL'] = true;
        }
        if(typeOfQuote == '1'){
            rowSection['isQuoteTypeFixedRate'] = true;
        }
        else if(typeOfQuote == '2'){
            rowSection['isQuoteTypeVariableRate'] = true;
        }
        else if(typeOfQuote == '3'){
            rowSection['isQuoteTypeFlatPremium'] = true;
        }
        else if(typeOfQuote == '4'){
            rowSection['isQuoteTypeMDP'] = true;
        }
        else if(typeOfQuote == '5'){
            rowSection['isQuoteTypeFlatCommission'] = true;
        }
        else if(typeOfQuote == '6'){
            rowSection['isQuoteTypeVariableCommission'] = true;
        }
        else if(typeOfQuote == '7'){
            rowSection['isQuoteTypePerHead'] = true;
        }
        else if(typeOfQuote == '8'){
            rowSection['isQuoteTypePerHeadVariable'] = true;
        }
        else if(typeOfQuote == '9'){
            rowSection['isQuoteTypeRiskPremiumBasis'] = true;
        }
        else if(typeOfQuote == '10'){
            rowSection['isQuoteTypePerHeadPremium'] = true;
        }

        if(ltaProgram == '1'){
            rowSection['LTAProgramYes'] = true;
        }
        else{
            rowSection['LTAProgramYes'] = false;
        }
        if(this.mapReinstatement[rowSection.Section__c] != undefined){
            let reinstatementstr = this.mapReinstatement[rowSection.Section__c];
            rowSection['ReinstatementStr'] = reinstatementstr;
        }

        if(this.isPhaseTypeLead == true){
            if(rowSection.OverridingCommission__c == null || rowSection.OverridingCommission__c == ''){
                rowSection['OverridingCommission__c'] = 0;
            }

            if(typeOfTreaty == '3' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                let totalEPI = 0;
                let cessionPerc = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.Section__r.Cession_Perc__c != undefined){
                    cessionPerc = rowSection.Section__r.Cession_Perc__c;
                }

                let cededPremiumValue = totalEPI * (cessionPerc / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(QS or Surplus) + PerHead
            else if((typeOfTreaty == '3' || typeOfTreaty == '4') && typeOfQuote == '7'){
                let totalEPI = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                let cededPremiumValue = totalEPI;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
            else if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                let totalEPI = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                let cededPremiumValue = totalEPI;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + FixedRate
            else if((typeOfTreaty == '4' || typeOfTreaty == '2') && typeOfQuote == '1'){
                let totalEPI = 0;
                let fixedRate = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.FixedRate__c != undefined){
                    fixedRate = rowSection.FixedRate__c;
                }
                let cededPremiumValue = totalEPI * (fixedRate / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + FlatPremium
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                let flatPremium = 0;
                if(rowSection.FlatPremium__c != undefined){
                    flatPremium = rowSection.FlatPremium__c;
                }
                let cededPremiumValue = flatPremium;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + MDP
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                let MDP = 0;
                if(rowSection.MDP__c != undefined){
                    MDP = rowSection.MDP__c;
                }
                let cededPremiumValue = MDP;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + VariableRate
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                let totalEPI = 0;
                let minRate = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.MinRate__c != undefined){
                    minRate = rowSection.MinRate__c;
                }
                let cededPremiumValue = totalEPI * (minRate / 100);
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + PerHeadPremium
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                let totalEPI = 0;
                let perHeadPremium = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.PerHeadPremium__c != undefined){
                    perHeadPremium = rowSection.PerHeadPremium__c;
                }
                let cededPremiumValue = totalEPI * perHeadPremium;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }

            //(SL or XL) + PerHeadVariable
            else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                let totalEPI = 0;
                let minPerHeadAmount = 0;
                if(rowSection.Section__r.TotalEPI__c != undefined){
                    totalEPI = rowSection.Section__r.TotalEPI__c;
                }
                if(rowSection.MinPerHeadAmount__c != undefined){
                    minPerHeadAmount = rowSection.MinPerHeadAmount__c;
                }
                let cededPremiumValue = totalEPI * minPerHeadAmount;
                rowSection['CededPremium__c'] = Math.round(cededPremiumValue);
            }
        }

        if(rowSection.Section__r != undefined){
            //Build list since Section__r cannot be retrieved in html
            rowSection['Section__r.Name'] = rowSection.Section__r.Name;
            rowSection['Section__r.Currency__c'] = rowSection.Section__r.Currency__c;
            rowSection['Section__r.CapacityPerRisk__c'] = rowSection.Section__r.CapacityPerRisk__c;
            rowSection['Section__r.Unlimited__c'] = rowSection.Section__r.Unlimited__c;
            rowSection['Section__r.EventLimit__c'] = rowSection.Section__r.EventLimit__c;
            rowSection['Section__r.Cession_Perc__c'] = rowSection.Section__r.Cession_Perc__c;
            rowSection['Section__r.Retention__c'] = rowSection.Section__r.Retention__c;
            rowSection['Section__r.CessionAmount__c'] = rowSection.Section__r.CessionAmount__c;
            rowSection['Section__r.RetentionAmount__c'] = rowSection.Section__r.RetentionAmount__c;
            rowSection['Section__r.TotalEPI__c'] = rowSection.Section__r.TotalEPI__c;
            rowSection['Section__r.Nature__c'] = rowSection.Section__r.Nature__c;
            rowSection['Section__r.LineAmount__c'] = rowSection.Section__r.LineAmount__c;
            rowSection['Section__r.CededLines__c'] = rowSection.Section__r.CededLines__c;
            rowSection['Section__r.RetentionLine__c'] = rowSection.Section__r.RetentionLine__c;
            rowSection['Section__r.Capacity__c'] = rowSection.Section__r.Capacity__c;
            rowSection['Section__r.Limit__c'] = rowSection.Section__r.Limit__c;
            rowSection['Section__r.Deductible__c'] = rowSection.Section__r.Deductible__c;
            rowSection['Section__r.AAD__c'] = rowSection.Section__r.AAD__c;
            rowSection['Section__r.AAL__c'] = rowSection.Section__r.AAL__c;
            rowSection['Section__r.TAL__c'] = rowSection.Section__r.TAL__c;
            rowSection['Section__r.ExpectedDP__c'] = rowSection.Section__r.ExpectedDP__c;
            rowSection['Section__r.ExpectedMDP__c'] = rowSection.Section__r.ExpectedMDP__c;
            rowSection['Section__r.ExpectedMP__c'] = rowSection.Section__r.ExpectedMP__c;
            rowSection['Section__r.LimitPercent__c'] = rowSection.Section__r.LimitPercent__c;
            rowSection['Section__r.DeductiblePercent__c'] = rowSection.Section__r.DeductiblePercent__c;
            rowSection['Section__r.Limit__c'] = rowSection.Section__r.Limit__c;
            rowSection['Section__r.Deductible__c'] = rowSection.Section__r.Deductible__c;
            rowSection['Section__r.MaxLimitAmount__c'] = rowSection.Section__r.MaxLimitAmount__c;
            rowSection['Section__r.MinLimitAmount__c'] = rowSection.Section__r.MinLimitAmount__c;
            rowSection['Section__r.EventLimit__c'] = rowSection.Section__r.EventLimit__c;
            rowSection['Section__r.Cession_Perc__c'] = rowSection.Section__r.Cession_Perc__c;
        }

        return rowSection;
    }

     handleSignForPool(event){
        this.displaySpinner = true;
        console.log('lstSigningReqDetails pool == ', this.lstSigningReqDetails);
        signPools({lstSigningReqs: this.lstSigningReqDetails})
        .then(result => {
            console.log('result pool == ', result);
            if(result.hasOwnProperty('Error') && result.Error){
                this.dispatchEvent(new ShowToastEvent({title: 'Error', message: result.Error, variant: 'error' }),);
            }else{
                this.dispatchEvent(new ShowToastEvent({title: 'Success', message: this.label.signForPoolSuccess, variant: 'success' }),);
                this.signingLabel = result.Success;

                 /*this.lstSigningReqDetails.forEach (element => {
                    if (element.ReinsurerStatus__c == 'Setup'){
                      this.SFPbtnVisible = true;
                    }else{
                      this.SFPbtnVisible = false;
                    }
              });*/
                this.SFPbtnVisible = false;
            }
            this.displaySpinner = false;
        })
        .catch(error => {
            this.error = error;
            this.displaySpinner = false;
        });

    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: CURRENCY_FIELD})
    setCurrencyPicklistOpt({error, data}) {
        if(data){//AMI 02/06/22 W0868
            let wireResults = data.values !== undefined ? data.values : [];
            let unsortedCurList = [];
            let sortedCurList = [];
            //RRA - Ticket 2239 - 04/03/2025
            this.mapCurrencyLabelCurrencyAPIName = new Map(); 
            for(var i = 0; i < data.values.length; i++){
               this.mapCurrencyLabelCurrencyAPIName.set(data.values[i].value, data.values[i].label);
            }

            if(wireResults.length > 0){
                //get all picklist options first
                wireResults.forEach(ele => {
                    unsortedCurList.push({'label':ele.label,'value':ele.value});
                });
               
                //sort retrived options
                sortedCurList = unsortedCurList.sort((a,b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));

                //move eur
                let eurObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'EUR'), 1)[0];
                sortedCurList.splice(0, 0, eurObj);

                //move usd
                let usdObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'USD'), 1)[0];
                sortedCurList.splice(1, 0, usdObj);

                //move gbp
                let gbpObj = sortedCurList.splice(sortedCurList.findIndex(ele => ele.label === 'GBP'), 1)[0];
                sortedCurList.splice(2, 0, gbpObj);

                //set display prop
                this.currencyOpt = sortedCurList;
            }
        }
        else{
           this.error = error;
        }
    }
    sortData(fieldName, sortDirection, lstData) {
        let sortResult = Object.assign([], lstData);
        let lstSortedLstData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                return sortDirection === 'asc' ? -1 : 1;
            }
            else if(a[fieldName] > b[fieldName]){
                return sortDirection === 'asc' ? 1 : -1;
            }
            else{
                return 0;
            }
        })
        return lstSortedLstData;
    }

}