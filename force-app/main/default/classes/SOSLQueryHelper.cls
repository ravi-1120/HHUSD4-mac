public class SOSLQueryHelper {
    private static final Set<String> SOSL_RESERVED_CHARACTERS_SET = new Set<String>{'?','&','|','!','{','}','[',']','(',')','^','~','*',':','\\','"','\'','+','-'};

    public String escapeSpecialCharacters(String str) {
        String escapedStr = '';
        Integer i = 0;
        while (i < str.length()) {
            String c = str.substring(i, i+1);
            if (SOSL_RESERVED_CHARACTERS_SET.contains(c)) {
                c = '\\' + c;
            }
            escapedStr += c;
             i += 1;
        }
        return escapedStr;
    }
    
    public List<String> addWildcardToTerms(List<String> terms) {
        List<String> termsWithWildcards = new List<String>();
        for (String term : terms) {
            termsWithWildcards.add(term + '*');
        }
        return termsWithWildcards;
    }
}