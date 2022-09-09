/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollabaoratorUtility
* @ Purpose         :   Utility Class for DEL_ContactCollaborationController which will run in 
*                       without sharing mode.
* @ Author          :   Dinesh Chandra
* @ Usage           :   1)Querying users under an Account for the Case
*                       2)Inserting case collaborators.
* @ Test Class Name :   DEL_ContactCollaborationControllerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com     |  1.0          |  Initial version
*******************************************************************************************************/
public without sharing class DEL_CaseCollabaoratorUtility {
    /**
     * @ author       :  Dinesh Chandra
     * @ description  :  To query all the user details of the potential case collaborators.
     * @ params       :  'idCaseId' - Case Id
     *                   'strUserName' - User name entered in the search
     *                   'list_FieldNames' - List of field names to query
     * @ return       :  list_Users - list of Users
    **/
    public static List<User> queryUsers(Id idCaseId, String strUserName, List<String> list_FieldNames) {
        List<User> list_Users = new List<User>();
        Set<Id> set_UserIdsToExclude = new Set<Id>();
        Case objCase = [SELECT 
                        Id,
                        AccountId,
                        ContactId 
                        FROM Case
                        WHERE Id = :idCaseId];
        if (String.isNotBlank(objCase.ContactId)) {
            List<User> list_ContactUsers = [SELECT 
                                            Id, 
                                            ContactId 
                                            FROM User
                                            WHERE ContactId = :objCase.ContactId];
            if (!list_ContactUsers.isEmpty()) {
                set_UserIdsToExclude.add(list_ContactUsers[0].Id);
            }
        }
        
        String strPattern = '%' + String.escapeSingleQuotes(strUserName) + '%';
        //Excluding users who are already collaborators for the Case.
        for (DEL_CaseCollaborator__c objCaseCollaborator : [SELECT 
                                                            Id,
                                                            User__c 
                                                            FROM DEL_CaseCollaborator__c 
                                                            WHERE Case__c = :idCaseId]
            ) {
                set_UserIdsToExclude.add(objCaseCollaborator.User__c);
            }

        // Excluding the logged-in User (Case-Owner) to not to be visible in
        // the list of potential collaborators.
        set_UserIdsToExclude.add(UserInfo.getUserId());

        String strQuery = 'SELECT Id, ';
        strQuery += String.join(list_FieldNames, ',') + ' FROM User WHERE Name LIKE :strpattern AND Id NOT IN :set_UserIdsToExclude '
            + 'AND AccountId = \'' + objCase.AccountId + '\' AND IsActive = true';
        if (String.isNotBlank(objCase.AccountId)) {
            list_Users = Database.query(strQuery);
        }
        
        return list_Users;
    }
    
    /**
     * @ author       :  Dinesh Chandra
     * @ description  :  Method to insert Case Collaborator records for the Case.
     * @ params       :  'list_UserIds' - List of Selected Users
     *                   'idCaseId' - Case Id
    **/
    public static void insertCaseCollaborators(List<Id> list_UserIds, Id idCaseId) {
        List<DEL_CaseCollaborator__c> list_CaseCollaborators = new List<DEL_CaseCollaborator__c>();
        for (Id idUser : list_UserIds) {
            DEL_CaseCollaborator__c objCaseCollaborator = new DEL_CaseCollaborator__c(
                User__c = idUser,
                Case__c = idCaseId
            );
            
            list_CaseCollaborators.add(objCaseCollaborator);
        }
        
        if (!list_CaseCollaborators.isEmpty()) {
            insert list_CaseCollaborators;
        }
    }

    /**
     * @ author       :  Vinay kant
     * @ description  :  To query all the user details of the case collaborators.
     * @ params       :  'idCaseId' - Case Id
     *                   'list_UserFields' - List of field names from User
     * @ return       :  list_CaseCollaborators - list of Case Collaborators
    **/
    public static List<DEL_CaseCollaborator__c> queryCaseCollaborators(Id idCaseId, List<String> list_UserFields) {
        String strQuery = 'SELECT Id, ';
        String strUserFields = '';
        for (String strFieldName : list_UserFields) {
            strUserFields += 'User__r.' + strFieldName + ',';
        }

        strQuery += strUserFields + 'Case__c FROM DEL_CaseCollaborator__c WHERE Case__c = :idCaseId AND User__r.IsPortalEnabled = true';
        List<DEL_CaseCollaborator__c> list_CaseCollaborators = Database.query(strQuery);
        return list_CaseCollaborators;
    }

    /**
     * @ author       :  Vinay kant
     * @ description  :  To delete case collaborators.
     * @ params       :  'list_CollaboratorIds' - List of Case Collaborator Ids.
    **/
    public static void deleteCollaborators(List<Id> list_CollaboratorIds) {
        List<DEL_CaseCollaborator__c> list_CaseCollaborators = [SELECT 
                                                                Id 
                                                                FROM 
                                                                DEL_CaseCollaborator__c 
                                                                WHERE Id IN :list_CollaboratorIds];

        if (!list_CaseCollaborators.isEmpty()) {
            delete list_CaseCollaborators;
        }
    }

    /**
     * @ author       :  Ankit C
     * @ description  :  Method to fetch Case Comments
     * @ params       :  strQuery - Query String
     *                   strRecordId - Case Id
    **/
    public static List<DEL_CaseComment__c> queryCaseComments(String strQuery, String strRecordId) {
        List<DEL_CaseComment__c> list_CaseComments = Database.query(strQuery);
        return list_CaseComments;
    }
}