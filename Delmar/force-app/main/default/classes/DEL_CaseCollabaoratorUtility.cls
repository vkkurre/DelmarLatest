/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollabaoratorUtility
* @ Purpose         :   utility Class for DEL_ContactCollaborationController
* @ Author          :   Dinesh Chandra
* @ Usage           :   1)Querying users under and Account for a case
                        2)Inserting case collaborator.
* @ Test Class Name :   DEL_ContactCollaborationControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public without sharing class DEL_CaseCollabaoratorUtility {
    
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
    * @ name     :  getUser
    * @ purpose  :  To query all the user details of the case collaborators.
    * @ author   :  Dinesh Chandra
    **/

    public static List<User> getUser(Id idCaseId, String strUserName, Id idCurrentId) {
        List<User> list_User = new List<User>();
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
       try {
            Case objCase = [SELECT 
                        Id,
                        AccountId,
                        ContactId 
                        FROM Case
                        WHERE Id = :idCaseId];

            String strPattern = '%' + strUserName + '%';
            list_User = [SELECT 
                          AccountId, 
                          ContactId, 
                          Id, 
                          Name, 
                          Username, 
                          Email 
                          FROM User 
                          WHERE Name LIKE :strpattern AND Id != :idCurrentId
                          AND AccountId = :objCase.AccountId];
        } catch (Exception objException) {
        objResponseWrapper.blnIsSuccess = false;
        objResponseWrapper.strErrorMessage = objException.getMessage();
        }
        return list_User;
    }
    
    /**
    * @ name     :  addUser
    * @ purpose  :  To add the selected users as case collaborators.
    * @ author   :  Dinesh Chandra
    **/

    public static List<DEL_CaseCollaborator__c> addUser(List<Id> list_UserIds, Id idCaseId) {
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
        }
        
        return list_objCaseCollaborators;
    }
}