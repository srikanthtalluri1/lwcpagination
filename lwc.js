/* eslint-disable @lwc/lwc/no-async-operation */

import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchFields from '@salesforce/apex/AWP_WaiverHandlerClass.fetchFields';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

import DFP_Complete from '@salesforce/label/c.DFP_Complete';
import DFP_Current from '@salesforce/label/c.DFP_Current';
import DFP_Upcoming from '@salesforce/label/c.DFP_Upcoming';
import pubsub from 'c/pubsub';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['AWP_Architecture_Waiver_Form__c.Status__c'];

export default class CustomHighlightPanel extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api fieldSet;
    @api get recordName() {
        return this._name;
    }
    set recordName(value) {
        if (value) {
            this._name = value;
        }
    }
    _name = '';
    fieldList = [];
    objectLabelName = '';
    intervalId;
    showEditRecordModal = false;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'AWP_Waiver_Relationships__r',
        fields: ['AWP_Waiver_Relationship__c.Id']
    })
    wiredRecords({ error, data }) {
        if (data) {
            this.childRecords = data.records;
        } else if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        pubsub.subscribe('navigate', this.handleNavigate.bind(this));
        console.log('Subscribed to navigate event');
    }

    handleNavigate(event) {
        console.log('event fired 77'+JSON.stringify(event));
        const { recordId, objectApiName, fieldSet} = event;
        this.recordId = recordId;
        this.objectApiName = objectApiName;
        this.fieldSet = fieldSet;

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

    disconnectedCallback() {
        clearInterval(this.intervalId);
    }
    removeHorizontalClass() {
        // this.loading = false;
        this.template.querySelectorAll('lightning-output-field')?.forEach(x => {
            x.classList.remove('slds-form-element_horizontal')
        })
    }

    showToast(title, variant, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message,
        });
        this.dispatchEvent(event);
    }

    handleActions(event) {
        const actionName = event.target.dataset.action;
        switch (actionName) {
            case 'edit':
                console.log('edit');
                this.childRecordId = this.childRecords?.[0].id;
                this.showEditRecordModal = true;
                break;
            default:
                break;
        }
    }

    closeModal() {
        this.showEditRecordModal = false;
    }




    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('data check 129 '+JSON.stringify(data));
            console.log('data check 130 '+data.fields.Status__c.value);
            this.currentStep = data.fields.Status__c.value; 
            this.progressMeth(); // Call your progress method to update the steps
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    @track currentTab = 'Due';
    @track showModal = false;
    @track modalMessage = '';
    nextTab = '';
    pendingTabEvent = null;

    @api indicatorType = 'Path';
    @api stepList='Due,Pending,Approved';
    @api currentStep='';
    @api currentStepPercentage=0;
    showTypeHorizontal;
    pathProgress;
    progressLabel;
    label = {
        DFP_Complete,
        DFP_Current,
        DFP_Upcoming
    };
    showTypeVertical;
    showTypeVertNav;
    showTypeHorizontal;
    showTypePath;
    showTypeBar;
    showTypeRing;
    stepsArray;
    pathProgress;
    stepPercent;
    countTotalSteps;
    countToCurrent;
    progressLabel;


    progressMeth(){
        console.log('Running progressMeth with currentStep:', this.currentStep);

        let indicatorDirty = this.indicatorType;
        let indicatorClean = indicatorDirty.trim().toLowerCase();
        let considerCurrentStepPercentage = false;
        switch (indicatorClean) {
            case 'path':
                this.showTypePath = true;
                break;
            default:
                this.showTypePath = true;
                break; 
        }        
        // convert stepList from string of comma-separated values to an array
        const stepListArray = this.stepList.split(',');
        let countTotalSteps = stepListArray.length;
        let stepsArrayTemp = [];
        let afterCurrent = false;
        let countToCurrent = 0;
        let currentCount = 0;


        if (!this.currentStep) {
            console.warn('Current step is null or undefined. Marking all steps as Upcoming.');
            // All steps should be marked as Upcoming
            for (let i = 0; i < stepListArray.length; i++) {
                let cleanArrayValue = stepListArray[i].trim();
                stepsArrayTemp.push({
                    label: cleanArrayValue,
                    status: 'Upcoming',
                    showCurrent: false,
                    showComplete: false,
                    showUpcoming: true,
                });
            }
            this.stepsArray = stepsArrayTemp;
        }
        else {
            for (let i = 0; i < stepListArray.length; i++) {
                currentCount = i + 1;
                let isFinalStep = false;
                if (currentCount == countTotalSteps) {
                    isFinalStep = true;
                }
                let cleanArrayValue = stepListArray[i].trim();
                if (afterCurrent == false) {
                    // this step might be Completed or Current
                    if (cleanArrayValue == this.currentStep) {
                        if (isFinalStep == true) {
                            switch (indicatorClean) {
                                default:
                                    // this is the current step, but since it is the final one, it is marked as Complete instead
                                    stepsArrayTemp.push({
                                        'label': cleanArrayValue,
                                        'status': 'Complete',
                                        'showCurrent': false,
                                        'showComplete': true,
                                        'showFinalComplete': false,
                                        'showUpcoming': false,
                                        'finalStep': true
                                    });
                                    break;
                            }
                            countToCurrent++;
                        }
                        else {
                            // this is the current step, but it is not the final one (or it's the final one for the vertnav indicator type)
                            stepsArrayTemp.push({
                                'label': cleanArrayValue,
                                'status': 'Current',
                                'showCurrent': true,
                                'showComplete': false,
                                'showUpcoming': false,
                                'finalStep': false
                            });
                            // set afterCurrent to true,
                            // so all subsequent steps
                            // are marked as future
                            afterCurrent = 'true';
                            countToCurrent++;
                        }
                    }
                    else {
                        // this is a completed step
                        stepsArrayTemp.push({
                            'label': cleanArrayValue,
                            'status': 'Complete',
                            'showCurrent': false,
                            'showComplete': true,
                            'showUpcoming': false,
                            'finalStep': isFinalStep
                        });
                        countToCurrent++;
                    }
                }
                else {
                    // this is an upcoming step
                    stepsArrayTemp.push({
                        'label': cleanArrayValue,
                        'status': 'Upcoming',
                        'showCurrent': false,
                        'showComplete': false,
                        'showUpcoming': true,
                        'finalStep': false
                    });
                }
            }
            this.stepsArray = stepsArrayTemp;
        }
    }
}
