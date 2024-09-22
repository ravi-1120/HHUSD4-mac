public with sharing class VeevaCalendarObjectThemeInfoHelper {

    private static Map<String, String> getThemeInfoFromArrays(List<IconDefinition> iconArray, List<ColorDefinition> colorArray) {
        String iconResult = '';
        String colorResult = '';
        String theme = '';

        for (IconDefinition icon : iconArray) {
            if (String.isNotBlank(icon.Url) && (String.isBlank(iconResult) || icon.Url.endsWithIgnoreCase('120.png') || 
                (!iconResult.endsWithIgnoreCase('120.png') && icon.Url.containsIgnoreCase('/custom/')))) {
                iconResult = icon.Url;
                theme = icon.Theme;
            }
        }
        for (ColorDefinition c : colorArray) {
            if (String.isNotBlank(c.Color) && (String.isBlank(colorResult) || c.Theme == theme)) {
                colorResult = c.Color;
            }
        }
        return new Map<String, String>{'iconUrl' => iconResult, 'color' => colorResult};
    }

    public static Map<String, Map<String, String>> getObjectIcons(List<String> desiredObjects){
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        List<TabDefinition> tabResults = [SELECT SObjectName, (SELECT Url, Theme FROM Icons), (SELECT Color, Theme FROM Colors) FROM TabDefinition WHERE SObjectName IN :desiredObjects];

        for (TabDefinition tab : tabResults) {
            if (!tab.Icons.isEmpty()) {
                String objectName = tab.SObjectName == 'Event' ? 'default' : tab.SObjectName;
                result.put(objectName, getThemeInfoFromArrays(tab.Icons, tab.Colors));
            }
        }
        return result;
    }

    public static Map<String, String> getEventObjectThemeInfo() {
        String eventApiName = Event.getSObjectType().getDescribe().getName();
        VeevaBaseObject eventBaseObject = VeevaBaseObject.create(eventApiName);
        if (eventBaseObject == null) {
            return null;
        }
        Map<String, Map<String, String>> eventIconInfo = getObjectIcons(new List<String>{eventApiName});
        return (!eventIconInfo.isEmpty()) ? eventIconInfo.values()[0] : null;
    }
}