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
        // Set of Parent Ids from EmailMessage records
        Set<Id> set_ParentIds = new Set<Id>();
        List<Case> list_CasesToUpdate = new List<Case>();
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        // List of DEL_CaseComment__c records to insert
        List<DEL_CaseComment__c> list_CaseComments = new List<DEL_CaseComment__c>();
        DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration = DEL_CaseCollaborationConfiguration__c.getOrgDefaults();
        
        for (EmailMessage objEmailMessage : list_EmailMessages) {
            set_ParentIds.add(objEmailMessage.ParentId);
        }
        
        // Map of Cases by Id
        Map<Id, Case> map_CasesById = new Map<Id, Case>([SELECT  
                                                         Id,
                                                         ContactId,
                                                         DEL_ToAddress__c,
                                                         DEL_CcAddress__c,
                                                         Visible_in_Community__c
                                                         FROM Case
                                                         WHERE Id IN :set_ParentIds
                                                        ]);
        
        try {
            for (EmailMessage objEmailMessage : list_EmailMessages) {
                if (
                    (map_CasesById.containsKey(objEmailMessage.ParentId) && 
                     map_CasesById.get(objEmailMessage.ParentId).Visible_in_Community__c) || 
                    (objEmailMessage.ToAddress == objCaseCollaborationConfiguration.OrgWideAddress__c)
                ) {
                    if ((objEmailMessage.ThreadIdentifier <> objEmailMessage.MessageIdentifier) && objEmailMessage.Incoming) {
                        if (String.isNotBlank(objEmailMessage.ParentId)) {
                            DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
                            objCaseComment.Case__c = objEmailMessage.ParentId;
                            objCaseComment.EmailMessageId__c = objEmailMessage.Id;
                            objCaseComment.CreatedByEmail__c = objEmailMessage.FromAddress;
                            objCaseComment.CommentCreatedName__c = objEmailMessage.FromName;
                            DEL_CaseCommentTriggerHelper.blnIsIncomingEmailMessage = true;
                            if (String.isNotBlank(objEmailMessage.HtmlBody)) {
                                objCaseComment.Body__c = DEL_Utils.handleHtmlBody(objEmailMessage.HtmlBody);
                            }
                            
                            list_CaseComments.add(objCaseComment);
                        }
                    }
                }
                
                if (objEMailMessage.Incoming && 
                    map_CasesById.containsKey(objEmailMessage.ParentId)
                   ) {
                       Case objCase = map_CasesById.get(objEmailMessage.ParentId);
                       if (String.isBlank(objCase.DEL_ToAddress__c)) {
                           objCase.DEL_ToAddress__c = objEmailMessage.ToAddress;
                       }

                       if (objCaseCollaborationConfiguration.CCAddressSwitch__c) {
                            String strCcAddresses = '';
                            Set<String> set_CcAddresses = new Set<String>();
                            if (String.isNotBlank(objCase.DEL_CcAddress__c)) {
                                set_CCAddresses.addAll(objCase.DEL_CcAddress__c.split(';'));
                            }
                            
                            if (String.isNotBlank(objEmailMessage.CCAddress)) {
                                set_CCAddresses.addAll(objEmailMessage.CCAddress.split('; '));
                            }
                            
                            for (String strCcAddress : set_CcAddresses) {
                                if ((strCcAddresses.length() + strCcAddress.length()) < 255) {
                                    if (String.isBlank(strCcAddresses)) {
                                        strCcAddresses = strCcAddresses + strCcAddress;
                                    } else {
                                        strCCAddresses = strCcAddresses + ';' + strCcAddress;
                                    }
                                } else {
                                    break;
                                }
                            }
                            
                            objCase.DEL_CcAddress__c = strCcAddresses;
                       }
                       
                       list_CasesToUpdate.add(objCase);
                   }
            }
            
            if (!list_CasesToUpdate.isEmpty()) {
                if (Test.isRunningTest() && DEL_EmailMessagesTriggerHelperTest.blnThrowException) {
                    throw new DMLException();
                }
                
                List<Database.SaveResult> list_UpdateResults = Database.Update(list_CasesToUpdate, false);
                list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpdateResults, 'Update'));
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