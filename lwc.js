/* eslint-disable no-case-declarations */
/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, track } from 'lwc';
import getWaiverRecords from '@salesforce/apex/AWP_WaiverHandlerClass.getWaiverRecordAndPermissions';
import getFilterDetails from '@salesforce/apex/AWP_WaiverHandlerClass.getFilterDetails';
import getUniqueValues from '@salesforce/apex/AWP_WaiverHandlerClass.getUniqueValues';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', sortable: true },
    {
        label: 'Requesting Portfolio',
        fieldName: 'Requesting_Portfolio__c',
        sortable: true
    },
    {
        label: 'Affected Standard Portfolio',
        fieldName: 'Affected_Standard_Portfolio__c',
        sortable: true
    },
    { label: 'Waiver Reason', fieldName: 'Waiver_Reason__c', sortable: true },
    { label: 'Status', fieldName: 'Status__c', sortable: true },
    {
        label: 'Standard Page Title',
        fieldName: 'Standard_Page_Title__c',
        sortable: true
    },
    { label: 'Requesting TPM', fieldName: 'Requesting_TPM__c', sortable: true },
    { label: 'Application Name', fieldName: 'App_Name__c', sortable: true },
    { label: 'Renew Counter', fieldName: 'Renew_Counter__c', sortable: true },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View', name: 'view' }
            ]
        },
    }
];

const PAGESIZE = [
    { label: '10', value: 10 },
    { label: '20', value: 20 },
    { label: '30', value: 30 },
    { label: '40', value: 40 },
    { label: '50', value: 50 }
];

export default class AwpWaiverListView extends LightningElement {
    @track records = [];
    columns = COLUMNS;
    isLoading = true;
    currentPage = 1;
    totalRecords;
    totalPages;
    sortedBy = 'Requesting_Portfolio__c';
    sortedDirection = 'asc';
    initialRecords = [];
    selectedWaiver = 'mywaivers';
    _tableSize = '12';
    showFilter = false;
    showRecord = false;
    recordId;
    @track _filterOptions = {
        options: [],
        selectedFilter: []
    };
    filterBy = [];
    @track _filteredFieldValues = [];
    selectedFilterValues = [];
    isLoadingFilter = false;
    filters = [];

    // Pagination state
    first = true;
    after = '';
    lastId = '';
    before = '';
    firstId = '';
    last = false;
    lastPageSize = 0;
    currentPageSize = 10;
    // END

    get noRecordsFound() {
        return this.records.length === 0;
    }

    get pageSizeOptions() {
        return PAGESIZE;
    }

    get showPaginationBar() {
        return this.totalPages > 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get rowNumberOffset() {
        return (this.currentPage - 1) * this.currentPageSize;
    }

    get waiverOptions() {
        return [
            { label: 'My Waivers', value: 'mywaivers' },
            { label: 'All Waivers', value: 'allwaivers' }
        ];
    }

    get tableSize() {
        return this._tableSize;
    }

    get rowActions() {
        return [
            { label: 'View', name: 'view' }
        ];
    }

    get filterOptions() {
        return this._filterOptions;
    }

    get filteredFieldValues() {
        return this._filteredFieldValues;
    }

    get showFilterValues() {
        return this._filteredFieldValues.length > 0;
    }

    connectedCallback() {
        this.fetchData();
        this.fetchFilterDetails();
    }

    handleSearch(event) {
        window.clearTimeout(this.delayTimeout);
        this.searchKey = event.target.value.toLowerCase() ?? '';
        this.delayTimeout = setTimeout(() => {
            this.isLoading = true;
            this.resetPaginationState();
            this.currentPage = 1;
            this.fetchData();
        }, 300);

    }

    handleReset(event) {
        if (!event.target.value) {
            this.currentPage = 1;
            this.searchKey = '';
            this.resetPaginationState();
            this.fetchData();
        }
    }

    handlePageSize(event) {
        this.currentPageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
        this.isLoading = true;
        this.fetchData();
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection: sortedDirection } = event.detail;
        console.log('sortedDirection==', sortedDirection);
        this.resetPaginationState();
        this.searchKey = '';
        this.sortedDirection = sortedDirection;
        this.sortedBy = sortedBy;
        this.currentPage = 1;
        this.fetchData();
    }

    handleFirst() {
        this.currentPage = 1;
        this.resetPaginationState();
        this.searchKey = '';
        this.fetchData();
    }

    handleLast() {
        this.currentPage = this.totalPages;
        this.resetPaginationState();
        this.searchKey = '';
        this.first = false;
        this.last = true;
        this.lastPageSize = this.totalRecords % this.currentPageSize;
        this.fetchData();
    }

    handleNext() {
        this.currentPage++;
        const lastRecord = this.records[this.records.length - 1];
        this.after = lastRecord[this.sortedBy] || 'NULL';
        this.before = '';
        this.lastId = lastRecord.Id;
        this.firstId = '';
        this.first = false;
        this.last = (this.currentPage === this.totalPages);
        this.fetchData();
    }

    handlePrevious() {
        this.currentPage--;
        const firstRecord = this.records[0];
        this.before = firstRecord[this.sortedBy] || 'NULL';
        this.after = '';
        this.firstId = firstRecord.Id;
        this.lastId = '';
        this.first = (this.currentPage === 1);
        this.last = false;
        this.fetchData();
    }

    resetPaginationState() {
        this.isLoading = true;
        this.before = '';
        this.firstId = '';
        this.after = '';
        this.lastId = '';
        this.first = true;
        this.last = false;
        this.lastPageSize = 0;
        this.sortedBy = 'Requesting_Portfolio__c';
        this.sortedDirection = 'asc';
    }

    fetchData() {
        getWaiverRecords({
            searchKey: this.searchKey,
            sortBy: this.sortedBy,
            sortOrder: this.sortedDirection,
            pageSize: this.currentPageSize,
            first: this.first,
            after: this.after,
            lastId: this.lastId,
            before: this.before,
            firstId: this.firstId,
            last: this.last,
            lastPageSize: this.lastPageSize,
            allOrMy: this.selectedWaiver,
            filters: JSON.stringify(this.filters)
        }).then((data) => {
            if (this.initialRecords.length === 0) {
                this.initialRecords = data.waiverRecords;
            }
            this.records = data.waiverRecords;
            this.totalRecords = data.waiverRecordsCount;
            this.totalPages = Math.ceil(data.waiverRecordsCount / this.currentPageSize);
            this.isLoading = false;
        }).catch((error) => {
            console.error(error);
            this.isLoading = false;
        });
    }

    async fetchFilterDetails() {
        let result = await getFilterDetails();
        if (result) {
            const filterOptions = result.filterOptions;
            this._filterOptions.options = filterOptions;
        }
    }

    //Action Buttons
    handleActions(event) {
        const actionName = event.target.dataset.action ? event.target.dataset.action : (event.detail.action.name ? event.detail.action.name : '');
        if (actionName) {
            switch (actionName) {
                case 'newwaiver':
                    this.handleNewWaiver();
                    break;
                case 'home':
                    this.handleHome();
                    break;
                case 'contactus':
                    this.handleContactUs();
                    break;
                case 'faq':
                    this.handleFAQ();
                    break;
                case 'help':
                    this.handleHelp();
                    break;
                case 'view':
                    this.handleView(event);
                    break;
                case 'close':
                    this.handleView(event);
                    break;
                case 'applyfilter':
                    this.handleFilterBy(actionName);
                    break;
                case 'resetfilter':
                    this.handleFilterBy(actionName);
                    break;
                case 'selectedValues':
                    this.handleFilterBy(actionName, event);
                    break;
                case 'selectedfiltervalue':
                    this.handleFilterBy(actionName, event);
                    break;
                case 'filterbyexpand':
                    this.handleFilterBy(actionName, event);
                    break;
                default:
                    break;
            }
        }
    }

    // Action Methods
    handleNewWaiver() {
        // Add logic for handling New Waiver button click
    }

    handleHome() {
        // Add logic for handling Home button click
    }

    handleContactUs() {
        // Add logic for handling Contact Us button click
    }

    handleFAQ() {
        // Add logic for handling FAQ button click
    }

    handleHelp() {
        // Add logic for handling Help button click
    }

    handleWaiverChange(event) {
        this.currentPage = 1;
        this.searchKey = '';
        this.resetPaginationState();
        this.selectedWaiver = event.detail.value;
        this.loading = true;
        this.fetchData();
    }

    handleFilter(showFilter) {
        this.showFilter = showFilter;
        this.showRecord = false;
        if (this.showFilter) {
            this._tableSize = '10';
        } else {
            this._tableSize = '12';
        }
    }

    handleView(event) {
        this.showRecord = !this.showRecord;
        this.showFilter = false;
        if (this.showRecord) {
            this.recordId = event.detail.row.Id;
            this.columns = [...COLUMNS.slice(0, 1)];
            this._tableSize = '2';
        } else {
            this._tableSize = '12';
            this.columns = [...COLUMNS];
        }
    }

    handleFilterBy(actionName, event) {
        let filterValue = event ? event.detail.value : null;
        const index = event ? parseInt(event.target.dataset.index, 10) : null;
        switch (actionName) {
            case 'applyfilter':
                console.log('applyfilter');
                this.filters = this._filteredFieldValues.map(x => {
                    return {
                        [x.filterFieldApiName]: x.selectedValue
                    }
                });
                this.fetchData();
                break;
            case 'resetfilter':
                this.filterBy = [];
                this.selectedFilterValues = [];
                this._filteredFieldValues = [];
                const options = this._filterOptions.options.map(x => {
                    x.selected = false;
                    return x;
                });
                this._filterOptions.options = [...options];
                this.handleFilter(false);
                console.log('resetfilter');
                this.filters = [];
                this.fetchData();
                break;
            case 'selectedfiltervalue':
                console.log('selectedfiltervalue');
                this._filteredFieldValues.filter(x => x.id === index)[0].selectedValue = filterValue;
                break;
            case 'filterbyexpand':
                console.log('filterbyexpand');
                this._filteredFieldValues.filter(x => x.id === index)[0].showValues = !this._filteredFieldValues.filter(x => x.id === index)[0].showValues;
                this._filteredFieldValues.filter(x => x.id === index)[0].icon = (this._filteredFieldValues.filter(x => x.id === index)[0].showValues) ? 'utility:dash' : 'utility:add';
                break;
            case 'selectedValues':
                filterValue = event.detail.selectedValues;
                if (filterValue.length) {
                    this._filterOptions.selectedFilter = filterValue;
                    this.handleFilter(true);
                    this.isLoadingFilter = true;
                    getUniqueValues({ fieldApiName: filterValue }).then((data) => {
                        const values = (data) ? Object.keys(data).map(x => {
                            return {
                                [x]: data[x].map((val) => {
                                    return { label: (val.value + ' (' + val.count + ')'), value: val.value };
                                })
                            }
                        }) : [];
                        let filteredFieldValues = values.map((x, ind) => {
                            return {
                                id: ind,
                                filterField: (this.filterOptions.options.filter(t => t.value === Object.keys(x)[0])[0].label),
                                filterFieldApiName: Object.keys(x)[0],
                                filteredFieldValue: Object.values(x)[0],
                                showValues: false,
                                selectedValue: [],
                                icon: 'utility:add'
                            }
                        });
                        this._filteredFieldValues = [...filteredFieldValues];
                        this.isLoadingFilter = false;
                    }).catch((error) => {
                        console.error(error);
                        this.isLoadingFilter = false;
                    });
                } else {
                    this._filterOptions.selectedFilter = [];
                }

                break;
            default:
                break;
        }
    }

}
