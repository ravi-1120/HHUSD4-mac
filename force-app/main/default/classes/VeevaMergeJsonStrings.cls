public with sharing class VeevaMergeJsonStrings {
    public class Input {
        @InvocableVariable(required=true label='List of Json Strings to Merge')
        public List<String> jsonStrings;
    }

    public class Output {
        @InvocableVariable(label='Merged Json String')
        public String mergedJsonString;
    }

    @InvocableMethod
    public static List<Output> mergeJsonStrings(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        for (Input input : inputs) {
            outputs.add(invoke(input));
        }
        return outputs;
    }

    private static Output invoke(Input input) {
        Output output = new Output();
        Map<String, Object> mergedJsonMap = new Map<String, Object>();
        for (String jsonString : input.jsonStrings) {
            if (String.isNotBlank(jsonString)) {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
                mergedJsonMap.putAll(jsonMap);
            }
        }
        output.mergedJsonString = JSON.serialize(mergedJsonMap);
        return output;
    }
}