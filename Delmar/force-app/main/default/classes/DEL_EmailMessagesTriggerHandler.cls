/*******************************************************************************************************
* 
* @ Name            :   DEL_EmailMessagesTriggerHandler
* @ Purpose         :   To handle the trigger events for DEL_EmailMessagesTrigger
* @ Author          :   Rakesh Nayak
* @ Usage           :   1) Creating case comment records for incoming mail replies related to case
* @ Test Class Name :   DEL_EmailMessagesTriggerHandlerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  rakesh.nayak@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public with sharing class DEL_EmailMessagesTriggerHandler {
    /**
    * @ author      : Rakesh Nayak
    * @ description : This method handles the incoming email replies related to a case and creates case comment rcords for the same.
    * @ params      : list_EmailMessages - list of EmailMessage records passed from trigger
    **/
    public static void handleEmailsOnInsert(List<EmailMessage> list_EmailMessages) {
        String strPattern = '(<br>){1}';
        Pattern pattern = Pattern.compile(strPattern);
        List<DEL_CaseComment__c> list_CaseComments = new List<DEL_CaseComment__c>();
        for (EmailMessage objEmailMessage : list_EmailMessages) {
            if ((objEmailMessage.ThreadIdentifier <> objEmailMessage.MessageIdentifier) && objEmailMessage.Incoming){
                if (String.isNotBlank(objEmailMessage.ParentId)) {
                    DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
                    objCaseComment.Case__c = objEmailMessage.ParentId;
                    if (String.isNotBlank(objEmailMessage.HtmlBody)) {
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