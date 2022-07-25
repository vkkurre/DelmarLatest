import { LightningElement,api,track, wire } from 'lwc';
import fetchComments from '@salesforce/apex/DEL_CaseCollaborationController.fetchComments';
import insertComment from '@salesforce/apex/DEL_CaseCollaborationController.insertComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';	
import { NavigationMixin } from 'lightning/navigation';


export default class Del_commentsPage extends NavigationMixin(LightningElement) {
    strBody = "";
    @api recordId;
    @track list_Comments = [];
    @track blnIsLoading = false;
    strInsertId;
    list_WiredComments; //contains retrieved data and errors from fetchComments(). Used to refresh apex data after insertion.
    
    /**
    * @ author      : Rakesh Nayak
    * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
    * @ params      : 'strRecordId' - Record Id of the Case
    * @ return      : List of DEL_CaseComment__c records
    **/
    @wire(fetchComments, { strRecordId : '$recordId' })
    commentResults (result) {
        this.list_WiredComments = result;
        if (result.data) {
            this.list_Comments = result.data;
        } else if (result.error) {
            this.handleErrors(error);
        }
    }

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is invoked on the click of submit button and used to insert the entered comment and refresh the updated comment list
    **/ 
    handleOnClick() {
        if (this.validateComment()) {
            this.handleIsLoading(true);
            this.strBody = this.template.querySelector('lightning-input').value;
            /**
            * @ author      : Rakesh Nayak
            * @ description : This method is used to create new Case Comment record using comment body 'strBody' and case ID 'strRecordId'
            * @ params      : 'strRecordId' - Record Id of the Case
            *                 'strBody'     - Body of the comment
            * @ return      : Wrapper class object of DEL_DMLHandler
            **/
            insertComment({
                strRecordId : this.recordId,
                strBody     : this.strBody
            })
            .then((result)=> {
                if(result.blnIsSuccess) {
                    //Toast event to show the success message of comment insertion.
                    this.showToastMessage('SUCCESS', 'success', 'Comment added successfully!');
                    //nullifying the comment input box after comment is submitted.
                    this.template.querySelector('.nullify').value = null;
                    //refreshing the comment list.
                    this.updateRecordView();
                } else {
                    this.showToastMessage('Error', 'error', result.strErrorMessage);
                }

                this.handleIsLoading(false);
            })
            .catch (error=> {
                this.handleErrors(error, 'ERROR!');
            });
        }
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method restricts the insertion of empty comment by displaying custom validation error.
    **/
    validateComment() {
        let CommentInputField = this.template.querySelector(".nullify");
        if (CommentInputField.value == '' || CommentInputField.value == null) {
            CommentInputField.setCustomValidity('Enter a comment');
            CommentInputField.reportValidity();
            return false;
        } else {
            CommentInputField.setCustomValidity('');
            CommentInputField.reportValidity();
            return true;
        }
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used to control the lightning-spinner based on the value of 'blnIsLoading'
    * @ params        : 'blnIsLoading'    - Boolean variable to turn on and off the lightning-spinner
    **/
    handleIsLoading(blnIsLoading) {
        this.blnIsLoading = blnIsLoading;
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used to update all the comments after insertion of new comment
    **/
    updateRecordView() {
        refreshApex(this.list_WiredComments);
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used used to navigate to the user's profile on click of name of user
    * @ params        : 'event'    - triggering event with click of name having 'id' attribute as CreatedById of that case comment
    **/
    navigateToUser(event) {
        this[NavigationMixin.Navigate]({
            type : 'standard__recordPage',
            attributes : { 
                recordId : event.target.dataset.id,
                actionName : 'view'
            }
        });
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used to display the ShowToast event based on the values of 'strTitle', 'strVariant' and 'strMessage'
    * @ params        : 'strTitle'    - Title of ShowToast event
    *                   'strVariant'  - Type of ShowToast event
    *                   'strMesssage' - Message to be displayed on the ShowToast event
    **/
    showToastMessage(strTitle, strVariant, strMessage) {
        const event = new ShowToastEvent({
            title   : strTitle,
            variant : strVariant,
            message : strMessage,
        });
        this.dispatchEvent(event);
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used to display the errors in apex operations or Javascript
    * @ params        : 'error'    - Single or Array of errors
    *                   'strTitle' - Body of the comment
    **/
    handleErrors(error, strTitle) {
        if (error.isArray(error.body)) {
            this.showToastMessage(strTitle, 'error', error.body.map(e=>e.message).join(', '));
        } else {
            this.showToastMessage(strTitle, 'error', error.body.message);
        }
    }
}