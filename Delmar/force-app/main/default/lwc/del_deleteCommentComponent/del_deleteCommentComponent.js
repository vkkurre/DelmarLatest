import { LightningElement, api } from 'lwc';

export default class Del_deleteCommentComponent extends LightningElement {
    @api blnShowDeleteModal;
    @api strCommentId;

    /**
    * @ author      : Vinaykant
    * @ description : Creating a custom event for closing this Delete Modal Box.
    **/
    handleCloseButton() {
        this.dispatchEvent(new CustomEvent('close'));
    }
    
    /**
    * @ author      : Vinaykant
    * @ description : Creating a custom event for deleting the current Case Comment.
    **/
    handleSaveButton() {
        let saveEvent = new CustomEvent('save', { detail: this.strCommentId });
        this.dispatchEvent(saveEvent);
    }
}