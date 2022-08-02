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
        
        public ResponseWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
            this.list_CaseComments = new List<DEL_CaseComment__c>();
        }
    }
    
    /**
    * @ author       :  Vinaykant
    * @ description  :  Apex Method to fetch Case Configuration Custom Setting.
    * @ return       :  DEL_CaseCommentConfiguration__c
    **/
    @AuraEnabled(cacheable=true) 
    public static DEL_CaseCommentConfiguration__c getCaseCommentConfigurations() {
        return DEL_CaseCommentConfiguration__c.getOrgDefaults();
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method queries and returns the CaseComment records related to the case with Id 'recordID'
    * @ params       :  'strRecordId' - Record Id of the Case
    * @ return       :  List of DEL_CaseComment__c records
    **/
    @AuraEnabled(cacheable = true)
    public static ResponseWrapper fetchComments(String strRecordId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
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
    * @ author       :  Vinaykant
    * @ description  :  Apex Method to delete a particular case comment from a case.
    * @ params       :  'idCommentId' - Case Comment Id which be fetched.
    * @ return       :  'objResponseWrapper' - Wrapper Class Object.
    **/
    @AuraEnabled
    public static ResponseWrapper deleteCaseComment(Id idCommentId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        DEL_CaseComment__c objCaseComment = [SELECT
                                             Id 
                                             FROM DEL_CaseComment__c 
                                             WHERE Id = :idCommentId];
        
        try {
            delete objCaseComment;
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
    * @ author       :  Vinaykant
    * @ description  :  Apex Method to update a particular case comment with new edited comment.
    * @ params       :  'idCommentId' - Case Comment Id of which will be fetched.
    *                   'strComment' - New Edited Comment Body String for Case Comment Record.
    * @ return       :  'objResponseWrapper' - Wrapper Class Object.
    **/
    @AuraEnabled
    public static ResponseWrapper updateCaseComment(Id idCommentId, String strComment) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        DEL_CaseComment__c objCaseComment = [SELECT 
                                             Id,
                                             Body__c
                                             FROM DEL_CaseComment__c 
                                             WHERE Id = :idCommentId];
        objCaseComment.Body__c = strComment;
        
        try {
            update objCaseComment;
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
    * @ author       :  Ankit
    * @ description  :  This method should be called to force an exception which 
    *                   will cover catch blocks when running test methods.
    **/
    public static void throwException() {
        throw new DMLException();
    }
}