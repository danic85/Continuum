import { LightningElement, wire, api, track } from 'lwc';
import getAvailableEngagements from '@salesforce/apex/ContinuumController.getAvailableEngagements';
import startEngagementEntry from '@salesforce/apex/ContinuumController.startEngagementEntry';
import endEngagements from '@salesforce/apex/ContinuumController.endEngagements';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class ContinuumTracker extends LightningElement {
    @track engagements;
    @track none = {selected: true, name: "No Engagement"};
    @track loading = true;


    connectedCallback() {
        getAvailableEngagements().then(data => {
            this.engagements = data;
            for(let i in this.engagements) {
                if (this.engagements[i]) {
                    if (this.engagements[i].selected === true) {
                        this.none.selected = false;
                    }
                }
            }
            this.loading = false;
        }).catch(error => {
            this.error = error.body.message;
        });
    }

    set error(value) {
        if (!value) return;
        this.fireToastEvent('error', "ERROR", value);
    }

    fireToastEvent(type, title, message) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    userSelection(event) {
        this.loading = true;
        event.preventDefault();
        if (event.detail === null) 
        {
            this.none.selected = true;
            endEngagements().then(() => {
                this.connectedCallback();
            }).catch(error => {
                this.fireToastEvent('error', 'ERROR', error.body.message);
            });
        }
        else this.none.selected = false;

        for(let i in this.engagements) {
            if (this.engagements[i]) {
                if (this.engagements[i].id === event.detail) {
                    startEngagementEntry({engagementId: event.detail}).then(() => {
                        this.connectedCallback();
                    }).catch(error => {
                        this.fireToastEvent('error', 'ERROR', error.body.message);
                    });
                }
            }
        }
    }
}