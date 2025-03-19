// RRA - ticket 2221 - 18/12/2024

import { LightningElement, track, api } from 'lwc';
//import ToastContainer from 'lightning/toastContainer';

export default class Lwc29ToastMsgSendOnPortal extends LightningElement {
  @track type='warning';
  @track message = '<strong> Please stay on this page until the sending confirmation message appears on your screen.</strong>';
  @track messageIsHtml=false;
  @track showToastBar = true;
  @api autoCloseTime = 5000;
  @track icon='';

 /* connectedCallback(){
    const toastContainer = ToastContainer.instance();
    toastContainer.maxShown = 3;
    toastContainer.Position = 'bottom-center';

  }*/

  @api
    showToast(type, message,icon,time) {
        this.type = type;
        this.message = message;
        this.icon=icon;
        this.autoCloseTime=time;
        setTimeout(() => {
            this.closeModel();
        }, this.autoCloseTime);
    }
    
    closeModel() {
        this.showToastBar = false;
        this.type = '';
        this.message = '';
    }
 
    get getIconName() {
        if(this.icon)
        {
            return this.icon;
        }
        return 'utility:' + this.type;
    }
 
    get innerClass() {
        return 'slds-icon_container slds-icon-utility-' + this.type + ' slds-m-right_small slds-no-flex slds-align-center';
    }
 
    get outerClass() {
        return 'slds-notify slds-notify_toast slds-theme_' + this.type;
    }

}