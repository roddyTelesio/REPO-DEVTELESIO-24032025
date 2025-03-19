import { LightningElement,wire,track,api } from 'lwc';
import getContentDocLinkData from '@salesforce/apex/reportExportSharingDetails.getContentDocLinkData';
import getProgramDetails from '@salesforce/apex/reportExportSharingDetails.getPrograms';
import checkBtnVisibility from '@salesforce/apex/reportExportSharingDetails.checkBtnVisibility';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {showToast} from 'c/lwcUtilityCmp';
import { loadScript } from "lightning/platformResourceLoader";
import SheetJS from '@salesforce/resourceUrl/SheetJS'; 

export default class LwcReportExportFileSharing extends LightningElement {
    isLibraryLoaded = false;
    allData;
    showButton;
    async connectedCallback(){
        await loadScript(this, SheetJS); // load the library
        checkBtnVisibility().then(res =>{
            if(res){
                this.showButton = true;
            }
        })

    }
    handleSharingInfo(){
        // async connectedCallback() {
            showToast(this,'Veiller patienter...','info','Récuperation des données en cours.');
            
            // At this point, the library is accessible with the `XLSX` variable
            this.version = XLSX.version;
            getProgramDetails().then(res=>{
                this.program=res;
                getContentDocLinkData({lstProgIds :  this.program}).then(data=>{
                    this.allData = data;
                    this.exportToExcel();
                }).catch(err=>{
                    console.log(err);
                });      
            }).catch(error=>{console.log(error)})
        // }
    }

    exportToExcel() {
        const filename = 'Reporting CAT Files.xlsx';
        const workbook = XLSX.utils.book_new();
        const headers = [];
        const worksheetData = [];
        const sharingExcelHeaders =  ['Entity','Macro LOB','Program Name','File Id','File Name','Sent by', 'Status Broker / Reinsurer', 'Shared With (Company Name)','Contact Name'];
        const excelColFieldMap = {
            'Entity' : 'pcc',
            'Macro LOB' : 'macrolob',
            'Program Name' : 'progName',
            'File Id' : 'fileId',
            'File Name' : 'fileName',
            'Sent by' : 'sentby',
            'Status Broker / Reinsurer' : 'userType',
            'Shared With (Company Name)' : 'sharedWith',
            'Contact Name' : 'contactName'
        };
        console.log(this.allData);
        
        for (const record of this.allData) {
            console.log('each ',record);
            
            let dt = {}
            // dt[sharingExcelHeaders[0]] = result[0].Program__c;
            // dt[sharingExcelHeaders[1]] =  result[0].Name;
            // dt[sharingExcelHeaders[2]] = this.uwYear;
            for (let index = 0; index < sharingExcelHeaders.length; index++) {
                dt[sharingExcelHeaders[index]]= record[excelColFieldMap[sharingExcelHeaders[index]]]; 
                console.log('#bb'+record[excelColFieldMap[sharingExcelHeaders[index]]]);
            }
            worksheetData.push(dt);
          
        }
        const worksheet = XLSX.utils.json_to_sheet(worksheetData, { header: sharingExcelHeaders });
        XLSX.utils.book_append_sheet(workbook, worksheet, 'ExportToExcel');
    
        const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
        const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });
    
        // Create a download link and click it programmatically to initiate the download
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = filename;
        a.click();
        showToast(this,'Téléchargement en cours.','success','Votre fichier de CSV est en cours de téléchargement.');
        // Release the object URL to free up memory
        URL.revokeObjectURL(a.href);
        this.dispatchEvent(new CustomEvent('close'))
    }
}