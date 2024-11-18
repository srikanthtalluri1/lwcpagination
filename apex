 @track editStates;
    handleEditDisableButton(event) {
        console.log('event fired 60'+JSON.stringify(event));
        const { recordIdVar, isDisabling } = event;
        // Ensure edit states are maintained per record
        if (!this.editStates) {
            this.editStates = {}; // Initialize if not already done
        }
        this.editStates[recordIdVar] = isDisabling;
        // Update the UI for the specific record
        this.updateDisableEditStateForRecord(recordIdVar);
        //this.disableButton = event;
    }

    updateDisableEditStateForRecord(recordIdVar) {
        const isDisableEditing = this.editStates[recordIdVar] || false;
        if (isDisableEditing) {
            this.disableButton = true;
        } else {
            this.disableButton = false;
        }
    }

    handleEditEnableButton(event) {
        console.log('event fired 83 '+JSON.stringify(event));
        const { recordIdVar, isEnabling } = event;
        // Ensure edit states are maintained per record
        if (!this.editStates) {
            this.editStates = {}; // Initialize if not already done
        }
        this.editStates[recordIdVar] = isEnabling;
        // Update the UI for the specific record
        this.updateEnableEditStateForRecord(recordIdVar);
        //this.disableButton = event;
    }

    updateEnableEditStateForRecord(recordIdVar) {
        const isEnableEditing = this.editStates[recordIdVar] || false;
        if (isEnableEditing) {
            this.disableButton = false;
        } else {
            this.disableButton = true;
        }
    }

    handleNavigate(event) {
        console.log('event fired 77'+JSON.stringify(event));
        const { recordId, objectApiName, fieldSet, editClick} = event;
        this.recordId = recordId;
        this.objectApiName = objectApiName;
        this.fieldSet = fieldSet;
        this.editClick = editClick;

        console.log('this.editClick 111 '+this.editClick);
        if (this.editClick) {
            this.disableButton = true;
        } else {
            this.disableButton = false;
        }

        fetchFields({
            recordId: this.recordId,
            objectName: this.objectApiName,
            fieldSetName: this.fieldSet
        }).then(result => {
            if (result) {
                console.log('result 63'+JSON.stringify(result));
                if (result.message && this.recordId) {
                    this.showToast('Error', 'error', result.message);
                    return;
                }
                // this.nameField = result.nameField;
                this.fieldList = result.fieldsAPI;
                console.log('this.fieldList 70'+JSON.stringify(this.fieldList));
                this.objectLabelName = result.objectLabelName;
                console.log('this.objectLabelName 72'+JSON.stringify(this.objectLabelName));
            }
        }).catch(error => {
            if (error && error.body && error.body.message) {
                this.showToast('Error', 'error', error.body.message);
            }
        });
        this.intervalId = setInterval(() => this.removeHorizontalClass(this), 1);


        this.progressMeth();
    }
