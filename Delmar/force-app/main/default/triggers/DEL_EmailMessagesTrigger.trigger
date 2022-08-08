/*******************************************************************************************************
* 
* @ Name            :   DEL_EmailMessagesTrigger
* @ Purpose         :   Trigger on EmailMessage object
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_EmailMessagesTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/

trigger DEL_EmailMessagesTrigger on EmailMessage (after insert) {
    /* Skip this trigger when DEL_EmailMessagesTriggerHelper.blnSkipTrigger is true
       or the IsActive__c is false in the DEL_TriggerConfiguration__mdt metadata for this trigger.
       CMDEL0001 is the name of the record used for this trigger.
    */
    if (
        (DEL_TriggerConfiguration__mdt.getInstance('CMDEL0001') != null &&
         !DEL_TriggerConfiguration__mdt.getInstance('CMDEL0001').IsActive__c) ||
        DEL_EmailMessagesTriggerHelper.blnSkipTrigger
    ) {
        return;
    }
    
    if (trigger.isAfter && trigger.isInsert) {
        DEL_EmailMessagesTriggerHelper.handleEmailsOnInsert(trigger.new);
    }
}