/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationController
* @ Purpose         :   To insert new comment and fetching all the comments
* @ Author          :   Rakesh Nayak
* @ Usage           :   1) For inserting a new comment on click of submit button
*                       2) For fetching all the related comments for a case
* @ Test Class Name :   DEL_CaseCollaborationControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  22-07-2022       |  rakesh.nayak@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_CaseCollaborationController {
    /**
    * @ Name     :  ResponseWrapper
    * @ Purpose  :  Wrapper class to send response to the lwc.
    * @ Author   :  Ankit CS
    **/
    public class ResponseWrapper {
        @AuraEnabled public Boolean blnIsSuccess;
        @AuraEnabled public String strErrorMessage;
        @AuraEnabled public Id idCaseCommentId;
        @AuraEnabled public List<DEL_CaseComment__c> list_CaseComments;
        @AuraEnabled public Map<Id, List<ContentVersion>> map_AttachmentsByCaseCommentId;
        @AuraEnabled public User objCurrentUser;
        
        public ResponseWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
            this.list_CaseComments = new List<DEL_CaseComment__c>();
            this.map_AttachmentsByCaseCommentId = new Map<Id, List<ContentVersion>>();
            this.objCurrentUser = new User();
        }
    }
    
    /**
    * @ author       :  Rakesh Nayak & Vinaykant
    * @ description  :  This method queries and returns the CaseComment records related to the case with Id 'recordID'
    * @ params       :  'strRecordId' - Record Id of the Case
    * @ return       :  List of DEL_CaseComment__c records
    **/
    @AuraEnabled(cacheable = true)
    public static ResponseWrapper fetchComments(String strRecordId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        Map<Id, ContentDocumentLink> map_ContentDocumentLinkByContentDocumentId = new Map<Id, ContentDocumentLink>();
        Map<Id, List<ContentVersion>> map_ContentVersionsByCaseCommentId = new Map<Id, List<ContentVersion>>();
        List<Id> list_CaseCommentIds = new List<Id>();
        Id idCurrentUser = UserInfo.getUserId();
        String strQueryCurrentUser = 'Select Id, Name, IsPortalEnabled From User WHERE Id = :idCurrentUser';
        try {
            User objUser = Database.query(strQueryCurrentUser);
            String strQueryCaseComments = 'SELECT CreatedDate, LastModifiedDate, CreatedById, ' 
                + ' CreatedBy.SmallPhotoUrl, CreatedBy.Name, Body__c, CommentCreatedName__c, CreatedByEmail__c, '
                + ' EmailMessageId__c, VisibleToCustomer__c FROM DEL_CaseComment__c WHERE Case__c = :strRecordId';
            
            if (objUser.IsPortalEnabled) {
                strQueryCaseComments += ' AND VisibleToCustomer__c = true';
            }
            
            strQueryCaseComments += ' ORDER BY CreatedDate DESC';
            
            objResponseWrapper.objCurrentUser = objUser;
            objResponseWrapper.list_CaseComments = Database.query(strQueryCaseComments);
            
            if (!objResponseWrapper.list_CaseComments.isEmpty()) {
                for (DEL_CaseComment__c objCaseComment : objResponseWrapper.list_CaseComments) {
                    list_caseCommentIds.add(objCaseComment.Id);
                }
                List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT 
                                                                       ContentDocumentId,
                                                                       LinkedEntityId
                                                                       FROM ContentDocumentLink 
                                                                       WHERE LinkedEntityId 
                                                                       IN :list_caseCommentIds];
                
                if (!list_contentDocumentLinks.isEmpty()) {
                    for (ContentDocumentLink objContentDocumentLink : list_contentDocumentLinks) {
                        map_ContentDocumentLinkByContentDocumentId.put(objContentDocumentLink.ContentDocumentId, objContentDocumentLink);
                    }
                    List<ContentVersion> list_ContentVersions = [SELECT 
                                                                 ContentDocumentId, 
                                                                 Id, 
                                                                 FileExtension, 
                                                                 Title, 
                                                                 ContentSize, 
                                                                 CreatedDate, 
                                                                 FileType, 
                                                                 ContentBodyId 
                                                                 FROM ContentVersion 
                                                                 WHERE ContentDocumentId 
                                                                 IN :map_ContentDocumentLinkByContentDocumentId.KeySet()
                                                                 ORDER BY Title];
                    
                    for (ContentVersion objContentVersion : list_contentVersions) {
                        String strCommentId = map_ContentDocumentLinkByContentDocumentId.get(objContentVersion.ContentDocumentId).LinkedEntityId;
                        if (map_ContentVersionsByCaseCommentId.containsKey(strCommentId)) {
                            map_ContentVersionsByCaseCommentId.get(strCommentId).add(objContentVersion);
                        } else {
                            map_ContentVersionsByCaseCommentId.put(strCommentId, new List<ContentVersion> { objContentVersion } );
                        }
                    }
                }
                objResponseWrapper.map_AttachmentsByCaseCommentId = map_ContentVersionsByCaseCommentId;
            }
            
            // Throw an exception from test class                                        
            if (Test.isRunningTest() && DEL_CaseCollaborationControllerTest.blnThrowException) {
                throwException();
            }
        } catch (Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
        }
        
        return objResponseWrapper;
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to create new Case Comment record using comment body 'strBody' and case ID 'strRecordId'
    * @ params       :  'strRecordId' - Record Id of the Case
    *                   'strBody'     - Body of the comment
    *                   'blnVisibleToCustomer - flag to specify if comment should be visible to Customers.
    *                   list_ContentDocumentIds -  List of ContentDocumentIds that were uploaded
    * @ return       :  objResponseWrapper - instance of ResponseWrapper class
    **/
    @AuraEnabled
    public static ResponseWrapper insertComment(
        String strBody, 
        String strRecordId, 
        Boolean blnVisibleToCustomer, 
        List<String> list_ContentDocumentIds
    ) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c(
            Body__c = strBody,
            Case__c = strRecordId,
            VisibleToCustomer__c = blnVisibleToCustomer
        );
        try {
            if (!list_ContentDocumentIds.isEmpty()) {
                objCaseComment.HasAttachment__c = true;
            }
            
            insert objCaseComment;
            if (!list_ContentDocumentIds.isEmpty()) {
                createContentDocumentLink(objCaseComment.Id, list_ContentDocumentIds);
            }
            
            // Throw an exception from test class                                        
            if (Test.isRunningTest() && DEL_CaseCollaborationControllerTest.blnThrowException) {
                throwException();
            }
        } catch(Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
        }
        return objResponseWrapper;
    }
    
    /**
    * @ author       :  Deeksha Suvarna
    * @ description  :  This method is used to create ContentDocumentLink for the ContentVersion
    * @ params       :  'strRecordId' - Record Id of the Case
    *                   'strBody'     - Body of the comment
    *                   'list_ContentDocumentIds' - List of ContentDocument Ids
    * @ return       :  objResponseWrapper - instance of ResponseWrapper class
    **/
    @AuraEnabled
    public static void createContentDocumentLink(Id idCaseCommentId, List<String> list_ContentDocumentIds) {
        List<ContentDocumentLink> list_ContentDocumentLinks = new List<ContentDocumentLink>();
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        for (String strContentDocumentId : list_ContentDocumentIds) {
            ContentDocumentLink objNewContentDocumentLink = new ContentDocumentLink();
            objNewContentDocumentLink.ShareType = 'V';
            objNewContentDocumentLink.Visibility = 'AllUsers';
            objNewContentDocumentLink.ContentDocumentId = strContentDocumentId;
            objNewContentDocumentLink.LinkedEntityId = idCaseCommentId;
            list_ContentDocumentLinks.add(objNewContentDocumentLink);   
        }
        
        if (!list_ContentDocumentLinks.isEmpty()) {
            List<Database.SaveResult> list_InsertResults = Database.insert(list_ContentDocumentLinks, false);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_InsertResults, 'Insert'));
        }
        
        if (!list_ConsolidatedDMLErrors.isEmpty()) {
            DEL_Utils.logDMLException(
                'DEL_CaseCollaborationController',
                'createContentDocumentLink',
                list_ConsolidatedDMLErrors
            );
        }
    }
    
    /**
    * @ author       :  Ankit
    * @ description  :  This method should be called to force an exception which 
    *                   will cover catch blocks when running test methods.
    **/
    public static void throwException() {
        throw new DMLException();
    }
}