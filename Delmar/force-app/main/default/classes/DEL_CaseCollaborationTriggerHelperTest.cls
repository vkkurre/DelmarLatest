/*******************************************************************************************************
* 
* @ Name            :   DEL_CaseCollaborationTriggerHelperTest
* @ Purpose         :   Test class for DEL_CaseCollaborationTriggerHelper
* @ Author          :   Dinesh Chandra
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   19-07-2022      |  dinesh.chandra@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@IsTest
public class DEL_CaseCollaborationTriggerHelperTest {
    public static Boolean blnThrowException = false;
    /**
    * @ author      : Dinesh Chandra
    * @ description : This method is used to setup data for testing apex class 'DEL_CaseCollaborationTriggerHelper'
    **/
    @TestSetup
    static void setupData() {
        Account objAccount = new DEL_TestUtility.AccountBuilder()
            .setName('Test Account Delmar')
            .createAccount();
        insert objAccount;
        
        List<Contact> list_Contacts = new List<Contact>();
        Contact objContact = new DEL_TestUtility.ContactBuilder()
            .setFirstName('First')
            .setLastName('User')
            .setAccountId(objAccount.Id)
            .createContact();
        list_Contacts.add(objContact);

        Contact objContact2 = new DEL_TestUtility.ContactBuilder()
            .setFirstName('Second')
            .setLastName('User')
            .setAccountId(objAccount.Id)
            .createContact();
        list_Contacts.add(objContact2);
        insert list_Contacts;
        
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

        User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'];
        User objUser2;

        System.runAs(objCurrentUser) {
            List<User> list_Users = new List<User>();
            User objUser = new DEL_TestUtility.UserBuilder()
                .setFirstName('Ram')
                .setLastName('keerthan')
                .setEmail('ram.keerthan@yopmail.com')
                .setUsername('ram.keerthan@yopmail.com')
                .setContactId(objContact.Id)
                .setProfileId(objProfile.Id)
                .setAlias('rkeer')
                .createUser();
            list_Users.add(objUser);

            objUser2 = new DEL_TestUtility.UserBuilder()
                .setFirstName('Test')
                .setLastName('Customer User')
                .setEmail('customer@delmar.com')
                .setUsername('customer@delmar.com')
                .setContactId(objContact2.Id)
                .setProfileId(objProfile.Id)
                .setAlias('rkeer')
                .createUser();
            list_Users.add(objUser2);

            insert list_Users;
        }

        CaseShare objCaseShare = new CaseShare(
            UserOrGroupId = objUser2.Id,
            CaseId = objCase.Id,
            RowCause = Schema.CaseShare.RowCause.Manual,
            CaseAccessLevel = 'Edit'
        );
        insert objCaseShare;
    }

    /**
    * @ author      : Dinesh Chandra
    * @ description : This method is used to test the creation of DEL_CaseCollaborator__c
    **/
    @IsTest
    private static void testCaseCollaboratorCreation() {
        Case objCase = [SELECT Id, ContactId FROM Case LIMIT 1];
        User objUser = [SELECT Id, ContactId FROM User WHERE ContactId = :objCase.ContactId];
        DEL_CaseCollaborator__c objCaseCollaborator2;

        DEL_CaseCollaborator__c objCaseCollaborator = new DEL_TestUtility.CaseCollaborationBuilder()
            .setCaseId(objCase.Id)
            .setUserId(objUser.Id)
            .createCaseCollaborator();
        Test.startTest();
        insert objCaseCollaborator;

        // Inserting the same case collaborator again to check the handleDuplicates() method
        objCaseCollaborator2 = new DEL_TestUtility.CaseCollaborationBuilder()
            .setCaseId(objCase.Id)
            .setUserId(objUser.Id)
            .createCaseCollaborator();
        try {
            insert objCaseCollaborator2;
        } catch (DmlException objException) {
            DEL_Utils.logException(
                'DEL_CaseCollaborationTriggerHelperTest',
                'testCaseCollaboratorCreation',
                objException,
                true
            );
        } 
        Test.stopTest();

        List<CaseShare> list_CaseShares = [SELECT 
                                           Id, 
                                           CaseId,
                                           UserOrGroupId
                                           FROM CaseShare
                                           WHERE CaseId = :objCase.Id
                                           AND UserOrGroupId = :objUser.Id];
        // Assert if a CaseShare record was created when a case collaborator was created.                                   
        System.assert(!list_CaseShares.isEmpty());
        //Assert if the duplicate case collaborator was not created.
        System.assert(objCaseCollaborator2.Id == null);
    } 

    /**
    * @ author      : Ankit
    * @ description : This method forces and exception to cover the catch blocks
    **/
    @isTest
    private static void handleException() {
        Test.startTest();
        List<DEL_CaseCollaborator__c> list_CaseCollaborators = [SELECT
                                                                Id 
                                                                FROM 
                                                                DEL_CaseCollaborator__c];
        blnThrowException = true;
        DEL_CaseCollaborationTriggerHelper.handleDuplicates(list_CaseCollaborators);
        blnThrowException = false;
        Test.stopTest();
    }
}