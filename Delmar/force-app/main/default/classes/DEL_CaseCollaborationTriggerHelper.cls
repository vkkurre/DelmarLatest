/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationTriggerHelper
* @ Purpose         :   To handle the trigger events for DEL_CaseCollaborationTrigger
* @ Author          :   Dinesh Chandra
* @ Usage           :   1) Creating case collaborators so that case can be collaborated from one agent to another.
*                       2) Avoid duplicate case collaborators.
* @ Test Class Name :   DEL_CaseCollaborationTriggerHelperTest
*
*   Date            |  Developer Name               |  Version    |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com     |  1.0        |  Initial version
*******************************************************************************************************/
public class DEL_CaseCollaborationTriggerHelper {
    
    public static Boolean blnSkipTrigger = false;

    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method handles the Case Sharing.Case collaborators are created and cases are shared.
    * @ params       :  list_CaseCollaborators - list of Case Collaborator records passed from trigger
    **/
    public static void shareCases(List<DEL_CaseCollaborator__c> list_CaseCollaborators) {    
        List<CaseShare> list_CaseShares = new List<CaseShare>();
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        try {
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                CaseShare objCaseShare = new CaseShare();
                objCaseShare.UserOrGroupId = objCaseCollaborator.User__c ;
                objCaseShare.CaseId = objCaseCollaborator.Case__c;
                objCaseShare.RowCause = Schema.CaseShare.RowCause.Manual;
                objCaseShare.CaseAccessLevel = 'Edit';
                list_CaseShares.add(objCaseShare);
            }
            
            if (!list_CaseShares.isEmpty()) {
                List<Database.SaveResult> list_InsertResults = Database.insert(list_CaseShares, false);
                list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_InsertResults, 'Insert'));
            }
            
            if (!list_ConsolidatedDMLErrors.isEmpty()) {
                DEL_Utils.logDMLException(
                    'DEL_CaseCollaborationTriggerHelper',
                    'shareCases',
                    list_ConsolidatedDMLErrors
                );
            }
        } catch(Exception objException) {
            DEL_Utils.logException(
                'DEL_CaseCollaborationTriggerHelper',
                'shareCases',
                objException,
                true
            );
        }
    }
    
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method handle avoids creation of duplicate case collaborators.
    * @ params       :  list_CaseCollaborators - list of Case collaborator records passed from trigger
    **/
    public static void handleDuplicates(List<DEL_CaseCollaborator__c> list_CaseCollaborators) {
        Set<String> set_CaseIds = new Set<String>();
        Map<String, List<DEL_CaseCollaborator__c>> map_ExistingCaseCollaborators = new Map<String, List<DEL_CaseCollaborator__c>>();
        try {
            if (Test.isRunningTest() && DEL_CaseCollaborationTriggerHelperTest.blnThrowException) {
                throw new DMLException();
            }
            
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                set_CaseIds.add(objCaseCollaborator.Case__c);
            }
            
            for (DEL_CaseCollaborator__c objCaseCollaborator : [SELECT 
                                                                Id, 
                                                                Case__c,
                                                                User__c  
                                                                FROM DEL_CaseCollaborator__c 
                                                                WHERE Case__c IN :set_CaseIds]
                ) {
                    String strUniqueKey = objCaseCollaborator.Case__c + '' + objCaseCollaborator.User__c;
                    if (map_ExistingCaseCollaborators.containsKey(strUniqueKey)) {
                        map_ExistingCaseCollaborators.get(strUniqueKey).add(objCaseCollaborator);
                    } else {
                        map_ExistingCaseCollaborators.put(strUniqueKey, new List<DEL_CaseCollaborator__c> { objCaseCollaborator });
                    }                                                    
                }
            
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                String strUniqueKey = objCaseCollaborator.Case__c + '' + objCaseCollaborator.User__c;
                if (map_ExistingCaseCollaborators.containsKey(strUniqueKey) &&
                    !map_ExistingCaseCollaborators.get(strUniqueKey).isEmpty()
                   ) {
                       objCaseCollaborator.addError('This user is already a collaborator for this Case.');
                   }
            }
        } catch(Exception objException) {
            DEL_Utils.logException(
                'DEL_CaseCollaborationTriggerHelper',
                'handleDuplicates',
                objException,
                true
            );
        } 
    }
}