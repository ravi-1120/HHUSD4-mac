import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class CalendarEntryPopoverBuilder extends PopoverBuilderHandler {

    build() {
        this.addSection("popover-event-title", this.fieldLabels.Event.Subject, this.popoverInfo.name);
        this.addSection("popover-event-time", this.popoverMessages.dateLabel, this.popoverInfo.eventDateTime);

        return this.popoverDiv;
    }
}