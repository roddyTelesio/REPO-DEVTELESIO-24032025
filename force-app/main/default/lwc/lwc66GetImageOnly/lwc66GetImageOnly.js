/*
  @description       : 
  @author            : Telesio - RRA
  @group             : 
  @last modified on  : 08-11-2024
  Ticket id          : W- 2171
  Ver   Date         Author                   Modification
  1.0   08-11-2024   RRA    Initial Version
*/
import { LightningElement, api } from 'lwc';

export default class Lwc66GetImageOnly extends LightningElement {
   @api imageUrl;
   @api height;
   @api width;
   @api alt;
}