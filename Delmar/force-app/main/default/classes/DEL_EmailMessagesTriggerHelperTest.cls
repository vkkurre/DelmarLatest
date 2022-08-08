/*******************************************************************************************************
* 
* @ Name            :   DEL_EmailMessagesTriggerHelperTest
* @ Purpose         :   Test class for DEL_EmailMessagesTriggerHelper
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   19-07-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class DEL_EmailMessagesTriggerHelperTest {
    
    public static Boolean blnThrowException = false;
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to setup data for testing apex class 'DEL_EmailMessagesTriggerHelper'
    **/
    @TestSetup
    static void createData() {
        Case objCase = new DEL_TestUtility.CaseBuilder()
            .setSubject('Case with Power Failure')
            .setDescription('Power failure happens after 4 hour work')
            .setStatus('New')
            .setOrigin('Email')
            .createCase();
        insert objCase;
        
        String strMergeFields = '{!Case.Subject},{!Case.CaseNumber},{!Case.Description},'
            +  '{!CaseComment.CommentCreatedName__c},{!CaseComment.Body__c},'
            + '{!CaseComment.CreatedDate},SiteLink';
        
        OrgWideEmailAddress objOrgWideAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        DEL_EmailAlertConfiguration__c objEmailAlertConfiguration = new DEL_TestUtility.EmailAlertConfigurationBuilder()
            .setMergeFields(strMergeFields)
            .setCaseQueryFields('Subject,CaseNumber,Description')
            .setCaseCommentFields('CommentCreatedName__c,Body__c,CreatedDate')
            .setSiteName('CaseComments')
            .setEmailTemplateName('DEL_CaseCommentAlert')
            .setOwnerId(UserInfo.getOrganizationId())
            .setOrgWideAddress(objOrgWideAddress.Address)
            .setEmailBreakPattern('(<br><div class="gmail_quote">){1}')
            .createConfiguration();
        insert objEmailAlertConfiguration;
        
        EmailTemplate objEmailTemplate = new DEL_TestUtility.EmailTemplateBuilder()
            .setName('Case Comment Email Alert')
            .setDeveloperName('DEL_CaseCommentAlert')
            .setHtmlValue('{!Case.Subject} SiteLink {!CaseComment.CommentCreatedName__c} {!CaseComment.CreatedDate}')
            .setFolderId(UserInfo.getOrganizationId())
            .setTemlateType('Custom')
            .createEmailTemplate();
        
        User objUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(objUser) {
            insert objEmailTemplate;
        }
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to test the 'handleEmailsOnInsert' method on DEL_EmailMessagesTriggerHelper
    **/
    @isTest
    private static void testEmailMessageCreation() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        EmailMessage objEmailMessage = new DEL_TestUtility.EmailMessageBuilder()
            .setTextBody('This is textbody')
            .setHtmlBody('<div>this is HtmlBody</div><br><div class="gmail_quote"><body>Test</body>')
            .setIncoming(true)
            .setFromAddress('abc@xyz.com')
            .setFromName('Test User')
            .setThreadIdentifier('qwerty')
            .setMessageIdentifier('1cwicjn')
            .setParentId(objCase.Id)
            .createEmailMessage();
        Test.startTest();
        insert objEmailMessage;
        Test.stopTest();
        
        DEL_CaseComment__c objCaseComment = [SELECT 
                                             Id, 
                                             Body__c, 
                                             Case__c
                                             FROM DEL_CaseComment__c
                                             LIMIT 1];
        // Assert if a case comment was created successfully from the email message.                                     
        System.assertEquals(objCaseComment.Body__c, '<div>this is HtmlBody</div>');
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to test to cover the catch blocks in
    *                   'handleEmailsOnInsert' method in DEL_EmailMessagesTriggerHelper
    **/
    @isTest
    private static void handleExceptions() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        
        EmailMessage objEmailMessage = new DEL_TestUtility.EmailMessageBuilder()
            .setTextBody('This is textbody')
            .setHtmlBody('<div>this is HtmlBody</div><br><div class="gmail_quote"><body>Test</body>')
            .setIncoming(true)
            .setFromAddress('abc@xyz.com')
            .setFromName('Test User')
            .setThreadIdentifier('qwerty')
            .setMessageIdentifier('1cwicjn')
            .setParentId(objCase.Id)
            .createEmailMessage();
        
        Test.startTest();
        blnThrowException = true;
        insert objEmailMessage;
        Test.stopTest();
        
        List<DEL_ExceptionLog__c> list_ExceptionLogs = [SELECT 
                                                        Id, 
                                                        ClassName__c, 
                                                        MethodName__c
                                                        FROM DEL_ExceptionLog__c
                                                        WHERE MethodName__c = 'handleEmailsOnInsert'];
        System.assert(!list_ExceptionLogs.isEmpty());
    }
}