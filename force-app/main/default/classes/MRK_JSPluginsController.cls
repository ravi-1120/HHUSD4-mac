/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_JSPluginsController.cls
* @description - Controller class for JS Plugins page
* @createdate - Mar 31st, 2014
*
*/

public without sharing class MRK_JSPluginsController {

	public String jsCode {get; set;}

	public MRK_JSPluginsController() {
		// TODO: create JS_PLUGINS Merck setting
		// add all data from setting into dataMap
		// put a switch in to enable/ disable
		// * everything
		// * hiding of homepage component sidebar module
		// * just specific plugins
		Map<String,String> dataMap = new Map<String,String>();
		String userid = UserInfo.getUserId();
		User u = [select ProfileId, Profile.Name from user where Id = :userid];
		dataMap.put('userid', userid);
		dataMap.put('profileId', u.ProfileId);
		dataMap.put('profileName', u.Profile.Name);
		dataMap.put('script', MRK_StaticResourceUtil.getResourceURL('mrk_jsplugins') + '/lib/app.js');
		jsCode = 'window.com_merck_sfdc_data_payload = ' + JSON.serializePretty(dataMap) + ';\n';
		jsCode += 'jQuery.getScript(window.com_merck_sfdc_data_payload.script);';

	}


}