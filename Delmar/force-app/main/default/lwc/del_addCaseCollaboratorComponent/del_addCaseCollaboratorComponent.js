import { api, LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getUsers from "@salesforce/apex/DEL_ContactCollaborationController.fetchUsers";
import createCaseCollaborators from "@salesforce/apex/DEL_ContactCollaborationController.addCaseCollaborators";
//CLDEL00001 - "Error" (Custom label error message title)
import CLDEL00001 from "@salesforce/label/c.CLDEL00001";
//CLDEL00007 - "Success" (Custom label success message title)
import CLDEL00007 from "@salesforce/label/c.CLDEL00007";
//CLDEL00008 - "The selected contacts have been added as collaborators for this Case." (Success message)
import CLDEL00008 from "@salesforce/label/c.CLDEL00008";
//CLDEL00009 - "Please select atleast one User" (Custom label for error message for having atleast one user selected)
import CLDEL00009 from "@salesforce/label/c.CLDEL00009";
//CLDEL00010 - "Enter Contact Name To Search" (Custom label for search input text label for searching case collaborator user)
import CLDEL00010 from "@salesforce/label/c.CLDEL00010";
//CLDEL00011 - "Search" (Placeholder for Contact search input)
import CLDEL00011 from "@salesforce/label/c.CLDEL00011";

export default class Del_addCaseCollaboratorComponent extends LightningElement {
    @api recordId;
    @api strCardTitle;
    strSearchLabelText = CLDEL00010;
    strPlaceHolderValue = CLDEL00011;
    strSearchKey = "";
    @track list_Users;
    blnIsLoading = false;
    @track objWiredResult;
    // Columns to be display for the datatable.
    list_Columns = [
        {
            label: "Name",
            fieldName: "Name",
            type: "text"
        },
        {
            label: "User Name",
            fieldName: "Username",
            type: "text"
        },
        {
            label: "Email",
            fieldName: "Email",
            type: "email"
        }
    ];

    /**
     * @ author      : Dinesh Chandra
     * @ description : Method to fetch all the users associated to the Account for the Case..
     **/
    @wire(getUsers, {
        idCaseId: "$recordId",
        strUserName: "$strSearchKey"
    })
    wiredUserList(result) {
        this.objWiredResult = result;
        this.blnIsLoading = true;
        if (result.data) {
            let objResponse = result.data;
            if (objResponse.blnIsSuccess) {
                this.list_Users = result.data.list_Users;
                this.blnIsLoading = false;
            } else {
                this.blnIsLoading = false;
                this.showToastMessage(CLDEL00001, "error", objResponse.strErrorMessage);
            }
        } else if (result.error) {
            this.blnIsLoading = false;
            this.handleErrors(result.error, CLDEL00001);
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
        let list_SelectedRecords = [
            ...this.template.querySelector("lightning-datatable").getSelectedRows()
        ];
        let list_SelectedUserIds = [];

        list_SelectedRecords.forEach((objSelectedRecord) => {
            list_SelectedUserIds.push(objSelectedRecord.Id);
        });

        list_SelectedUserIds = [...new Set(list_SelectedUserIds)];
        if (list_SelectedUserIds.length) {
            /**
             * @ author      : Dinesh Chandra
             * @ description : This method queries and returns the CaseComment records related to the case with Id 'recordID'
             **/
            this.blnIsLoading = true;
            createCaseCollaborators({
                list_UserIds: list_SelectedUserIds,
                idCaseId: this.recordId
            })
                .then((result) => {
                    if (result.blnIsSuccess) {
                        refreshApex(this.objWiredResult);
                        this.blnIsLoading = false;
                        this.showToastMessage(CLDEL00007, CLDEL00008, "success");
                    } else {
                        this.blnIsLoading = false;
                        this.showToastMessage(CLDEL00001, result.strErrorMessage, "error");
                    }
                })
                .catch((error) => {
                    this.blnIsLoading = false;
                    this.handleErrors(error, CLDEL00001);
                });
        } else {
            this.showToastMessage(CLDEL00001, CLDEL00009, "error");
        }
    }

    /**
     * @ author        : Ankit C
     * @ description   : This method can be called to display toast messages
     **/
    showToastMessage(strTitle, strMessage, strVariant) {
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
            this.showToastMessage(strTitle, "error", error.body.map((e) => e.message).join(", "));
        } else {
            this.showToastMessage(strTitle, "error", error.body.message);
        }
    }
}