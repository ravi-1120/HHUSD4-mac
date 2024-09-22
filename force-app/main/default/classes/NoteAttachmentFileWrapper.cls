public with sharing class NoteAttachmentFileWrapper {
    public NoteAttachmentFileWrapper(NoteAndAttachment noteAndAttachment) {
        if (noteAndAttachment.IsNote) {
            this.type = 'note';
        } else {
            this.type = 'attachment';
        }
        this.data = noteAndAttachment;
    }

    public NoteAttachmentFileWrapper(ContentDocument file) {
        this.type = 'file';
        this.data = file;
    }

    @AuraEnabled
    public SObject data {
        get; set;
    }

    @AuraEnabled
    public String type { get; set; }

    @AuraEnabled
    public String lastModifiedDate {
        get {
            return ((DateTime)data.get('LastModifiedDate')).format();
        }
    }
}