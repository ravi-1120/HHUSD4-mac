import CreateCallDataFormatter from 'c/createCallDataFormatter';

let DragHelper;

export default function setUpDragHelper(grid, calendar, eventStore, settings) {
    const schedulerGrid = grid;
    const store = eventStore;
    let removedAccount;
    let removedAccountIndex;
    // eslint-disable-next-line no-undef
    DragHelper = class SchedulerPaneDragHelper extends bryntum.calendar.DragHelper {

        static get configurable() {
            return {
                callOnFunctions      : true,
                // Don't drag the actual row element, clone it
                cloneTarget          : true,
                // We size the cloned element manually
                autoSizeClonedTarget : false,
                // Only allow drag of row elements inside on the unscheduled grid
                targetSelector       : '.b-grid-row:not(.b-group-row)'
            };
        }

        createProxy(element) {
            const proxy = document.createElement('div');
            const selected = schedulerGrid.getRecordFromElement(element);
            // save removed account to re-add to store after drop
            removedAccount = selected;
            removedAccountIndex = schedulerGrid.store.indexOf(removedAccount);

            if (schedulerGrid.store.records.length < 1 || schedulerGrid.store.records[0].data.calls) {
                return proxy;
            }

            // eslint-disable-next-line @lwc/lwc/no-inner-html
            proxy.innerHTML = `<div class="b-cal-event b-has-content b-cal-event-withicon">
                <div class="b-cal-event-content drag-proxy">
                <div>${this._getProxyText(selected.data)}</div> 
                </div>
            </div>`;
            return proxy;
        }

        _getProxyText(data) {
            return data['Account-Formatted_Name_vod__c'] || 
                data['Child_Account_vod__c-Parent_Child_Name_vod__c'] || 
                data.Cycle_Plan_Account_vod__r?.Formatted_Name_vod__c || 
                '';
        }

        onDragAbort() {
            this.tip?.hide();
        }

        onDrop(event) {
            const dropDate = calendar.getDateFromDomEvent(event);
            if (!dropDate) { // was not dropped on calendar date
                return;
            }
            const mode = calendar.mode.modeName || calendar.mode;
            if (mode === 'month') {
                const sameDayEvents = Object.values(store.idRegister).filter(e => CreateCallDataFormatter.datesAreSameDay(e.startDate, dropDate)).sort();
                const callInfo = CreateCallDataFormatter.processDataForCreateCall(dropDate, sameDayEvents, false, 30,
                    mode, settings.allowedCallRecordTypes, settings.callBackdateLimit);
                const adjustedStartTime = new Date(CreateCallDataFormatter.adjustStartTime(callInfo));
                calendar.modes.month.autoCreate.startHour = adjustedStartTime.getHours() + adjustedStartTime.getMinutes() / 60;
            }

            // workaround for persisting accounts in the pane after dragging 
            let newId = Math.random();
            while (schedulerGrid.store.findRecord('id', newId)) {
                newId = Math.random();
            }
            newId = `_generatedt_${newId}`;
            removedAccount.id = newId;
            schedulerGrid.store.insert(removedAccountIndex, [removedAccount]);
            
            if (removedAccount) {
                schedulerGrid.deselectRow(removedAccount);
            }
        }
    }

    const helper = new DragHelper({
        containers: [grid, calendar],
        constrain    : false,
        outerElement : grid.element
    });
    return helper;
}