({
    objectToComponentNameMap: {
        Expense_Header_vod__c: 'c:emPageControllerFactory',
        Expense_Line_vod__c: 'c:emPageControllerFactory',
    },

    loadPageControllerFactory: function(component) {
        const objectApiName = component.get('v.objectApiName');
        const componentName = this.getPageControllerFactoryName(objectApiName)
        if (componentName) {
            this.createComponent(component, componentName);
        } else {
            const loadedEvent = component.getEvent('pageCtrlFactoryLoadedEvent');
            loadedEvent.fire();
        }
    },

    getPageControllerFactoryName: function(objectApiName) {
        let componentName = this.objectToComponentNameMap[objectApiName];
        if (!componentName) {
            if (this.isEM(objectApiName)) {
                componentName = 'c:emPageControllerFactory';
            }
        }
        return componentName;
    },

    isEM: function(objectApiName) {
        return objectApiName.startsWith('EM_');
    },

    createComponent: function(component, type) {
        $A.createComponent(
            type,
            {},
            this.createComponentCallback(component)
        );
    },

    createComponentCallback: function(component) {
        return function(newComponent, status, errorMessage) {
            if (status === 'INCOMPLETE') {
                console.error('loading page controller factory incomplete: ' + errorMessage);
            } else if (status === 'ERROR') {
                console.error('loading page controller factory error: ' + errorMessage);
            }
            const loadedEvent = component.getEvent('pageCtrlFactoryLoadedEvent');
            loadedEvent.fire();
        }.bind(this);
    },
})