/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCommentTriggerHelper
* @ Purpose         :   Helper class for DEL_CaseCommentTrigger
* @ Author          :   Ankit C
* @ Usage           :   1) To populate fields and send email alerts when case comment is created.
* @ Test Class Name :   DEL_CaseCommentTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_CaseCommentTriggerHelper {
    public static Boolean blnSkipTrigger = false;
    // Map of Users by Id
    public static Map<Id, User> map_UserById;
    // Map of Case Collaborators by Case Id
    public static Map<Id, List<DEL_CaseCollaborator__c>> map_CaseCollaboratorsByCaseId;
    // Map of Cases by Id
    public static Map<Id, Case> map_CaseById;
    public static DEL_EmailAlertConfiguration__c objEmailAlertConfiguration;
    // Map of EmailMessages records by Case Id
    public static Map<Id, EmailMessage> map_EmailMessageByCaseId;
    // List of DEL_CaseComment__c records to update
    public static List<DEL_CaseComment__c> list_CaseCommentsToUpdate;
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method handles all the operations to be performed in the afterInsert trigger context.
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void processAfterInsert(List<DEL_CaseComment__c> list_CaseComments) {
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        objEmailAlertConfiguration = DEL_EmailAlertConfiguration__c.getOrgDefaults();
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        createCollectionsAfterInsert(list_CaseComments);
        sendCommentNotificationEmail(list_CaseComments);

        if (!list_CaseCommentsToUpdate.isEmpty()) {
            for (DEL_CaseComment__c objCaseComment : list_CaseCommentsToUpdate) {
                populateFields(objCaseComment);
            }

            blnSkipTrigger = true;
            List<Database.SaveResult> list_UpdateResults = Database.update(list_CaseCommentsToUpdate, false);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpdateResults, 'Update'));
            blnSkipTrigger = false;
        }

        if (!list_ConsolidatedDMLErrors.isEmpty()) {
            DEL_Utils.logDMLException(
                'DEL_CaseCommentTriggerHelper',
                'processAfterInsert',
                list_ConsolidatedDMLErrors
            );
        }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method populates the fields which are empty
    * @ params       :  objCaseComment - DEL_CaseComment__c record to be updated.
    **/
    public static void populateFields(DEL_CaseComment__c objCaseComment) {
        if (!map_UserById.containsKey(objCaseComment.CreatedById)) {
            return;
        }

        if (String.isBlank(objCaseComment.CommentCreatedName__c)) {
            objCaseComment.CommentCreatedName__c = map_UserById.get(objCaseComment.CreatedById).Name;
        }

        if (String.isBlank(objCaseComment.CreatedByEmail__c)) {   
            objCaseComment.CreatedByEmail__c = map_UserById.get(objCaseComment.CreatedById).Email;
        }
    }

    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method creates all the collection variables which are used in processAfterInsert()
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void createCollectionsAfterInsert(List<DEL_CaseComment__c> list_CaseComments) {
        map_CaseCollaboratorsByCaseId = new Map<Id, List<DEL_CaseCollaborator__c>>();
        Set<Id> set_CaseIds = new Set<Id>();
        Set<Id> set_UserIds = new Set<Id>();
        map_UserById = new Map<Id, User>();
        map_CaseById = new Map<Id, Case>();
        map_EmailMessageByCaseId = new Map<Id, EmailMessage>();

        // Query to get the list of case comments that will be updated
        list_CaseCommentsToUpdate = [
            SELECT
                Id,
                CommentCreatedName__c,
                CreatedByEmail__c,
                CreatedById
            FROM 
                DEL_CaseComment__c
            WHERE
                Id IN :list_CaseComments
        ];
        
        for (DEL_CaseComment__c objCaseComment : list_CaseComments) {
            set_CaseIds.add(objCaseComment.Case__c);
            set_UserIds.add(objCaseComment.CreatedById);
        }
        
        // Query the Case Collaborators related the Case
        for (DEL_CaseCollaborator__c objCollaborator : [
            SELECT 
            Id,
            Case__c,
            User__c
            FROM
            DEL_CaseCollaborator__c
            WHERE
            Case__c IN :set_CaseIds
        ]) {
            if (map_CaseCollaboratorsByCaseId.containsKey(objCollaborator.Case__c)) {
                map_CaseCollaboratorsByCaseId.get(objCollaborator.Case__c).add(objCollaborator);
            } else { 
                map_CaseCollaboratorsByCaseId.put(objCollaborator.Case__c, new List<DEL_CaseCollaborator__c> { objCollaborator });
            }
            
            set_UserIds.add(objCollaborator.User__c);
        }
        
        // Query Cases
        String strCaseQuery = 'SELECT Id, OwnerId, SuppliedEmail, ' + objEmailAlertConfiguration.CaseQueryFields__c 
            + ' FROM Case WHERE Id IN :set_CaseIds';
        List<Case> list_Cases = Database.query(strCaseQuery);
        map_CaseById = new Map<Id, Case>(list_Cases);
        for (Case objCase : map_CaseById.values()) {
            set_UserIds.add(objCase.OwnerId);
        }
        
        // Query Users
        map_UserById = new Map<Id, User>([
            SELECT  
                Id,
                Name,
                Email
            FROM 
                User
            WHERE Id IN :set_UserIds
        ]);

        // Query the latest EmailMessage record which have Headers for Cases
        for (EmailMessage objEmailMessage : [
            SELECT 
                Id,
                ParentId,
                Headers
            FROM
                EmailMessage
            WHERE
                ParentId IN :set_CaseIds
            ORDER BY ParentId, CreatedDate DESC
        ]) {
            if (
                String.isNotBlank(objEmailMessage.Headers) && 
                !map_EmailMessageByCaseId.containsKey(objEmailMessage.ParentId)
            ) {
                map_EmailMessageByCaseId.put(objEmailMessage.ParentId, objEmailMessage);
            }
        }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method sends email alerts when a DEL_CaseComment__c is created.
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void sendCommentNotificationEmail(List<DEL_CaseComment__c> list_CaseComments) {
        List<Messaging.SingleEmailMessage> list_EmailMessages = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> list_OrgWideEmailAddresses = [
            SELECT 
            Id, 
            Address, 
            DisplayName 
            FROM 
            OrgWideEmailAddress 
            WHERE Address = :objEmailAlertConfiguration.OrgWideAddress__c
        ];
        EmailTemplate objTemplate = [
            SELECT 
            Id,
            HtmlValue,
            Subject
            FROM EmailTemplate
            WHERE DeveloperName = :objEmailAlertConfiguration.CaseCommentEmailTemplate__c
        ];
        
        String strSiteURL;
        if (Test.isRunningTest()) {
            strSiteURL = DEL_CaseCommentTriggerHelperTest.getSiteLink();
        } else {
            Site objSite = [SELECT Id FROM Site WHERE Name = :objEmailAlertConfiguration.SiteName__c];
            SiteDetail objSiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :objSite.Id];
            strSiteURL = objSiteDetail.SecureURL;
        }
        
        List<String> list_MergeFields = objEmailAlertConfiguration.MergeFields__c.split(',');
        for (DEL_CaseComment__c objCaseComment : list_CaseComments) {
            Messaging.SingleEmailMessage objSingleMessage = new Messaging.SingleEmailMessage();
            List<String> list_ToAddresses = new List<String>();
            if (map_UserById.containsKey(objCaseComment.CreatedById)) {
                // Adding the Case Comment Created By Email
                list_ToAddresses.add(map_UserById.get(objCaseComment.CreatedById).Email);
            }

            if (map_CaseCollaboratorsByCaseId.containsKey(objCaseComment.Case__c)) {
                // Adding the Case Collabortors Emails
                for (DEL_CaseCollaborator__c objCollaborator : map_CaseCollaboratorsByCaseId.get(objCaseComment.Case__c)) {
                    if (map_UserById.containsKey(objCollaborator.User__c)) {
                        list_ToAddresses.add(map_UserById.get(objCollaborator.User__c).Email);
                    }
                }
            }
            
            if (map_CaseById.containsKey(objCaseComment.Case__c)) {
                Case objCase = map_CaseById.get(objCaseComment.Case__c);
                String strSubject = objTemplate.Subject;
                if (strSubject.contains('{!Case.Subject}')) {
                    strSubject = strSubject.replace('{!Case.Subject}', objCase.Subject);
                }

                objSingleMessage.setSubject(strSubject);
                if (map_UserById.containsKey(objCase.OwnerId)) {
                    // Adding the Case Owner Email
                    list_ToAddresses.add(map_UserById.get(objCase.OwnerId).Email);
                }
                
                if (String.isNotBlank(objCase.SuppliedEmail)) {
                     // Adding the Case Web Email
                    list_ToAddresses.add(objCase.SuppliedEmail);
                }

                // Setting the references in the Email headers 
                if (map_EmailMessageByCaseId.containsKey(objCase.Id)) {
                    EmailMessage objEmailMessage = map_EmailMessageByCaseId.get(objCase.Id);
                    String strReferences;
                    if (objEmailMessage.Headers.contains('References:')) {
                        String strHeaders = objEmailMessage.Headers;
                        strReferences = strHeaders.substringAfter('References:');
                        objSingleMessage.setReferences(strReferences);
                    }
                }

                objSingleMessage.setWhatId(objCase.Id);
            }
            
            String strHtmlBody = objTemplate.HtmlValue;
            strHtmlBody = getHtmlBody(
                objCaseComment, 
                map_CaseById.get(objCaseComment.Case__c), 
                list_MergeFields, 
                strHtmlBody, 
                strSiteURL
            );

            objSingleMessage.setToAddresses(list_ToAddresses);
            
            if (!list_OrgWideEmailAddresses.isEmpty()) {
                objSingleMessage.setOrgWideEmailAddressId(list_OrgWideEmailAddresses[0].Id);
            }

            objSingleMessage.setHtmlBody(strHtmlBody); 
            list_EmailMessages.add(objSingleMessage);
        }

        Messaging.SendEmailResult[] list_Results = Messaging.sendEmail(list_EmailMessages);
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method forms the Html Body of the email that needs to be sent
    * @ params       :  objCaseComment - DEL_CaseComment__c record
                        objCase - related Case
                        list_MergeFields - list of merge fields that are included in the email template.
                        strHtml - HtmlBody from the email template.
                        strSiteURL - Community Page Url.
    **/
    public static String getHtmlBody(
        DEL_CaseComment__c objCaseComment, 
        Case objCase, 
        List<String> list_MergeFields, 
        String strHtml, 
        String strSiteURL
    ) {
        // Map of Case field values by field API Names.
        Map<String, Object> map_CaseFieldByName = objCase.getPopulatedFieldsAsMap();
        // Map of Case Comment field values by field API Names.
        Map<String, Object> map_CaseCommentFieldByName = objCaseComment.getPopulatedFieldsAsMap();
        if (String.isNotBlank(strHTML)) {
            for (String strMergeFieldName : list_MergeFields) {
                String strField = '';
                String strConvertedDate = '';
                if (strMergeFieldName.contains('SiteLink')) {
                    strHTML = strHTML.replace(strMergeFieldName, strSiteURL + '/' + objCase.Id);
                } else if (strMergeFieldName.contains('{!Case.')) {
                    strField = strMergeFieldName.subString(strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}'));
                    if (map_CaseFieldByName.get(strField) != null) {
                        strHTML = strHTML.replace(strMergeFieldName, (String) map_CaseFieldByName.get(strField));
                    } else {
                        strHTML = strHTML.replace(strMergeFieldName, '');
                    }
                } else if (strMergeFieldName.contains('{!CaseComment.') && strMergeFieldName.contains('Date')) {
                    strField = strMergeFieldName.subString(strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}'));
                    DateTime dtmDateValue = DateTime.valueOf(map_CaseCommentFieldByName.get(strField));
                    String strDate = dtmDateValue.format('MMMM d');
                    String strTime = dtmDateValue.format('h:mm a z');
                    strHTML = strHTML.replace(strMergeFieldName, strDate + ' at ' + strTime);
                } else if (strMergeFieldName.contains('{!CaseComment.')) {
                    strField = strMergeFieldName.subString(strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}'));
                    if (map_CaseCommentFieldByName.get(strField) != null) {
                        strHTML = strHTML.replace(strMergeFieldName, (String) map_CaseCommentFieldByName.get(strField));
                    } else {
                        strHTML = strHTML.replace(strMergeFieldName, '');
                    }   
                }
            }
        }
        
        return strHtml;
    }
}
