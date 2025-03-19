import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class FlowRedirectionCmp extends NavigationMixin(LightningElement) {
    @api timer;
    @api isDisplayButton = false;
    spinner;
    connectedCallback() {
            this.spinner = true;
            setTimeout(function() {
                let url = 'https://app.powerbi.com/reportEmbed?reportId=c182b7a6-fe7f-4e94-8aff-4eb5436ed6f8&autoAuth=true&ctid=396b38cc-aa65-492b-bb0e-3d94ed25a97b'; 
                window.open(url, "_blank");
              }, this.timer);
              this.isDisplayButton = true;
              this.spinner = false;
    }
    handleClickButton(){
        window.location.href = window.location.origin + '/lightning/n/CRM'; 
    }
}