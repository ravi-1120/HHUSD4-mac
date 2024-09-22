global class MSD_CORE_SchSCHybridUserProcessor implements Schedulable {
    global void execute(SchedulableContext SC) {
        MSD_CORE_SCHybridUserProcessor hybridProcessor = new MSD_CORE_SCHybridUserProcessor();
        hybridProcessor.processHybridUsers();
    }

}