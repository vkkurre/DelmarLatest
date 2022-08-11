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
    /**
    * @ author       :  Anit C
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

        Case objCase = new DEL_TestUtility.CaseBuilder()
            .setSubject('Case with Power Failure')
            .setDescription('Power failure happens after 4 hour work')
            .setStatus('New')
            .setOrigin('Email')
            .setSuppliedEmail('test@delmar.com')
            .setLanguage('French')
            .createCase();
        insert objCase;
        
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
        DEL_EmailAlertConfiguration__c objEmailAlertConfiguration = new DEL_TestUtility.EmailAlertConfigurationBuilder()
            .setMergeFields(strMergeFields)
            .setCaseQueryFields('Subject,CaseNumber,Description')
            .setSiteName('CaseComments')
            .setEmailTemplateName('DEL_CaseCommentAlert')
            .setSpanishTemplateName('DEL_CaseCommentAlertSpanish')
            .setFrenchTemplateName('DEL_CaseCommentAlertFrench')
            .setOwnerId(UserInfo.getOrganizationId())
            .setOrgWideAddress(objOrgWideAddress.Address)
            .setEmailBreakPattern('(<br><div class="gmail_quote">){1}')
            .createConfiguration();
        insert objEmailAlertConfiguration;
        
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
        }
    }

    /**
    * @ author       :  Anit C
    * @ description  :  test method to test the logic in processAfterInsert()
    **/
    @isTest
    static void testCaseCommentCreation() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setCaseId(objCase.Id)
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
    * @ description  :  This method returns a dummy site link while running test class
    **/
    public static String getSiteLink() {
        return 'https://demo-developer-edition.ap15.force.com';
    }

    /**
    * @ author       :  Anit C
    * @ description  :  test method to test the logic in processAfterInsert()
    **/
    @isTest
    static void testGetDefaultLanguage() {
        Case objCase = [SELECT 
                        Id,
                        Contact.Preferred_Language__c,
                        Language__c
                        FROM Case 
                        LIMIT 1];
        Test.startTest();
        String strLanguage = DEL_CaseCommentTriggerHelper.getDefaultLanguage(objCase);
        Test.stopTest();

        System.assertEquals('French', strLanguage);
    }
}