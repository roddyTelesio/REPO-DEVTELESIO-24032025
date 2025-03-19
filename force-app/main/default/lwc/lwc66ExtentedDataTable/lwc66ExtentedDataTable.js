/*
  @description       : 
  @author            : Telesio - RRA
  @group             : 
  @last modified on  : 08-11-2024
  Ticket id          : W- 2171
  Ver   Date         Author                   Modification
  1.0   08-11-2024   RRA    Initial Version
*/
import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import imageTemplate from './templates/imageDatatable.html';

export default class Lwc66ExtentedDataTable extends LightningDatatable {
    //Let's create the Custom Type for the different types
    static customTypes = {
        image: {  // the name of the new datatype
            template: imageTemplate, // The HTML file that will get rendered
            typeAttributes: ['height', 'width', 'alt']  // the attribute of custom data type that we have created
        }
    };
}