import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class UnavailableTimePopoverBuilder extends PopoverBuilderHandler {

    build() {
        this.addSection("popover-unavailable-time", this.popoverMessages.dateLabel, this.popoverInfo.eventDateTime);
        return this.popoverDiv;
    }

    get popoverHeaderText() {
        return this.popoverMessages.unavailableTimeLabel;
    }
}