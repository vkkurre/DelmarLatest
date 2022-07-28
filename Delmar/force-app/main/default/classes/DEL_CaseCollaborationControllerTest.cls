/*********************************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationControllerTest
* @ Purpose         :   Test class for DEL_CaseCollaborationController
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* =====================================================================================================================
*   27-06-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*   22-07-2022      |  vinaykant.kurre@absyz.com    |  1.0          |  Include all other methods of DEL_CaseCollaborationController
*
***********************************************************************************************************************/
@Istest
public class DEL_CaseCollaborationControllerTest {
    public static Boolean blnThrowException = false;
    
    /**
    * @ author      : Rakesh Nayak & Vinaykant
    * @ description : This method is used to setup data for testing apex class 'DEL_CaseCollaborationController'
    **/
    @TestSetup
    static void createData(){
        Account objAccount = new DEL_TestUtility.AccountBuilder()
            .setName('Test Account Delmar')
            .createAccount();
        insert objAccount;

        Contact objContact = new DEL_TestUtility.ContactBuilder()
            .setFirstName('First')
            .setLastName('User')
            .setAccountId(objAccount.Id)
            .createContact();
        insert objContact;

        Case objCase = new DEL_TestUtility.CaseBuilder()
            .setSubject('Case with Power Failure')
            .setDescription('Power failure happens after 4 hour work')
            .setStatus('New')
            .setOrigin('Email')
            .setPriority('Medium')
            .setType('Electrical')
            .setAccountId(objAccount.Id)
            .setContactId(objContact.Id)
            .createCase();
        insert objCase;

        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setCaseId(objCase.Id)
            .createCaseComment();
        insert objCaseComment;
    }

    /**
    * @ author      : Vinaykant
    * @ description : This method is used to test all the methods in apex class 'DEL_CaseCollaborationController'
    **/
    @IsTest
    private static void caseCommentTestMethod() {
        Case objCase = [SELECT 
                        Id,
                        Subject
                        FROM Case
                        LIMIT 1];

        Id idCaseId = objCase.Id;
        String strComment = 'Power failure happened';

        DEL_CaseCollaborationController.ResponseWrapper objResultFetch = new DEL_CaseCollaborationController.ResponseWrapper();

        //Test the Class Methods.
        Test.startTest();
        DEL_CaseCollaborationController.insertComment(strComment, idCaseId);
        DEL_CaseComment__c objCaseComment = [SELECT 
                                            Id 
                                            FROM DEL_CaseComment__c 
                                            WHERE Case__c = : idCaseId 
                                            LIMIT 1];

        objResultFetch = DEL_CaseCollaborationController.fetchComments(idCaseId);
        DEL_CaseCollaborationController.updateCaseComment(objCaseComment.Id, 'Hello');
        DEL_CaseCollaborationController.deleteCaseComment(objCaseComment.Id);
        Test.stopTest();

        //Check the Result.
        System.assertEquals(2, objResultFetch.list_CaseComments.size(), 'ERROR: Atleast one case comment record should be created.');
    }

    /**
    * @ author      : Ankit
    * @ description : This method is used to cover all the catch blocks
    **/
    @IsTest
    private static void handleExceptions() {
        Case objCase = [SELECT 
                        Id,
                        Subject
                        FROM Case
                        LIMIT 1];

        Id idCaseId = objCase.Id;
        String strComment = 'Power failure happened';
        DEL_CaseCollaborationController.ResponseWrapper objResponse = new DEL_CaseCollaborationController.ResponseWrapper();
        Test.startTest();
        blnThrowException = true;
        objResponse = DEL_CaseCollaborationController.insertComment(strComment, idCaseId);
        objResponse = DEL_CaseCollaborationController.fetchComments(idCaseId);

        DEL_CaseComment__c objCaseComment = [SELECT 
                                            Body__c, 
                                            Case__c 
                                            FROM DEL_CaseComment__c 
                                            LIMIT 1];

        objResponse = DEL_CaseCollaborationController.updateCaseComment(objCaseComment.Id, 'Hello');
        objResponse = DEL_CaseCollaborationController.deleteCaseComment(objCaseComment.Id);
        Test.stopTest();

        System.assert(!objResponse.blnIsSuccess);
    }
}