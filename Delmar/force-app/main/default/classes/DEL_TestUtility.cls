/*********************************************************************************************************************
* 
* @ Name            :  DEL_TestUtility
* @ Purpose         :  This is utility class which can be used to create test data for test classes
* @ Author          :  Ankit C
*
*   Date            |  Developer Name         |  Version      |  Changes
* =====================================================================================================================
*   26-07-2022      |  ankit.c@absyz.com      |  1.0          |  Initial Version
*
***********************************************************************************************************************/
@isTest
public class DEL_TestUtility {
    /**
    * @ Name     :  AccountBuilder
    * @ Purpose  :  To create Account record
    * @ Author   :  Ankit C
    **/
    public class AccountBuilder {
        private String strName;
        
        public AccountBuilder() {
            this.strName = '';
        }
        
        public AccountBuilder setName(String strValue) {
            this.strName = strValue;
            return this;
        }
        
        public Account createAccount() {
            Account objAccount = new Account();
            objAccount.Name = this.strName;
            
            return objAccount;
        }
    }
    
    /**
    * @ Name     :  ContactBuilder
    * @ Purpose  :  To create Contact record
    * @ Author   :  Ankit C
    **/
    public class ContactBuilder {
        private String strFirstName;
        private String strLastName;
        private Id idAccountId;
        
        public ContactBuilder() {
            this.strFirstName = '';
            this.strLastName = '';
        }
        
        public ContactBuilder setFirstName(String strValue) {
            this.strFirstName = strValue;
            return this;
        }
        
        public ContactBuilder setLastName(String strValue) {
            this.strLastName = strValue;
            return this;
        }
        
        public ContactBuilder setAccountId(Id idValue) {
            this.idAccountId = idValue;
            return this;
        }
        
        public Contact createContact() {
            Contact objContact = new Contact();
            objContact.FirstName = this.strFirstName;
            objContact.LastName = this.strLastName;
            objContact.AccountId = this.idAccountId;
            
            return objContact;
        }
    }
    
    /**
    * @ Name     :  UserBuilder
    * @ Purpose  :  To create User record
    * @ Author   :  Ankit C
    **/
    public class UserBuilder {
        private String strFirstName;
        private String strLastName;
        private Id idContactId;
        private Id idProfileId;
        private String strEmail;
        private String strUsername;
        private String strAlias;
        
        public UserBuilder() {
            this.strFirstName = '';
            this.strLastName = '';
            this.strEmail = '';
            this.strUsername = '';
            this.strAlias = '';
        }
        
        public UserBuilder setFirstName(String strValue) {
            this.strFirstName = strValue;
            return this;
        }
        
        public UserBuilder setLastName(String strValue) {
            this.strLastName = strValue;
            return this;
        }
        
        public UserBuilder setEmail(String strValue) {
            this.strEmail = strValue;
            return this;
        }
        
        public UserBuilder setUsername(String strValue) {
            this.strUsername = strValue;
            return this;
        }
        
        public UserBuilder setAlias(String strValue) {
            this.strAlias = strValue;
            return this;
        }
        
        public UserBuilder setContactId(Id idValue) {
            this.idContactId = idValue;
            return this;
        }
        
        public UserBuilder setProfileId(Id idValue) {
            this.idProfileId = idValue;
            return this;
        }
        
        public User createUser() {
            User objUser = new User();
            objUser.FirstName = this.strFirstName;
            objUser.LastName = this.strLastName;
            objUser.Email = this.strEmail;
            objUser.Username = this.strUsername;
            objUser.Alias = this.strAlias;
            objUser.ContactId = this.idContactId;
            objUser.ProfileId = this.idProfileId;
            objUser.TimeZoneSidKey = 'America/Los_Angeles';
            objUser.LocaleSidKey = 'en_US';
            objUser.EmailEncodingKey = 'ISO-8859-1';
            objUser.LanguageLocaleKey = 'en_US';
            
            return objUser;
        }
    }
    
    /**
    * @ Name     :  CaseBuilder
    * @ Purpose  :  To create Case record
    * @ Author   :  Ankit C
    **/
    public class CaseBuilder {
        private String strSubject;
        private String strDescription;
        private Id idContactId;
        private Id idAccountId;
        private String strOrigin;
        private String strType;
        private String strStatus;
        private String strPriority;
        private String strSuppliedEmail;
        
        public CaseBuilder() {
            this.strSubject = '';
            this.strDescription = '';
            this.strOrigin = '';
            this.strType = '';
            this.strStatus = '';
            this.strPriority = '';
            this.strSuppliedEmail = '';
        }
        
        public CaseBuilder setSubject(String strValue) {
            this.strSubject = strValue;
            return this;
        }
        
        public CaseBuilder setDescription(String strValue) {
            this.strDescription = strValue;
            return this;
        }
        
        public CaseBuilder setOrigin(String strValue) {
            this.strOrigin = strValue;
            return this;
        }
        
        public CaseBuilder setType(String strValue) {
            this.strType = strValue;
            return this;
        }
        
        public CaseBuilder setPriority(String strValue) {
            this.strPriority = strValue;
            return this;
        }
        
        public CaseBuilder setStatus(String strValue) {
            this.strStatus = strValue;
            return this;
        }
        
        public CaseBuilder setContactId(Id idValue) {
            this.idContactId = idValue;
            return this;
        }
        
        public CaseBuilder setAccountId(Id idValue) {
            this.idAccountId = idValue;
            return this;
        }
        
        public CaseBuilder setSuppliedEmail(String strValue) {
            this.strSuppliedEmail = strValue;
            return this;
        }
        
        public Case createCase() {
            Case objCase = new Case();
            objCase.Subject = this.strSubject;
            objCase.Description =  this.strDescription;
            objCase.Origin = this.strOrigin;
            objCase.Type = this.strType;
            objCase.Priority = this.strPriority;
            objCase.AccountId = this.idAccountId;
            objCase.ContactId = this.idContactId;
            objCase.SuppliedEmail = this.strSuppliedEmail;
            
            return objCase;
        }
    }
    
    /**
    * @ Name     :  CaseCommentBuilder
    * @ Purpose  :  To create DEL_CaseComment__c record
    * @ Author   :  Ankit C
    **/
    public class CaseCommentBuilder {
        private String strBody;
        private String idCaseId;
        private String strEmailMessageId;
        
        public CaseCommentBuilder() {
            this.strBody = '';
            this.strEmailMessageId = '';
        }
        
        public CaseCommentBuilder setBody(String strValue) {
            this.strBody = strValue;
            return this;
        }
        
        public CaseCommentBuilder setEmailMessageId(String strValue) {
            this.strEmailMessageId = strValue;
            return this;
        }
        
        public CaseCommentBuilder setCaseId(Id idValue) {
            this.idCaseId = idValue;
            return this;
        }
        
        public DEL_CaseComment__c createCaseComment() {
            DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
            objCaseComment.Body__c = this.strBody;
            objCaseComment.Case__c = this.idCaseId;
            objCaseComment.EmailMessageId__c = this.strEmailMessageId;
            
            return objCaseComment;
        }
    }
    
    /**
    * @ Name     :  CaseCollaborationBuilder
    * @ Purpose  :  To create DEL_CaseCollaborator__c record
    * @ Author   :  Dinesh Chandra
    **/
    public class CaseCollaborationBuilder {
        private Id idCaseId;
        private Id idUserId;
        
        public CaseCollaborationBuilder setCaseId(Id idValue) {
            this.idCaseId = idValue;
            return this;
        }
        
        public CaseCollaborationBuilder setUserId(Id idValue) {
            this.idUserId = idValue;
            return this;
        }
        
        public DEL_CaseCollaborator__c createCaseCollaborator() {
            DEL_CaseCollaborator__c objCaseCollaborator = new DEL_CaseCollaborator__c();
            objCaseCollaborator.User__c = this.idUserId;
            objCaseCollaborator.Case__c = this.idCaseId;
            
            return objCaseCollaborator;
        }
    }
    
    /**
    * @ Name     :  EmailMessagetBuilder
    * @ Purpose  :  To create Email Message record
    * @ Author   :  Rakesh Nayak
    **/
    public class EmailMessageBuilder {
        private String strTextBody;
        private String strHtmlBody;
        private Id idParentId;
        private String strFromAddress;
        private String strFromName;
        private String strMessageIdentifier;
        private String strThreadIdentifier;
        private Boolean blnIncoming;
        private String strHeaders;
        
        public EmailMessageBuilder() {
            this.strTextBody = '';
            this.strHtmlBody = '';
            this.strFromAddress = '';
            this.strFromName = '';
            this.strMessageIdentifier = '';
            this.strThreadIdentifier = '';
            this.strHeaders = '';
        }
        
        public EmailMessageBuilder setTextBody(String strValue) {
            this.strTextBody = strValue;
            return this;
        }
        
        public EmailMessageBuilder setHtmlBody(String strValue) {
            this.strHtmlBody = strValue;
            return this;
        }
        
        public EmailMessageBuilder setMessageIdentifier(String strValue) {
            this.strMessageIdentifier = strValue;
            return this;
        }
        
        public EmailMessageBuilder setThreadIdentifier(String strValue) {
            this.strThreadIdentifier = strValue;
            return this;
        }
        
        public EmailMessageBuilder setFromName(String strValue) {
            this.strFromName = strValue;
            return this;
        }
        
        public EmailMessageBuilder setParentId(Id idValue) {
            this.idParentId = idValue;
            return this;
        }
        
        public EmailMessageBuilder setFromAddress(String strValue) {
            this.strFromAddress = strValue;
            return this;
        }
        
        public EmailMessageBuilder setIncoming(Boolean blnValue) {
            this.blnIncoming = blnValue;
            return this;
        }
        
        public EmailMessageBuilder setHeaders(String strValue) {
            this.strHeaders = strValue;
            return this;
        }
        
        public EmailMessage createEmailMessage() {
            EmailMessage objEmailMessage = new EmailMessage();
            objEmailMessage.TextBody = this.strTextBody;
            objEmailMessage.HtmlBody = this.strHtmlBody;
            objEmailMessage.ThreadIdentifier = this.strThreadIdentifier;
            objEmailMessage.MessageIdentifier = this.strMessageIdentifier;
            objEmailMessage.FromName = this.strFromName;
            objEmailMessage.FromAddress = this.strFromAddress;
            objEmailMessage.ParentId = this.idParentId;
            objEmailMessage.Incoming = this.blnIncoming;
            objEmailMessage.Headers = this.strHeaders;
            
            return objEmailMessage;
        }
    }
    
    /**
    * @ Name     :  EmailAlertConfigurationBuilder
    * @ Purpose  :  To create DEL_EmailAlertConfiguration__c record
    * @ Author   :  Ankit C
    **/
    public class EmailAlertConfigurationBuilder {
        private String strMergeFields;
        private String strCaseQueryFields;
        private String strCaseCommentFields;
        private String strSiteName;
        private String strEmailTemplateName;
        private String strOrgWideAddress;
        private Id idSetupOwnerId;
        private String strEmailBreakPattern;
        
        public EmailAlertConfigurationBuilder() {
            this.strMergeFields = '';
            this.strCaseQueryFields = '';
            this.strCaseCommentFields = '';
            this.strSiteName = '';
            this.strEmailTemplateName = '';
            this.strOrgWideAddress = '';
            this.strEmailBreakPattern = '';
        }
        
        public EmailAlertConfigurationBuilder setMergeFields(String strValue) {
            this.strMergeFields = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setCaseQueryFields(String strValue) {
            this.strCaseQueryFields = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setCaseCommentFields(String strValue) {
            this.strCaseCommentFields = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setSiteName(String strValue) {
            this.strSiteName = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setEmailTemplateName(String strValue) {
            this.strEmailTemplateName = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setOrgWideAddress(String strValue) {
            this.strOrgWideAddress = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setEmailBreakPattern(String strValue) {
            this.strEmailBreakPattern = strValue;
            return this;
        }
        
        public EmailAlertConfigurationBuilder setOwnerId(Id idValue) {
            this.idSetupOwnerId = idValue;
            return this;
        }
        
        public DEL_EmailAlertConfiguration__c createConfiguration() {
            DEL_EmailAlertConfiguration__c objEmailAlertConfiguration = new DEL_EmailAlertConfiguration__c(
                MergeFields__c = this.strMergeFields,
                CaseQueryFields__c = this.strCaseQueryFields,
                CaseCommentFields__c = this.strCaseCommentFields,
                SiteName__c = this.strSiteName,
                CaseCommentEmailTemplate__c = this.strEmailTemplateName,
                SetupOwnerId = this.idSetupOwnerId,
                OrgWideAddress__c = this.strOrgWideAddress,
                EmailReplyBreakPattern__c = this.strEmailBreakPattern
            );
            
            return objEmailAlertConfiguration;
        }
    }
    
    /**
    * @ Name     :  EmailTemplateBuilder
    * @ Purpose  :  To create EmailTemplate record
    * @ Author   :  Ankit C
    **/
    public class EmailTemplateBuilder {
        private String strName;
        private String strDeveloperName;
        private String strHtmlValue;
        private Id idFolderId;
        private String strTemplateType;
        private String strSubject;
        
        public EmailTemplateBuilder() {
            this.strName = '';
            this.strDeveloperName = '';
            this.strHtmlValue = '';
            this.strTemplateType = '';
            this.strSubject = '';
        }
        
        public EmailTemplateBuilder setName(String strValue) {
            this.strName = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setDeveloperName(String strValue) {
            this.strDeveloperName = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setHtmlValue(String strValue) {
            this.strHtmlValue = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setFolderId(Id idValue) {
            this.idFolderId = idValue;
            return this;
        }
        
        public EmailTemplateBuilder setTemlateType(String strValue) {
            this.strTemplateType = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setSubject(String strValue) {
            this.strSubject = strValue;
            return this;
        }
        
        public EmailTemplate createEmailTemplate() {
            EmailTemplate objEmailTemplate = new EmailTemplate(
                Name = this.strName,
                DeveloperName = this.strDeveloperName,
                HtmlValue = this.strHtmlValue,
                FolderId = this.idFolderId,
                TemplateType = this.strTemplateType,
                Subject = this.strSubject
            );
            
            return objEmailTemplate;
        }
    }

    /**
    * @ Name     :  ContentVersionBuilder
    * @ Purpose  :  To create ContentVersion record
    * @ Author   :  Rakesh Nayak
    **/
    public class ContentVersionBuilder {
        private String strTitle;
        private String strPathOnClient;
        private Blob blobVersionData;
        private  Boolean blnIsMajorVersion;
        
        public ContentVersionBuilder() {
            this.strTitle= '';
            this.strPathOnClient = '';
        }
        
        public ContentVersionBuilder setTitle(String strValue) {
            this.strTitle = strValue;
            return this;
        }
        
        public ContentVersionBuilder setPathOnClient(String strValue) {
            this.strPathOnClient = strValue;
            return this;
        }
        
        public ContentVersionBuilder setVersionData(String strValue) {
            this.blobVersionData = EncodingUtil.base64Decode(strValue);
            return this;
        }
        
        public ContentVersionBuilder setIsMajorVersion(Boolean blnValue) {
            this.blnIsMajorVersion = blnValue;
            return this;
        }
        
        public ContentVersion createContentVersion() {
            ContentVersion objContentVersion = new ContentVersion();
            objContentVersion.Title = this.strTitle;
            objContentVersion.PathOnClient = this.strPathOnclient;
            objContentVersion.VersionData = this.blobVersionData;
            objContentVersion.IsMajorVersion =this.blnIsMajorVersion;
            
            return objContentVersion;
        }
    }

    /**
    * @ Name     :  ContentDocumentLinkBuilder
    * @ Purpose  :  To create ContentDocumentLink record
    * @ Author   :  Rakesh Nayak
    **/
    public class ContentDocumentLinkBuilder {
        private Id idContentDocumentId;
        private String strVisibility;
        private String strShareType;
        private Id idLinkedEntityId;
        
        public ContentDocumentLinkBuilder() {
            this.strVisibility = '';
            this.strShareType = '';
        }
        
        public ContentDocumentLinkBuilder setContentDocumentId(Id idValue) {
            this.idContentDocumentId = idValue;
            return this;
        }
        
        public ContentDocumentLinkBuilder setLinkedEntityId(Id idValue) {
            this.idLinkedEntityId = idValue;
            return this;
        }
        
        public ContentDocumentLinkBuilder setShareType(String strValue) {
            this.strShareType = strValue;
            return this;
        }
        
        public ContentDocumentLinkBuilder setVisibility(String strValue) {
            this.strVisibility = strValue;
            return this;
        }
        
        public ContentDocumentLink createContentDocumentLink() {
            ContentDocumentLink objContentDocumentLink = new ContentDocumentLink();
            objContentDocumentLink.ContentDocumentId = this.idContentDocumentId;
            objContentDocumentLink.LinkedEntityId = this.idLinkedEntityId;
            objContentDocumentLink.ShareType = this.strShareType;
            objContentDocumentLink.Visibility = this.strVisibility;
            
            return objContentDocumentLink;
        }
    }
}