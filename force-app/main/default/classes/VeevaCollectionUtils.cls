public class VeevaCollectionUtils {
    public static List<List<Object>> splitList(List<Object> sourceRecords, Integer splitSize, Type returnType){
        List<List<Object>> result;
        if(sourceRecords != null && splitSize > 0 && returnType != null) {
            result = (List<List<Object>>)returnType.newInstance();
            List<Object> emptyList = sourceRecords.clone();
            emptyList.clear();
            List<Object> tempList = emptyList.clone();
            Integer index = 0, count = 0, size = sourceRecords.size();
            while(index < size) {
                tempList.add(sourceRecords.get(index++));
                ++count;
                if(count == splitSize) {
                    result.add(tempList);
                    tempList = emptyList.clone();
                    count = 0;
                }
            }
            if(!tempList.isEmpty()) {
                result.add(tempList);
            }
        }
        return result;
    }
}