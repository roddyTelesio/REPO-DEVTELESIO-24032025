import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

/**
 * @description Navigate to record page
 * BBH 19.06.2024
 */
function  navigateToRecordViewPage(component,recordId,ObjectApiName,type='Redirect') {
    console.log('navigateToRecordViewPage')
    console.log('type '+type);
    if(type == 'Redirect'){
        console.log('here'+recordId)
        component[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                objectApiName :ObjectApiName,
                actionName: 'view'
            }
        }).then(url => {
            console.log('##url '+url)
            window.open(url, "_blank");
        });     
    }
    else if(type== 'sameTab'){
        component[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: ObjectApiName,
                actionName: 'view'
            },
        });
    }
}

//DOCUMENT TYPES WHICH WE NEED TO REDIRECT TO THEIR RECORD PAGES AFTER CLICKING ON THE HYPER LINK
const documentTypeRedirect = ['12'];

//DOCUMENTS TO EXPORT - CAT W-2045
const docTypeToExport = ['12'];

// TITLE HEADERS IN CAT SHARING DETAILS EXCEL 
const sharingExcelHeaders =  ['Principal Ceding Company','Program','Underwriting Year', 'File Name', 'Shared With', 'Email Address','User Type' ];

//MAPPING OF WHICH HEADER/COLUMN MAPS TO WHICH FIELD IN THE RECORD (Wrapper class in LWC63_ExportSharingDetails)
const excelColFieldMap = {
    'File Name' : 'fileName',
    'Shared With' : 'sharedWith',
    'Email Address': 'emailAddress',
    'User Type' : 'userType'
};

/**
 * @description Show toast
 */
function showToast(component,title,variant, message){
    const event = new ShowToastEvent({
      title: title,
      variant: variant,
      message: message,
      mode: variant == "warning" ? "sticky" : "dismissible"
    });
    component.dispatchEvent(event);
}

//RETURNS TEXT OF FILE SIZE 
function formatFileSize(bytes) {
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    if (bytes === 0) return '0 Byte';
    const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    // return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
    return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;

}

//BBH 29.09.2024
function frenchFormatFileSize(bytes) {
    const sizes = ['Octets', 'Ko', 'Mo', 'Go', 'To'];
    if (bytes === 0) return '0 Octet';
    const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    // return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
    return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;

}

//BBH 04.07.2024 SORT AXA DOCUMENTS BY DOC TYPE, THEN BY NAME
function sortObjectsByFields(objects, ...fields) {
    return objects.sort((a, b) => {
        for (const field of fields) {
            const comparison = a[field].localeCompare(b[field]);
            if (comparison !== 0) {
                return comparison;
            }
        }
        return 0;
    });
}


//USED IN LWC47 AND LWC48
function reCountTotalFileSize(totalFileSize,lstDocuments){

    // let maxSize = 12*1024*1024;
    totalFileSize.fileSize = 0;
    totalFileSize.displaySize = '0 Mo';
    totalFileSize.viewable = false;
    if(lstDocuments && lstDocuments.length > 0 ){
        for (let index = 0; index < lstDocuments.length; index++) {
            const element = lstDocuments[index];
            if(element['FileSizeRaw']){
                totalFileSize.fileSize+=element['FileSizeRaw'];
            }
        }
        totalFileSize.displaySize = (totalFileSize.fileSize/(1024*1024)).toFixed(2)+' Mo';

        totalFileSize.viewable = true;
    }
}

export {navigateToRecordViewPage,
    documentTypeRedirect,
    docTypeToExport,
    showToast,
    sharingExcelHeaders,
    excelColFieldMap,
    formatFileSize,
    frenchFormatFileSize,
    sortObjectsByFields,
    reCountTotalFileSize
}