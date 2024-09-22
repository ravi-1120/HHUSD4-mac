/**
 * example URL to load app
 * 	/apex/MRK_AppLoader?stylesheets=//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css,//static-01.s3.amazonaws.com/projects/angularjs-base-template/styles.css&scripts=https://localhost:35729/livereload.js?snipver=1,//static-01.s3.amazonaws.com/projects/angularjs-base-template/libs.js,//static-01.s3.amazonaws.com/projects/angularjs-base-template/app.js
 * 	/apex/MRK_AppLoader?stylesheets=//static-01.s3.amazonaws.com/projects/angularjs-base-template/styles.css&scripts=https://localhost:35729/livereload.js?snipver=1,//static-01.s3.amazonaws.com/projects/angularjs-base-template/libs.js,//static-01.s3.amazonaws.com/projects/angularjs-base-template/app.js
 */
public class MRK_AppLoaderController {

	private Map<string,string> pageParams = ApexPages.currentPage().getParameters();

	public MRK_AppLoaderController() {
		
	}

	public String getDebugOutput() {
		return JSON.serializePretty(pageParams);
	}


	public List<String> getStylesheets() {
		return pageParams.get('stylesheets').split(',');
		/*
		return new List<String>{
			'//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css',
			'//static-01.s3.amazonaws.com/projects/angularjs-base-template/styles.css'
		};
		*/
	}

	public List<String> getScripts() {
		return pageParams.get('scripts').split(',');
		/*
		return new List<String>{
			'https://localhost:35729/livereload.js?snipver=1',
			'//static-01.s3.amazonaws.com/projects/angularjs-base-template/libs.js',
			'//static-01.s3.amazonaws.com/projects/angularjs-base-template/app.js'
		};
		*/
	}

}