/*
 * CaseControllerMVN 
 * Created By:      Vamsi Krishna
 * Created Date:    23/12/2019
 * Description:     This Class Deals with knowledge related Queries
 * 
 *   
 */

public class MSD_CORE_Knowledge_Contoller {
    
public static List<String> GetAvailableRecordTypeNamesForSObject(Schema.SObjectType objType) {
    List<String> names = new List<String>();
    List<RecordTypeInfo> infos = objType.getDescribe().getRecordTypeInfos();
    // If there are 2 or more RecordTypes...
    if (infos.size() > 1) {
        for (RecordTypeInfo i : infos) {
           if (i.isAvailable() && !String.valueOf(i.getRecordTypeId()).endsWith('AAA'))
                names.add(i.getName());
        }
    } 
    // Otherwise there's just the Master record type,
    // so add it in, since it MUST always be available
    else names.add(infos[0].getName());
    return names;
}
}