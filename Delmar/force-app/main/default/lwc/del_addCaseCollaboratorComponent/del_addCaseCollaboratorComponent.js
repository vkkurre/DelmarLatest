import { api, LightningElement, track, wire } from 'lwc';
import getUserData from '@salesforce/apex/DEL_ContactCollaborationController.getUserData';
import addContactCollaborator from '@salesforce/apex/DEL_ContactCollaborationController.addContactCollaborator';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class customRecordSearch extends LightningElement {
    @api recordId;
    @api strCardTitle;
    strSearchKey = '';
    @track list_Users;
    blnIsLoading = false;
    // Columns to be display for the datatable.
    list_Columns = [
        { 
            label: 'Name', 
            fieldName: 'Name', 
            type: 'text'
        },
        { 
            label: 'User Name', 
            fieldName: 'Username', 
            type: 'text' 
        } ,
        { 
            label: 'Email', 
            fieldName: 'Email', 
            type: 'email' 
        }        
    ];
    
    /**
    * @ author      : Dinesh Chandra
    * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
    **/
    @wire(getUserData, 
    { 
        idCaseId: '$recordId', 
        strUserName: '$strSearchKey'
    })
    wiredUserList(result) {
        this.blnIsLoading = true;
        if (result.data) {
            let objResponse = result.data;
            if (objResponse.blnIsSuccess) {
                this.list_Users = objResponse.list_Users;
                this.blnIsLoading = false;
            } else {
                this.blnIsLoading = false;
                this.showToastMessage('Error', 'error', objResponse.strErrorMessage);
            }
        } else if (result.error) {
            this.blnIsLoading = fasle;
            this.handleErrors(result.error, 'ERROR!');
        }
    }

    /**
    * @ author      : Dinesh Chandra
    * @ description : This Funcation will get the value from Text Input.
    **/
    handelSearchKey(event) {
        this.strSearchKey = event.target.value;
    }

    /**
    * @ author      : Dinesh Chandra
    * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
    **/
    collaborateContactHandler() {
        let list_SelectedRecords = [...this.template.querySelector("lightning-datatable").getSelectedRows()];
        let list_SelectedUserIds = [];
        
        list_SelectedRecords.forEach(objSelectedRecord => {
            list_SelectedUserIds.push(objSelectedRecord.Id);
        });
    
        list_SelectedUserIds = [...new Set(list_SelectedUserIds)];
        if (list_SelectedUserIds) {
            /**
            * @ author      : Dinesh Chandra
            * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
            **/
            this.blnIsLoading = true;
            addContactCollaborator({ 
                list_UserIds: list_SelectedUserIds, 
                idCaseId: this.recordId
            })
            .then((result) => {
                if (result.blnIsSuccess) {
                    this.blnIsLoading = false;
                    this.showToastMessage(
                        'Success',
                        'The selected contacts have been added as collaborators for this Case.',
                        'success'
                    );
                } else {
                    this.blnIsLoading = false;
                    this.showToastMessage('Error', result.strErrorMessage, 'error');
                }
            })
            .catch((error) => {
                this.blnIsLoading = false;
                this.handleErrors(error, 'Error');
            });
         } else {
            this.showToastMessage('Error', 'Please Select a User', 'error');
         }
    }

    /**
    * @ author        : Ankit C
    * @ description   : This method can be called to display toast messages
    **/
    showToastMessage(strTitle, strMessage, strVariant){
        const event = new ShowToastEvent({
            title: strTitle,
            message: strMessage,
            variant: strVariant
        });

        this.dispatchEvent(event);
    }

    /**
    * @ author        : Ankit C
    * @ description   : This method is used to display the errors in apex operations or Javascript
    **/
    handleErrors(error, strTitle) {
        if (error.isArray(error.body)) {
            this.showToastMessage(strTitle, 'error', error.body.map(e=>e.message).join(', '));
        } else {
            this.showToastMessage(strTitle, 'error', error.body.message);
        }
    }
}