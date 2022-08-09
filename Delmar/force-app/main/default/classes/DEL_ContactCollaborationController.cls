/*******************************************************************************************************
* 
* @ Name            :   DEL_ContactCollaborationController
* @ Purpose         :   To handle the case sharing from one customer to another customer on community page.
* @ Author          :   Dinesh Chandra
* @ Usage           :   1) Creating case collaborators so that case can be collaborated from one customer to another.
* @ Test Class Name :   DEL_ContactCollaborationControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public with sharing class DEL_ContactCollaborationController {
    
    /**
    * @ name     :  ResponseWrapper
    * @ purpose  :  Wrapper class to send response to the lwc.
    * @ author   :  Dinesh Chandra
    **/
    public class ResponseWrapper {
        @AuraEnabled public Boolean blnIsSuccess;
        @AuraEnabled public String strErrorMessage;
        @AuraEnabled public List<User> list_Users;
        
        public ResponseWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
            this.list_Users = new List<User>();
        }
    }
    
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method handles the User data of case under the same account.
    * @ params       :  'idCaseId'    - list of Case Collaborator records passed from trigger.
    *                   'strUserName' - string of user name in the searchbar.
    **/
    @AuraEnabled(cacheable = true)
    public static ResponseWrapper getUserData(Id idCaseId, String strUserName, Id currentId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        objResponseWrapper.list_Users = DEL_CaseCollabaoratorUtility.getUser(idCaseId, strUserName, currentId);
        return objResponseWrapper;
    }
    
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method handles the sharing of case with selected users.
    * @ params       :  'list_UserIds' - list of Selected Users
    *                   'idCaseId' - Id of Case
    **/
    @AuraEnabled
    public static ResponseWrapper addContactCollaborator(List<Id> list_UserIds, Id idCaseId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        try {
            List <DEL_CaseCollaborator__c> list_Collaborators= DEL_CaseCollabaoratorUtility.addUser(list_UserIds,idCaseId);
        } catch(Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
            DEL_Utils.logException(
                'DEL_ContactCollaborationController',
                'addContactCollaborator',
                objException,
                true
            ); 
        }

        return objResponseWrapper; 
    }
}