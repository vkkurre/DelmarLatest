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
*  17-06-2022       |  rakesh.nayak@absyz.com       |  1.0          |  Initial version
*  21-06-2022       |  rakesh.nayak@absyz.com       |  1.1          |  Changed variable and function names
*  27-06-2022       |  rakesh.nayak@absyz.com       |  1.2          |  Added test class
*  22-07-2022       |  vinaykant.kurre@absyz.com    |  1.3          |  Added method to get CustomSetting & Update/Delete 
                                                                       CaseComments
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
        @AuraEnabled public List<DEL_CaseComment__c> list_CaseComments;
        @AuraEnabled public Map<Id, List<ContentVersion>> map_AttachmentsByCaseCommentId;

        public ResponseWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
            this.list_CaseComments = new List<DEL_CaseComment__c>();
            this.map_AttachmentsByCaseCommentId = new Map<Id, List<ContentVersion>>();
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

        try {
            objResponseWrapper.list_CaseComments = [SELECT
                                                    CreatedDate,
                                                    LastModifiedDate,
                                                    CreatedById,
                                                    CreatedBy.SmallPhotoUrl,
                                                    CreatedBy.Name,
                                                    Body__c,
                                                    CommentCreatedName__c,
                                                    CreatedByEmail__c
                                                    FROM DEL_CaseComment__c 
                                                    WHERE Case__c = :strRecordId 
                                                    ORDER BY CreatedDate 
                                                    DESC];
            
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
    * @ return       :  objResponseWrapper - instance of ResponseWrapper class
    **/
    @AuraEnabled
    public static ResponseWrapper insertComment(String strBody, String strRecordId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c(
            Body__c = strBody,
            Case__c = strRecordId
        );
        
        try {
            insert objCaseComment;
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
    * @ author       :  Ankit
    * @ description  :  This method should be called to force an exception which 
    *                   will cover catch blocks when running test methods.
    **/
    public static void throwException() {
        throw new DMLException();
    }
}