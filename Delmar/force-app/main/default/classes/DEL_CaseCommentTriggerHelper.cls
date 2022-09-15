/*********************************************************************************************************
* 
* @ Name            :   DEL_CaseCommentTriggerHelper
* @ Purpose         :   Helper class for DEL_CaseCommentTrigger
* @ Author          :   Ankit C
* @ Usage           :   1) To populate fields and send email alerts when case comment is created.
* @ Test Class Name :   DEL_CaseCommentTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ========================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*  22-08-2022       |  rakesh.nayak@absyz.com        |  1.1          |  Added email differentiation logic
*********************************************************************************************************/
public class DEL_CaseCommentTriggerHelper {
    public static Boolean blnSkipTrigger = false;
    public static Boolean blnIsIncomingEmailMessage = false;
    // Map of Users by Id
    public static Map<Id, User> map_UserById;
    // Map of Cases by Id
    public static Map<Id, Case> map_CasesById;
    // List of DEL_CaseComment__c records to update
    public static List<DEL_CaseComment__c> list_CaseCommentsToUpdate;
    // List of Case records to update
    public static List<Case> list_CasesToUpdate;
    // List of DEL_CaseComment__c records to which have attachments
    public static List<DEL_CaseComment__c> list_CaseCommentsWithoutAttachments;
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method handles all the operations to be performed in the afterInsert trigger context.
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void processAfterInsert(List<DEL_CaseComment__c> list_CaseComments) {
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        list_CasesToUpdate = new List<Case>();
        list_CaseCommentsWithoutAttachments = new List<DEL_CaseComment__c>();
        createCollectionsAfterInsert(list_CaseComments);
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        if (!list_CaseCommentsToUpdate.isEmpty()) {
            for (DEL_CaseComment__c objCaseComment : list_CaseCommentsToUpdate) {
                populateFields(objCaseComment);
                if (!objCaseComment.HasAttachment__c) {
                    list_CaseCommentsWithoutAttachments.add(objCaseComment);
                }
            }
            
            blnSkipTrigger = true;
            List<Database.SaveResult> list_UpdateResults = Database.update(list_CaseCommentsToUpdate, false);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpdateResults, 'Update'));
            blnSkipTrigger = false;

            if (!list_CasesToUpdate.isEmpty()) {
                List<Database.SaveResult> list_CaseUpdateResults = Database.update(list_CasesToUpdate, false);
                list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_CaseUpdateResults, 'Update'));
            }
        }
        
        if (!list_ConsolidatedDMLErrors.isEmpty()) {
            DEL_Utils.logDMLException(
                'DEL_CaseCommentTriggerHelper',
                'processAfterInsert',
                list_ConsolidatedDMLErrors
            );
        }
        
        if (!list_CaseCommentsWithoutAttachments.isEmpty()) {
            processAfterInsertAysnc(list_CaseCommentsWithoutAttachments, blnIsIncomingEmailMessage);
        }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method contains logic that can be processed in asynchronous context
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records to process
    **/
    public static void processAfterInsertAysnc(List<DEL_CaseComment__c> list_CaseComments, Boolean blnIsIncomingEmailMessage) {
        ID idJobId = System.enqueueJob(new DEL_AsyncCaseCommentEmailAlerts(list_CaseComments, blnIsIncomingEmailMessage));
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method populates the fields which are empty
    * @ params       :  objCaseComment - DEL_CaseComment__c record to be updated.
    **/
    public static void populateFields(DEL_CaseComment__c objCaseComment) {
        if (String.isBlank(objCaseComment.CommentCreatedBy__c)) {
            objCaseComment.CommentCreatedBy__c = objCaseComment.CreatedById;

            if (map_UserById.containsKey(objCaseComment.CommentCreatedBy__c) && map_UserById.get(objCaseComment.CommentCreatedBy__c).IsPortalEnabled) {
                map_CasesById.get(objCaseComment.Case__c).Status = 'Awaiting Internal Response';
                list_CasesToUpdate.add(map_CasesById.get(objCaseComment.Case__c));
            } else if (map_UserById.containsKey(objCaseComment.CommentCreatedBy__c) && !map_UserById.get(objCaseComment.CommentCreatedBy__c).IsPortalEnabled) {
                map_CasesById.get(objCaseComment.Case__c).Status = 'Awaiting Customer Response';
                list_CasesToUpdate.add(map_CasesById.get(objCaseComment.Case__c));
            }
        }

        if (String.isBlank(objCaseComment.CommentCreatedName__c)) {
            objCaseComment.CommentCreatedName__c = map_UserById.get(objCaseComment.CreatedById).Name;
        }
        
        if (Test.isRunningTest() && DEL_CaseCommentTriggerHelperTest.blnThrowException) {
            throw new DMLException();
        }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method creates all the collection variables which are used in processAfterInsert()
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void createCollectionsAfterInsert(List<DEL_CaseComment__c> list_CaseComments) {
        Set<Id> set_UserIds = new Set<Id>();
        Set<Id> set_CaseIds = new Set<Id>();
        map_UserById = new Map<Id, User>();
        // Query to get the list of case comments that will be updated
        list_CaseCommentsToUpdate = [SELECT
                                     Id,
                                     CommentCreatedBy__c,
                                     CommentCreatedName__c,
                                     CommentCreatedBy__r.Name,
                                     CreatedById,
                                     Body__c,
                                     Case__c,
                                     EmailMessageId__c,
                                     CreatedDate,
                                     VisibleToCustomer__c,
                                     HasAttachment__c,
                                     (
                                         SELECT
                                         Id,
                                         LinkedEntityId,
                                         ContentDocumentId
                                         FROM ContentDocumentLinks
                                     )
                                     FROM DEL_CaseComment__c
                                     WHERE Id IN :list_CaseComments
                                    ];

        for (DEL_CaseComment__c objCaseComment : list_CaseCommentsToUpdate) {
            set_UserIds.add(objCaseComment.CreatedById);
            set_CaseIds.add(objCaseComment.Case__c);
        }
        
        // Query Users
        map_UserById = new Map<Id, User>([SELECT  
                                          Id,
                                          Name,
                                          IsPortalEnabled,
                                          Email
                                          FROM User
                                          WHERE Id IN :set_UserIds
                                         ]);
        // Query Cases
        map_CasesById = new Map<Id, Case>([SELECT  
                                          Id,
                                          Status
                                          FROM Case
                                          WHERE Id IN :set_CaseIds
                                         ]);
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method sends email alerts when Case Comments are created with attachments.
    * @ params       :  list_CaseComments - List of CaseComment records
    **/
    public static void processCaseCommentsWithAttachments(List<DEL_CaseComment__c> list_CaseComments) {
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        createCollectionsAfterInsert(list_CaseComments);
        processAfterInsertAysnc(list_CaseCommentsToUpdate,blnIsIncomingEmailMessage);
    }
}