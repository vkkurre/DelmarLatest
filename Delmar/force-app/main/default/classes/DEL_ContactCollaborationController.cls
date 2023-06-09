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
        @AuraEnabled public List<FieldsWrapper> list_FieldsWrappers;
        @AuraEnabled public List<DEL_CaseCollaborator__c> list_CaseCollaborators;
        
        public ResponseWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
            this.list_Users = new List<User>();
            this.list_FieldsWrappers = new List<FieldsWrapper>();
            this.list_CaseCollaborators = new List<DEL_CaseCollaborator__c>();
        }
    }

    /**
    * @ name     :  FieldsWrapper
    * @ purpose  :  Wrapper class to send field attributes for data table columns
    * @ author   :  Ankit C
    **/
    public class FieldsWrapper {
        @AuraEnabled public String strLabel;
        @AuraEnabled public String strName;
        @AuraEnabled public String strType;
        
        public FieldsWrapper() {
            this.strLabel = '';
            this.strName = '';
            this.strType = '';
        }
    }
    
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method fetches all the users under the Account for the Case.
    * @ params       :  'idCaseId'    - Case Id
    *                   'strUserName' - Name entered in the search bar
    * @ return       :  objResponseWrapper - instance of the ResponseWrapper class
    **/
    @AuraEnabled(cacheable = true)
    public static ResponseWrapper fetchUsers(Id idCaseId, String strUserName) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        //Api names of fields to query from User.
        List<String> list_FieldApiNames = new List<String>();
        DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration = DEL_CaseCollaborationConfiguration__c.getOrgDefaults();
        try {
            List<Schema.SObjectField> list_Fields = DEL_Utils.getFieldsFromFieldSet('User', objCaseCollaborationConfiguration.CollaboratorsFieldSet__c);
            for (Schema.SObjectField objField : list_Fields) {
                FieldsWrapper objFieldsWrapper = new FieldsWrapper();
                Schema.DescribeFieldResult objFieldResult = objField.getDescribe();
                list_FieldApiNames.add(String.valueOf(objFieldResult.getName()));
                objFieldsWrapper.strLabel = objFieldResult.getLabel();
                objFieldsWrapper.strName = objFieldResult.getName();
                if (String.valueOf(objFieldResult.getType()) == 'String') {
                    objFieldsWrapper.strType = 'text';
                } else if (
                    String.valueOf(objFieldResult.getType()) == 'Date' || 
                    String.valueOf(objFieldResult.getType()) == 'DateTime'
                ) {
                    objFieldsWrapper.strType = 'date';
                } else if (
                    String.valueOf(objFieldResult.getType()) == 'Double' || 
                    String.valueOf(objFieldResult.getType()) == 'Integer' || 
                    String.valueOf(objFieldResult.getType()) == 'Long'
                ) {
                    objFieldsWrapper.strType = 'number';
                } else {
                    objFieldsWrapper.strType = String.valueOf(objFieldResult.getType()).toLowerCase();
                }

                objResponseWrapper.list_FieldsWrappers.add(objFieldsWrapper);
            }

            objResponseWrapper.list_Users = DEL_CaseCollabaoratorUtility.queryUsers(
                idCaseId, 
                strUserName,
                list_FieldApiNames
            );

            objResponseWrapper.list_CaseCollaborators = DEL_CaseCollabaoratorUtility.queryCaseCollaborators(idCaseId, list_FieldApiNames);
        } catch(Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
            DEL_Utils.logException(
                'DEL_ContactCollaborationController',
                'fetchUsers',
                objException,
                true
            ); 
        }

        return objResponseWrapper;
    }
    
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method handles the sharing of case with selected users.
    * @ params       :  'list_UserIds' - list of Selected Users
    *                   'idCaseId' - Id of Case
    * @ return       :  objResponseWrapper - instance of the ResponseWrapper class
    **/
    @AuraEnabled
    public static ResponseWrapper addCaseCollaborators(List<Id> list_UserIds, Id idCaseId) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        try { 
            DEL_CaseCollabaoratorUtility.insertCaseCollaborators(list_UserIds, idCaseId);
        } catch(Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
            DEL_Utils.logException(
                'DEL_ContactCollaborationController',
                'addCaseCollaborators',
                objException,
                true
            ); 
        }

        return objResponseWrapper; 
    }

    /**
    * @ author       :  Vinay kant
    * @ description  :  This method will delete all Case Collaborators present in the list of Ids - 'list_CollaboratorIds'.
    * @ params       :  'list_CollaboratorIds' - list of Selected Case Collaborators
    * @ return       :  objResponseWrapper - instance of the ResponseWrapper class
    **/
    @AuraEnabled
    public static ResponseWrapper deleteCaseCollaborators(List<Id> list_CollaboratorIds) {
        ResponseWrapper objResponseWrapper = new ResponseWrapper();
        try {
            DEL_CaseCollabaoratorUtility.deleteCollaborators(list_CollaboratorIds);
        } catch(Exception objException) {
            objResponseWrapper.blnIsSuccess = false;
            objResponseWrapper.strErrorMessage = objException.getMessage();
            DEL_Utils.logException(
                'DEL_ContactCollaborationController',
                'deleteCaseCollaborator',
                objException,
                true
            ); 
        }
        
        return objResponseWrapper; 
    }
}