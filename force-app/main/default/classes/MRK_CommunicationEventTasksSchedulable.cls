global class MRK_CommunicationEventTasksSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
		MRK_CommunicationServices.runCommunicationEventPublish();
	}
}