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
*******************************************************************************************************/
public class DEL_CaseCollaborationController {
    /**
    * @ Name            :   ResponseWrapper
    * @ Purpose         :   Wrapper class to send response to the lwc.
    * @ Author          :   Ankit CS
    **/
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean blnIsSuccess;
        @AuraEnabled 
        public String strErrorMessage;
    }

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
    * @ params      : 'strRecordId' - Record Id of the Case
    * @ return      : List of DEL_CaseComment__c records
    **/
    @AuraEnabled(cacheable = true)
    public static List<DEL_CaseComment__c> fetchComments(String strRecordId) {
        return [
            SELECT
            CreatedDate,
            CreatedById,
            CreatedBy.SmallPhotoUrl,
            CreatedBy.Name,
            Body__c 
            FROM DEL_CaseComment__c 
            WHERE Case__c = :strRecordId 
            ORDER BY CreatedDate 
            DESC
        ];
    }

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is used to create new Case Comment record using comment body 'strBody' and case ID 'strRecordId'
    * @ params      : 'strRecordId' - Record Id of the Case
    *                 'strBody'     - Body of the comment
    * @ return      : objResponseWrapper - instance of ResponseWrapper class
    **/
    @AuraEnabled
    public static ResponseWrapper insertComment(String strBody, String strRecordId) {
        ResponseWrapper objDMLHandler = new ResponseWrapper();
        DEL_Casecomment__c objCaseComment = new DEL_Casecomment__c(
            Body__c = strBody,
            Case__c = strRecordId
        );

        try {
            insert objCaseComment;
        } catch(Exception objException) {
            objDMLHandler.blnIsSuccess = false;
            objDMLHandler.strErrorMessage = objException.getMessage();
            return objDMLHandler;
        }

        objDMLHandler.blnIsSuccess = true;
        objDMLHandler.strErrorMessage = '';
        return objDMLHandler;
    }
}