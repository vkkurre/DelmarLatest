import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from "lightning/navigation";
//Custom label for the place holder in comment input field.
import CLDEL00002 from "@salesforce/label/c.CLDEL00002";
//Custom label for the message to indiciate that the comment input field is blank
import CLDEL00003 from "@salesforce/label/c.CLDEL00003";
//Custom label for file download url.
import CLDEL00004 from "@salesforce/label/c.CLDEL00004";
//Custom label for file preview url.
import CLDEL00005 from "@salesforce/label/c.CLDEL00005";
//Custom label for the success message when comment is added.
import CLDEL00006 from "@salesforce/label/c.CLDEL00006";
//Custom label error message title
import CLDEL00001 from "@salesforce/label/c.CLDEL00001";
//Custom label success message title
import CLDEL00007 from "@salesforce/label/c.CLDEL00007";
//Custom label for View Full Message Label in Menu Option.
import CLDEL00012 from "@salesforce/label/c.CLDEL00012";
import fetchComments from "@salesforce/apex/DEL_CaseCollaborationController.fetchComments";
import insertComment from "@salesforce/apex/DEL_CaseCollaborationController.insertComment";

export default class Del_caseCollaborationComponent extends NavigationMixin(LightningElement) {
    strBody = "";
    @api recordId;
    blnValid = true;
    strErrorMessageCommentInput;
    @track list_Comments = [];
    strPlaceHolderText = CLDEL00002;
    strViewFullMessageMenuLabel = CLDEL00012;
    blnIsLoading = false;
    // List that contains retrieved data and errors from fetchComments(). Used to refresh apex data after insertion
    list_WiredComments;

    /**
     * @ author      : Rakesh Nayak & Vinaykant
     * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
     **/
    @wire(fetchComments, { strRecordId: "$recordId" })
    commentResults(result) {
        const { error, data } = result;
        this.list_WiredComments = result;
        if (data) {
            if (data.blnIsSuccess) {
                let list_Attachments = JSON.parse(
                    JSON.stringify(data.map_AttachmentsByCaseCommentId)
                );

                /*Adding two attributes in each attachment of every comment retreived from apex class 
                  in Map Object 'map_AttachmentsByCaseCommentId'. */
                for (var idCaseCommentId in list_Attachments) {
                    let list_AttachmentsTemp = list_Attachments[idCaseCommentId];
                    for (let objAttachment of list_AttachmentsTemp) {
                        objAttachment["strDownloadURL"] =
                            CLDEL00004 + objAttachment.ContentDocumentId;
                        objAttachment["strFileURL"] = CLDEL00005.replace(
                            "{!FileId}",
                            objAttachment.Id
                        );
                    }
                    list_Attachments[idCaseCommentId] = list_AttachmentsTemp;
                }

                this.list_Comments = JSON.parse(JSON.stringify(data.list_CaseComments));
                let list_CommentsTemp = this.list_Comments;
                
                /*Adding attributes in each of the comment retreived from apex class 
                  in List of Object 'DEL_CaseComment__c'. */
                for (let objComment of list_CommentsTemp) {
                    /*Adding one attribute to each of the Case Comment with list of the attachments 
                    file*/
                    if (objComment["Id"] in list_Attachments) {
                        objComment["listAttachments"] = list_Attachments[objComment["Id"]];
                    } else {
                        objComment["listAttachments"] = [];
                    }

                    /*Adding one attribute to each of the Case Comment whether to show View Full
                    Message Menu Option*/
                    objComment["blnMenuOption"] = objComment.hasOwnProperty("EmailMessageId__c");
                }

                this.list_Comments = list_CommentsTemp;
            } else {
                this.showToastMessage(CLDEL00001, "error", data.strErrorMessage);
            }

            this.blnIsLoading = false;
        } else if (error) {
            this.blnIsLoading = false;
            this.handleErrors(error, CLDEL00001);
        }
    }

    /**
     * @ author      : Deeksha Suvarna
     * @ description : This method is invoked on the change of comment text field to store
     *                 the value on 'strBody' variable.
     **/
    handleChangeComment(event) {
        this.strBody = event.target.value;
    }

    /**
    * @ author      : Rakesh Nayak
    * @ description : This method is invoked on the click of submit button and 
                      used to insert the entered comment and refresh the updated comment list
    **/
    handleOnClick() {
        this.blnValid = this.validateComment();
        if (this.blnValid) {
            this.handleIsLoading(true);
            /**
            * @ author      : Rakesh Nayak
            * @ description : This method is used to create new Case Comment record using comment 
                              body 'strBody' and case ID 'strRecordId'
            **/
            insertComment({
                strRecordId: this.recordId,
                strBody: this.strBody
            })
                .then((result) => {
                    if (result.blnIsSuccess) {
                        // Nullifying the comment input box after comment is submitted.
                        this.strBody = "";
                        // Refreshing the comment list.
                        this.updateRecordView();
                        this.showToastMessage(CLDEL00007, "success", CLDEL00006);
                    } else {
                        this.showToastMessage(CLDEL00001, "error", result.strErrorMessage);
                    }
                    this.handleIsLoading(false);
                })
                .catch((error) => {
                    this.handleErrors(error, CLDEL00001);
                });
        }
    }

    /**
     * @ author        : Vinaykant
     * @ description   : This method will navigate user to pages.
     **/
    navigateToRecordPage(event) {
        /**
         * @ author      : Vinaykant
         * @ description : This method is used to navigate to Record Page based recordId.
        **/
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.value,
                actionName: 'view',
            },
        }).then((url) => {
            window.open(url);
        });
    }

    /**
     * @ author        : Rakesh Nayak
     * @ description   : This method restricts the insertion of empty comment by displaying custom validation error.
     **/
    validateComment() {
        if (!this.strBody) {
            this.strErrorMessageCommentInput = CLDEL00003;
            return false;
        } else {
            this.strErrorMessageCommentInput = "";
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
     * @ author        : Rakesh Nayak
     * @ description   : This method is used to display the ShowToast event based on the values of
     *                   'strTitle', 'strVariant' and 'strMessage'.
     **/
    showToastMessage(strTitle, strVariant, strMessage) {
        const event = new ShowToastEvent({
            title: strTitle,
            variant: strVariant,
            message: strMessage
        });
        this.dispatchEvent(event);
    }

    /**
     * @ author        : Rakesh Nayak
     * @ description   : This method is used to display the errors in apex operations or Javascript
     **/
    handleErrors(error, strTitle) {
        if (error.isArray(error.body)) {
            this.showToastMessage(strTitle, "error", error.body.map((e) => e.message).join(", "));
        } else {
            this.showToastMessage(strTitle, "error", error.body.message);
        }
    }
}