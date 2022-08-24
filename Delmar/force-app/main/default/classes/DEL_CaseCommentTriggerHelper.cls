/*********************************************************************************************************
* 
* @ Name            :   DEL_CaseCommentTriggerHelper
* @ Purpose         :   Helper class for DEL_CaseCommentTrigger
* @ Author          :   Ankit C
* @ Usage           :   1) To populate fields and send email alerts when case comment is created.
* @ Test Class Name :   DEL_CaseCommentTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ========================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*  22-08-2022       |  rakesh.nayak@absyz.com        |  1.1          |  Added email differentiation logic
*********************************************************************************************************/
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
    // List of DEL_CaseComment__c records to which have attachments
    public static List<DEL_CaseComment__c> list_CaseCommentsWithoutAttachments;
    // Map of ContentVersion Ids by Case Comment Id
    public static Map<Id, List<String>> map_ContentVersionIdsByCaseCommentId;
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method handles all the operations to be performed in the afterInsert trigger context.
    * @ params       :  list_CaseComments - list of DEL_CaseComment__c records from trigger.new
    **/
    public static void processAfterInsert(List<DEL_CaseComment__c> list_CaseComments) {
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        list_CaseCommentsWithoutAttachments = new List<DEL_CaseComment__c>();
        objEmailAlertConfiguration = DEL_EmailAlertConfiguration__c.getOrgDefaults();
        createCollectionsAfterInsert(list_CaseComments);
        List<String> list_ConsolidatedDMLErrors = new List<String>();
        if (!list_CaseCommentsToUpdate.isEmpty()) {
            for (DEL_CaseComment__c objCaseComment : list_CaseCommentsToUpdate) {
                populateFields(objCaseComment);
                if (!objCaseComment.HasAttachment__c) {
                    list_CaseCommentsWithoutAttachments.add(objCaseComment);
                }
            }
            
            blnSkipTrigger = true;
            List<Database.SaveResult> list_UpdateResults = Database.update(list_CaseCommentsToUpdate, false);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpdateResults, 'Update'));
            blnSkipTrigger = false;
        }


        if (!list_CaseCommentsWithoutAttachments.isEmpty()) {
            sendCommentNotificationEmail(list_CaseCommentsWithoutAttachments);
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
        //Map of CaseComment Id by ContentDocumentId
        Map<Id, Id> map_CaseCommentIdByContentDocumentId = new Map<Id, Id>();
        map_ContentVersionIdsByCaseCommentId = new Map<Id, List<String>>();
        
        // Query to get the list of case comments that will be updated
        list_CaseCommentsToUpdate = [SELECT
                                     Id,
                                     CommentCreatedName__c,
                                     CreatedByEmail__c,
                                     CreatedById,
                                     Body__c,
                                     Case__c,
                                     EmailMessageId__c,
                                     CreatedDate,
                                     VisibleToCustomer__c,
                                     HasAttachment__c,
                                     (
                                        SELECT 
                                        Id,
                                        LinkedEntityId,
                                        ContentDocumentId
                                        FROM ContentDocumentLinks
                                     )
                                     FROM DEL_CaseComment__c
                                     WHERE Id IN :list_CaseComments
                                    ];
        
        for (DEL_CaseComment__c objCaseComment : list_CaseCommentsToUpdate) {
            set_CaseIds.add(objCaseComment.Case__c);
            set_UserIds.add(objCaseComment.CreatedById);

            if (!objCaseComment.ContentDocumentLinks.isEmpty()) {
                for (ContentDocumentLink objContentDocumentLink : objCaseComment.ContentDocumentLinks) {
                    map_CaseCommentIdByContentDocumentId.put(
                        objContentDocumentLink.ContentDocumentId, 
                        objContentDocumentLink.LinkedEntityId
                    );
                }
            }
        }

        //Get ContenVersionIds By Case Comment
        if (!map_CaseCommentIdByContentDocumentId.keySet().isEmpty()) {
            for (ContentVersion objContentVersion : [SELECT 
                                                     Id,
                                                     ContentDocumentId
                                                     FROM
                                                     ContentVersion
                                                     WHERE ContentDocumentId IN :map_CaseCommentIdByContentDocumentId.keySet()
                                                    ]
            ) {
                if (!map_ContentVersionIdsByCaseCommentId.containsKey(map_CaseCommentIdByContentDocumentId.get(objContentVersion.ContentDocumentId))) {
                    map_ContentVersionIdsByCaseCommentId.put(
                        map_CaseCommentIdByContentDocumentId.get(objContentVersion.ContentDocumentId), 
                        new List<String> { objContentVersion.Id }
                    );
                } else {
                   map_ContentVersionIdsByCaseCommentId.get(map_CaseCommentIdByContentDocumentId.get(objContentVersion.ContentDocumentId)).add(objContentVersion.Id);
                }
            }
        }
        
        // Query the Case Collaborators related the Case
        for (DEL_CaseCollaborator__c objCollaborator : [SELECT 
                                                        Id,
                                                        Case__c,
                                                        User__c
                                                        FROM DEL_CaseCollaborator__c
                                                        WHERE Case__c IN :set_CaseIds
                                                       ]
            ) {
                if (map_CaseCollaboratorsByCaseId.containsKey(objCollaborator.Case__c)) {
                    map_CaseCollaboratorsByCaseId.get(objCollaborator.Case__c).add(objCollaborator);
                } else { 
                    map_CaseCollaboratorsByCaseId.put(
                        objCollaborator.Case__c,
                        new List<DEL_CaseCollaborator__c> { objCollaborator }
                    );
                }
                
                set_UserIds.add(objCollaborator.User__c);
            }
        
        // Query Cases
        String strCaseQuery = 'SELECT Id, OwnerId, DEL_CcAddress__c, SuppliedEmail, ContactEmail, Contact.Preferred_Language__c, Language__c, ' + 
            + objEmailAlertConfiguration.CaseQueryFields__c + ' FROM Case WHERE Id IN :set_CaseIds';
        List<Case> list_Cases = Database.query(strCaseQuery);
        map_CaseById = new Map<Id, Case>(list_Cases);
        for (Case objCase : map_CaseById.values()) {
            set_UserIds.add(objCase.OwnerId);
        }
        
        // Query Users
        map_UserById = new Map<Id, User>([SELECT  
                                          Id,
                                          Name,
                                          IsPortalEnabled,
                                          Email
                                          FROM User
                                          WHERE Id IN :set_UserIds
                                         ]);
        
        // Query the latest EmailMessage record which have Headers for Cases
        for (EmailMessage objEmailMessage : [SELECT 
                                             Id,
                                             ParentId,
                                             Headers
                                             FROM EmailMessage
                                             WHERE ParentId IN :set_CaseIds
                                             ORDER BY ParentId, CreatedDate DESC
                                            ]
            ) {
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
        Set<String> set_EmailTemplateNames = new Set<String> {
            objEmailAlertConfiguration.CaseCommentEmailTemplateEnglish__c,
            objEmailAlertConfiguration.CaseCommentsEmailTemplateFrench__c,
            objEmailAlertConfiguration.CaseCommentsEmailTemplateSpanish__c
        };
        Map<String, EmailTemplate> map_EmailTemplateByName = new Map<String, EmailTemplate>();
        Map<String, EmailTemplate> map_EmailTemplateByLanguage = new Map<String, EmailTemplate>();
        List<OrgWideEmailAddress> list_OrgWideEmailAddresses = [SELECT 
                                                                Id, 
                                                                Address, 
                                                                DisplayName 
                                                                FROM OrgWideEmailAddress 
                                                                WHERE Address = :objEmailAlertConfiguration.OrgWideAddress__c
                                                               ];

        for (EmailTemplate objTemplate : [SELECT 
                                          Id,
                                          HtmlValue,
                                          Subject,
                                          DeveloperName
                                          FROM EmailTemplate
                                          WHERE DeveloperName IN :set_EmailTemplateNames
                                         ]
        ) {
            map_EmailTemplateByName.put(objTemplate.DeveloperName, objTemplate);
        }

        map_EmailTemplateByLanguage.put(
            'English', 
            map_EmailTemplateByName.get(objEmailAlertConfiguration.CaseCommentEmailTemplateEnglish__c)
        );
        map_EmailTemplateByLanguage.put(
            'French', 
            map_EmailTemplateByName.get(objEmailAlertConfiguration.CaseCommentsEmailTemplateFrench__c)
        );
        map_EmailTemplateByLanguage.put(
            'Spanish', 
            map_EmailTemplateByName.get(objEmailAlertConfiguration.CaseCommentsEmailTemplateSpanish__c)
        );
        
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
            Messaging.SingleEmailMessage objSingleMessageForCustomers = new Messaging.SingleEmailMessage();
            Messaging.SingleEmailMessage objSingleMessageForAgents = new Messaging.SingleEmailMessage();
            List<String> list_CustomerToAddresses = new List<String>();
            List<String> list_AgentToAddresses = new List<String>();
            EmailTemplate objTemplateForCustomers;
            EmailTemplate objTemplateForAgents = map_EmailTemplateByLanguage.get('English');

            if (map_UserById.containsKey(objCaseComment.CreatedById)) {
                // Adding the Case Comment Created By Email
                if (map_UserById.get(objCaseComment.CreatedById).IsPortalEnabled && objCaseComment.VisibleToCustomer__c) {
                    list_CustomerToAddresses.add(map_UserById.get(objCaseComment.CreatedById).Email);
                } else {
                    list_AgentToAddresses.add(map_UserById.get(objCaseComment.CreatedById).Email);
                }
            }
            
            if (map_CaseCollaboratorsByCaseId.containsKey(objCaseComment.Case__c)) {
                // Adding the Case Collabortors Emails
                for (DEL_CaseCollaborator__c objCollaborator : map_CaseCollaboratorsByCaseId.get(objCaseComment.Case__c)) {
                    if (map_UserById.containsKey(objCollaborator.User__c)) {
                        if (map_UserById.get(objCollaborator.User__c).IsPortalEnabled && objCaseComment.VisibleToCustomer__c) {
                            list_CustomerToAddresses.add(map_UserById.get(objCollaborator.User__c).Email);
                        } else {
                            list_AgentToAddresses.add(map_UserById.get(objCollaborator.User__c).Email);
                        }
                    }
                }
            }
            
            if (map_CaseById.containsKey(objCaseComment.Case__c)) {
                Case objCase = map_CaseById.get(objCaseComment.Case__c);
                String strLanguage = getDefaultLanguage(objCase);
                objTemplateForCustomers = map_EmailTemplateByLanguage.get(strLanguage);
                if (objCaseComment.VisibleToCustomer__c) {
                    String strSubjectForCustomers = objTemplateForCustomers.Subject;
                    if (strSubjectForCustomers.contains('{!Case.Subject}')) {
                        strSubjectForCustomers = strSubjectForCustomers.replace('{!Case.Subject}', objCase.Subject);
                        objSingleMessageForCustomers.setSubject(strSubjectForCustomers);
                    }
                }
                
                String strSubjectForAgents =objTemplateForAgents.Subject;
                if (strSubjectForAgents.contains('{!Case.Subject}')) {
                    strSubjectForAgents = strSubjectForAgents.replace('{!Case.Subject}', objCase.Subject);
                    objSingleMessageForAgents.setSubject(strSubjectForAgents);
                }

                if (map_UserById.containsKey(objCase.OwnerId)) {
                    // Adding the Case Owner Email
                    if (map_UserById.get(objCase.OwnerId).IsPortalEnabled && objCaseComment.VisibleToCustomer__c) {
                        list_CustomerToAddresses.add(map_UserById.get(objCase.OwnerId).Email);
                    } else {
                        list_AgentToAddresses.add(map_UserById.get(objCase.OwnerId).Email);
                    }
                }

                if (objCaseComment.VisibleToCustomer__c) {
                    if (String.isNotBlank(objCase.ContactEmail)) {
                        // Adding the Case Contact Email
                        list_CustomerToAddresses.add(objCase.ContactEmail);
                    } else if (String.isNotBlank(objCase.SuppliedEmail)) {
                        // Adding the Case Web Email
                        list_CustomerToAddresses.add(objCase.SuppliedEmail);
                    }

                    if (String.isNotBlank(objCase.DEL_CcAddress__c)) {
                        // Adding the CC Emails
                        list_CustomerToAddresses.addAll(objCase.DEL_CcAddress__c.split(';'));
                    }
                }

                
                // Setting the references in the Email headers 
                if (map_EmailMessageByCaseId.containsKey(objCase.Id)) {
                    EmailMessage objEmailMessage = map_EmailMessageByCaseId.get(objCase.Id);
                    String strReferences;
                    if (objEmailMessage.Headers.contains('References:')) {
                        String strHeaders = objEmailMessage.Headers;
                        strReferences = strHeaders.substringAfter('References:');
                        if (objCaseComment.VisibleToCustomer__c) {
                            objSingleMessageForCustomers.setReferences(strReferences);
                        }

                        objSingleMessageForAgents.setReferences(strReferences);
                    }
                }
                if (objCaseComment.VisibleToCustomer__c) {
                    objSingleMessageForCustomers.setWhatId(objCase.Id);
                }
                objSingleMessageForAgents.setWhatId(objCase.Id);
            }
            
            if (objCaseComment.VisibleToCustomer__c) {
                String strHtmlBodyForCustomers = objTemplateForCustomers.HtmlValue;
                //Get the Email Template for Customers
                strHtmlBodyForCustomers = getHtmlBody(
                    objCaseComment, 
                    map_CaseById.get(objCaseComment.Case__c), 
                    list_MergeFields, 
                    strHtmlBodyForCustomers,
                    strSiteURL, 
                    'Customer'
                );
    
                objSingleMessageForCustomers.setToAddresses(list_CustomerToAddresses);
                objSingleMessageForCustomers.setHtmlBody(strHtmlBodyForCustomers);
            }

            String strHtmlBodyForAgents = objTemplateForAgents.HtmlValue;
            //Get the Email Template for Agents
            strHtmlBodyForAgents = getHtmlBody(
                objCaseComment, 
                map_CaseById.get(objCaseComment.Case__c), 
                list_MergeFields, 
                strHtmlBodyForAgents,
                strSiteURL, 
                'Agent'
            );

            objSingleMessageForAgents.setHtmlBody(strHtmlBodyForAgents);
            objSingleMessageForAgents.setToAddresses(list_AgentToAddresses);
            
            //Setting Org Wide Email Address
            if (!list_OrgWideEmailAddresses.isEmpty()) {
                if (objCaseComment.VisibleToCustomer__c) {
                    objSingleMessageForCustomers.setOrgWideEmailAddressId(list_OrgWideEmailAddresses[0].Id);
                }
                
                objSingleMessageForAgents.setOrgWideEmailAddressId(list_OrgWideEmailAddresses[0].Id);
            }

            //Add attachments associated to the Case Comment
            if (map_ContentVersionIdsByCaseCommentId.containsKey(objCaseComment.Id)) {
                objSingleMessageForAgents.setEntityAttachments(map_ContentVersionIdsByCaseCommentId.get(objCaseComment.Id));
                if (objCaseComment.VisibleToCustomer__c) {
                    objSingleMessageForCustomers.setEntityAttachments(map_ContentVersionIdsByCaseCommentId.get(objCaseComment.Id));
                }
            }

            if(objCaseComment.VisibleToCustomer__c) {
                list_EmailMessages.add(objSingleMessageForCustomers);
            }
            
            objSingleMessageForAgents.setHtmlBody(strHtmlBodyForAgents);
            list_EmailMessages.add(objSingleMessageForAgents); 
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
        String strSiteURL, 
        String strUsertype
    ) {
        if (strUserType == 'Agent') {
            strSiteURL = URL.getSalesforceBaseUrl().toExternalForm();
        }
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
                    strField = strMergeFieldName.subString(
                        strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}')
                    );
                    if (map_CaseFieldByName.get(strField) != null) {
                        strHTML = strHTML.replace(strMergeFieldName, (String) map_CaseFieldByName.get(strField));
                    } else {
                        strHTML = strHTML.replace(strMergeFieldName, '');
                    }
                } else if (strMergeFieldName.contains('{!CaseComment.') && strMergeFieldName.contains('Date')) {
                    strField = strMergeFieldName.subString(
                        strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}')
                    );
                    DateTime dtmDateValue = DateTime.valueOf(map_CaseCommentFieldByName.get(strField));
                    String strDate = dtmDateValue.format('MMMM d');
                    String strTime = dtmDateValue.format('h:mm a z');
                    strHTML = strHTML.replace(strMergeFieldName, strDate + ' at ' + strTime);
                } else if (strMergeFieldName.contains('{!CaseComment.')) {
                    strField = strMergeFieldName.subString(
                        strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}')
                    );
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

    /**
    * @ author       :  Ankit C
    * @ description  :  This method gets the default language for the Case.
    * @ params       :  objCase - related Case
    * @ return       :  strDefaultLanguage - default language for the Case.
    **/
    public static String getDefaultLanguage(Case objCase) {
        String strDefaultLanguage = 'English';
        if (
            String.isNotBlank(objCase.ContactId) &&
            String.isNotBlank(objCase.Contact.Preferred_Language__c)
        ) {
            strDefaultLanguage = objCase.Contact.Preferred_Language__c;
        } else if (String.isNotBlank(objCase.Language__c)) {
            strDefaultLanguage = objCase.Language__c;
        }

        return strDefaultLanguage;
    }

    /**
    * @ author       :  Ankit C
    * @ description  :  This method sends email alerts when Case Comments are created with attachments.
    * @ params       :  list_CaseComments - List of CaseComment records
    **/
    public static void processCaseCommentsWithAttachments(List<DEL_CaseComment__c> list_CaseComments) {
        objEmailAlertConfiguration = DEL_EmailAlertConfiguration__c.getOrgDefaults();
        list_CaseCommentsToUpdate = new List<DEL_CaseComment__c>();
        createCollectionsAfterInsert(list_CaseComments);
        sendCommentNotificationEmail(list_CaseCommentsToUpdate);
    }
}