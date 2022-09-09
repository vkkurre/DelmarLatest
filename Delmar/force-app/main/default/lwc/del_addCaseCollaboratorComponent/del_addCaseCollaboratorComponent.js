import { api, LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getUsers from "@salesforce/apex/DEL_ContactCollaborationController.fetchUsers";
import createCaseCollaborators from "@salesforce/apex/DEL_ContactCollaborationController.addCaseCollaborators";
import deleteCaseCollaborators from "@salesforce/apex/DEL_ContactCollaborationController.deleteCaseCollaborators";
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
//CLDEL00015 - "Customer Collaborators" (This is a title for Case Collaborator Section in the Case Collaborator Component)
import CLDEL00015 from "@salesforce/label/c.CLDEL00015";
//CLDEL00016 - "Remove" (This is a label Value for Remove Button in the Case Collaborator Component)
import CLDEL00016 from "@salesforce/label/c.CLDEL00016";
//CLDEL00017 - "Successfully removed selected collaborators from this Case." (This is Success Message after successfull removal of Case Collaborator)
import CLDEL00017 from "@salesforce/label/c.CLDEL00017";
//CLDEL00018 - "Search Contacts for this Case" (This is the value for the title in 'Add Case Collaborators Component')
import CLDEL00018 from "@salesforce/label/c.CLDEL00018";

export default class Del_addCaseCollaboratorComponent extends LightningElement {
    @api recordId;
    strCardTitle = CLDEL00018;
    strSearchKey = "";
    strSearchLabelText = CLDEL00010;
    strPlaceHolderValue = CLDEL00011;
    strCollaboratorTitle;
    strRemoveButtonLabel = CLDEL00016;
    @track list_Users;
    @track list_CaseCollaborators;
    blnIsLoading = false;
    blnCollaboratorsAvailable = false;
    @track objWiredResult;
    // Columns to be display for the datatable.
    @track list_Columns = [];

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
                /*Fetching Case Collaborators and setting up data-table*/
                let intCountCaseCollaborators = objResponse.list_CaseCollaborators.length;
                this.strCollaboratorTitle = CLDEL00015 + " (" + intCountCaseCollaborators + ")";
                if (intCountCaseCollaborators > 0) {
                    this.blnCollaboratorsAvailable = true;
                    this.list_CaseCollaborators = JSON.parse(
                        JSON.stringify(objResponse.list_CaseCollaborators)
                    );
                    this.list_CaseCollaborators.forEach((objCaseCollaborator) => {
                        for (let objField of objResponse.list_FieldsWrappers) {
                            objCaseCollaborator[objField.strName] =
                                objCaseCollaborator.User__r[objField.strName];
                        }
                    });
                } else {
                    this.blnCollaboratorsAvailable = false;
                }

                /*Fetching Users and setting up data-table for */
                let list_Columns = [];
                if (objResponse.list_FieldsWrappers) {
                    for (let objField of objResponse.list_FieldsWrappers) {
                        list_Columns.push({
                            label: objField.strLabel,
                            fieldName: objField.strName,
                            type: objField.strType,
                            hideDefaultActions: true
                        });
                    }
                    this.list_Columns = list_Columns;
                }

                this.list_Users = result.data.list_Users;
                let objContactsSection = this.template.querySelector(".contacts-section");
                if (this.list_Users.length === 0) {
                    objContactsSection.classList.remove("del-scrollable-style");
                } else {
                    objContactsSection.classList.add("del-scrollable-style");
                }

                this.blnIsLoading = false;
            } else {
                this.blnIsLoading = false;
                this.showToastMessage(CLDEL00001, objResponse.strErrorMessage, "error");
            }
        } else if (result.error) {
            this.blnIsLoading = false;
            this.handleErrors(result.error, CLDEL00001);
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This Function will make Remove Button disabled/enabled in the component.
     **/
    handleSelectedCollaborators(event) {
        let removeButton = this.template.querySelector(".removeButton");
        if (event.detail.selectedRows.length > 0) {
            removeButton.disabled = false;
        } else {
            removeButton.disabled = true;
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This Function will Remove selected Case Collaborator from the Case.
     **/
    removeCollaboratorHandler(event) {
        let list_SelectedCollaborators = [
            ...this.template.querySelector(".dataTableCollaborators").getSelectedRows()
        ];

        let list_SelectedCollaboratorIds = [];
        list_SelectedCollaborators.forEach((objSelectedCollaborator) => {
            list_SelectedCollaboratorIds.push(objSelectedCollaborator.Id);
        });
        list_SelectedCollaboratorIds = [...new Set(list_SelectedCollaboratorIds)];

        if (list_SelectedCollaboratorIds.length) {
            this.blnIsLoading = true;
            /**
             * @ author      : Vinay kant
             * @ description : This method will call Apex Method to delete Case Collaborators of this Case.
             * @ params      : 'list_SelectedCollaboratorIds' - List of Selected Case Collaborator Ids.
             **/
            deleteCaseCollaborators({
                list_CollaboratorIds: list_SelectedCollaboratorIds
            })
                .then((result) => {
                    if (result.blnIsSuccess) {
                        refreshApex(this.objWiredResult);
                        this.blnIsLoading = false;
                        this.showToastMessage(CLDEL00007, CLDEL00017, "success");
                    } else {
                        this.blnIsLoading = false;
                        this.showToastMessage(CLDEL00001, result.strErrorMessage, "error");
                    }
                })
                .catch((error) => {
                    this.blnIsLoading = false;
                    this.showToastMessage(CLDEL00001, error.body.message, "error");
                });
        }
    }

    /**
     * @ author      : Dinesh Chandra
     * @ description : This Function will get the value from Text Input.
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
            ...this.template.querySelector(".dataTableUsers").getSelectedRows()
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
