/*******************************************************************************************************
* 
* @ Name            :   DEL_ContentDocumentLinkTriggerHelper
* @ Purpose         :   To handle the trigger events for DEL_ContentDocumentLinkTrigger
* @ Author          :   Rakesh Nayak
* @ Usage           :   1) Creating ContentDocumentLink records for CaseComments to link the email attachments
* @ Test Class Name :   DEL_ContentDocumentLinkTriggerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  02-08-2022       |  rakesh.nayak@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_ContentDocumentLinkTriggerHelper {
    public static Boolean blnSkipTrigger = false;
    
    /**
     * @ author      : Rakesh Nayak
     * @ description : This method handles the incoming ContentDocumentLink records and creates new link to case comment records.
     * @ params      : list_ContentDocumentLinks - list of ContentDocumentLink records passed from trigger
    **/
    public static void handleContentDocumentLinksOnInsert(List<ContentDocumentLink> list_ContentDocumentLinks) {
        Set<Id> set_LinkedEntityIDs = new Set<Id>();
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        Map<Id, List<ContentDocumentLink>> map_ListOfContentDocumentLinksByLinkedEntityId = new Map<Id, List<ContentDocumentLink>>();
        List<ContentDocumentLink> list_ContentDocumentLinksToInsert = new List<ContentDocumentLink>();
        try {
            for (ContentDocumentLink objContentDocumentLink : list_ContentDocumentLinks) {
                if (objContentDocumentLink.LinkedEntityId.getSObjectType().getDescribe().getName() == 'EmailMessage') {
                    set_LinkedEntityIDs.add(objContentDocumentLink.LinkedEntityId);
                    if (map_ListOfContentDocumentLinksByLinkedEntityId.containsKey(objContentDocumentLink.LinkedEntityId)) {
                        map_ListOfContentDocumentLinksByLinkedEntityId.get(objContentDocumentLink.LinkedEntityId).add(objContentDocumentLink);
                    } else {
                        map_ListOfContentDocumentLinksByLinkedEntityId.put(objContentDocumentLink.LinkedEntityId, new List<ContentDocumentLink> {objContentDocumentLink});
                    }
                }
            }
            
            if (!set_LinkedEntityIDs.isEmpty()) {
                List<DEL_CaseComment__c> list_CaseComments = [SELECT
                                                              Id,
                                                              EmailMessageID__c
                                                              FROM DEL_CaseComment__c
                                                              WHERE EmailMessageID__c IN :set_LinkedEntityIDs];
                
                //Creating ContentDocumentLinks for the case comment records                                              
                for (DEL_CaseComment__c objCaseComment : list_CaseComments) {
                    if (map_ListOfContentDocumentLinksByLinkedEntityId.containsKey(objCaseComment.EmailMessageID__c)) {
                        for (ContentDocumentLink objContentDocumentLink : map_ListOfContentDocumentLinksByLinkedEntityId.get(objCaseComment.EmailMessageID__c)) {
                            ContentDocumentLink objNewContentDocumentLink = new ContentDocumentLink();
                            objNewContentDocumentLink.ShareType = 'V';
                            objNewContentDocumentLink.Visibility = 'AllUsers';
                            objNewContentDocumentLink.ContentDocumentId = objContentDocumentLink.ContentDocumentId;
                            objNewContentDocumentLink.LinkedEntityId = objCaseComment.Id;
                            list_ContentDocumentLinksToInsert.add(objNewContentDocumentLink);
                        }
                    }
                }
            }
            
            if (!list_ContentDocumentLinksToInsert.isEmpty()) {
                if (Test.isRunningTest() && DEL_ContentDocumentLinkTriggerTest.blnThrowException) {
                    throw new DMLException();
                }
                
                blnSkipTrigger = true;
                List<Database.SaveResult> list_InsertResults = Database.insert(list_ContentDocumentLinksToInsert, false);
                blnSkipTrigger = false;
                list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_InsertResults, 'Insert'));
            }
            
            if (!list_ConsolidatedDMLErrors.isEmpty()) {
                DEL_Utils.logDMLException(
                    'DEL_ContentDocuentLinkTriggerHelper',
                    'handleContentDocumentLinksOnInsert',
                    list_ConsolidatedDMLErrors
                );
                
            }
        } catch(Exception objException) {
            DEL_Utils.logException(
                'DEL_ContentDocuentLinkTriggerHelper',
                'handleContentDocumentLinksOnInsert',
                objException,
                true
            );
        }
    }
}