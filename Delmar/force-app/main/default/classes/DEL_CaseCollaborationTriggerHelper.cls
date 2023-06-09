/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationTriggerHelper
* @ Purpose         :   To handle the trigger events for DEL_CaseCollaborationTrigger
* @ Author          :   Dinesh Chandra
* @ Usage           :   1) Creating case collaborators so that case can be collaborated from one agent
*                          to another.
*                       2) Avoid duplicate case collaborators.
* @ Test Class Name :   DEL_CaseCollaborationTriggerHelperTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  18-07-2022       |  dinesh.chandra@absyz.com     |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_CaseCollaborationTriggerHelper {
    public static DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration;
    public static Boolean blnSkipTrigger = false;
    
    /**
    * @ author      : Dinesh Chandra
    * @ description : This method handles the Case Sharing.Case collaborators are created and cases are shared.
    * @ params      : list_CaseCollaborators - list of Case Collaborator records passed from trigger
    **/
    public static void shareCases(List<DEL_CaseCollaborator__c> list_CaseCollaborators) {    
        List<CaseShare> list_CaseShares = new List<CaseShare>();
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        Set<Id> set_UserIds = new Set<Id>();
        Map<Id, User> map_UserById = new Map<Id, User>();
        try {
            EntityDefinition objEntityDefinition = [SELECT  
                                                    DeveloperName, 
                                                    ExternalSharingModel, 
                                                    InternalSharingModel 
                                                    FROM EntityDefinition 
                                                    WHERE DeveloperName = 'Case'
                                                    ]; 
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                set_UserIds.add(objCaseCollaborator.User__c);
            }

            map_UserById = new Map<Id, User>([
                SELECT 
                Id,
                IsPortalEnabled
                FROM 
                User
                WHERE Id IN :set_UserIds
            ]);

            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                if (
                    map_UserById.containsKey(objCaseCollaborator.User__c) &&
                    !map_UserById.get(objCaseCollaborator.User__c).IsPortalEnabled &&
                    objEntityDefinition.InternalSharingModel != 'Private' &&
                    objEntityDefinition.InternalSharingModel != 'Read'
                ) {
                    continue;
                }
                
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
    
    public static void deleteSharedCases(List<DEL_CaseCollaborator__c> list_CaseCollaborators) {
        List<CaseShare> list_CaseShares = new List<CaseShare>(); 
        List<CaseShare> list_DeleteCaseShares = new List<CaseShare>(); 
        Set<Id> set_CaseIds = new Set<Id>();
        Set<Id> set_UserIds = new Set<Id>();
        Map<Id, CaseShare> map_CaseShareByUserId = new Map<Id, CaseShare>();

        try {
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                set_CaseIds.add(objCaseCollaborator.Case__c);
                set_UserIds.add(objCaseCollaborator.User__c);
            }

            list_CaseShares = [SELECT 
                               Id, 
                               CaseId, 
                               UserOrGroupId 
                               FROM CaseShare 
                               WHERE CaseId IN :set_CaseIds
                               AND UserOrGroupId IN :set_UserIds
                               AND RowCause = 'Manual'];
            for (CaseShare objCaseShare : list_CaseShares) {
                map_CaseShareByUserId.put(objCaseShare.UserOrGroupId, objCaseShare);
            }

            for (Id idUserId : set_UserIds) {
                if (map_CaseShareByUserId.containsKey(idUserId)) {
                    CaseShare objCaseShare = map_CaseShareByUserId.get(idUserId);
                    Id idCaseId = objCaseShare.CaseId;
                    if (set_CaseIds.contains(idCaseId)) {
                        list_DeleteCaseShares.add(objCaseShare);
                    }
                }
            }
            if (!list_DeleteCaseShares.isEmpty()) {
                delete list_DeleteCaseShares;
            }

        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_CaseCollaborationTriggerHelper',
                'deleteSharedCases',
                objException,
                true
            );
        }
    }


    /**
    * @ author      : Dinesh Chandra
    * @ description : This method handles creation of URL's for Community Portal for Customers and Salesforce Login for Agents.
    * @ params      : list_CaseCollaborators - list of Case collaborator records passed from trigger
    **/
    public static void populateFields(List<DEL_CaseCollaborator__c> list_CaseCollaborators) {
        String strCommnunityURL = '';
        try {
            objCaseCollaborationConfiguration = DEL_CaseCollaborationConfiguration__c.getOrgDefaults();
            String strSFURL = URL.getSalesforceBaseUrl().toExternalForm();
            if (Test.isRunningTest()) {
                if (DEL_CaseCollaborationTriggerHelperTest.blnThrowException) {
                    throw new DMLException();
                }
                
                strCommnunityURL = DEL_CaseCollaborationTriggerHelperTest.getSiteLink();
            } else {
                Site objSite = [SELECT 
                                Id
                                FROM Site 
                                WHERE Name = :objCaseCollaborationConfiguration.SiteName__c
                               ];
                SiteDetail objSiteDetail = [SELECT
                                            SecureURL 
                                            FROM SiteDetail
                                            WHERE DurableId = :objSite.Id
                                           ];
                strCommnunityURL = objSiteDetail.SecureURL;
            }
            
            Set<Id> set_UserIds = new Set<Id>();
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                set_UserIds.add(objCaseCollaborator.User__c);
            }
            
            Map<Id, User> map_UsersById = new Map<Id, User>([SELECT 
                                                             Id,
                                                             IsPortalEnabled 
                                                             FROM User 
                                                             WHERE Id IN :set_UserIds
                                                            ]);
            for (DEL_CaseCollaborator__c objCaseCollaborator : list_CaseCollaborators) {
                if (map_UsersById.containsKey(objCaseCollaborator.User__c) && 
                    map_UsersById.get(objCaseCollaborator.User__c).IsPortalEnabled
                   ) {
                       objCaseCollaborator.CaseUrl__c = strCommnunityURL + '/' + objCaseCollaborator.Case__c;
                   } else {
                       objCaseCollaborator.CaseUrl__c = strSFURL + '/' + objCaseCollaborator.Case__c;
                   }
            }
        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_CaseCollaborationTriggerHelper',
                'populateFields',
                objException,
                true
            );
        }
    }
    
    /**
    * @ author      : Dinesh Chandra
    * @ description : This method handle avoids creation of duplicate case collaborators.
    * @ params      : list_CaseCollaborators - list of Case collaborator records passed from trigger
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