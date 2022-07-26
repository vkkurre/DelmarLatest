/*******************************************************************************************************
* 
* @ Name            :   DEL_Utils
* @ Purpose         :   Common functionalities can be created as methods in this class 
                        and used across various classes
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_UtilsTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  26-07-2022       |  ankit.c@absyz.com            |  1.0          |  Initial version
*******************************************************************************************************/
public class DEL_Utils {
    /**
    * @ author      : Ankit C
    * @ description : This method is used to initialize/insert a DEL_ExceptionLog__c record
                      based on the input parameters.
    * @ params      : strClassName - Class name where exception has occurred
                      strMethodName - Method name where exception has occurred
                      objException - Exception object
                      blnIsInsertMode - if set as true, then the record will be inserted else it won't
    * @ return      : DEL_ExceptionLog__c - new record which is inserted/initialized.
    **/
    public static DEL_ExceptionLog__c logException(
        String strClassName, 
        String strMethodName, 
        Exception objException, 
        Boolean blnIsInsertMode
    ) {
        DEL_ExceptionLog__c objExceptionLog = new DEL_ExceptionLog__c(
            ClassName__c = strClassName,
            MethodName__c = strMethodName,
            ErrorMessage__c = objException.getMessage(),
            StackTrace__c = objException.getStackTraceString(),
            ExceptionType__c = objException.getTypeName()
        );

        if (blnIsInsertMode) {
            insert objExceptionLog;
        }

        return objExceptionLog;
    }
}
