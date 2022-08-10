/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollabaoratorUtility
* @ Purpose         :   Utility Class for DEL_ContactCollaborationController which will run in 
                        without sharing mode.
* @ Author          :   Dinesh Chandra
* @ Usage           :   1)Querying users under an Account for the Case
                        2)Inserting case collaborators.
* @ Test Class Name :   DEL_ContactCollaborationControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com       |  1.0          |  Initial version
*******************************************************************************************************/
public without sharing class DEL_CaseCollabaoratorUtility {
    /**
     * @ author       :  Dinesh Chandra
     * @ description  :  To query all the user details of the case collaborators.
     * @ params       :  'idCaseId' - Case Id
     *                   'strUserName' - User name entered in the search
     * @ return       :  list_Users - list of Users
    **/
    public static List<User> queryUsers(Id idCaseId, String strUserName) {
        List<User> list_Users = new List<User>();
        Set<Id> set_UserIdsToExclude = new Set<Id>();
        Case objCase = [SELECT 
                        Id,
                        AccountId,
                        ContactId 
                        FROM Case
                        WHERE Id = :idCaseId];
        
        String strPattern = '%' + strUserName + '%';
        //Excluding users who are already collaborators for the Case.
        for (DEL_CaseCollaborator__c objCaseCollaborator : [SELECT 
                                                            Id,
                                                            User__c 
                                                            FROM DEL_CaseCollaborator__c 
                                                            WHERE Case__c = :idCaseId]
        ) {
            set_UserIdsToExclude.add(objCaseCollaborator.User__c);
        }

        set_UserIdsToExclude.add(UserInfo.getUserId());

        list_Users = [SELECT 
                      AccountId, 
                      ContactId, 
                      Id, 
                      Name, 
                      Username, 
                      Email 
                      FROM User 
                      WHERE Name LIKE :strpattern 
                      AND Id NOT IN :set_UserIdsToExclude
                      AND AccountId = :objCase.AccountId];
        
        return list_Users;
    }
    
    /**
     * @ author       :  Dinesh Chandra
     * @ description  :  Method to insert Case Collaborator records for the Case.
     * @ params       :  'list_UserIds' - List of Selected Users
     *                   'idCaseId' - Case Id
    **/
    public static void insertCaseCollaborators(List<Id> list_UserIds, Id idCaseId) {
        List<DEL_CaseCollaborator__c> list_objCaseCollaborators = new List<DEL_CaseCollaborator__c>();
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
    }
}