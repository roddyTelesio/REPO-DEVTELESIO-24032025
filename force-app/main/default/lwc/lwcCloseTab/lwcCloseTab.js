/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 25-06-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   24-06-2024   Patrick Randrianarisoa   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class lwcCloseTab extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        window.close();
    }
}