/*******************************************************************************************************
* 
* @ Name            :   DEL_FlowHandlerTest
* @ Purpose         :   Test class for DEL_FlowHandler
* @ Author          :   Deeksha
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   25-07-2022      |  deekshasuvarna@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@IsTest
public class DEL_FlowHandlerTest {   
    /**
    * @ author      : Deeksha
    * @ description : This method is used to setup data for testing apex class 'DEL_FlowHandler'
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
            .setCaseCommentFields('CommentCreatedName__c,Body__c,CreatedDate')
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
    * @ author      : Deeksha 
    * @ description : This method is used to test the method in apex class 'DEL_FlowHandler'
    **/
    @Istest
    private static void caseCommentTestMethod() {
        Case objCase = [SELECT 
                        Id,
                        Subject
                        FROM Case
                        LIMIT 1];

        Id idCaseId = objCase.Id;
        String strComment = 'Power failure happened';
        List<DEL_CaseComment__c> list_CaseComments = new List<DEL_CaseComment__c>();
        
        //Test the Class Methods.
        Test.startTest();
        DEL_CaseComment__c objCaseComment = [SELECT 
                                            Id,
                                            Case__c
                                            FROM DEL_CaseComment__c 
                                            WHERE Case__c = : idCaseId 
                                            LIMIT 1];
        
		list_CaseComments.add(objCaseComment);
        DEL_FlowHandler.formHTMLValue(list_CaseComments);
        Test.stopTest();

        //Check the Result.
        System.assertEquals(1, list_CaseComments.size());
    }

    /**
    * @ author      : Ankit C 
    * @ description : This method returns a dummy site link while running test class
    **/
    public static String getSiteLink() {
        return 'https://absyzdev-developer-edition.ap15.force.com';
    }
}