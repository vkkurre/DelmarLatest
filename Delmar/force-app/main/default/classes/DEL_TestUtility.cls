/*********************************************************************************************************************
* 
* @ Name            :   DEL_TestUtility
* @ Purpose         :   This is utility class which can be used to create test data for test classes
* @ Author          :   Ankit C
*
*   Date            |  Developer Name               |  Version      |  Changes
* =====================================================================================================================
*   26-07-2022      |  ankit.c@absyz.com            |  1.0          |  Initial Version
*
***********************************************************************************************************************/
@isTest
public class DEL_TestUtility {
    /**
    * @ Name            :   AccountBuilder
    * @ Purpose         :   To create Account record
    * @ Author          :   Ankit C
    **/
    public class AccountBuilder {
        private String strName;

        public AccountBuilder() {
            this.strName = '';
        }

        public AccountBuilder setName(String strValue) {
            this.strName = strValue;
            return this;
        }

        public Account createAccount() {
            Account objAccount = new Account();
            objAccount.Name = this.strName;

            return objAccount;
        }
    }

    /**
    * @ Name            :   ContactBuilder
    * @ Purpose         :   To create Contact record
    * @ Author          :   Ankit C
    **/
    public class ContactBuilder {
        private String strFirstName;
        private String strLastName;
        private Id idAccountId;

        public ContactBuilder() {
            this.strFirstName = '';
            this.strLastName = '';
        }

        public ContactBuilder setFirstName(String strValue) {
            this.strFirstName = strValue;
            return this;
        }

        public ContactBuilder setLastName(String strValue) {
            this.strLastName = strValue;
            return this;
        }

        public ContactBuilder setAccountId(Id idValue) {
            this.idAccountId = idValue;
            return this;
        }

        public Contact createContact() {
            Contact objContact = new Contact();
            objContact.FirstName = this.strFirstName;
            objContact.LastName = this.strLastName;
            objContact.AccountId = this.idAccountId;

            return objContact;
        }
    }

    /**
    * @ Name            :   UserBuilder
    * @ Purpose         :   To create User record
    * @ Author          :   Ankit C
    **/
    public class UserBuilder {
        private String strFirstName;
        private String strLastName;
        private Id idContactId;
        private Id idProfileId;
        private String strEmail;
        private String strUsername;
        private String strAlias;

        public UserBuilder() {
            this.strFirstName = '';
            this.strLastName = '';
            this.strEmail = '';
            this.strUsername = '';
            this.strAlias = '';
        }

        public UserBuilder setFirstName(String strValue) {
            this.strFirstName = strValue;
            return this;
        }

        public UserBuilder setLastName(String strValue) {
            this.strLastName = strValue;
            return this;
        }

        public UserBuilder setEmail(String strValue) {
            this.strEmail = strValue;
            return this;
        }

        public UserBuilder setUsername(String strValue) {
            this.strUsername = strValue;
            return this;
        }

        public UserBuilder setAlias(String strValue) {
            this.strAlias = strValue;
            return this;
        }

        public UserBuilder setContactId(Id idValue) {
            this.idContactId = idValue;
            return this;
        }

        public UserBuilder setProfileId(Id idValue) {
            this.idProfileId = idValue;
            return this;
        }

        public User createUser() {
            User objUser = new User();
            objUser.FirstName = this.strFirstName;
            objUser.LastName = this.strLastName;
            objUser.Email = this.strEmail;
            objUser.Username = this.strUsername;
            objUser.Alias = this.strAlias;
            objUser.ContactId = this.idContactId;
            objUser.ProfileId = this.idProfileId;
            objUser.TimeZoneSidKey = 'America/Los_Angeles';
            objUser.LocaleSidKey = 'en_US';
            objUser.EmailEncodingKey = 'ISO-8859-1';
            objUser.LanguageLocaleKey = 'en_US';

            return objUser;
        }
    }

    /**
    * @ Name            :   CaseBuilder
    * @ Purpose         :   To create Case record
    * @ Author          :   Ankit C
    **/
    public class CaseBuilder {
        private String strSubject;
        private String strDescription;
        private Id idContactId;
        private Id idAccountId;
        private String strOrigin;
        private String strType;
        private String strStatus;
        private String strPriority;

        public CaseBuilder() {
            this.strSubject = '';
            this.strDescription = '';
            this.strOrigin = '';
            this.strType = '';
            this.strStatus = '';
            this.strPriority = '';
        }

        public CaseBuilder setSubject(String strValue) {
            this.strSubject = strValue;
            return this;
        }

        public CaseBuilder setDescription(String strValue) {
            this.strDescription = strValue;
            return this;
        }

        public CaseBuilder setOrigin(String strValue) {
            this.strOrigin = strValue;
            return this;
        }

        public CaseBuilder setType(String strValue) {
            this.strType = strValue;
            return this;
        }

        public CaseBuilder setPriority(String strValue) {
            this.strPriority = strValue;
            return this;
        }

        public CaseBuilder setStatus(String strValue) {
            this.strStatus = strValue;
            return this;
        }

        public CaseBuilder setContactId(Id idValue) {
            this.idContactId = idValue;
            return this;
        }

        public CaseBuilder setAccountId(Id idValue) {
            this.idAccountId = idValue;
            return this;
        }

        public Case createCase() {
            Case objCase = new Case();
            objCase.Subject = this.strSubject;
            objCase.Description =  this.strDescription;
            objCase.Origin = this.strOrigin;
            objCase.Type = this.strType;
            objCase.Priority = this.strPriority;
            objCase.AccountId = this.idAccountId;
            objCase.ContactId = this.idContactId;

            return objCase;
        }
    }

    /**
    * @ Name            :   CaseCommentBuilder
    * @ Purpose         :   To create DEL_CaseComment__c record
    * @ Author          :   Ankit C
    **/
    public class CaseCommentBuilder {
        private String strBody;
        private String idCaseId;

        public CaseCommentBuilder() {
            this.strBody = '';
        }

        public CaseCommentBuilder setBody(String strValue) {
            this.strBody = strValue;
            return this;
        }

        public CaseCommentBuilder setCaseId(Id idValue) {
            this.idCaseId = idValue;
            return this;
        }

        public DEL_CaseComment__c createCaseComment() {
            DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
            objCaseComment.Body__c = this.strBody;
            objCaseComment.Case__c = this.idCaseId;

            return objCaseComment;
        }
    }
}
