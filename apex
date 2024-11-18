console.log('this.editClick', '====', this.editClick);
        pubsub.subscribe('editClick', this.handleEditDisablingButton.bind(this));
        pubsub.subscribe('editClickViewOnly', this.handleEditDisablingButtonViewOnly.bind(this));

    }

    /*handleEditDisablingButton(event) {
        console.log('event fired 190'+JSON.stringify(event));
        this.disablingButton = event;
        if(this.disablingButton){
            this.editClick = false;
        }
        else{
            this.editClick = true;
        }
    }*/

    @track editStates;
    handleEditDisablingButton(event) {
        console.log('Event received: 198 ', JSON.stringify(event));
        const { recordIdVar, isEditing } = event;
        // Ensure edit states are maintained per record
        if (!this.editStates) {
            this.editStates = {}; // Initialize if not already done
        }
        this.editStates[recordIdVar] = isEditing;
        // Update the UI for the specific record
        this.updateEditStateForRecord(recordIdVar);
    }

    updateEditStateForRecord(recordIdVar) {
        const isEditing = this.editStates[recordIdVar] || false;
        if (isEditing) {
            // Enable edit mode for the specific record
            this.editClick = true; // Specific record being edited
            this.disablingButton = false;

            // Fetch waiver details
            fetchWaiverDetails({ recordId: this.recordId })
                .then(data => {
                    if (data) {
                        this.name = data.Name;
                        this.status = data.Status;
                        this.waiverReason = data.waiverReason;
                        //this.rationaleForWaiver = data.RationaleForWaiver;
                        this.renewCounter = data.RenewCounter;
                        //this.originalWaiverSubmissionDate = data.OriginalWaiverSubmissionDate;
                    }
                })
                .catch(error => {
                    console.error('Error fetching waiver details:', error);
                });
        } else {
            // Disable edit mode for the specific record
            this.editClick = false;
            this.disablingButton = true;
        }
    }

    handleEditDisablingButtonViewOnly(event) {
        console.log('Event received: 223 ', JSON.stringify(event));
        const { recordIdVar, isEditingViewOnly } = event;
        // Ensure edit states are maintained per record
        if (!this.editStates) {
            this.editStates = {}; // Initialize if not already done
        }
        this.editStates[recordIdVar] = isEditingViewOnly;
        // Update the UI for the specific record
        this.updateEditStateForRecordViewOnly(recordIdVar);
    }

    updateEditStateForRecordViewOnly(recordIdVar) {
        const isEditing = this.editStates[recordIdVar] || false;
        if (isEditing) {
            // Enable edit mode for the specific record
            this.editClick = true; // Specific record being edited
            this.disablingButton = false;
        } else {
            // Disable edit mode for the specific record
            this.editClick = false;
            this.disablingButton = true;
        }
    }


    @track waiverData = {};
    disablingButton = true;
    handleInputChangeValid(event) {
        const field = event.target.dataset.field;
        this.waiverData[field] = event.target.value;
    }
    handleSave() {
        saveWaiver({ waiverData: this.waiverData, recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Waiver saved successfully.', 'success');
                this.editClick = false;
                this.disablingButton = true;
                //pubsub.publish('saveSuccess', false);

                pubsub.publish('saveSuccess', { recordId: this.recordId, isDisabling: false });

                
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                pubsub.publish('saveSuccess', true);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    handleCancelWaiver(event){
        console.log('oncancel event recordEditForm');
        this.editClick = false;
        this.disablingButton = true;
        //pubsub.publish('saveSuccess', false);

        pubsub.publish('saveSuccess', { recordId: this.recordId, isDisabling: false });
    }
