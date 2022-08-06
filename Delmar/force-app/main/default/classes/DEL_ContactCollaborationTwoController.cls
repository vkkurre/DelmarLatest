public without sharing class DEL_ContactCollaborationTwoController {
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

    public static List<User> getUser(Id idCaseId, String strUserName, Id currentId) {
        List<User> list_User = new List<User>();
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
                                             WHERE Name LIKE :strpattern AND Id <>: currentId
                                             AND AccountId = :objCase.AccountId];
       } catch (Exception obj_exception) {
         system.debug(obj_exception.getMessage());
       }
      return list_User;
    }

    public static List<DEL_CaseCollaborator__c> addUser(List<Id> list_UserIds, Id idCaseId) {

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
            
        } catch(Exception obj_Exception) {
            system.debug(obj_exception.getMessage());
        }
     return list_objCaseCollaborators;
}
}