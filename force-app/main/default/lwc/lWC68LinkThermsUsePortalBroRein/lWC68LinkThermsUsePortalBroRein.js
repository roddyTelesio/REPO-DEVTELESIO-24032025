//RRA - Ticket 2261 - 09012025
import { LightningElement } from 'lwc';
//import component lwc
import modalPopTermsOfUserBrokerRein from 'c/lWC68ModalPopupTermsOfUserBrokerRein';

export default class LWC68LinkThermsUsePortalBroRein extends LightningElement {

  handleClikLink (event){
    console.log('OK');
      modalPopTermsOfUserBrokerRein.open({
          label: 'TERMS OF USE OF ACTOR NEW GEN',
          size: 'large',
      });
  }
}