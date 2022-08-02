/*******************************************************************************************************
* 
* @ Name            :   DEL_FlowHandler
* @ Purpose         :   Apex class which has methods that can be invoked from Flows.
* @ Author          :   Deeksha
* @ Test Class Name :   DEL_FlowHandlerTest
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   21-07-2022      |  deekshasuvarna@absyz.com     |  1.0          |  Initial Version
*******************************************************************************************************/
public class DEL_FlowHandler {
    
    /**
    * @ author       :  Deeksha
    * @ description  :  This method handles the fetching and replacing the merge field 
    *                   values in the HTMLValue of the Email Template.
    * @ params       :  list_CaseComments - list of CaseComment records
    **/
    @InvocableMethod(label = 'Get HTML body of the case comment email template')
    public static List<String> formHTMLValue(List<DEL_CaseComment__c> list_CaseComments) {
        List<String> list_MergeFields = new List<String>();
        List<String> list_QueryFields = new List<String>();
        List<String> list_CaseCommentFields = new List<String>();
        String strHTML = '';
        try {
            DEL_EmailAlertConfiguration__c objConfiguration = DEL_EmailAlertConfiguration__c.getOrgDefaults();
            list_MergeFields = objConfiguration.MergeFields__c.split(',');
            list_QueryFields = objConfiguration.CaseQueryFields__c.split(',');
            list_CaseCommentFields = objConfiguration.CaseCommentFields__c.split(',');
            String strSiteURL = '';
            
            if (Test.isRunningTest()) {
                strSiteURL = DEL_FlowHandlerTest.getSiteLink();
            } else {
                Site objSite = [SELECT Id FROM Site WHERE Name = :objConfiguration.SiteName__c];
                SiteDetail objSiteDetail = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :objSite.Id];
                strSiteURL = objSiteDetail.SecureURL;
            }
            
            EmailTemplate objTemplate = [SELECT 
                                         Id,
                                         HtmlValue
                                         FROM EmailTemplate
                                         WHERE DeveloperName = :objConfiguration.CaseCommentEmailTemplate__c];
            strHTML = objTemplate.HtmlValue;
            Id idCaseId;
            if (!list_CaseComments.isEmpty()) {
                idCaseId = list_CaseComments[0].Case__c;
            }
            
            String strCaseQuery = 'SELECT Id, ' + objConfiguration.CaseQueryFields__c + ' FROM Case WHERE Id = :idCaseId';
            Id idCaseCommentId; 
            if (!list_CaseComments.isEmpty()) {
                idCaseCommentId = list_CaseComments[0].Id;
            }
            String strCaseCommentQuery = 'SELECT Id, ' + objConfiguration.CaseCommentFields__c + ' FROM DEL_CaseComment__c WHERE Id = :idCaseCommentId';
            Case objCase = Database.query(strCaseQuery);
            DEL_CaseComment__c objCaseComment = Database.query(strCaseCommentQuery);
            Map<String, Object> map_CaseFieldByName = objCase.getPopulatedFieldsAsMap();
            Map<String, Object> map_CaseCommentFieldByName = objCaseComment.getPopulatedFieldsAsMap();
            if (String.isNotBlank(strHTML)) {
                String strField = '';
                String strConvertedDate = '';
                for (String strMergeFieldName : list_MergeFields) {
                    if (strMergeFieldName.contains('SiteLink')) {
                        strHTML = strHTML.replace(strMergeFieldName, strSiteURL + '/' + idCaseId);
                    } else if (strMergeFieldName.contains('{!Case.')) {
                        strField = strMergeFieldName.subString(strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}'));
                        if (map_CaseFieldByName.get(strField) != null) {
                            strHTML = strHTML.replace(strMergeFieldName, (String) map_CaseFieldByName.get(strField));
                        } else {
                            strHTML = strHTML.replace(strMergeFieldName, '');
                        }
                    } else if (strMergeFieldName.contains('{!CaseComment.') && strMergeFieldName.contains('Date')) {
                        strField = strMergeFieldName.subString(strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}'));
                        DateTime dtmDateValue = DateTime.valueOf(map_CaseCommentFieldByName.get(strField));
                        String strDate = dtmDateValue.format('MMMM d');
                        String strTime = dtmDateValue.format('h:mm a z');
                        strHTML = strHTML.replace(strMergeFieldName, strDate + ' at ' + strTime);
                    } else if (strMergeFieldName.contains('{!CaseComment.')) {
                        strField = strMergeFieldName.subString(strMergeFieldName.indexOf('.') + 1, strMergeFieldName.indexOf('}'));
                        if (map_CaseCommentFieldByName.get(strField) != null) {
                            strHTML = strHTML.replace(strMergeFieldName, (String) map_CaseCommentFieldByName.get(strField));
                        } else {
                            strHTML = strHTML.replace(strMergeFieldName, '');
                        }   
                    }
                }
            } 
            
            return new List<String>{ strHTML };
        } catch(Exception objException) {
            DEL_Utils.logException(
                'DEL_FlowHandler',
                'formHTMLValue',
                objException,
                true
            );
            
            return new List<String>();
        }
    }
}