/*******************************************************************************************************
* 
* @ Name            :   DEL_FeedItemDeleteEventTrigger
* @ Purpose         :   Trigger on FeedItemDeleteEvent platform event
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_FeedItemDeleteEventTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-09-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/
trigger DEL_FeedItemDeleteEventTrigger on DEL_FeedItemDeleteEvent__e (after insert) {

    /* Skip this trigger when DEL_FeedItemDeleteEventTriggerHelper.blnSkipTrigger is true
       or the IsActive__c is false in the DEL_TriggerConfiguration__mdt metadata for this trigger.
       CMDEL0005 is the name of the record used for this trigger.
    */
    if (
        (DEL_TriggerConfiguration__mdt.getInstance('CMDEL0005') != null &&
         !DEL_TriggerConfiguration__mdt.getInstance('CMDEL0005').IsActive__c) ||
        DEL_EmailMessagesTriggerHelper.blnSkipTrigger
    ) {
        return;
    }

    if (trigger.isAfter && trigger.isInsert) {
        DEL_FeedItemDeleteEventTriggerHelper.processFeedItemsAfterInsert(trigger.new);
    }
}