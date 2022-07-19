import { LightningElement,api,track, wire } from 'lwc';
import fetchComments from '@salesforce/apex/DEL_CommentsPageController.fetchComments';
import insertComment from '@salesforce/apex/DEL_CommentsPageController.insertComment';
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
    
    //fetchComments-this method used to fetch the comments related to the case.
    @wire(fetchComments,{strRecordId : '$recordId'})
    commentResults (result){
        this.list_WiredComments = result;
        if (result.data){
            this.list_Comments = JSON.parse(JSON.stringify(result.data));
        }
        else if (result.error){
            this.handleErrors(error);
        }
    }

    //handleOnClick- this method is invoked on the click comment submission button and used to insert the entered comment and refresh the updated comment list.
    handleOnClick(){
        if (this.validateComment()){
            this.handleIsLoading(true);
            this.strBody = this.template.querySelector('lightning-input').value;
            insertComment({
                strRecordId : this.recordId,
                strBody     : this.strBody
            })
            .then((result)=>{
                if(result.blnIsSuccess){
                    //Toast event to show the success message of comment insertion.
                    this.showToastMessage('SUCCESS','success','Comment added successfully!');
                    //nullifying the comment input box after comment is submitted.
                    this.template.querySelector('.nullify').value = null;
                    //refreshing the comment list.
                    this.updateRecordView();
                }
                else{
                    this.showToastMessage('Error','success',result.strErrorMessage);
                }
                this.handleIsLoading(false);
            })
            .catch (error=>{
                this.handleErrors(error,'ERROR!');
            });

        }
    }

//validateComment- this method restricts the insertion of empty comment.
    validateComment(){
        let CommentInputField = this.template.querySelector(".nullify");
        if (CommentInputField.value == '' || CommentInputField.value == null){
            CommentInputField.setCustomValidity('Enter a comment');
            CommentInputField.reportValidity();
            return false;
        }
        else {
            CommentInputField.setCustomValidity('');
            CommentInputField.reportValidity();
            return true;
        }
    }

//handlsLoading- This method is used to control the lightning spinner during record insertion.
    handleIsLoading(blnIsLoading){
        this.blnIsLoading = blnIsLoading;
    }

//updateRecordView- This method is used to refresh the apex data of comments after insertion of a comment.
    updateRecordView(){
        refreshApex(this.list_WiredComments);
    }

//navigateToUser- This method is used to navigate to user profile on click of his name.
    navigateToUser(event){
        this[NavigationMixin.Navigate]({
            type : 'standard__recordPage',
            attributes : { 
                recordId : event.target.dataset.id,
                actionName : 'view'
            }
        });
    }

//showToastMessage- This method is used to show Toast Messages.
    showToastMessage(strTitle, strVariant, strMessage){
        const event = new ShowToastEvent({
            title   : strTitle,
            variant : strVariant,
            message : strMessage,
        });
        this.dispatchEvent(event);
    }

//handleErrors- this function is used to handle the exceptions and errors in the code.
handleErrors(error, strTitle){
    if (error.isArray(error.body)){
        this.showToastMessage(strTitle, 'error', error.body.map(e=>e.message).join(', '));
    }
    else{
        this.showToastMessage(strTitle, 'error', error.body.message);
    }
}
}