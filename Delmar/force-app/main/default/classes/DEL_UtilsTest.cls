/*******************************************************************************************************
* 
* @ Name            :   DEL_UtilsTest
* @ Purpose         :   Test class for the DEL_Utils class.
* @ Author          :   Ankit C
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  26-07-2022       |  ankit.c@absyz.com            |  1.0          |  Initial version
*******************************************************************************************************/
@IsTest
private class DEL_UtilsTest {
    /**
     * @ author      : Ankit C
     * @ description : Test method for logException() method in DEL_Utils class
    **/
    @IsTest
    private static void testLogException() {
        Account objAccount = new Account();
        DEL_ExceptionLog__c objExceptionLog = new DEL_ExceptionLog__c();
        Test.startTest();
        try {
            // This DML will fail as Name is required.
            insert objAccount;
        } catch (Exception objException) {
            objExceptionLog = DEL_Utils.logException(
                'DEL_UtilsTest',
                'testLogException',
                objException,
                true
            );
        }
        Test.stopTest();

        // Assert if an DEL_ExceptionLog__c record was created of DML Type
        System.assert(objExceptionLog.Id != null);
        System.assertEquals('System.DmlException', objExceptionLog.ExceptionType__c, 'Record was not created.');
    }
}
