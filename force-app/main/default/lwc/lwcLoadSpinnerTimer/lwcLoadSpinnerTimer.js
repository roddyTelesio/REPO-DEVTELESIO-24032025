import { LightningElement } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class LwcLoadSpinnerTimer extends LightningElement {
    showSpinner = true;

    connectedCallback() {
        // Hide the spinner after 4 seconds
        setTimeout(() => {
            this.showSpinner = false;
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }, 7000);
    }
}