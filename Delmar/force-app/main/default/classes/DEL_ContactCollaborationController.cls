/*******************************************************************************************************
* 
* @ Name            :   DEL_ContactCollaborationController
* @ Purpose         :   To handle the case sharing from one customer to another customer on community page.
* @ Author          :   Dinesh Chandra
* @ Usage           :   1) Creating case collaborators so that case can be collaborated from one customer
                           to another.
                        
* @ Test Class Name :   DEL_ContactCollaborationControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public with sharing class DEL_ContactCollaborationController {
    /**
    * @ Name            :   ResponseWrapper
    * @ Purpose         :   Wrapper class to send response to the lwc.
    * @ Author          :   Dinesh Chandra
    **/
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean blnIsSuccess;
        @AuraEnabled 
        public String strErrorMessage;
        @AuraEnabled 
        public List<User> list_Users;

        public ResponseWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
            this.list_Users = new List<User>();
        }
    }

    /**
    * @ author      : Dinesh Chandra
    * @ description : This method handles the User data of case under the same account.
    * @ params      : 'idCaseId'    - list of Case Collaborator records passed from trigger.
                      'strUserName' - string of user name in the searchbar.
    **/
    @AuraEnabled(cacheable = true)
    public static ResponseWrapper getUserData(Id idCaseId, String strUserName) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        try {
            Case objCase = [SELECT 
                            Id,
                            AccountId,
                            ContactId 
                            FROM Case
                            WHERE Id = :idCaseId];
            String strPattern = '%' + strUserName + '%';
            objResponseWrapper.list_Users = [SELECT 
                                             AccountId, 
                                             ContactId, 
                                             Id, 
                                             Name, 
                                             Username, 
                                             Email 
                                             FROM User 
                                             WHERE Name LIKE :strpattern 
                                             AND AccountId = :objCase.AccountId];
        } catch (Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
            DEL_Utils.logException(
                'DEL_ContactCollaborationController',
                'getUserData',
                objException,
                true
            );
        }

        return objResponseWrapper;
    }

    /**
    * @ author      : Dinesh Chandra
    * @ description : This method handles the sharing of case with selected users.
    * @ params      : 'list_UserIds' - list of Selected Users
                      'idCaseId' - Id of Case
    **/
    @AuraEnabled
    public static ResponseWrapper addContactCollaborator(List<Id> list_UserIds, Id idCaseId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        List<DEL_CaseCollaborator__c> list_objCaseCollaborators = new List<DEL_CaseCollaborator__c>();
        try {
            for (Id idUser : list_UserIds) {
                DEL_CaseCollaborator__c objCaseCollaborator = new DEL_CaseCollaborator__c (
                    User__c = idUser,
                    Case__c = idCaseId
                );
                list_objCaseCollaborators.add(objCaseCollaborator);
            }

            if (!list_objCaseCollaborators.isEmpty()) {
                insert list_objCaseCollaborators;
            }
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