(function() {


	var app = angular.module('items', ['ngSanitize']);
	app.controller('ItemsCntrl', function($scope, $timeout) {

		jQuery('input').placeholder();

		var client = new forcetk.Client();
		client.setSessionToken(mrk.cfg.sfdcSessionId);

		$scope.items = [];

		$scope.predicate = 'date';
		$scope.reverse = true;

			/*
			sortTransparent: '//static-01.s3.amazonaws.com/force.com-communications/images/sort_transparent_arrow.gif',
			sortAsc: '//static-01.s3.amazonaws.com/force.com-communications/images/sort_asc_arrow.gif',
			sortDesc: '//static-01.s3.amazonaws.com/force.com-communications/images/sort_desc_arrow.gif'
			*/


		$scope.images = {
			sortTransparent: '//static-01.s3.amazonaws.com/force.com-communications/images/sort-transparent-arrow.png',
			sortAsc: '//static-01.s3.amazonaws.com/force.com-communications/images/sort-asc-arrow.png',
			sortDesc: '//static-01.s3.amazonaws.com/force.com-communications/images/sort-desc-arrow.png'
		};

		function openLink(url) {
			//jQuery('#link-launcher').attr('href', url).click();
			window.open(url, "_blank");
		}

		function selectedItems() {
			var items = [];
			angular.forEach($scope.items, function(e, idx) {
				if (e.selected) {
					items.push(e);
				}
			});
			return items;
		}

		function saveActivity(activities) {

			client.apexrest("/mrk/communication/" + mrk.cfg.userid, function(data) {
					console.log(data);
				}, function(err) {
					console.log(err);
				},
				'PUT',
				angular.toJson({
					"data": {
						"activities": angular.toJson(activities)
					}
				}));

		}

		function deselectAll() {
			angular.forEach($scope.items, function(e, idx) {
				e.selected = false;
			});			
		}

		$scope.markAsRead = function() {
			var activities = [];
			angular.forEach($scope.items, function(e, idx) {
				if (e.selected && e.read !== 'read') {
					e.read = 'read';
					activities.push({
						type: e.type,
						id: e.id,
						read: e.read
					});
				}
			});

			$timeout(function() {
				console.log('deselecting v3');
				deselectAll();
			}, 500);

			console.log(activities);
			saveActivity(activities);
		};

		$scope.markAsUnread = function() {

			var activities = [];

			angular.forEach($scope.items, function(e, idx) {
				if (e.selected && e.read !== 'unread') {
					e.read = 'unread';
					activities.push({
						type: e.type,
						id: e.id,
						read: e.read
					});
				}
			});

			$timeout(function() {
				console.log('deselecting v3');
				deselectAll();
			}, 500);


			console.log(activities);
			saveActivity(activities);
		};

		$scope.toggleSelectAll = function() {

			angular.forEach($scope.items, function(e, idx) {
				e.selected = $scope.allSelected
			});
		};

		$scope.itemSelected = function() {
			var result = false;
			angular.forEach($scope.items, function(e, idx) {
				result = result || e.selected;
			});
			return result;
		};

		$scope.itemListViews = mrk.cfg.viewList;

		var viewFilters = {
			'All': function(e) {
				return true;
			},

			'Unread': function(e) {
				return e.read.toLowerCase() !== 'read';
			},

			'Read': function(e) {
				return e.read.toLowerCase() === 'read';
			},

			'All Action': function(e) {
				return (e.audience.toLowerCase() === 'action');
			},

			'Unread Action': function(e) {
				return (e.read.toLowerCase() !== 'read') && (e.audience.toLowerCase() === 'action');
			},

			'All Background': function(e) {
				return (e.audience.toLowerCase() === 'background');
			},

			'Unread Background': function(e) {
				return (e.read.toLowerCase() !== 'read') && (e.audience.toLowerCase() === 'background');
			}

		};

		
		$scope.filterChanged = function() {

			// clear search
			$scope.search = '';

			$scope.items.length = 0;

			angular.forEach($scope.allItems, function(e, idx) {

				if (viewFilters[$scope.itemFilter](e)) {
					$scope.items.push(e);
				}

			});

		};

		

		$scope.itemClicked = function(e) {
			console.log(e);
			openLink(e.url);
			if (e.read !== 'read') {
				e.read = 'read';
				saveActivity([{
					type: e.type,
					id: e.id,
					read: e.read
				}]);
			}
			//console.log($scope.items[idx].title);
		}

		client.apexrest(mrk.cfg.apexrestItemsSourceURLPrefix + mrk.cfg.userid, function(data) {
			console.log(JSON.parse(data.items));
			console.log(JSON.parse(data.settings));
			$scope.settings = JSON.parse(data.settings);
			$scope.allItems = JSON.parse(data.items);

			angular.forEach($scope.allItems, function(e, idx) {
				$scope.items.push(e);
			});

			$scope.$apply();

			$scope.itemFilter = mrk.cfg.defaultView;
			$scope.filterChanged();
			$scope.$apply();			

		});

		/*
	    	$scope.allItems = [ {
		"type": "communication",
	  "url" : "/apex/MRK_Communication?id=a2eK0000000DAhTIAW",
	  "date" : "2013-08-08",
	  "read" : "unread",
	  "source" : "General;AFLURIA",
	  "title" : "Policy Letter Update",
	  "id" : "a2eK0000000DAhTIAW"
	}, {
		"type": "communication",
	  "url" : "/apex/MRK_Communication?id=a2eK0000000DDLbIAO",
	  "date" : "2013-08-22",
	  "read" : "read",
	  "source" : "General",
	  "title" : "My Comm 1",
	  "id" : "a2eK0000000DDLbIAO"
	}, {
		"type": "data stewardship",
	  "url" : "/apex/MRK_DatastewardshipRequest?id=1",
	  "date" : "2013-03-12",
	  "read" : "unread",
	  "source" : "Account Stewardship",
	  "title" : "Account X",
	  "id" : "1"
	}, {
		"type": "data stewardship",
	  "url" : "/apex/MRK_DatastewardshipRequest?id=2",	
	  "date" : "2013-04-25",
	  "read" : "read",
	  "source" : "Account Stewardship",
	  "title" : "Account Y",
	  "id" : "2"
	}, {
		"type": "data stewardship",
	  "url" : "/apex/MRK_DatastewardshipRequest?id=3",	
	  "date" : "2013-05-03",
	  "read" : "unread",
	  "source" : "Account Stewardship",
	  "title" : "Account QZV",
	  "id" : "3"
	} ];
	*/


	});


})();