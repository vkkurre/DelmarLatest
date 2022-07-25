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
@IsTest
private class DEL_EmailMessagesTriggerHelperTest {
    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is used to setup data for testing apex class 'DEL_EmailMessagesTriggerHelper'
    **/
    @TestSetup
    static void createData() {
        Case objCase = new Case(
            Status = 'New',
            Origin = 'Email',
            Subject = 'Test Case'
        );
        insert objCase;

        EmailMessage objEmailMessage = new EmailMessage(
            TextBody = 'This is textbody',
            HtmlBody = '<div>this is HtmlBody</div><br><body>Test</body>',
            Incoming = true,
            FromAddress = 'abc@xyz.com',
            FromName = 'Test User',
            ThreadIdentifier = 'qwerty',
            MessageIdentifier = '1cwicjn',
            ParentId = objCase.Id
        );
        insert objEmailMessage;
    }

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is used to test the 'handleEmailsOnInsert' method on DEL_EmailMessagesTriggerHelper
    **/
    @IsTest
    private static void emailMessageTriggerTestMethod() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        List<EmailMessage> list_EmailMessages = [
            SELECT TextBody,
            HtmlBody,
            Incoming,
            ThreadIdentifier,
            MessageIdentifier,
            FromAddress,
            FromName,
            ParentId
            FROM EmailMessage
            WHERE ParentId = :objCase.Id
        ];

        Test.startTest();
        DEL_EmailMessagesTriggerHelper.handleEmailsOnInsert(list_EmailMessages);
        Test.stopTest();

        DEL_CaseComment__c objCaseComment = [SELECT Id, Body__c, Case__c
                                             FROM DEL_CaseComment__c
                                             LIMIT 1];
        System.assertEquals(objCaseComment.Body__c, 'this is HtmlBody');
    }
}