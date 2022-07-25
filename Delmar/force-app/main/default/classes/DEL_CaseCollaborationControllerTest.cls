/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationControllerTest
* @ Purpose         :   Test class for DEL_CaseCollaborationController
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   27-06-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@Istest
private class DEL_CaseCollaborationControllerTest {
    @TestSetup
    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is used to setup data for testing apex class 'DEL_CaseCollaborationController'
    **/
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

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is used to test the methods 'insertComment' and 'fetchComments' in 
                      apex class 'DEL_CaseCollaborationController'
    **/
    @IsTest
    private static void caseCommentTestMethod() {
        String strCommentBody = 'Hi Sir';
        Test.startTest();
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        DEL_CaseCollaborationController.ResponseWrapper objWrapper = DEL_CaseCollaborationController.insertComment(strCommentBody, objCase.Id);
        List<DEL_CaseComment__c> list_CaseComments = DEL_CaseCollaborationController.fetchComments(objCase.Id);
        Test.stopTest();
        System.assertEquals(2, list_CaseComments.size());
    }  
}