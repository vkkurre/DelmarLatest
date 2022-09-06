/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCommentTriggerHelperTest
* @ Purpose         :   Test class for DEL_CaseCommentTriggerHelper
* @ Author          :   Ankit C
*
*   Date            |  Developer Name                |  Version      |  Changes
* ======================================================================================================
*  05-08-2022       |  ankit.c@absyz.com             |  1.0          |  Initial version
*******************************************************************************************************/
@isTest
public class DEL_CaseCommentTriggerHelperTest {
    public static Boolean blnThrowException = false;
    /**
    * @ author       :  Ankit C
    * @ description  :  Method to setup test data
    **/
    @TestSetup
    static void setupData() {
        Account objAccount = new DEL_TestUtility.AccountBuilder()
            .setName('Test Account Delmar')
            .createAccount();
        insert objAccount;
        
        Contact objContact = new DEL_TestUtility.ContactBuilder()
            .setFirstName('Test')
            .setLastName('Contact')
            .setAccountId(objAccount.Id)
            .createContact();
        insert objContact;

        List<Case> list_Cases = new List<Case>();
        Case objCase = new DEL_TestUtility.CaseBuilder()
            .setSubject('Case with Power Failure')
            .setDescription('Power failure happens after 4 hour work')
            .setStatus('New')
            .setOrigin('Email')
            .setSuppliedEmail('test@delmar.com')
            .setLanguage('French')
            .createCase();
        list_Cases.add(objCase);

        Case objCase2 = new DEL_TestUtility.CaseBuilder()
            .setSubject('Case assigned to a Queue')
            .setDescription('Case assigned to a Queue')
            .setStatus('New')
            .setOrigin('Email')
            .setSuppliedEmail('test@delmar.com')
            .setLanguage('English')
            .createCase();
        list_Cases.add(objCase2);

        insert list_Cases;

        ContentVersion objContentVersion = new DEL_TestUtility.ContentVersionBuilder()
            .setTitle('Test')
            .setPathOnClient('image.jpg')
            .setVersionData('this is test data')
            .setIsMajorVersion(true)
            .createContentVersion();
        insert objContentVersion;
        
        ContentDocument objContentDocument = [SELECT 
                                              Id,
                                              Title,
                                              LatestPublishedVersionId
                                              FROM ContentDocument];
        
        ContentDocumentLink objContentDocumentLink = new DEL_TestUtility.ContentDocumentLinkBuilder()
            .setContentDocumentId(objContentDocument.Id)
            .setVisibility('AllUsers')
            .setShareType('V')
            .setLinkedEntityId(objCase.Id)
            .createContentDocumentLink();
        insert objContentDocumentLink;
        
        EmailMessage objEmailMessage = new DEL_TestUtility.EmailMessageBuilder()
            .setTextBody('This is textbody')
            .setHtmlBody('<div>this is HtmlBody</div><br><body>Test</body>')
            .setIncoming(true)
            .setFromAddress('abc@xyz.com')
            .setFromName('Test User')
            .setThreadIdentifier('qwerty')
            .setMessageIdentifier('1cwicjn')
            .setParentId(objCase.Id)
            .setHeaders('References: <ZGwLB000000000000000000000000000000000000000000000RG4VR600YY4l4m6jQLmO31R1KiHtwQ@sfdc.net>')
            .createEmailMessage();
        DEL_EmailMessagesTriggerHelper.blnSkipTrigger = true;
        insert objEmailMessage;
        DEL_EmailMessagesTriggerHelper.blnSkipTrigger = false;
        
        String strMergeFields = '{!Case.Subject},{!Case.CaseNumber},{!Case.Description},'
            +  '{!CaseComment.CommentCreatedName__c},{!CaseComment.Body__c},'
            + '{!CaseComment.CreatedDate},SiteLink';
        
        OrgWideEmailAddress objOrgWideAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration = new DEL_TestUtility.CaseCollaborationConfigurationBuilder()
            .setMergeFields(strMergeFields)
            .setCaseQueryFields('Subject,CaseNumber,Description')
            .setSiteName('CaseComments')
            .setEmailTemplateName('DEL_CaseCommentAlert')
            .setSpanishTemplateName('DEL_CaseCommentAlertSpanish')
            .setFrenchTemplateName('DEL_CaseCommentAlertFrench')
            .setOwnerId(UserInfo.getOrganizationId())
            .setOrgWideAddress(objOrgWideAddress.Address)
            .createConfiguration();
        insert objCaseCollaborationConfiguration;
        
        List<EmailTemplate> list_EmailTemplates = new List<EmailTemplate>();
        EmailTemplate objEmailTemplate = new DEL_TestUtility.EmailTemplateBuilder()
            .setName('Case Comment Email Alert - English')
            .setDeveloperName('DEL_CaseCommentAlert')
            .setHtmlValue('{!Case.Subject} SiteLink {!CaseComment.CommentCreatedName__c} {!CaseComment.CreatedDate}')
            .setFolderId(UserInfo.getOrganizationId())
            .setTemlateType('Custom')
            .setSubject('New comment has been posted on Case: {!Case.Subject}')
            .createEmailTemplate();
        list_EmailTemplates.add(objEmailTemplate);

        EmailTemplate objEmailTemplate2 = new DEL_TestUtility.EmailTemplateBuilder()
            .setName('Case Comment Email Alert - Spanish')
            .setDeveloperName('DEL_CaseCommentAlertSpanish')
            .setHtmlValue('{!Case.Subject} SiteLink {!CaseComment.CommentCreatedName__c} {!CaseComment.CreatedDate}')
            .setFolderId(UserInfo.getOrganizationId())
            .setTemlateType('Custom')
            .setSubject('Se ha publicado un nuevo comentario sobre el caso: {!Case.Subject}')
            .createEmailTemplate();
        list_EmailTemplates.add(objEmailTemplate2);

        EmailTemplate objEmailTemplate3 = new DEL_TestUtility.EmailTemplateBuilder()
            .setName('Case Comment Email Alert - French')
            .setDeveloperName('DEL_CaseCommentAlertFrench')
            .setHtmlValue('{!Case.Subject} SiteLink {!CaseComment.CommentCreatedName__c} {!CaseComment.CreatedDate}')
            .setFolderId(UserInfo.getOrganizationId())
            .setTemlateType('Custom')
            .setSubject('Un nouveau commentaire a été posté sur Case: {!Case.Subject}')
            .createEmailTemplate();
        list_EmailTemplates.add(objEmailTemplate3);

        User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(objCurrentUser) {
            insert list_EmailTemplates;
            
            Group objGroup = new Group(
                Name = 'Test Delmar Queue',
                DeveloperName = 'DEL_TestDelmarQueue',
                Type = 'Queue',
                DoesSendEmailToMembers = true
            );

            insert objGroup;

            QueueSObject objQueueSObject = new QueueSObject(
                QueueId = objGroup.Id,
                SObjectType = 'Case'
            );
            insert objQueueSObject;

            GroupMember objGroupMember = new GroupMember(
                GroupId = objGroup.Id,
                UserOrGroupId = objCurrentUser.Id
            );

            insert objGroupMember;
        }
    }

    /**
    * @ author       :  Ankit C
    * @ description  :  test method to test the logic in processAfterInsert()
    **/
    @isTest
    static void testCaseCommentCreation() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setCaseId(objCase.Id)
            .setHasAttachment(false)
            .setVisibleToCustomer(true)
            .createCaseComment();
        Test.startTest();
        insert objCaseComment;
        Test.stopTest();
        
        objCaseComment = [
            SELECT
            Id,
            CommentCreatedName__c,
            CreatedByEmail__c
            FROM 
            DEL_CaseComment__c
            WHERE Id = :objCaseComment.Id
        ];
        // Assert if the fields were populated
        System.assert(objCaseComment.CommentCreatedName__c != null);
        System.assert(objCaseComment.CreatedByEmail__c != null);
    }

    /**
    * @ author       :  Ankit C
    * @ description  :  Test Case Comment creation with Attachments
    **/
    @isTest
    static void testCaseCommentCreationWithAttachments() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setCaseId(objCase.Id)
            .setHasAttachment(true)
            .setVisibleToCustomer(true)
            .createCaseComment();
        Test.startTest();
        insert objCaseComment;
        ContentDocument objContentDocument = [SELECT 
                                              Id,
                                              Title,
                                              LatestPublishedVersionId
                                              FROM ContentDocument LIMIT 1];
        ContentDocumentLink objNewContentDocumentLink = new ContentDocumentLink();
        objNewContentDocumentLink.ShareType = 'V';
        objNewContentDocumentLink.Visibility = 'AllUsers';
        objNewContentDocumentLink.ContentDocumentId = objContentDocument.Id;
        objNewContentDocumentLink.LinkedEntityId = objCaseComment.Id;
        insert objNewContentDocumentLink;
        Test.stopTest();
        
        objCaseComment = [
            SELECT
            Id,
            CommentCreatedName__c,
            CreatedByEmail__c
            FROM 
            DEL_CaseComment__c
            WHERE Id = :objCaseComment.Id
        ];
        // Assert if the fields were populated
        System.assert(objCaseComment.CommentCreatedName__c != null);
        System.assert(objCaseComment.CreatedByEmail__c != null);
    }

    /**
    * @ author       :  Ankit C
    * @ description  :  Test Case Comment creation when associated Case is asssigned to a Queue
    **/
    @isTest
    static void testCaseOwnerQueue() {
        Case objCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Case assigned to a Queue' LIMIT 1];
        Group objGroup = [SELECT Id, Name FROM Group WHERE DeveloperName = 'DEL_TestDelmarQueue' LIMIT 1];
        objCase.OwnerId = objGroup.Id;
        update objCase;
        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setCaseId(objCase.Id)
            .setHasAttachment(false)
            .setVisibleToCustomer(true)
            .createCaseComment();
        Test.startTest();
        insert objCaseComment;
        Test.stopTest();
    }

    /**
    * @ author       :  Ankit C
    * @ description  :  Test method to cover catch blocks
    **/
    @isTest
    static void testExceptions() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setHasAttachment(true)
            .setCaseId(objCase.Id)
            .setVisibleToCustomer(true)
            .createCaseComment();
        Test.startTest();
        blnThrowException = true;
        insert objCaseComment;  
        blnThrowException = false;
        Test.stopTest();
    }

    /**
    * @ author       :  Ankit C 
    * @ description  :  This method returns a dummy site link while running test class
    **/
    public static String getSiteLink() {
        return 'https://demo-developer-edition.ap15.force.com';
    }
}