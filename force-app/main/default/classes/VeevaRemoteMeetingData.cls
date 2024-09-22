public inherited sharing class VeevaRemoteMeetingData {
    public static final Set<String> statusCodes = new Set<String>{'Saved_vod', 'Delivered_vod', 'Sent_vod', 'Scheduled_vod', 'Pending_vod', 'Group_vod', 'Bounced_vod', 'Failed_vod', 'Dropped_vod'};
    public static final Set<String> invitedStatusCodes = new Set<String>{'Saved_vod', 'Delivered_vod', 'Sent_vod', 'Scheduled_vod', 'Pending_vod', 'Group_vod'};
    public Map<String, Boolean> accountInviteStatus { get; set; }
    
    public VeevaRemoteMeetingData() {
        this.accountInviteStatus = new Map<String, Boolean>();
    }

    public Integer getInvitedAttendees() {
        Integer invited = 0;
        for (String Id: accountInviteStatus.keySet()) {
            if (accountInviteStatus.get(Id) == true) {
                invited += 1;
            }
        }
        return invited;
    }

    public Integer getTotalAttendees() {
        return accountInviteStatus.keySet().size();
    }
}