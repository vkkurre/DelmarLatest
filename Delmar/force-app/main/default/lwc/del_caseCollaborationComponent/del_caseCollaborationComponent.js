import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { deleteRecord } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";
import fetchComments from "@salesforce/apex/DEL_CaseCollaborationController.fetchComments";
import insertComment from "@salesforce/apex/DEL_CaseCollaborationController.insertComment";
//CLDEL00001 - "Error" (Custom label error message title)
import CLDEL00001 from "@salesforce/label/c.CLDEL00001";
//CLDEL00002 - "Add Comment" (Custom label for the place holder in comment input field)
import CLDEL00002 from "@salesforce/label/c.CLDEL00002";
//CLDEL00003 - "Please add a comment here" (Custom label for the message to indiciate that the comment input field is blank)
import CLDEL00003 from "@salesforce/label/c.CLDEL00003";
//CLDEL00004 - "/sfc/servlet.shepherd/document/download/" (Custom label for file download url)
import CLDEL00004 from "@salesforce/label/c.CLDEL00004";
//CLDEL00005 - "/sfc/servlet.shepherd/version/download/{!FileId}?asInline=true" (Custom label for file preview url)
import CLDEL00005 from "@salesforce/label/c.CLDEL00005";
//CLDEL00006 - "Your comment has been added successfully." (Custom label for the success message when comment is added)
import CLDEL00006 from "@salesforce/label/c.CLDEL00006";
//CLDEL00007 - "Success" (Custom label success message title)
import CLDEL00007 from "@salesforce/label/c.CLDEL00007";
//CLDEL00012 - "View Full Message" (Custom label for View Full Message Label in Menu Option)
import CLDEL00012 from "@salesforce/label/c.CLDEL00012";
//CLDEL00013 - "Visible to Customer	" (Label for Visible to Customer checkbox)
import CLDEL00013 from "@salesforce/label/c.CLDEL00013";
//CLDEL00014 - "Selected files have been added to the comment" (Custom label for success message when files are uploaded)
import CLDEL00014 from "@salesforce/label/c.CLDEL00014";

export default class Del_caseCollaborationComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    @track list_Comments = [];
    // List that contains retrieved data and errors from fetchComments(). Used to refresh apex data after insertion
    @track list_WiredComments;
    // List of files that were uploaded
    @track list_SelectedFiles = [];
    objCurrentUserDetails;
    idCaseCommentId;
    strBody = "";
    strErrorMessageCommentInput;
    strPlaceHolderText = CLDEL00002;
    strViewFullMessageMenuLabel = CLDEL00012;
    strVisibleToCustomerLabel = CLDEL00013;
    blnIsLoading = false;
    blnValid = true;
    blnVisibleToCustomer = true;
    blnCheckboxVisible = false;
    blnVisibleToCustomer = true;
    blnIsRendered = false;
    blnVisibleToCustomerSwitch = false;

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
                if (data.objEmailAlertConfiguration) {
                    this.blnVisibleToCustomerSwitch = data.objEmailAlertConfiguration.VisibleToCustomerSwitch__c;
                }
                
                let objCurrentUser = JSON.parse(JSON.stringify(data.objCurrentUser));

                this.blnCheckboxVisible = !objCurrentUser.IsPortalEnabled;

                let list_Attachments = JSON.parse(
                    JSON.stringify(data.map_AttachmentsByCaseCommentId)
                );

                /** Adding two attributes in each attachment of every comment retreived from apex class 
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

                /** Adding attributes in each of the comment retreived from apex class 
                  in List of Object 'DEL_CaseComment__c'. */
                for (let objComment of list_CommentsTemp) {
                    /** Adding one attribute to each of the Case Comment with list of the attachments 
                    file */
                    if (objComment["Id"] in list_Attachments) {
                        objComment["listAttachments"] = list_Attachments[objComment["Id"]];
                    } else {
                        objComment["listAttachments"] = [];
                    }

                    /** Adding one attribute to each of the Case Comment whether to show View Full
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
     * @ author      : Vinaykant
     * @ description : This method is used to handle the checkbox value to be stored on the variable.
     **/
    handleVisibleToCustomer(event) {
        this.blnVisibleToCustomer = event.target.checked;
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
     *                 used to insert the entered comment and refresh the updated comment list
     **/
    handleOnClick() {
        this.blnValid = this.validateComment();
        if (this.blnValid) {
            this.handleIsLoading(true);
            let list_DocumentIds = [];
            for (let objFile of this.list_SelectedFiles) {
                list_DocumentIds.push(objFile.documentId);
            }

            /**
             * @ author      : Rakesh Nayak
             * @ description : This method is used to create new Case Comment record using comment
             *                 body 'strBody' and case ID 'strRecordId'
             **/
            insertComment({
                strRecordId: this.recordId,
                strBody: this.strBody,
                blnVisibleToCustomer: this.blnVisibleToCustomer,
                list_ContentDocumentIds: list_DocumentIds
            })
                .then((result) => {
                    if (result.blnIsSuccess) {
                        // Nullifying the comment input box after comment is submitted.
                        this.strBody = "";
                        this.blnVisibleToCustomer = true;
                        this.list_SelectedFiles = [];
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
     * @ description   : This method is used to navigate to Record Page based recordId.
     **/
    navigateToRecordPage(event) {
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.target.value,
                actionName: "view"
            }
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
     * @ author        : Rakesh Nayaks
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
     * @ author        : Ankit C
     * @ description   : This method handles the logic to be performed after files are uploaded
     **/
    handleUploadFinished(event) {
        // Get the list of uploaded files
        this.handleIsLoading(true);
        if (this.list_SelectedFiles) {
            for (let objFile of event.detail.files) {
                this.list_SelectedFiles.push(objFile);
            }
        } else {
            this.list_SelectedFiles = event.detail.files;
        }

        this.handleIsLoading(false);
        this.showToastMessage(CLDEL00007, "success", CLDEL00014);
    }

    /**
     * @ author        : Deeksha Suvarna
     * @ description   : This method is used to display the list after removal of unwanted files.
     **/
    handleRemoveFile(event) {
        this.handleIsLoading(true);
        let idRemovedDocumentId = event.target.dataset.item;
        let list_Temp = this.list_SelectedFiles;
        deleteRecord(idRemovedDocumentId)
            .then(() => {
                for (let i = 0; i < list_Temp.length; i++) {
                    if (list_Temp[i].documentId === idRemovedDocumentId) {
                        list_Temp.splice(i, 1);
                    }
                }

                this.list_SelectedFiles = list_Temp;
                this.handleIsLoading(false);
            })
            .catch((error) => {
                this.handleIsLoading(false);
                this.handleErrors(error, CLDEL00001);
            });
    }

    /**
     * @ author        : Rakesh Nayak
     * @ description   : This method is used to display the errors in apex operations or Javascript
     **/
    handleErrors(error, strTitle) {
        if (Array.isArray(error.body)) {
            this.showToastMessage(strTitle, "error", error.body.map((e) => e.message).join(", "));
        } else if (error.body.error) {
            this.showToastMessage(strTitle, "error", error.body.error);
        } else if (error.body.message) {
            this.showToastMessage(strTitle, "error", error.body.message);
        } else {
            this.showToastMessage(strTitle, "error", "Unknown Error");
        }
    }

    /**
     * @ author        : Rakesh Nayak
     * @ description   : This method is used to align the label of file-upload component
     **/
    renderedCallback() {
        if (this.blnIsRendered) {
            return;
        }

        this.blnIsRendered = true;
        const objStyle = document.createElement("style");
        objStyle.innerText = `
            .del-file-upload-css .slds-form-element__label {
                display: none;
            }
        `;

        let list_Templates = this.template.querySelectorAll("lightning-file-upload");
        if (list_Templates && list_Templates.length) {
            list_Templates.forEach((objCurrent) => {
                objCurrent.appendChild(objStyle);
            });
        }
    }
}
