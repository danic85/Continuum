import { LightningElement, api, track } from 'lwc';

export default class ContinuumSelector extends LightningElement {
    @api engagement;
    @api iconName = 'utility:add';
    @api iconVariant = '';

    get titleClass() {
        return (this.engagement.selected ? 'selected' : '');  
    }

    selectHandler(event) {
        event.preventDefault();
        this.dispatchEvent(new CustomEvent('selected', {detail: this.engagement.id}));
    }
}