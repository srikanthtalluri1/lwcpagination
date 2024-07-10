import { LightningElement, wire, track } from "lwc";
import getWaiverRecords from "@salesforce/apex/AWP_WaiverHandlerClass.getWaiverRecordAndPermissions";
// import getWaiverCount from "@salesforce/apex/AWP_WaiverHandlerClass.getWaiverCount";

const COLUMNS = [
    { label: "Name", fieldName: "Name", sortable: true },
    {
        label: "Requesting Portfolio",
        fieldName: "Requesting_Portfolio__c",
        sortable: true
    },
    {
        label: "Affected Standard Portfolio",
        fieldName: "Affected_Standard_Portfolio__c",
        sortable: true
    },
    { label: "Waiver Reason", fieldName: "Waiver_Reason__c", sortable: true },
    { label: "Status", fieldName: "Status__c", sortable: true },
    {
        label: "Standard Page Title",
        fieldName: "Standard_Page_Title__c",
        sortable: true
    },
    { label: "Requesting TPM", fieldName: "Requesting_TPM__c", sortable: true },
    { label: "Application Name", fieldName: "App_Name__c", sortable: true },
    { label: "Renew Counter", fieldName: "Renew_Counter__c", sortable: true }
];

const PAGESIZE = [
    { label: "10", value: 10 },
    { label: "20", value: 20 },
    { label: "30", value: 30 },
    { label: "40", value: 40 },
    { label: "50", value: 50 }
];

export default class AwpWaiverListView extends LightningElement {
    @track records = [];
    columns = COLUMNS;
    isLoading = true;
    currentPage = 1;
    totalRecords;
    totalPages;
    sortedBy = "Requesting_Portfolio__c";
    sortDirection = "asc";
    initialRecords = [];

    // Pagination state
    first = true;
    after = "";
    lastId = "";
    before = "";
    firstId = "";
    last = false;
    lastPageSize = 0;
    currentPageSize = 10;
    // Pagination state

    // @wire(getWaiverCount)
    // getWaiverCount({ data, error }) {
    //     if (data) {
    //         this.totalRecords = data;
    //         this.totalPages = Math.ceil(data / this.currentPageSize);
    //     } else if (error) {
    //         console.error(error);
    //     }
    // }

    // @wire(getWaiverRecords, {
    //     sortBy: "$sortedBy",
    //     sortByType: "String",
    //     sortOrder: "$sortDirection",
    //     pageSize: "$currentPageSize",
    //     first: "$first",
    //     after: "$after",
    //     lastId: "$lastId",
    //     before: "$before",
    //     firstId: "$firstId",
    //     last: "$last",
    //     lastPageSize: "$lastPageSize"
    // })
    // getWaiverRecords({ data, error }) {
    //     this.isLoading = false;
    //     if (data) {
    //         this.initialRecords = data.waiverRecords;
    //         this.records = data.waiverRecords;
    //         this.totalRecords = data.waiverRecordsCount;
    //         this.totalPages = Math.ceil(data.waiverRecordsCount / this.currentPageSize);
    //     } else if (error) {
    //         console.error(error);
    //     }
    // }

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

    connectedCallback() {
        this.fetchData();
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
    }

    handleSearch() {
        this.isLoading = true;
        const searchKey = this.searchKey;
        this.resetPaginationState();
        this.searchKey = searchKey;
        this.currentPage = 1;
        this.fetchData();
    }

    handlePageSize(event) {
        this.currentPageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
        this.isLoading = true;
        this.fetchData();
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        console.log('sortDirection==', sortDirection);
        this.resetPaginationState();
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;
        this.currentPage = 1;
        this.fetchData();
    }

    // sortBy(field, reverse, primer) {
    //     const key = primer
    //         ? function (x) {
    //             return primer(x[field]);
    //         }
    //         : function (x) {
    //             return x[field];
    //         };

    //     return function (a, b) {
    //         a = key(a);
    //         b = key(b);
    //         return reverse * ((a > b) - (b > a));
    //     };
    // }

    handleFirst() {
        this.currentPage = 1;
        this.resetPaginationState();
        this.fetchData();
    }

    handleLast() {
        this.currentPage = this.totalPages;
        this.resetPaginationState();
        this.first = false;
        this.last = true;
        this.lastPageSize = this.totalRecords % this.currentPageSize;
        this.fetchData();
    }

    handleNext() {
        this.currentPage++;
        // this.resetPaginationState();
        const lastRecord = this.records[this.records.length - 1];
        // this.after = lastRecord[this.sortedBy] || "NULL";
        this.lastId = lastRecord.Id;
        this.firstId = "";
        this.first = false;
        this.last = (this.currentPage === this.totalPages);
        this.fetchData();
    }

    handlePrevious() {
        this.currentPage--;
        // this.resetPaginationState();
        const firstRecord = this.records[0];
        // this.before = firstRecord[this.sortedBy] || "NULL";
        this.firstId = firstRecord.Id;
        this.lastId = "";
        this.first = (this.currentPage === 1);
        this.last = false;
        this.fetchData();
    }

    handleReset() {
        this.currentPage = 1;
        this.resetPaginationState();
        this.fetchData();
    }

    resetPaginationState() {
        this.isLoading = true;
        // this.before = "";
        this.firstId = "";
        // this.after = "";
        this.lastId = "";
        this.first = true;
        this.last = false;
        this.lastPageSize = 0;
        this.sortedBy = "Requesting_Portfolio__c";
        this.sortDirection = "asc";
        this.searchKey = "";
        // this.fetchData();
    }

    fetchData() {
        getWaiverRecords({
            searchKey: this.searchKey,
            sortBy: this.sortedBy,
            // sortByType: "String",
            sortOrder: this.sortDirection,
            pageSize: this.currentPageSize,
            first: this.first,
            // after: this.after,
            lastId: this.lastId,
            // before: this.before,
            firstId: this.firstId,
            last: this.last,
            lastPageSize: this.lastPageSize
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

    //Action Buttons
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
}
