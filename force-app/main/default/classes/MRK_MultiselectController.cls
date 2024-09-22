/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_MultiselectController.cls
* @description - MultiselectController synchronizes the values of the hidden elements to the
* SelectOption lists.
* base source code: https://github.com/metadaddy-sfdc/Visualforce-Multiselect-Picklist
* @createdate - Aug 7th, 2014
*
*/

public with sharing class MRK_MultiselectController {
    // SelectOption lists for public consumption
    public SelectOption[] leftOptions { get; set; }
    public SelectOption[] rightOptions { get; set; }
    
    // Parse &-separated values and labels from value and 
    // put them in option
    private void setOptions(SelectOption[] options, String value) {
        options.clear();
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
              EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    
    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden { get; set {
           leftOptionsHidden = value;
           setOptions(leftOptions, value);
        }
    }
    
    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden { get; set {
           rightOptionsHidden = value;
           setOptions(rightOptions, value);
        }
    }
}