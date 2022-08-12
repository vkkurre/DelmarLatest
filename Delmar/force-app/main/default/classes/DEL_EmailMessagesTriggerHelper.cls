/*******************************************************************************************************
* 
* @ Name            :   DEL_EmailMessagesTriggerHelper
* @ Purpose         :   To handle the trigger events for DEL_EmailMessagesTrigger
* @ Author          :   Rakesh Nayak
* @ Usage           :   1) Creating case comment records for incoming mail replies related to case
* @ Test Class Name :   DEL_EmailMessagesTriggerHelperTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  rakesh.nayak@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_EmailMessagesTriggerHelper {
    
    public static Boolean blnSkipTrigger = false;
    
    /**
     * @ author      : Rakesh Nayak
     * @ description : This method handles the incoming email replies related to a case and creates case comment records for the same.
     * @ params      : list_EmailMessages - list of EmailMessage records passed from trigger
    **/
    public static void handleEmailsOnInsert(List<EmailMessage> list_EmailMessages) {
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        List<DEL_CaseComment__c> list_CaseComments = new List<DEL_CaseComment__c>();
        try {
            for (EmailMessage objEmailMessage : list_EmailMessages) {
                if ((objEmailMessage.ThreadIdentifier <> objEmailMessage.MessageIdentifier) && objEmailMessage.Incoming) {
                    if (String.isNotBlank(objEmailMessage.ParentId)) {
                        DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
                        objCaseComment.Case__c = objEmailMessage.ParentId;
                        objCaseComment.EmailMessageId__c = objEmailMessage.Id;
                        objCaseComment.CreatedByEmail__c = objEmailMessage.FromAddress;
                        objCaseComment.CommentCreatedName__c = objEmailMessage.FromName;
                        if (String.isNotBlank(objEmailMessage.HtmlBody)) {
                            objCaseComment.Body__c = DEL_Utils.handleHtmlBody(objEmailMessage.HtmlBody);
                        }

                        list_CaseComments.add(objCaseComment);
                    }
                }
            }
            
            if (!list_CaseComments.isEmpty()) {
                if (Test.isRunningTest() && DEL_EmailMessagesTriggerHelperTest.blnThrowException) {
                    throw new DMLException();
                }
                
                List<Database.SaveResult> list_InsertResults = Database.insert(list_CaseComments, false);
                list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_InsertResults, 'Insert'));
            }
            
            if (!list_ConsolidatedDMLErrors.isEmpty()) {
                DEL_Utils.logDMLException(
                    'DEL_EmailMessagesTriggerHelper',
                    'handleEmailsOnInsert',
                    list_ConsolidatedDMLErrors
                );
            }
        } catch(Exception objException) {
            DEL_Utils.logException(
                'DEL_EmailMessagesTriggerHelper',
                'handleEmailsOnInsert',
                objException,
                true
            );
        }
    }
}