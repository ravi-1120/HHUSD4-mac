/**
 * MyInsightsV2HTMLReportOptions is responsible for retrieving HTML Report Options to show to a user
 * on the Lightning App Page. This is done by extending the VisualEditor.DynamicPickList Apex class.
 *
 * Any LWC that sets this Apex class as its datasource will be given the options that are returned
 * by the getValues() method, this Apex class does not set a default value in the getDefaultValue()
 * since null is a valid option when users choose to perform advance configurations around LWCs that
 * take HTML Reports as a property.
 */
public with sharing class MyInsightsV2HTMLReportOptions extends VisualEditor.DynamicPickList {

    private final VisualEditor.DesignTimePageContext context;
    private final MyInsightsVisualEditorConfiguration configuration;

    public MyInsightsV2HTMLReportOptions(VisualEditor.DesignTimePageContext context) {
       this.context = context;
       this.configuration = new MyInsightsVisualEditorConfiguration();
    }
  
    public override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    public override Boolean isValid(Object value) {
        try {
            return ((MyInsightsReportOptionId) JSON.deserialize((String) value, MyInsightsReportOptionId.class)).isValid();
        } catch(Exception e) {
            return false;
        }
    }
  
    public override VisualEditor.DynamicPickListRows getValues() {
        MyInsightsHTMLReportOptionsService optionsService = new MyInsightsHTMLReportOptionsService(this.context);
        return optionsService.sortAndCreateRows(true);
    }
}