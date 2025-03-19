import { LightningElement, track, wire,api } from 'lwc';
import getContentDocLinkData from '@salesforce/apex/LWC63_ExportSharingDetails.getContentDocLinkData';
import getProgramDetails from '@salesforce/apex/LWC01_WorkingScope.getProgramDetails';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {showToast,sharingExcelHeaders,excelColFieldMap} from 'c/lwcUtilityCmp';
import { loadScript } from "lightning/platformResourceLoader";
import SheetJS from '@salesforce/resourceUrl/SheetJS'; 

export default class Lwc63ExportSharingDetails extends LightningElement {

    @api lstContentDocIds;
    isLibraryLoaded = false;
    allData;
    @api program;
    @api uwYear;
    @api pcc;
    @api parent;

    async connectedCallback() {
        showToast(this,'Veiller patienter...','info','Récuperation des données en cours.');
        await loadScript(this, SheetJS); // load the library
        // At this point, the library is accessible with the `XLSX` variable
        this.version = XLSX.version;
        getContentDocLinkData({lstConVersionId : this.lstContentDocIds, programId :  this.program}).then(data=>{
            this.allData = data;
            getProgramDetails({id : this.program})
            .then(result => {
                this.exportToExcel(result);
            })
            .catch(error => {
                this.error = error;
            });
        });      
    }

    exportToExcel(result) {
        const filename = result[0].PrincipalCedingCompany__r.Name+','+result[0].Name+'-'+this.uwYear+'.xlsx';
        const workbook = XLSX.utils.book_new();
        const headers = [];
        const worksheetData = [];
    
        for (const record of this.allData) {
            let dt = {}
            dt[sharingExcelHeaders[0]] = result[0].PrincipalCedingCompany__r.Name;
            dt[sharingExcelHeaders[1]] =  result[0].Name;
            dt[sharingExcelHeaders[2]] = this.uwYear;
            for (let index = 3; index < sharingExcelHeaders.length; index++) {
                dt[sharingExcelHeaders[index]]= record[excelColFieldMap[sharingExcelHeaders[index]]]; 
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