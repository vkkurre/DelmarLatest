/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationTrigger
* @ Purpose         :   Trigger on DEL_CaseCollaborator__c object
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_CaseCollaborationTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/

trigger DEL_CaseCollaborationTrigger on DEL_CaseCollaborator__c (after insert, before insert) {
    /* Skip this trigger when DEL_CaseCollaborationTriggerHelper.blnSkipTrigger is true
       or the IsActive__c is false in the DEL_TriggerConfiguration__mdt metadata for this trigger.
       CMDEL0002 is the name of the record used for this trigger.
    */
    if (
        (DEL_TriggerConfiguration__mdt.getInstance('CMDEL0002') != null &&
        !DEL_TriggerConfiguration__mdt.getInstance('CMDEL0002').IsActive__c) ||
        DEL_CaseCollaborationTriggerHelper.blnSkipTrigger
    )  {
        return;
    }

    if (Trigger.isInsert && Trigger.isBefore) {
        DEL_CaseCollaborationTriggerHelper.handleDuplicates(trigger.new);
    }
    
    if (Trigger.isInsert && Trigger.isAfter) {
        DEL_CaseCollaborationTriggerHelper.shareCases(trigger.new);     
    }
}