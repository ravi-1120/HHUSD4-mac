({
	handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        $A.get('e.force:refreshView').fire();
    }
})