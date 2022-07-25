trigger DEL_EmailMessagesTrigger on EmailMessage (after insert) {
    /* Skip this trigger when DEL_EmailMessagesTriggerHandler.blnSkipTrigger is true
       or the IsActive__c is false in the DEL_TriggerConfiguration__mdt metadata for this trigger.
       CMDEL0001 is the name of the record used for this trigger.
    */
    if (
        (DEL_TriggerConfiguration__mdt.getInstance('CMDEL0001') != null &&
        !DEL_TriggerConfiguration__mdt.getInstance('CMDEL0001').IsActive__c) ||
        DEL_EmailMessagesTriggerHandler.blnSkipTrigger
    ) {
        return;
    }
  
    if (trigger.isAfter && trigger.isInsert) {
        DEL_EmailMessagesTriggerHandler.handleEmailsOnInsert(trigger.new);
    }
}