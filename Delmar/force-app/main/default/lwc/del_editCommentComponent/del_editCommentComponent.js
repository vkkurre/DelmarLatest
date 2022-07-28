import { LightningElement, api } from 'lwc';

export default class Del_editCommentComponent extends LightningElement {
    @api blnShowEditModal;
    @api strCommentId;
    @api strComment;

    /**
    * @ author      : Vinaykant
    * @ description : Handling changes/edit on the Case Comment in the Edit Modal Box.
    **/
    handleComValueChanges(event) {
        this.strComment = event.target.value;
    }

    /**
    * @ author      : Vinaykant
    * @ description : Creating custom event for saving changes made to Case Comment.
    **/
    handleSaveButton() {
        let objInfo = { 
                        commentId: this.strCommentId, 
                        commentBody: this.strComment 
                      };
        let saveEvent = new CustomEvent('save', { detail : objInfo });
        this.dispatchEvent(saveEvent);
    }

    /**
    * @ author      : Vinaykant
    * @ description : Creating custom event for closing the Edit Modal Box.
    **/
    handleCloseButton() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}