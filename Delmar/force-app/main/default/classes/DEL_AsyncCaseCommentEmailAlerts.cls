/*******************************************************************************************************
* 
* @ Name            :   DEL_AsyncCaseCommentEmailAlerts
* @ Purpose         :   Queueable Apex class for sending email alerts asynchronously.
* @ Author          :   Ankit C
* @ Usage           :   Send email alerts when a Case Comment is created.
* @ Test Class Name :   DEL_CaseCommentTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  23-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_AsyncCaseCommentEmailAlerts implements Queueable {
    // List of DEL_CaseComment__c records
    public List<DEL_CaseComment__c> list_CaseComments;
    // Map of EmailMessages records by Case Id
    public Map<Id, EmailMessage> map_EmailMessageByCaseId;
    // Map of Case Collaborators by Case Id
    public Map<Id, List<DEL_CaseCollaborator__c>> map_CaseCollaboratorsByCaseId;
    // Map of Users by Id
    public Map<Id, User> map_UserById;
    // Map of Cases by Id
    public Map<Id, Case> map_CaseById;
    public DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration;
    // Map of ContentVersion Ids by Case Comment Id
    public Map<Id, List<String>> map_ContentVersionIdsByCaseCommentId;
    //Boolean variable to check if the Case Comment is created from incoming email message
    public Boolean blnIsIncomingEmailMessage;
    
    public DEL_AsyncCaseCommentEmailAlerts(List<DEL_CaseComment__c> list_CaseComments, Boolean blnIsIncomingEmailMessage) {
        this.list_CaseComments = list_CaseComments;
        this.map_EmailMessageByCaseId = new Map<Id, EmailMessage>();
        this.map_UserById = new Map<Id, User>();
        this.objCaseCollaborationConfiguration = DEL_CaseCollaborationConfiguration__c.getOrgDefaults();
        this.map_CaseById = new Map<Id, Case>();
        this.map_CaseCollaboratorsByCaseId = new Map<Id, List<DEL_CaseCollaborator__c>>();
        this.map_ContentVersionIdsByCaseCommentId = new Map<Id, List<String>>();
        this.blnIsIncomingEmailMessage = blnIsIncomingEmailMessage;
    }
    
    public void execute(QueueableContext context) {
        Set<String> set_EmailTemplateNames = new Set<String> {
            objCaseCollaborationConfiguration.CaseCommentEmailTemplateEnglish__c,
            objCaseCollaborationConfiguration.CaseCommentsEmailTemplateFrench__c,
            objCaseCollaborationConfiguration.CaseCommentsEmailTemplateSpanish__c
        };
        Set<Id> set_CaseIds = new Set<Id>();
        Set<Id> set_UserIds = new Set<Id>();
        Set<Id> set_QueueIds = new Set<Id>();
        List<Messaging.SingleEmailMessage> list_EmailMessages = new List<Messaging.SingleEmailMessage>();
        //Map of CaseComment Id by ContentDocumentId
        Map<Id, Id> map_CaseCommentIdByContentDocumentId = new Map<Id, Id>();
        Map<String, EmailTemplate> map_EmailTemplateByName = new Map<String, EmailTemplate>();
        Map<String, EmailTemplate> map_EmailTemplateByLanguage = new Map<String, EmailTemplate>();
        Map<Id, Group> map_GroupById = new Map<Id, Group>();

        try {
            for (DEL_CaseComment__c objCaseComment : list_CaseComments) {
                set_CaseIds.add(objCaseComment.Case__c);
                set_UserIds.add(objCaseComment.CommentCreatedBy__c);
            
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
                map_ContentVersionIdsByCaseCommentId = DEL_Utils.queryContentVersionsByCaseComment(map_CaseCommentIdByContentDocumentId);
            }
        
            // Query the Case Collaborators related the Case
            if (!set_CaseIds.isEmpty()) {
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
            }
        
            // Query Cases
            String strCaseQuery = 'SELECT Id, OwnerId, DEL_CcAddress__c, SuppliedEmail, ContactEmail, Contact.Preferred_Language__c, Language__c, ' 
                + 'Case_Thread_ID__c, ' + objCaseCollaborationConfiguration.CaseQueryFields__c + ' FROM Case WHERE Id IN :set_CaseIds';
            List<Case> list_Cases = Database.query(strCaseQuery);
            map_CaseById = new Map<Id, Case>(list_Cases);
            for (Case objCase : map_CaseById.values()) {
                if (String.valueOf(objCase.OwnerId).startsWith('00G')) {
                    set_QueueIds.add(objCase.OwnerId);
                } else {
                    set_UserIds.add(objCase.OwnerId);
                }
            }

            if (!set_QueueIds.isEmpty()) {
                map_GroupById = DEL_Utils.queryQueues(set_QueueIds);
                for (Group objGroup : map_GroupById.values()) {
                    if (!objGroup.GroupMembers.isEmpty()) {
                        for (GroupMember objgroupMember : objGroup.GroupMembers) {
                            set_UserIds.add(objgroupMember.UserOrGroupId);
                        }
                    }
                }
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

            List<OrgWideEmailAddress> list_OrgWideEmailAddresses = [SELECT 
                                                                    Id, 
                                                                    Address, 
                                                                    DisplayName 
                                                                    FROM OrgWideEmailAddress 
                                                                    WHERE Address = :objCaseCollaborationConfiguration.OrgWideAddress__c
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
                map_EmailTemplateByName.get(objCaseCollaborationConfiguration.CaseCommentEmailTemplateEnglish__c)
            );
            map_EmailTemplateByLanguage.put(
                'French', 
                map_EmailTemplateByName.get(objCaseCollaborationConfiguration.CaseCommentsEmailTemplateFrench__c)
            );
            map_EmailTemplateByLanguage.put(
                'Spanish', 
                map_EmailTemplateByName.get(objCaseCollaborationConfiguration.CaseCommentsEmailTemplateSpanish__c)
            );
            
            String strSiteURL = '';
            if (Test.isRunningTest()) {
                strSiteURL = DEL_CaseCommentTriggerHelperTest.getSiteLink();
            } else {
                List<Site> list_Sites = [SELECT Id FROM Site WHERE Name = :objCaseCollaborationConfiguration.SiteName__c];
                if (!list_Sites.isEmpty()) {
                    List<SiteDetail> list_SiteDetails = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :list_Sites[0].Id];
                    if (!list_SiteDetails.isEmpty()) {
                        strSiteURL = list_SiteDetails[0].SecureURL;
                    }
                }
            }
            
            List<String> list_MergeFields = objCaseCollaborationConfiguration.MergeFields__c.split(',');
            for (DEL_CaseComment__c objCaseComment : list_CaseComments) {
                Messaging.SingleEmailMessage objSingleMessageForCustomers = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage objSingleMessageForAgents = new Messaging.SingleEmailMessage();
                List<String> list_CustomerToAddresses = new List<String>();
                List<String> list_AgentToAddresses = new List<String>();
                EmailTemplate objTemplateForCustomers;
                EmailTemplate objTemplateForAgents = map_EmailTemplateByLanguage.get('English');
                String strCaseEmailThreadId = '';
                
                if (map_UserById.containsKey(objCaseComment.CommentCreatedBy__c)) {
                    // Adding the Case Comment Created By Email
                    if (map_UserById.get(objCaseComment.CommentCreatedBy__c).IsPortalEnabled && objCaseComment.VisibleToCustomer__c) {
                        list_CustomerToAddresses.add(map_UserById.get(objCaseComment.CommentCreatedBy__c).Email);
                    } else if(!map_UserById.get(objCaseComment.CommentCreatedBy__c).IsPortalEnabled) {
                        list_AgentToAddresses.add(map_UserById.get(objCaseComment.CommentCreatedBy__c).Email);
                    }
                }
                
                if (map_CaseCollaboratorsByCaseId.containsKey(objCaseComment.Case__c)) {
                    // Adding the Case Collabortors Emails
                    for (DEL_CaseCollaborator__c objCollaborator : map_CaseCollaboratorsByCaseId.get(objCaseComment.Case__c)) {
                        if (map_UserById.containsKey(objCollaborator.User__c)) {
                            if (map_UserById.get(objCollaborator.User__c).IsPortalEnabled && objCaseComment.VisibleToCustomer__c) {
                                list_CustomerToAddresses.add(map_UserById.get(objCollaborator.User__c).Email);
                            } else if(!map_UserById.get(objCollaborator.User__c).IsPortalEnabled) {
                                list_AgentToAddresses.add(map_UserById.get(objCollaborator.User__c).Email);
                            }
                        }
                    }
                }
                
                if (map_CaseById.containsKey(objCaseComment.Case__c)) {
                    Case objCase = map_CaseById.get(objCaseComment.Case__c);
                    String strLanguage = getDefaultLanguage(objCase);
                    strCaseEmailThreadId = objCase.Case_Thread_ID__c;
                    objTemplateForCustomers = map_EmailTemplateByLanguage.get(strLanguage);
                    if (objCaseComment.VisibleToCustomer__c) {
                        String strSubjectForCustomers = objTemplateForCustomers.Subject;
                        if (strSubjectForCustomers.contains('{!Case.Subject}')) {
                            strSubjectForCustomers = strSubjectForCustomers.replace('{!Case.Subject}', objCase.Subject);
                            if (!objCaseCollaborationConfiguration.EnableNewEmailThreadingBehavior__c) {
                                strSubjectForCustomers = strSubjectForCustomers + ' ' + strCaseEmailThreadId;
                            }

                            objSingleMessageForCustomers.setSubject(strSubjectForCustomers);
                        }
                    }
                    
                    String strSubjectForAgents = objTemplateForAgents.Subject;
                    if (strSubjectForAgents.contains('{!Case.Subject}')) {
                        strSubjectForAgents = strSubjectForAgents.replace('{!Case.Subject}', objCase.Subject);
                        if (!objCaseCollaborationConfiguration.EnableNewEmailThreadingBehavior__c) {
                            strSubjectForAgents = strSubjectForAgents + ' ' + strCaseEmailThreadId;
                        }
                        objSingleMessageForAgents.setSubject(strSubjectForAgents);
                    }
                    
                    if (map_UserById.containsKey(objCase.OwnerId)) {
                        // Adding the Case Owner Email
                        if (map_UserById.get(objCase.OwnerId).IsPortalEnabled && objCaseComment.VisibleToCustomer__c) {
                            list_CustomerToAddresses.add(map_UserById.get(objCase.OwnerId).Email);
                        } else if (!map_UserById.get(objCase.OwnerId).IsPortalEnabled) {
                            list_AgentToAddresses.add(map_UserById.get(objCase.OwnerId).Email);
                        }
                    } else if (map_GroupById.containsKey(objCase.OwnerId)) {
                        Group objGroup = map_GroupById.get(objCase.OwnerId);
                        if (String.isNotBlank(objGroup.Email)) {
                            //Add Queue Email if present
                            list_AgentToAddresses.add(objGroup.Email);
                        } else if (objGroup.DoesSendEmailToMembers && !objGroup.GroupMembers.isEmpty()) {
                            //If Send Email to Members is true add Emails of Group Members
                            for (GroupMember objGroupMember : objGroup.GroupMembers) {
                                if (map_UserById.containsKey(objGroupMember.UserOrGroupId)) {
                                    list_AgentToAddresses.add(map_UserById.get(objGroupMember.UserOrGroupId).Email);
                                }
                            }
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

                        if (objCaseCollaborationConfiguration.CCAddressSwitch__c && String.isNotBlank(objCase.DEL_CcAddress__c)) {
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

                    if (!objCaseCollaborationConfiguration.EnableNewEmailThreadingBehavior__c) {
                        strHtmlBodyForCustomers = strHtmlBodyForCustomers + '<br/>' + strCaseEmailThreadId;
                    }
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

                if (!objCaseCollaborationConfiguration.EnableNewEmailThreadingBehavior__c) {
                    strHtmlBodyForAgents = strHtmlBodyForAgents + '<br/>' + strCaseEmailThreadId;
                }
                
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
                
                if (objCaseComment.VisibleToCustomer__c && !list_CustomerToAddresses.isEmpty()) {
                    list_EmailMessages.add(objSingleMessageForCustomers);
                }
                
                objSingleMessageForAgents.setHtmlBody(strHtmlBodyForAgents);
                if (!list_AgentToAddresses.isEmpty()) {
                    list_EmailMessages.add(objSingleMessageForAgents);
                }
            }
            
            Messaging.SendEmailResult[] list_Results = Messaging.sendEmail(list_EmailMessages);
            Boolean blnIsSendEmailSuccess = true;
            for (Messaging.SendEmailResult objSendEmailResult : list_Results) {
                if (!objSendEmailResult.isSuccess()) {
                    blnIsSendEmailSuccess = false;
                }
            }

            List<DEL_FeedItemDeleteEvent__e> list_FeedItemDeleteEvents = new List<DEL_FeedItemDeleteEvent__e>();

            if (blnIsSendEmailSuccess) {
                for (Case objCase : map_CaseById.values()) {
                    list_FeedItemDeleteEvents.add(new DEL_FeedItemDeleteEvent__e(CaseId__c = objCase.Id, IncomingEmail__c = blnIsIncomingEmailMessage));
                }
    
                // Call method to publish events
                List<Database.SaveResult> list_SaveResults = EventBus.publish(list_FeedItemDeleteEvents);
            }
        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_AsyncCaseCommentEmailAlerts',
                'execute',
                objException,
                true
            );
        }
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method gets the default language for the Case.
    * @ params       :  objCase - related Case
    * @ return       :  strDefaultLanguage - default language for the Case.
    **/
    public String getDefaultLanguage(Case objCase) {
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
    * @ description  :  This method forms the Html Body of the email that needs to be sent
    * @ params       :  objCaseComment - DEL_CaseComment__c record
    *                   objCase - related Case
    *                   list_MergeFields - list of merge fields that are included in the email template.
    *                   strHtml - HtmlBody from the email template.
    *                   strSiteURL - Community Page Url.
    *                   strUsertype - Defines if the User is Agent/Customer
    **/
    public String getHtmlBody(
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
}