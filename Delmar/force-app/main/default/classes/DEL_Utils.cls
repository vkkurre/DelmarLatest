/*******************************************************************************************************
* 
* @ Name            :   DEL_Utils
* @ Purpose         :   Common functionalities can be created as methods in this class 
*                       and used across various classes
* @ Author          :   Ankit C
* @ Test Class Name :   DEL_UtilsTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  26-07-2022       |  ankit.c@absyz.com            |  1.0          |  Initial version
*  12-08-2022       |  rakesh.nayak@absyz.com       |  1.1          |  Added Html body handler logic
*******************************************************************************************************/
public class DEL_Utils {
    /**
    * @ author       :  Ankit C
    * @ description  :  This method is used to initialize/insert a DEL_ExceptionLog__c record
    *                   based on the input parameters.
    * @ params       :  strClassName - Class name where exception has occurred
    *                   strMethodName - Method name where exception has occurred
    *                   objException - Exception object
    *                   blnIsInsertMode - if set as true, then the record will be inserted else it won't
    * @ return       :  DEL_ExceptionLog__c - new record which is inserted/initialized.
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
            Database.insert(objExceptionLog, false);
        }
        
        return objExceptionLog;
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to create exception logs from a list of error messages
    *                   from a DML operation.
    * @ params       :  strClassName - Class name where DML exception has occurred
    *                   strMethodName - Method name where DML exception has occurred
    *                   list_ErrorMessages - List of rror message from the DML operation
    **/
    public static void logDMLException(
        String strClassName, 
        String strMethodName, 
        List<String> list_ErrorMessages
    ) {
        List<DEL_ExceptionLog__c> list_ExceptionLogs = new List<DEL_ExceptionLog__c>();
        for (String strErrorMessage : list_ErrorMessages) {
            DEL_ExceptionLog__c objExceptionLog = new DEL_ExceptionLog__c(
                ClassName__c = strClassName,
                MethodName__c = strMethodName,
                ErrorMessage__c = strErrorMessage,
                ExceptionType__c = 'DMLException'
            );
            list_ExceptionLogs.add(objExceptionLog);
        }
        
        Database.insert(list_ExceptionLogs, false);
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to process the errors occured in DML operations.
    * @ params       :  list_SaveResults - List of Database.SaveResult records from DML operation
    *                   strOperationType - Type of DML operation
    * @ return       :  list_Errors - List of Error messages from the failed DML operations.
    **/
    public static List<String> processDMLErrors(
        List<Database.SaveResult> list_SaveResults,
        String strOperationType
    ) {
        List<String> list_Errors = new List<String>();
        for (Database.SaveResult objSaveResult : list_SaveResults) {
            if (!objSaveResult.isSuccess()) {
                for (Database.Error objError : objSaveResult.getErrors()) {
                    String strErrorMessage = strOperationType + ' failed for ' + 
                        objSaveResult.getId() + '. Error: ' + objError.getMessage() + 
                        '. Status Code: ' + objError.getStatusCode();
                    list_Errors.add(strErrorMessage);
                }
            }
        }
        
        return list_Errors;
    }

    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to process the Html body of email message to get latest reply mail.
    * @ params       :  strHtmlBody - Html Body of email message record
    * @ return       :  strLatestReply - Latest reply from the email thread.
    **/
    public static String handleHtmlBody(String strHtmlBody) {
        String strLatestReply = '';
        Boolean blnMainDivStarted = false;
        Integer intOpenDivCount;
        Integer intClosedDivCount;
        List<String> list_EmailThreadParts = strHtmlBody.split('>');
        for (String strEmailSection : list_EmailThreadParts) {
            if (strEmailSection.contains('<div') && !blnMainDivStarted) {
                strLatestReply = strEmailsection;
                blnMainDivStarted = true;
                intOpenDivCount = strEmailSection.countMatches('<div');
            } else if(blnMainDivStarted) {
                strLatestReply = strLatestReply + '>' + strEmailSection;
                intOpenDivCount = (intOpenDivCount + strEmailSection.countMatches('<div')) - strEmailSection.countMatches('</div');
            }

            if (intOpenDivCount == 0) {
                strLatestReply = strLatestReply + '>';
                break;
            }
        }

        return strLatestReply;
    }

    /**
    * @ author       :  Ankit C
    * @ description  :  This method is used to get the fields from a FieldSet
    * @ params       :  strObjectName - Object API Name
    *                   strFieldSetName - FieldSet Name
    * @ return       :  
    **/
    public static List<Schema.SObjectField> getFieldsFromFieldSet(String strObjectName, String strFieldSetName) {
        List<Schema.SObjectField> list_Fields = new List<Schema.SObjectField>();
        if (String.isNotBlank(strObjectName)) {
            Schema.DescribeSObjectResult objObjectResult = Schema.getGlobalDescribe().get(strObjectName).getDescribe();
            Map<String, Schema.FieldSet> map_FieldsetByName = objObjectResult.fieldSets.getMap();
            if (map_FieldsetByName.containsKey(strFieldSetName)) {
                for (Schema.FieldSetMember objFieldSetMember : map_FieldsetByName.get(strFieldSetName).getFields()) {
                    list_Fields.add(objFieldSetMember.getSObjectField());
                }
            }
        }

        return list_Fields;
    }
}
