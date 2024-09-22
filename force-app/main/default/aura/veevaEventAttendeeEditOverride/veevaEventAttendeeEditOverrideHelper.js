/* eslint-disable */
({
    setNewPageProperties: function(component, targetRecord) {
        const pageRef = component.get('v.pageReference');
        const inContextOfRef = JSON.parse(atob(pageRef.state.inContextOfRef.substring(2))) || {};
        const redirectTo = {
            type: 'standard__recordPage',
            attributes: {
                objectApiName: targetRecord.objectApiName,
                recordId: targetRecord.id,
                actionName: 'edit'
            },
            state: {
                backgroundContext: this.getPageRefUrl(inContextOfRef),
                inContextOfRef,
            },
        }
        if (targetRecord.noOverride) {
            redirectTo.state.nooverride = '1';
        }
        component.set('v.pageReference', redirectTo);
    },

    getPageRefUrl: function(pageRef) {
        let url = '';
        let params = '';
        const attrs = pageRef.attributes || {};
        url = `${url}lightning/r/${attrs.objectApiName}/${attrs.recordId}/${attrs.actionName}`;
        if (pageRef.state) {
          Object.keys(pageRef.state).forEach(param => {
            if (typeof pageRef.state[param] === 'object') {
              params = `${params}${param}=${JSON.stringify(pageRef.state[param])}&`;
            } else {
              params = `${params}${param}=${pageRef.state[param]}&`;
            }
          });
        }
        return `/${url}?${params}`;
      }
})