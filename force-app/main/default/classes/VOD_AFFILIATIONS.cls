public class VOD_AFFILIATIONS {
    static Boolean inAffilTrig = false;
    static Boolean upAffilTrig = false;
    static Boolean isMerge = false;
    static Integer count = 0;
    static List<Boolean> disableTrigger = new List<Boolean>();

    public static void setAfilTrig (Boolean p_inAffilTrig) {
        inAffilTrig = p_inAffilTrig;
    }

    public static Boolean getAfilTrig () {
        return inAffilTrig;
    }

    public static void setUpdAfilTrig (Boolean p_upAffilTrig) {
        upAffilTrig = p_upAffilTrig;
    }

    public static Boolean getUpdAfilTrig () {
        return upAffilTrig;
    }

    public static List<Boolean> getDisableTrigger() {
       return disableTrigger;
    }

    public static void setDisableTrigger(List<Boolean> value) {
       disableTrigger = value;
    }

    public static void setMerge(boolean value) {
        isMerge = value;
    }

    public static Boolean getMerge () {
        return isMerge;
    }

    public static Integer getCount() {
        return count;
    }

    public static void incCount() {
        count++;
    }
}