/*********************************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationControllerTest
* @ Purpose         :   Test class for DEL_CaseCollaborationController
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* =====================================================================================================================
*   22-07-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*
***********************************************************************************************************************/
@isTest
public class DEL_CaseCollaborationControllerTest {
    public static Boolean blnThrowException = false;
    
    /**
    * @ author       :  Rakesh Nayak & Vinaykant
    * @ description  :  This method is used to setup data for testing apex class 'DEL_CaseCollaborationController'
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
        
        String strMergeFields = '{!Case.Subject},{!Case.CaseNumber},{!Case.Description},'
            +  '{!CaseComment.CommentCreatedName__c},{!CaseComment.Body__c},'
            + '{!CaseComment.CreatedDate},SiteLink';
        
        OrgWideEmailAddress objOrgWideAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        DEL_EmailAlertConfiguration__c objEmailAlertConfiguration = new DEL_TestUtility.EmailAlertConfigurationBuilder()
            .setMergeFields(strMergeFields)
            .setCaseQueryFields('Subject,CaseNumber,Description')
            .setSiteName('CaseComments')
            .setEmailTemplateName('DEL_CaseCommentAlert')
            .setOwnerId(UserInfo.getOrganizationId())
            .setOrgWideAddress(objOrgWideAddress.Address)
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
        
        DEL_CaseComment__c objCaseComment = new DEL_TestUtility.CaseCommentBuilder()
            .setBody('Hi, can I get an update?')
            .setCaseId(objCase.Id)
            .createCaseComment();
        insert objCaseComment;
    }
    
    /**
    * @ author       :  Vinaykant
    * @ description  :  This method is used to test all the methods in apex class 'DEL_CaseCollaborationController'
    **/
    @isTest
    private static void caseCommentTestMethod() {
        Case objCase = [SELECT 
                        Id,
                        Subject
                        FROM Case
                        LIMIT 1];
        
        Id idCaseId = objCase.Id;
        String strComment = 'Power failure happened';
        Boolean blnVisibleToCustomer = true;

        DEL_CaseCollaborationController.ResponseWrapper objResultFetch = new DEL_CaseCollaborationController.ResponseWrapper();
        
        //Test the Class Methods.
        Test.startTest();
        DEL_CaseCollaborationController.insertComment(strComment, idCaseId, blnVisibleToCustomer);
        DEL_CaseComment__c objCaseComment = [SELECT 
                                             Id 
                                             FROM DEL_CaseComment__c 
                                             WHERE Case__c = : idCaseId 
                                             LIMIT 1];
        
        objResultFetch = DEL_CaseCollaborationController.fetchComments(idCaseId);
        Test.stopTest();
        
        //Check the Result.
        System.assertEquals(2, objResultFetch.list_CaseComments.size(), 'ERROR: Atleast one case comment record should be created.');
    }
    
    /**
    * @ author       :  Ankit
    * @ description  :  This method is used to cover all the catch blocks
    **/
    @isTest
    private static void handleExceptions() {
        Case objCase = [SELECT 
                        Id,
                        Subject
                        FROM Case
                        LIMIT 1];
        
        Id idCaseId = objCase.Id;
        String strComment = 'Power failure happened';
        Boolean blnVisibleToCustomer = true;
        DEL_CaseCollaborationController.ResponseWrapper objResponse = new DEL_CaseCollaborationController.ResponseWrapper();
        Test.startTest();
        blnThrowException = true;
        objResponse = DEL_CaseCollaborationController.insertComment(strComment, idCaseId, blnVisibleToCustomer);
        objResponse = DEL_CaseCollaborationController.fetchComments(idCaseId);
        
        DEL_CaseComment__c objCaseComment = [SELECT 
                                             Body__c, 
                                             Case__c 
                                             FROM DEL_CaseComment__c 
                                             LIMIT 1];
        Test.stopTest();
        
        System.assert(!objResponse.blnIsSuccess);
    }
}