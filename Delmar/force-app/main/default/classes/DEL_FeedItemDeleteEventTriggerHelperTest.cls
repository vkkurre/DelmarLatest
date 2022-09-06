/*******************************************************************************************************
* 
* @ Name            :   DEL_FeedItemDeleteEventTriggerHelperTest
* @ Purpose         :   Test class for DEL_FeedItemDeleteEventTriggerHelper
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   06-09-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
public class DEL_FeedItemDeleteEventTriggerHelperTest {
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to setup data for testing apex class 'DEL_FeedItemDeleteEventTriggerHelper'
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

        FeedItem objFeedItemOne = new DEL_TestUtility.FeedItemBuilder()
            .setParentId(objCase.Id)
            .setType('EmailMessageEvent')
            .setBody('TestBody1')
            .createFeedItem();
        insert objFeedItemOne;

        FeedItem objFeedItemTwo = new DEL_TestUtility.FeedItemBuilder()
            .setParentId(objCase.Id)
            .setType('EmailMessageEvent')
            .setBody('TestBody2')
            .createFeedItem();
        insert objFeedItemTwo;

        FeedItem objFeedItemThree = new DEL_TestUtility.FeedItemBuilder()
            .setParentId(objCase.Id)
            .setType('EmailMessageEvent')
            .setBody('TestBody3')
            .createFeedItem();
        insert objFeedItemThree;

        OrgWideEmailAddress objOrgWideAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        String strMergeFields = '{!Case.Subject},{!Case.CaseNumber},{!Case.Description},'
            +  '{!CaseComment.CommentCreatedName__c},{!CaseComment.Body__c},'
            + '{!CaseComment.CreatedDate},SiteLink';
        DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration = new DEL_TestUtility.CaseCollaborationConfigurationBuilder()
            .setMergeFields(strMergeFields)
            .setCaseQueryFields('Subject,CaseNumber,Description')
            .setSiteName('CaseComments')
            .setEmailTemplateName('DEL_CaseCommentAlert')
            .setOwnerId(UserInfo.getOrganizationId())
            .setOrgWideAddress(objOrgWideAddress.Address)
            .createConfiguration();
        insert objCaseCollaborationConfiguration;
        
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
    * @ description  :  This method is used to test the 'processFeedItemsAfterInsert' method on DEL_FeedItemDeleteEventTriggerHelper
    **/
    @isTest
    private static void testFeedItemDeletion() {
        Case objCase = [SELECT Id FROM Case LIMIT 1];

        DEL_FeedItemDeleteEvent__e objFeedItemDeleteEvent = new DEL_TestUtility.FeedItemDeleteEventBuilder()
            .setCaseId(objCase.Id)
            .setIncomingEmail(false)
            .createFeedItemDeleteEvent();

        List<DEL_FeedItemDeleteEvent__e> list_FeedItemDeleteEvents = new List<DEL_FeedItemDeleteEvent__e>{objFeedItemDeleteEvent};
        Test.startTest();
        List<Database.SaveResult> list_SaveResults = EventBus.publish(list_FeedItemDeleteEvents);
        Test.stopTest();

        List<FeedItem> list_FeedItems = [SELECT Id, 
                                         ParentId, 
                                         Type 
                                         FROM FeedItem WHERE ParentId =:objCase.Id AND Type = 'EmailMessageEvent'];
        
        //Assert that 2 of the recent FeedItems are deleted.
        System.assertEquals(1, list_FeedItems.size());

    }
}
