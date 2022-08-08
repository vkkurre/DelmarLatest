/*******************************************************************************************************
* 
* @ Name            :   DEL_ContentDocumentLinkTriggerTest
* @ Purpose         :   Test class for ContentDocumentLinkTriggerHelper
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   04-08-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class DEL_ContentDocumentLinkTriggerTest {
    public static Boolean blnThrowException = false;

    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to setup data for testing apex class 'DEL_ContentDocumentLinkTriggerHelper'
    **/
    @TestSetup
    static void createTestData() {
        Case objCase = new DEL_TestUtility.CaseBuilder()
            .setSubject('Case with Power Failure')
            .setDescription('Power failure happens after 4 hour work')
            .setStatus('New')
            .setOrigin('Email')
            .createCase();
        insert objCase;
        
        OrgWideEmailAddress objOrgWideAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        String strMergeFields = '{!Case.Subject},{!Case.CaseNumber},{!Case.Description},'
            +  '{!CaseComment.CommentCreatedName__c},{!CaseComment.Body__c},'
            + '{!CaseComment.CreatedDate},SiteLink';
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
        
        EmailMessage objEmailMessage = new DEL_TestUtility.EmailMessageBuilder()
            .setTextBody('This is textbody')
            .setHtmlBody('<div>this is HtmlBody</div><br><body>Test</body>')
            .setIncoming(true)
            .setFromAddress('abc@xyz.com')
            .setFromName('Test User')
            .setThreadIdentifier('qwerty')
            .setMessageIdentifier('1cwicjn')
            .setParentId(objCase.Id)
            .createEmailMessage();
        insert objEmailMessage;
        
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
            .setLinkedEntityId(objEmailMessage.Id)
            .createContentDocumentLink();
        insert objContentDocumentLink;
    }

    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to test the method 'handleContentDocumentLinksOnInsert' in apex class 'DEL_ContentDocumentLinkTriggerHelper'
    **/
    @isTest
    private static void testContentDocumentLinkCreation() {
        ContentDocument objContentDocument = [SELECT 
                                              Id,
                                              Title,
                                              LatestPublishedVersionId
                                              FROM ContentDocument];
        
        List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT 
                                                               Id,
                                                               Visibility,
                                                               ShareType,
                                                               LinkedEntityId,
                                                               ContentDocumentId
                                                               FROM ContentDocumentLink
                                                               WHERE ContentDocumentId = :objContentDocument.Id];
        
        Test.startTest();
        DEL_ContentDocumentLinkTriggerHelper.handleContentDocumentLinksOnInsert(list_ContentDocumentLinks);
        Test.stopTest();
        
        DEL_CaseComment__c objCasecomment = [SELECT Id FROM DEL_CaseComment__c];
        ContentDocumentLink objContentDocumentLink = [SELECT 
                                                      Id,
                                                      ShareType,
                                                      Visibility,
                                                      ContentDocumentId,
                                                      LinkedEntityId
                                                      FROM ContentDocumentLink
                                                      WHERE LinkedEntityId = :objCasecomment.Id];
        
        System.assertEquals(objCaseComment.Id, objContentDocumentLink.LinkedEntityId);
    }

    @isTest
    private static void handleExceptions() {
        ContentDocument objContentDocument = [SELECT 
                                              Id,
                                              Title,
                                              LatestPublishedVersionId
                                              FROM ContentDocument];
        
        List<ContentDocumentLink> list_ContentDocumentLinks = [SELECT 
                                                               Id,
                                                               Visibility,
                                                               ShareType,
                                                               LinkedEntityId,
                                                               ContentDocumentId
                                                               FROM ContentDocumentLink
                                                               WHERE ContentDocumentId = :objContentDocument.Id];
        
        Test.startTest();
        blnThrowException = true;
        DEL_ContentDocumentLinkTriggerHelper.handleContentDocumentLinksOnInsert(list_ContentDocumentLinks);
        Test.stopTest();
        
        List<DEL_ExceptionLog__c> list_ExceptionLogs = [SELECT 
                                                        Id, 
                                                        ClassName__c, 
                                                        MethodName__c
                                                        FROM DEL_ExceptionLog__c
                                                        WHERE MethodName__c = 'handleContentDocumentLinksOnInsert'];
        System.assert(!list_ExceptionLogs.isEmpty());
    }
}