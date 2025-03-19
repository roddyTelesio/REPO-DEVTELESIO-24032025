import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class Lwc64CRMRedirectionGlobalDashboard extends NavigationMixin(LightningElement) {
    isDisplayButton = false;
    spinner;
    connectedCallback() {
            this.spinner = true;
            setTimeout(function() {
                let url = 'https://app.powerbi.com/reportEmbed?reportId=41231149-c7d1-4d4f-ad46-3fd2f64dfd04&autoAuth=true&ctid=396b38cc-aa65-492b-bb0e-3d94ed25a97b'; 
                window.open(url, "_blank");
              }, 0);
              this.isDisplayButton = true;
              this.spinner = false;
    }
    handleClickButton(){
        window.location.href = window.location.origin + '/lightning/n/CRM'; 
    }
}