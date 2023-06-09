/*******************************************************************************************************
* 
* @ Name            :   DEL_ContentDocumentLinkTrigger
* @ Purpose         :   Trigger on ContentDocumentLink object
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_ContentDocumentLinkTriggerTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/

trigger DEL_ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    /* Skip this trigger when DEL_ContentDocumentLinkTriggerHelper.blnSkipTrigger is true
        or the IsActive__c is false in the DEL_TriggerConfiguration__mdt metadata for this trigger.
        CMDEL0003 is the name of the record used for this trigger.
    */
    if (
        (DEL_TriggerConfiguration__mdt.getInstance('CMDEL0003') != null &&
         !DEL_TriggerConfiguration__mdt.getInstance('CMDEL0003').IsActive__c) ||
        DEL_ContentDocumentLinkTriggerHelper.blnSkipTrigger
    ) {
        return;
    }
    
    if (trigger.isAfter && trigger.isInsert) {
        DEL_ContentDocumentLinkTriggerHelper.handleContentDocumentLinksOnInsert(trigger.new);
    }
}