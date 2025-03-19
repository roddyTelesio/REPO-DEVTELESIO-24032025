import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import dualListboxSortCmpCSS from '@salesforce/resourceUrl/WorkSortingCmpCss';

export default class Lwc66WorkListViewSorting extends LightningElement {
    @api recordIds;

    connectedCallback() {
        console.log('Selected Record IDs:', this.recordIds);
    }

    @api recordList     = [];  
    @api isDebug; 
    @api selectionList = [];
    @api orderedList = [];
    @api unOrderedList = [];
    @api allPriorityFilled;
    @api currentUrl;
    mapContact = new Map();
    listOptions = []; 
    defaultOptions = [];
    requiredOptions = [];

    renderedCallback() {
        if(this.allPriorityFilled){
            Promise.all([loadStyle(this, dualListboxSortCmpCSS)]);
        }
    }

    connectedCallback() {
        this.recordList.forEach(eachRecord => {
            this.mapContact.set(eachRecord.Id, eachRecord);

            this.selectionList.push(eachRecord);

            this.listOptions.push({
                value : eachRecord.Id,
                // label : eachRecord.Name+' - '+this.truncateString(eachRecord.Subject__c,90)+ ' - Current Priority : '+((eachRecord?.Priority_Order__c) ? eachRecord.Priority_Order__c : 'None')
                label : this.truncateString(eachRecord.Subject__c,100)+ ' - Priority : '+((eachRecord?.Priority_Order__c) ? eachRecord.Priority_Order__c : 'None')
            });
            if(eachRecord.Priority_Order__c && eachRecord.Priority_Order__c != 'Not determined yet'){
                this.defaultOptions.push(eachRecord.Id);
            }
            this.requiredOptions.push(eachRecord.Id) 
        });
    }

    handleChange(event) {
        // Get the list of the "value" attribute on all the selected options
        try {
            const selectedOptionsList = event.detail.value;
            this.orderedList = [] ;
            let count=1;
            let newPriority = 'None';
            selectedOptionsList.forEach(eachRecord => {
                this.orderedList.push(this.mapContact.get(eachRecord)) ;
                newPriority = count;
                count++; 
                let foundObject = this.listOptions.find(option => option.value === eachRecord);
                // foundObject.label = this.mapContact.get(eachRecord).Name+' - '+this.truncateString(this.mapContact.get(eachRecord).Subject__c,80)+ ' - Current Priority : '+((this.mapContact.get(eachRecord)?.Priority_Order__c) ? this.mapContact.get(eachRecord).Priority_Order__c : 'None')+' - New Priority : '+  newPriority ;
                foundObject.label = this.truncateString(this.mapContact.get(eachRecord).Subject__c,90)+ ' - Priority : '+  newPriority ;
            }) ;
            
            const allValues = this.listOptions.map(option => option.value);
            this.unOrderedList = [];
            allValues.filter(value => !selectedOptionsList.includes(value)).forEach(value => {
                this.unOrderedList.push(this.mapContact.get(value));
    
                let foundObject = this.listOptions.find(option => option.value === value);
                // foundObject.label = this.mapContact.get(value).Name+' - '+this.truncateString(this.mapContact.get(value).Subject__c,80)+ ' - Current Priority : '+((this.mapContact.get(value)?.Priority_Order__c) ? this.mapContact.get(value).Priority_Order__c : 'None')+' - New Priority : None' ;
                foundObject.label = this.truncateString(this.mapContact.get(value).Subject__c,90)+ ' - Priority : None' ;
            });
        } catch (error) {
            console.log(error)
        }
       
    }

    truncateString(str, num) {
        return str.length > num ? str.slice(0, num) + '...' : str;
    }
    
}