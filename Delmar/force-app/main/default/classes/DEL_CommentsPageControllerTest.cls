/*******************************************************************************************************
* 
* @ Name            :   DEL_CommentsPageControllerTest
* @ Purpose         :   Test class for DEL_CommentsPageController
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   27-06-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@istest
private class DEL_CommentsPageControllerTest {
    @TestSetup
    static void createData(){
        Case objCase = new Case(
            Status = 'New',
            Origin = 'Web'
        );
    insert objCase;
    String strCommentBody = 'Hey, Can I know the update';
    DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c(
        Case__c = objCase.Id,
        Body__c = strCommentBody
    );
    insert objCaseComment;
    }
    @isTest
    private static void caseCommentTestMethod(){
        String strCommentBody = 'Hi Sir';
        Test.startTest();
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        Id idCaseCommentId = DEL_CommentsPageController.insertComment(strCommentBody, objCase.Id);
        List<DEL_CaseComment__c> list_comments = DEL_CommentsPageController.fetchComments(objCase.Id);
        Test.stopTest();
        System.assertEquals(2, list_comments.size());
    }
}