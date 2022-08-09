/*******************************************************************************************************
* 
* @ Name            :   DEL_ContactCollaborationControllerTest
* @ Purpose         :   Test class for DEL_ContactCollaborationController
* @ Author          :   Dinesh Chandra
*
*   Date            |  Developer Name                 |  Version      |  Changes
* ======================================================================================================
*   19-07-2022      |  dinesh.chandra@absyz.com       |  1.0          |  Initial Version
*
*******************************************************************************************************/
@isTest
private class DEL_ContactCollaborationControllerTest {
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method is used to setup data for testing apex class 'DEL_ContactCollaborationController'
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
        
        List<User> list_Users = new List<User>();
        Profile objProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community Plus User'];
        User objUser = new DEL_TestUtility.UserBuilder()
            .setFirstName('ram')
            .setLastName('keerthan')
            .setEmail('ram.keerthan@yopmail.com')
            .setUserName('ramkeerthan@yopmail.com')
            .setAlias('rkeer')
            .setContactId(objContact.Id)
            .setProfileId(objProfile.Id)
            .createUser();
        list_Users.add(objUser);
        
        User objUser2 = new DEL_TestUtility.UserBuilder()
            .setFirstName('Test')
            .setLastName('Customer User')
            .setEmail('customer@delmar.com')
            .setUsername('customer@delmar.com')
            .setContactId(objContact2.Id)
            .setProfileId(objProfile.Id)
            .setAlias('deltest')
            .createUser();
        list_Users.add(objUser2);
        
        insert list_Users;
        
        CaseShare objCaseShare = new CaseShare(
            UserOrGroupId = objUser2.Id,
            CaseId = objCase.Id,
            RowCause = Schema.CaseShare.RowCause.Manual,
            CaseAccessLevel = 'Edit'
        );
        insert objCaseShare;
    }
    
    /**
    * @ author       :  Dinesh Chandra
    * @ description  :  This method is used to test the 'getUserData' and 'addContactCollaborator'methods on DEL_ContactCollaborationController
    **/
    @isTest
    private static void testCaseCollaboration() {  
        Case objCase = [SELECT 
                        Id 
                        FROM Case 
                        LIMIT 1];
        User objUser = [SELECT 
                        Id
                        FROM User 
                        WHERE Username = 'customer@delmar.com'
                        LIMIT 1];
        String strUserNameSearchKey = 'ram';
        List<Id> list_UserIds = new List<Id>();
        list_UserIds.add(objUser.Id);
        
        DEL_ContactCollaborationController.ResponseWrapper objResponseWrapper = new DEL_ContactCollaborationController.ResponseWrapper();
        DEL_ContactCollaborationController.ResponseWrapper objResponseWrapper2 = new DEL_ContactCollaborationController.ResponseWrapper();
        //Test Methods
        Test.startTest();
        objResponseWrapper = DEL_ContactCollaborationController.addContactCollaborator(list_UserIds, objCase.Id);
        objResponseWrapper2 = DEL_ContactCollaborationController.getUserData(objCase.Id, strUserNameSearchKey,objUser.Id);
        Test.stopTest();
        
        //  Assert results
        System.assertEquals(true, objResponseWrapper.blnIsSuccess, objResponseWrapper.strErrorMessage);
        System.assertEquals(1, objResponseWrapper2.list_Users.size(), 'Atleast: One User should be fetched.');
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  This method is used to test the catch blocks in the DEL_ContactCollaborationController class
    **/
    @isTest
    private static void testExceptions() {
        DEL_ContactCollaborationController.ResponseWrapper objResponseWrapper = new DEL_ContactCollaborationController.ResponseWrapper();
        DEL_ContactCollaborationController.ResponseWrapper objResponseWrapper2 = new DEL_ContactCollaborationController.ResponseWrapper();
        List<User> objUser = [SELECT 
                              Id
                              FROM User 
                              WHERE Username = 'customer@delmar.com'
                              LIMIT 1];
        List<Id> list_UserIds = new List<Id>();
        list_UserIds.add(objUser.get(0).Id);
        
        Test.startTest();
        objResponseWrapper = DEL_ContactCollaborationController.addContactCollaborator(list_UserIds, null);
        objResponseWrapper2 = DEL_ContactCollaborationController.getUserData(null, 'ram',objUser.get(0).Id);
         Test.stopTest();
        
        // Assert if the methods encountered exceptions in them
        System.assert(!objResponseWrapper.blnIsSuccess);
        System.assert(!objResponseWrapper2.blnIsSuccess);
    }
    
}