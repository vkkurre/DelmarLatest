/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCommentTrigger
* @ Purpose         :   Trigger on DEL_CaseComment__c object
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_CaseCommentTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/
trigger DEL_CaseCommentTrigger on DEL_CaseComment__c (after insert) {
    /* Skip this trigger when DEL_CaseCommentTriggerHelper.blnSkipTrigger is true
       or the IsActive__c is false in the DEL_TriggerConfiguration__mdt metadata for this trigger.
       CMDEL0003 is the name of the record used for this trigger.
    */
    if (
        (DEL_TriggerConfiguration__mdt.getInstance('CMDEL0003') != null &&
        !DEL_TriggerConfiguration__mdt.getInstance('CMDEL0003').IsActive__c) ||
        DEL_CaseCommentTriggerHelper.blnSkipTrigger
    ) {
        return;
    }

    if (trigger.isAfter && trigger.isInsert) {
        try {
            DEL_CaseCommentTriggerHelper.processAfterInsert(trigger.new);
        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_CaseCommentTriggerHelper',
                'processAfterInsert',
                objException,
                true
            );
        }
    }
}