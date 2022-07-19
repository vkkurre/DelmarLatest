/*******************************************************************************************************
* 
* @ Name            :   DEL_CommentsPageController
* @ Purpose         :   To insert new comment and fetching all the comments
* @ Author          :   Rakesh Nayak
* @ Usage           :   1) For inserting a new comment on click of submit button
*                       2) For fetching all the related comments for a case
* @ Test Class Name :   DEL_CommentsPageControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  17-06-2022       |  rakesh.nayak@absyz.com       |  1.0          |  Initial version
*  21-06-2022       |  rakesh.nayak@absyz.com       |  1.1          |  Changed variable and function names
*  27-06-2022       |  rakesh.nayak@absyz.com       |  1.2          |  Added test class
*******************************************************************************************************/
public class DEL_CommentsPageController{
    public class DEL_DMLHandler{
        @AuraEnabled
        public Boolean blnIsSuccess;
        @AuraEnabled 
        public String  strErrorMessage;
    }

    //fetchComments-This method queries and returns the CaseComment records related to the case with Id 'recordID'
    @AuraEnabled(cacheable = true)
    public static List<DEL_CaseComment__c> fetchComments(String strRecordId){
        return [SELECT
                CreatedDate,
                CreatedById,
                CreatedBy.SmallPhotoUrl,
                CreatedBy.Name,
                Body__c 
                FROM DEL_CaseComment__c 
                WHERE Case__c = :strRecordId 
                ORDER BY CreatedDate 
                DESC];
    }
    //insertComment- This method takes the Body of comment and case Id as parameters and inserts the comment to salesforce.
    @AuraEnabled
    public static DEL_DMLHandler insertComment(String strBody, String strRecordId){
        DEL_Casecomment__c objCaseComment = new DEL_Casecomment__c(
            Body__c = strBody,
            Case__c = strRecordId
            );
        try{
            insert objCaseComment;
        }
        catch(DmlException objException){
            DEL_DMLHandler objDMLHandler = new DEL_DMLHandler();
            objDMLHandler.blnIsSuccess = false;
            objDMLHandler.strErrorMessage = objException.getMessage();
            return objDMLHandler;
        }
        DEL_DMLHandler objDMLHandler = new DEL_DMLHandler();
            objDMLHandler.blnIsSuccess = true;
            objDMLHandler.strErrorMessage = ' ';
            return objDMLHandler;
    }
}