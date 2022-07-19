trigger DEL_EmailMessagesTrigger on EmailMessage (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        DEL_EmailMessagesTriggerHandler.handleEmailsOnInsert(trigger.new);
    }
}