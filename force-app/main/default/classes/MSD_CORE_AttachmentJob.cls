global class MSD_CORE_AttachmentJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {
        // TODO: have super update the status for the job
        super.execute(opts);

        Map<String,String> ret;
        String op = (String)opts.get('op');
        if (op == 'unpack') {
            ret = unpack(opts);
        }
        super.done(opts);
        return ret;
    }

    public Map<String,String> unpack(Map<String,String> opts) {
        Map<String,String> ret = new Map<String,String>();
        MSD_CORE_Logger.loggingEnabled = true;
        String msg = (String)opts.get('msg');
        MSD_CORE_Logger.debug('MSD_CORE_AttachmentJob.unpack called with msg=' + msg);
        MSD_CORE_Logger.flush();
        return ret;
    }
}