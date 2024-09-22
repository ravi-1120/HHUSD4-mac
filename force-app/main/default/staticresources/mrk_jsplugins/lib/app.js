(function() {

	window.console = window.console || {log: function() {}};

	jQuery.noConflict();
	jQuery(function($) {

		if (console && console.log) {
			console.log('UI override homepage component posting a heartbeat!');
		}

		var app = {

			l: function(o) {
				if (window.location.href.match(/001U00000065yU1/) !== null) {
					//alert((new Date()).getTime() + ': ' + o);
				}
			},

			run: function() {
				//this.hideThisSidebarHomepageComponent();

				try {
					if (window.com_merck_sfdc_data_payload) {
						app.context = window.com_merck_sfdc_data_payload;
						app.l(app.context.profileName);			
						this.installPluginsWrapper();	
					}
					
				} catch (e) {
					console.log('error invoking installPluginsWrapper\n' + e)
				}

			},

			data: {
				nonApprovedAccountPlanStatuses: ['Draft', 'Submitted', 'Revisions Required'],
				approvalObjectNames: ['Coaching Report', 'Account Plan']
			},

			hideThisSidebarHomepageComponent: function() {
				// hide *this* sidebar homepage component
				$("h2:contains('MRK_UI_Override')").parent().parent().hide();
			},

			userCanSeeAccountPlansOfAnyStatus: function() {
				 return !( (app.context.profileName === 'MRK - Sales Representative') || (app.context.profileName === 'MRK - Sales Manager') )
			},

			containsAccountPlansToRemove: function($table) {
				var match = false;

				for (var i = 0; i < app.data.nonApprovedAccountPlanStatuses.length; i++) {
					var status = app.data.nonApprovedAccountPlanStatuses[i];
					match = match || ( $table.find("td:contains('" + status + "')").size() > 0 );
				}

				$table.find("tr").each(function() {
					var $e = $(this);
					match = match || ( ( $e.find("td:contains('Approved')").size() > 0 ) && ( $e.find("td img[title='Not Checked']").size() > 0 ) );
				});

				return match;
			},


			plugins: [
				{
					name: 'account | account plan related list',
					fingerprint: function() {
						
						if ( app.userCanSeeAccountPlansOfAnyStatus() ) {
							return false;
						}

						var $table = $("h3:contains('Account Plans')").closest('.pbHeader').siblings('.pbBody').find('table');
						return app.containsAccountPlansToRemove($table);

					},
					run: function() {
                        var that = this;
					    var $relatedListBody = $("h3:contains('Account Plans')").closest('.pbHeader').siblings('.pbBody');
					    var $showMoreContainer = $relatedListBody.find('div.pShowMore');
					    if ($showMoreContainer.size() > 0) {
					        var rowCount = $relatedListBody.find('table').find('tr').size();
					        // click link to load additional rows
					        $showMoreContainer.find('a').first().get(0).click();
					        var int = setInterval(function() {
					            console.log('checking for additional rows loaded ...');
					            
					            if ($("h3:contains('Account Plans')").closest('.pbHeader').siblings('.pbBody').find('div.pShowMore').size() == 0) {
					               that.applyRules();
					               clearInterval(int);    
					            }
                                
					        }, 200);
					    } else {
					       this.applyRules();    
					    }

					},

					applyRules: function() {

						var $table = $("h3:contains('Account Plans')").closest('.pbHeader').siblings('.pbBody').find('table');

						for (var i = 0; i < app.data.nonApprovedAccountPlanStatuses.length; i++) {
							var status = app.data.nonApprovedAccountPlanStatuses[i];
							app.l(this.name + ': removing account plans with status of ' + status);

							$table.find("td:contains('" + status + "')").parent().remove();
						}	

						$table.find("tr").each(function() {
							var $e = $(this);
							if ( ( $e.find("td:contains('Approved')").size() > 0 ) && ( $e.find("td img[title='Not Checked']").size() > 0 ) ) {
								$e.remove();
							}
						});

						
						// update "Account Plans [<count>]" at top of page
						var visibleRowsCount = $table.find("td").parent().size();

						if (visibleRowsCount == 0) {
							$table.find("tr").parent().html('<tr class="headerRow"><th scope="col" class="noRowsHeader">No records to display</th></tr>');
						}

						$("span.listTitle:contains('Account Plans')").find('span.count').text('[' + visibleRowsCount + ']');
												
					}
				},

				{
					name: 'remove reassign link from items to approve',
					fingerprint: function() {

						return $("h3:contains('Items to Approve')").size() > 0;
					},
					run: function() {
						
						// remove Manage All button
						$("h3:contains('Items to Approve')").closest('tr').find("input[value='Manage All']").css('visibility', 'hidden');

						for (var i = 0; i < app.data.approvalObjectNames.length; i++) {
							var objectName = app.data.approvalObjectNames[i];
							$("h3:contains('Items to Approve')").closest('.pbHeader').siblings('.pbBody').find("td:contains('" + objectName + "')").parent().each(function() {
								var $e = $(this);
								$e.children().first().children().first().html('');
								//$e.children().first().contents().get(1).remove();
								// remove the '|' between Reassign | Approve/Reject 
								$e.children().first().contents().filter(function () { return this.nodeType === 3; }).remove();
								
							});
						}
						
					}
				},

				{
					name: 'remove reassign button and link from items to approve view',
					fingerprint: function() {

						return $("h1:contains('Items to Approve')").size() > 0;
					},
					run: function() {
						
						// hide the Reassign buttion
						$("input[value='Reassign']").hide();

						for (var i = 0; i < app.data.approvalObjectNames.length; i++) {
							var objectName = app.data.approvalObjectNames[i];
							$('.homeBlock .pbBody').find("td:contains('" + objectName + "')").parent().find('.actionColumn').each(function() {
								var $e = $(this);
								$e.find('a').first().remove();

								$e.children().first().children().first().html('');
								//$e.children().first().contents().get(1).remove();
								// remove the '|' between Reassign | Approve/Reject 
								$e.contents().filter(function () { return this.nodeType === 3; }).remove();
								
							});
						}
						
					}
				}


			],

			installPlugins: function(context) {

				$.each(this.plugins, function(i, p) {
					p.context = context;
					if (p.fingerprint.call(p) && !p.installed) {
						console.log('installing plugin: ' + p.name);
						p.run.call(p);
						p.installed = true;
					}
				});

			},

			installPluginsWrapper: function(context) {
	
				var self = this;
				self.installPlugins(context);

				var counter = 0;
				var interval = setInterval(function() {
					self.installPlugins(context);
					counter += 1;
					if (counter > 200) {
						clearInterval(interval);
					}
				}, 100);

			}

		};

		app.run();
	
	});


})();

		//getUserInfo();
		
		/*
		function getUserInfo() {

		    // //raw.github.com/carhartl/jquery-cookie/master/jquery.cookie.js
		    // '/soap/ajax/29.0/connection.js'

		    $.getScript('/soap/ajax/30.0/connection.js', function() {

					$.getScript('//raw.github.com/carhartl/jquery-cookie/master/jquery.cookie.js', function() {

				    sforce.connection.sessionId = jQuery.cookie('sid');
				    sforce.connection.getUserInfo(function(result) {
				    	console.log(result.userId);

				    	function onSuccess(result) {
				    		console.log(result);
				    	}

				    	var onFailure = onSuccess;

				    	sforce.connection.query("select ProfileId from User where Id = '" + result.userId + "'", {onSuccess: onSuccess, onFailure: onFailure});

				    });
		    	
		    	})

		    });
		    
		}

		function isOverridePage() {

				return ( $('.mainTitle').text().match(/account plan/i) != null ) && 
				( ( $('input[value="Submit for Approval"]').size() > 0 ) ||
		        ( $('input[value="Recall Approval Request"]').size() > 0 ) );

		}

		if ( isOverridePage() ) {

			var $submitForApprovalButtons = $('input[value="Submit for Approval"]');
			$submitForApprovalButtons.each(function() {
			   var $e = $(this);
			   console.log('overriding onclick handler');
			   $e.get(0).onclick = function() {
			       var resp = confirm('Once you submit this record for approval, you might not be able to edit it or recall it from the approval process depending on your settings. Continue?');
			       if (resp) {
							  var objectId = location.pathname.replace('/', '');
							  document.location.href = '/apex/MRK_ApproverSelector?id=' + objectId;
			       }
			   };
			});
	
		}
		*/

