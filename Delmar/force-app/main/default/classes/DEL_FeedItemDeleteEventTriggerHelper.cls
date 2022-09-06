/*********************************************************************************************************
* 
* @ Name            :   DEL_FeedItemDeleteEventTriggerHelper
* @ Purpose         :   Helper class for DEL_FeedItemDeleteEventTrigger
* @ Author          :   Rakesh Nayak
* @ Usage           :   1) To delete the Feed Item records created by emails sent/received on creation of
                           case comments.
* @ Test Class Name :   DEL_CaseCommentTriggerHelperTest
*
*   Date            |  Developer Name                |  Version      |  Changes
* ========================================================================================================
*  06-09-2022       |  rakesh.nayak@absyz.com        |  1.0          |  Initial version
*********************************************************************************************************/
public class DEL_FeedItemDeleteEventTriggerHelper {
    
    public static Boolean blnSkipTrigger = false;

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method processes the incoming DEL_FeedItemDeleteEvent__e records to fetch feed items created by case comment emails and deletes them.
    * @ params      : list_FeedItemDeleteEvents - list of DEL_FeedItemDeleteEvent__e records passed from trigger
    **/
    public static void processFeedItemsAfterInsert(List<DEL_FeedItemDeleteEvent__e> list_FeedItemDeleteEvents) {
        Set<Id> set_CaseIds = new Set<Id>();
        Boolean blnIsIncomingEmailMessage;
        for (DEL_FeedItemDeleteEvent__e objFeedItemDeleteEvent : list_FeedItemDeleteEvents) {
            set_CaseIds.add(objFeedItemDeleteEvent.CaseId__c);
        }

        blnIsIncomingEmailMessage = list_FeedItemDeleteEvents[0].IncomingEmail__c;
        String strFeedItemQuery ='SELECT Id, ParentId, Type FROM FeedItem WHERE ParentId IN :set_CaseIds AND Type = \'EmailMessageEvent\' ORDER BY CreatedDate DESC';
        if (blnIsIncomingEmailMessage) {
            strFeedItemQuery = strFeedItemQuery + ' LIMIT 3';
        } else {
            strFeedItemQuery = strFeedItemQuery + ' LIMIT 2';
        }

        List<Feeditem> list_FeedItems = Database.query(strFeedItemQuery);
        if (!list_FeedItems.isEmpty()) {
            Database.DeleteResult[] list_DeleteResults = Database.delete(list_FeedItems);
        }
    }
}
