//RRA - Ticket 2261 - 09012025
import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class LWC68ModalPopupTermsOfUserBrokerRein extends LightningModal {
   @api label;
    handleCancel(event) {
        this.close('OK');
    }

}