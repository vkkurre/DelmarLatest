import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import fetchComments from '@salesforce/apex/DEL_CaseCollaborationController.fetchComments';
import insertComment from '@salesforce/apex/DEL_CaseCollaborationController.insertComment';
import deleteCaseComment from '@salesforce/apex/DEL_CaseCollaborationController.deleteCaseComment';
import updateCaseComment from '@salesforce/apex/DEL_CaseCollaborationController.updateCaseComment';
import getCaseCommentConfigurations from '@salesforce/apex/DEL_CaseCollaborationController.getCaseCommentConfigurations';
import UserId from '@salesforce/user/Id';

export default class Del_caseCollaborationComponent extends NavigationMixin(LightningElement) {
    strBody = "";
    @api recordId;
    @track list_Comments = [];
    blnIsLoading = false;
    blnShowDeleteModal = false;
    blnShowEditModal = false;
    strSelectedCommentId;
    strSelectedComment;
    list_WiredComments; //contains retrieved data and errors from fetchComments(). Used to refresh apex data after insertion.
    idUserId = UserId;
    strTimeInSeconds;
    objCaseCommentConfiguration = {};

    /**
    * @ author      : Vinaykant
    * @ description : This Wire Adapter Fetches the Time Limit Custom Setting for Edit/Delete Menu Option for Case Comments.
    **/
    @wire(getCaseCommentConfigurations)
    getTimeLimit({ error, data }) {
        if (data) {
            this.objCaseCommentConfiguration = data;
            this.strTimeInSeconds = this.objCaseCommentConfiguration.TimeLimitInSeconds__c;
        } else if (error) {
            this.showToastMessage('Error', 'error', error.body.message);
        }
    }
    
    /**
    * @ author      : Rakesh Nayak & Vinaykant
    * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
    **/
    @wire(fetchComments, { strRecordId : '$recordId' })
    commentResults(result) {
        const { error, data } = result;
        this.list_WiredComments = result;
        if (data) {
            if (data.blnIsSuccess) {
                this.list_Comments = JSON.parse(JSON.stringify(data.list_CaseComments));
                let list_CommentsTemp = this.list_Comments;
                for (let objComment of list_CommentsTemp) {
                    /* Adding one more attribute to case comment record object for  
                    determining the current logged-in user and case comment user are same. */
                    if (objComment['CreatedById'] == this.idUserId) {
                        objComment['blnCurrentUser'] = true;
                    } else {
                        objComment['blnCurrentUser'] = false;
                    }

                    /* Adding one attribute to list_comments object to determine case comment should 
                    be editable or not and to add readable format of date. */
                    objComment['blnEdit'] = this.commentTime(objComment['CreatedDate']).blnIsEditable;
                }

                this.list_Comments = list_CommentsTemp;
            } else {
                this.showToastMessage('Error', 'error', data.strErrorMessage);
            }

            this.blnIsLoading = false;
        } else if (error) {
            this.blnIsLoading = false;
            this.handleErrors(error);
        }
    }

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is invoked on the click of submit button and 
                      used to insert the entered comment and refresh the updated comment list
    **/ 
    handleOnClick() {
        if (this.validateComment()) {
            this.handleIsLoading(true);
            this.strBody = this.template.querySelector('.nullify').value;
            /**
            * @ author      : Rakesh Nayak
            * @ description : This method is used to create new Case Comment record using comment 
                              body 'strBody' and case ID 'strRecordId'
            **/
            insertComment({
                strRecordId : this.recordId,
                strBody     : this.strBody
            })
            .then((result) => {
                if(result.blnIsSuccess) {
                    // Nullifying the comment input box after comment is submitted.
                    this.template.querySelector('.nullify').value = null;
                    // Refreshing the comment list.
                    this.updateRecordView();
                    this.showToastMessage('Success', 'success', 'Your comment has been added successfully.');
                } else {
                    this.showToastMessage('Error', 'error', result.strErrorMessage);
                }
                this.handleIsLoading(false);
            })
            .catch (error => {
                this.handleErrors(error, 'ERROR!');
            });
        }
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method restricts the insertion of empty comment by displaying custom validation error.
    **/
    validateComment() {
        let objCommentInputField = this.template.querySelector(".nullify");
        if (!objCommentInputField.value) {
            objCommentInputField.setCustomValidity('Please enter a comment');
            objCommentInputField.reportValidity();
            return false;
        } else {
            objCommentInputField.setCustomValidity('');
            objCommentInputField.reportValidity();
            return true;
        }
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used to control the lightning-spinner based on the value of 'blnIsLoading'
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
    * @ author      : Vinaykant
    * @ description : This Method is capturing Custom Event for closing Edit Modal Box for comment.
    **/
    closeEditModal() {
        this.blnShowEditModal = false;
    }

    /**
    * @ author      : Vinaykant
    * @ description : This Method is capturing Custom Event for closing Delete Modal Box for comment.
    **/
    closeDeleteModal() {
        this.blnShowDeleteModal = false;
    }

    /**
    * @ author      : Vinaykant
    * @ description : This Method is capturing Custom Event from Delete Modal Box to delete Case Comment.
    **/
    saveDeleteChanges(event) {
        this.blnShowDeleteModal = false;
        /**
        * @ author      : Vinaykant
        * @ description : Calling an apex method named 'deleteCaseComment' to delete case comment record.
        **/
        deleteCaseComment({ 
            idCommentId: event.detail 
        }).then(result => {
            if(result.blnIsSuccess) {
                this.showToastMessage('Success', 'success', 'Comment deleted successfully.');
                this.blnIsLoading = true;
                this.updateRecordView();
            } else {
                this.showToastMessage('Error', 'error', result.strErrorMessage);
            }
        }).catch(error => {
            this.handleErrors(error, 'Error Occured while deleting Comment.');
        });
        
    }

    /**
    * @ author      : Vinaykant
    * @ description : This Method is capturing Custom Event from Edit Modal Box to edit Case Comment.
    **/
    saveEditChanges(event) {
        this.blnShowEditModal = false;
        let strCommentMessage = '';
        //Checking if the edited comment is blank, if it's blank it will revert back to previous saved comment.
        if (!(event.detail.commentBody)) {
            strCommentMessage = this.strSelectedComment;
        } else {
            strCommentMessage = event.detail.commentBody;
        }

        /**
        * @ author      : Vinaykant
        * @ description : This Apex Method Call is used to update or edit the changes made by edit option in the case comment.
        **/
        updateCaseComment({
            idCommentId: event.detail.commentId, 
            strComment: strCommentMessage 
        }).then(result => {
            if(result.blnIsSuccess) {
                this.showToastMessage('Success', 'success', 'Comment edited successfully.');
                this.blnIsLoading = true;
                this.updateRecordView();
            } else {
                this.showToastMessage('Error', 'error', result.strErrorMessage);
            }
        }).catch(error => {
            this.handleErrors(error, 'Error Occured while editing Comment.');
        });

    }

    /**
    * @ author      : Vinaykant
    * @ description : This Method is handling the edit menu option from each case comment side button in HTML.
    **/
    editComment(event) {
        this.strSelectedCommentId = event.target.value;
        this.strSelectedComment = event.target.dataset.comment;
        this.blnShowEditModal = true;
    }

    /**
    * @ author      : Vinaykant
    * @ description : This Method is handling the delete menu option from each case comment side button in HTML.
    **/
    deleteComment(event) {
        this.strSelectedCommentId = event.target.value;
        this.blnShowDeleteModal = true;
    }

    /**
    * @ author      : Vinaykant
    * @ description : Function to format the ISO Date Format from apex class to Normal Date Format.
    **/
    commentTime(dtDate) {
        let dtCurrentdate = new Date();
        let dtCommentDate = new Date(Date.parse(dtDate));
        let intSeconds = Math.round((dtCurrentdate.getTime() - dtCommentDate.getTime())/1000);
        let objTimeInfo;

        objTimeInfo = intSeconds >= parseInt(this.strTimeInSeconds) ? 
            objTimeInfo = { blnIsEditable: false } : 
            objTimeInfo = { blnIsEditable: true };

        return objTimeInfo;
    }

    /**
    * @ author        : Rakesh Nayak
    * @ description   : This method is used to display the ShowToast event based on the values of 
    *                   'strTitle', 'strVariant' and 'strMessage'.
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
    **/
    handleErrors(error, strTitle) {
        if (error.isArray(error.body)) {
            this.showToastMessage(strTitle, 'error', error.body.map(e=>e.message).join(', '));
        } else {
            this.showToastMessage(strTitle, 'error', error.body.message);
        }
    }
}