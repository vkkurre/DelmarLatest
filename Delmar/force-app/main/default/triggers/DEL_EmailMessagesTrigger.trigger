trigger DEL_EmailMessagesTrigger on EmailMessage (after insert) {
    if (
        (DEL_TriggerConfig__mdt.getInstance('CMDEL0001') != null &&
        !DEL_TriggerConfig__mdt.getInstance('CMDEL0001').IsActive__c) ||
        DEL_EmailMessagesTriggerHandler.blnSkipTrigger
    ) {
        return;
    }
  
    if (trigger.isAfter && trigger.isInsert) {
        DEL_EmailMessagesTriggerHandler.handleEmailsOnInsert(trigger.new);
    }
}