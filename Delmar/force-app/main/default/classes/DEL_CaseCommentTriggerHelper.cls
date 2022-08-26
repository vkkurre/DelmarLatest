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
    // Map of Users by Id
    public static Map<Id, User> map_UserById;
    // Map of Case Collaborators by Case Id
    public static Map<Id, List<DEL_CaseCollaborator__c>> map_CaseCollaboratorsByCaseId;
    // Map of Cases by Id
    public static Map<Id, Case> map_CaseById;
    public static DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration;
    // Map of EmailMessages records by Case Id
    public static Map<Id, EmailMessage> map_EmailMessageByCaseId;
    // List of DEL_CaseComment__c records to update
    public static List<DEL_CaseComment__c> list_CaseCommentsToUpdate;
    // List of DEL_CaseComment__c records to which have attachments
    public static List<DEL_CaseComment__c> list_CaseCommentsWithoutAttachments;
    // Map of ContentVersion Ids by Case Comment Id
    public static Map<Id, List<String>> map_ContentVersionIdsByCaseCommentId;
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method handles all the operations to be performed in the afterInsert trigger context.
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void processAfterInsert(List<DEL_CaseComment__c> list_CaseComments) {
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        list_CaseCommentsWithoutAttachments = new List<DEL_CaseComment__c>();
        objCaseCollaborationConfiguration = DEL_CaseCollaborationConfiguration__c.getOrgDefaults();
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
        }
        
        if (!list_ConsolidatedDMLErrors.isEmpty()) {
            DEL_Utils.logDMLException(
                'DEL_CaseCommentTriggerHelper',
                'processAfterInsert',
                list_ConsolidatedDMLErrors
            );
        }
        
        if (!list_CaseCommentsWithoutAttachments.isEmpty()) {
            processAfterInsertAysnc(list_CaseCommentsWithoutAttachments);
        }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method contains logic that can be processed in asynchronous context
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records to process
    **/
    public static void processAfterInsertAysnc(List<DEL_CaseComment__c> list_CaseComments) {
        ID idJobId = System.enqueueJob(new DEL_AsyncCaseCommentEmailAlerts(
            list_CaseComments,
            map_EmailMessageByCaseId,
            map_UserById,
            map_CaseById,
            map_CaseCollaboratorsByCaseId,
            objCaseCollaborationConfiguration,
            map_ContentVersionIdsByCaseCommentId
        ));
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method populates the fields which are empty
    * @ params       :  objCaseComment - DEL_CaseComment__c record to be updated.
    **/
    public static void populateFields(DEL_CaseComment__c objCaseComment) {
        if (!map_UserById.containsKey(objCaseComment.CreatedById)) {
            return;
        }
        
        if (String.isBlank(objCaseComment.CommentCreatedName__c)) {
            objCaseComment.CommentCreatedName__c = map_UserById.get(objCaseComment.CreatedById).Name;
        }
        
        if (String.isBlank(objCaseComment.CreatedByEmail__c)) {   
            objCaseComment.CreatedByEmail__c = map_UserById.get(objCaseComment.CreatedById).Email;
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
        map_CaseCollaboratorsByCaseId = new Map<Id, List<DEL_CaseCollaborator__c>>();
        Set<Id> set_CaseIds = new Set<Id>();
        Set<Id> set_UserIds = new Set<Id>();
        map_UserById = new Map<Id, User>();
        map_CaseById = new Map<Id, Case>();
        map_EmailMessageByCaseId = new Map<Id, EmailMessage>();
        //Map of CaseComment Id by ContentDocumentId
        Map<Id, Id> map_CaseCommentIdByContentDocumentId = new Map<Id, Id>();
        map_ContentVersionIdsByCaseCommentId = new Map<Id, List<String>>();
        
        // Query to get the list of case comments that will be updated
        list_CaseCommentsToUpdate = [SELECT
                                     Id,
                                     CommentCreatedName__c,
                                     CreatedByEmail__c,
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
            set_CaseIds.add(objCaseComment.Case__c);
            set_UserIds.add(objCaseComment.CreatedById);
            
            if (!objCaseComment.ContentDocumentLinks.isEmpty()) {
                for (ContentDocumentLink objContentDocumentLink : objCaseComment.ContentDocumentLinks) {
                    map_CaseCommentIdByContentDocumentId.put(
                        objContentDocumentLink.ContentDocumentId, 
                        objContentDocumentLink.LinkedEntityId
                    );
                }
            }
        }
        
        //Get ContenVersionIds By Case Comment
        if (!map_CaseCommentIdByContentDocumentId.keySet().isEmpty()) {
            for (ContentVersion objContentVersion : [SELECT 
                                                     Id,
                                                     ContentDocumentId
                                                     FROM
                                                     ContentVersion
                                                     WHERE ContentDocumentId IN :map_CaseCommentIdByContentDocumentId.keySet()
                                                    ]
                ) {
                    if (!map_ContentVersionIdsByCaseCommentId.containsKey(map_CaseCommentIdByContentDocumentId.get(objContentVersion.ContentDocumentId))) {
                        map_ContentVersionIdsByCaseCommentId.put(
                            map_CaseCommentIdByContentDocumentId.get(objContentVersion.ContentDocumentId),
                            new List<String> { objContentVersion.Id }
                        );
                    } else {
                        map_ContentVersionIdsByCaseCommentId.get(map_CaseCommentIdByContentDocumentId.get(objContentVersion.ContentDocumentId)).add(objContentVersion.Id);
                    }
                }
        }
        
        // Query the Case Collaborators related the Case
        for (DEL_CaseCollaborator__c objCollaborator : [SELECT 
                                                        Id,
                                                        Case__c,
                                                        User__c
                                                        FROM DEL_CaseCollaborator__c
                                                        WHERE Case__c IN :set_CaseIds
                                                       ]
            ) {
                if (map_CaseCollaboratorsByCaseId.containsKey(objCollaborator.Case__c)) {
                    map_CaseCollaboratorsByCaseId.get(objCollaborator.Case__c).add(objCollaborator);
                } else { 
                    map_CaseCollaboratorsByCaseId.put(
                        objCollaborator.Case__c,
                        new List<DEL_CaseCollaborator__c> { objCollaborator }
                    );
                }
                
                set_UserIds.add(objCollaborator.User__c);
            }
        
        // Query Cases
        String strCaseQuery = 'SELECT Id, OwnerId, DEL_CcAddress__c, SuppliedEmail, ContactEmail, Contact.Preferred_Language__c, Language__c, ' 
            + 'Case_Thread_ID__c, ' + objCaseCollaborationConfiguration.CaseQueryFields__c + ' FROM Case WHERE Id IN :set_CaseIds';
        List<Case> list_Cases = Database.query(strCaseQuery);
        map_CaseById = new Map<Id, Case>(list_Cases);
        for (Case objCase : map_CaseById.values()) {
            set_UserIds.add(objCase.OwnerId);
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
        
        // Query the latest EmailMessage record which have Headers for Cases
        for (EmailMessage objEmailMessage : [SELECT 
                                             Id,
                                             ParentId,
                                             Headers
                                             FROM EmailMessage
                                             WHERE ParentId IN :set_CaseIds
                                             ORDER BY ParentId, CreatedDate DESC
                                            ]
            ) {
                if (
                    String.isNotBlank(objEmailMessage.Headers) && 
                    !map_EmailMessageByCaseId.containsKey(objEmailMessage.ParentId)
                ) {
                    map_EmailMessageByCaseId.put(objEmailMessage.ParentId, objEmailMessage);
                }
            }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method sends email alerts when Case Comments are created with attachments.
    * @ params       :  list_CaseComments - List of CaseComment records
    **/
    public static void processCaseCommentsWithAttachments(List<DEL_CaseComment__c> list_CaseComments) {
        objCaseCollaborationConfiguration = DEL_CaseCollaborationConfiguration__c.getOrgDefaults();
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        createCollectionsAfterInsert(list_CaseComments);
        processAfterInsertAysnc(list_CaseCommentsToUpdate);
    }
}