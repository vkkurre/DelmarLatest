public with sharing class DEL_EmailMessagesTriggerHandler {
    //handleEmailsOnInsert- 
    public static void handleEmailsOnInsert(List<EmailMessage> list_EmailMessages){
        String strPattern = '(<br>){1}';
        Pattern pattern = Pattern.compile(strPattern);
        List<DEL_CaseComment__c> list_CaseComments = new List<DEL_CaseComment__c>();
        for (EmailMessage objEmailMessage : list_EmailMessages) {
            if ((objEmailMessage.ThreadIdentifier <> objEmailMessage.MessageIdentifier) &&  objEmailMessage.Incoming == true){
                if (objEmailMessage.ParentId <> null){
                    DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
                    objCaseComment.Case__c = objEmailMessage.ParentId;
                    if (String.isNotBlank(objEmailMessage.HtmlBody)){
                        String[] list_SplitResults = pattern.split(objEmailMessage.HtmlBody);
                        objCaseComment.Body__c = list_SplitResults.get(0).stripHtmlTags();
                    }
                    list_CaseComments.add(objCaseComment);
                }
            }
        }
        insert list_CaseComments;
    }
}