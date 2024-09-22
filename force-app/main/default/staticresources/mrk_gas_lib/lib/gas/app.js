/*
TODO -


* scroll to search results section
* clear messages on each new request
* sort
* iPad - [Go] keyboard button triggers search

*/
(function () {
	"use strict";
	var $ = jQuery,
	app = window.app = {


		run: function() {

			var templatesString = $.trim($('#templates').html());
			templatesString = <%= tmpl %>;
			app.tmpls = app.parseTemplates( templatesString );

			var base = app.tmpls.base;
			delete app.tmpls['base'];
			var partials = app.tmpls;

			/*console.log('reading cookie');
			var defaultGasSearch = readCookie('defaultGasSearch');
			console.log('defaultGasSearch is: ' + defaultGasSearch);
			if (defaultGasSearch == 'business') {
				$('#search-organizations').trigger('click');
			}  else {
				$('#search-individuals').trigger('click');
			}*/

			$('#tablet-version-container').html( Mustache.to_html(base, {}, partials) );

			// populate picklist option values
			$.each(app.searchFields, function(idx, sf) {
				var name = sf.apiQualifiedFieldName;
				var $e = $('#' + name);
				if ($e.size() == 0) {
					return;
				}

				if (sf.is_picklist === 'true') {
					var options = JSON.parse(sf.picklist_options);
					app.options = options;
					$e.empty();
					$.each(options, function(i, opt) {
						$e.append( $("<option value='" + opt.value + "'>" + ((i == 0) ? "--" + sf.label + "--" : opt.label) + "</option>") );
					});
				}

			});

			// populate sort by list
			var $sort = $('#sort-by-field');
			$sort.empty();
			$.each(app.searchFields, function(idx, sf) {
				$sort.append( $("<option value='" + ((sf.obj === 'Address_vod__c') ? 'ADD_' : '')  + sf.apiname + "'>" + sf.label + "</option>") );
			});

			$('input[type=text]').each(function() {
				var $e = $(this);
				//$e.val( $.attr('placeholder') );
				$e.css({color: 'grey'})
			});

			$('#search-individuals').click(function() {
				console.log('setting cookie: person');
				createCookie('defaultGasSearch','person',3650);
				$('input[type="text"]').val('');
				console.log('clearing inputs');
				$('.individual-fields').show();
				$('.organization-fields').hide();

			});

			$('#search-organizations').click(function() {
				console.log('setting cookie: business');
				createCookie('defaultGasSearch','business',3650);

				var sPageURL = window.location.search.substring(1);
				var paramFound = 'N';
				if(sPageURL.search('ANI=')>=0 || sPageURL.search('SAP_ID=')>=0) paramFound='Y';

				if(paramFound=='N'){
					$('input[type="text"]').val('');
				}
				console.log('clearing inputs');
				$('.organization-fields').show();
				$('.individual-fields').hide();
			});



			$('.align-account').live('click', function() {
			    app.selectedAccount = {Id: $(this).data('account-id'), Name: $(this).data('account-name')};
			    $('#align-account-dialog h2').text(app.selectedAccount.Name);
			    $.mobile.changePage('#align-account-dialog');
			    return false;
			});

			var alignmentRequestInProgress = false;

			$('#request-temporary-alignment').live('click', function() {
					if (alignmentRequestInProgress) { console.log('preventing multiple alignment requests'); return false; }
			    alignmentRequestInProgress = true;

			    $.mobile.changePage('#main');
			    setTimeout(function() {
		            $.mobile.loading( 'show', {text: 'Aligning ...', textonly: false, textVisible: true} );
		            console.log('calling temporaryAlignmentRequest(' + app.selectedAccount.Id + ')');
		            $('#user-messages').hide();
			        temporaryAlignmentRequest(app.selectedAccount.Id);
			        alignmentRequestInProgress = false;
			    }, 500);
			    return false;
			});

			$('#request-oneday-alignment').live('click', function() {
					if (alignmentRequestInProgress) { console.log('preventing multiple alignment requests'); return false; }
			    alignmentRequestInProgress = true;

			    $.mobile.changePage('#main');
			    setTimeout(function() {
		            $.mobile.loading( 'show', {text: 'Aligning ...', textonly: false, textVisible: true} );
			        console.log('calling oneDayAlignmentRequest(' + app.selectedAccount.Id + ')');
			        $('#user-messages').hide();
			        oneDayAlignmentRequest(app.selectedAccount.Id);
			        alignmentRequestInProgress = false;
			    }, 500);
			   return false;
			});


			$('#reset-btn').live('click', function() {
			    $.mobile.changePage('#main');
			    setTimeout(function() {
		            $.mobile.loading( 'show', {text: 'Reseting Search ...', textonly: false, textVisible: true} );
		            console.log('calling refreshPageRequest');
		            $('#user-messages').hide();
			        refreshPageRequest();
			    }, 500);
			    return false;
			});


			$('#request-permanent-alignment').live('click', function() {
					if (alignmentRequestInProgress) { console.log('preventing multiple alignment requests'); return false; }
			    alignmentRequestInProgress = true;

			    $.mobile.changePage('#main');
			    setTimeout(function() {
		            $.mobile.loading( 'show', {text: 'Aligning ...', textonly: false, textVisible: true} );
			        console.log('calling permanentAlignmentRequest(' + app.selectedAccount.Id + ')');
			        $('#user-messages').hide();
			        permanentAlignmentRequest(app.selectedAccount.Id);
			        alignmentRequestInProgress = false;
			    }, 500);
			   return false;
			});

			$('.dialog-information').live('click', function() {
				$.mobile.changePage('#main');
				return false;
			});

			$('#search-form').submit(function() {
			    app.search();
			    $('#search-btn').focus();
			    return false;
			});


			$('#search-btn').click(function() {
			    app.search();
			    return false;
			});



			$('#request-new-account').hide();
			//$('input, textarea').placeholder();

			$.each(app.searchFields, function(idx, sf) {
				var name = sf.apiQualifiedFieldName;
				var $src = $('#' + name);


				if ($src.size() === 0) {
					return;
				}

				if ($src.get(0).tagName.toLowerCase() === 'input') {
					$src.placeholder();
				}
			});

			$('#sort-by-field').change(function() {
				var $e = $(this);

				var sortField = $e.val();
				var sortAsc = true;
				app.ui.sortAccountList(sortField, sortAsc);
				app.ui.updateSortDirection(sortAsc);
			});

			$('#sort-direction').click(function() {
				var $e = $(this);
				var $icon = $e.find('.ui-icon');
				var sortAsc = $icon.hasClass('ui-icon-arrow-d');
				app.ui.updateSortDirection(sortAsc);
			});

			$('input[type=radio]').each(function() {
				var $e = $(this);
				if ($e.val().toLowerCase() === 'contains') {
					$e.attr('checked', true);
				} else {
					$e.attr('checked', false);
				}

			});

		},

		parseTemplates: function(templatesString) {

			var templateName = null;
			var templates = {};
			$.each(templatesString.split("\n"), function(i, line) {
				var matches = line.match(/(.*)\.mustache\:/i);
				if (matches !== null) {
					templateName = $.trim(matches[1]);
				} else {
					templates[templateName] = templates[templateName] || [];
					templates[templateName].push(line);
				}
			});

			$.each(templates, function(k,v) {
				templates[k] = v.join("\n");
			});
			return templates;
		},

	    execute: function(result) {
	        app.result = result;
	        console.log('execute(result.type=' + result.type + ')');
	        console.log(result);

	        app.ui.displayUserMessages(result);

	        switch(result.type) {

	        	case 'searchMetadata':
	        		app.searchFields = result.data;
	        	break;

	            case 'searchResults':
	            	app.ui.renderSearchResults(result);
	            	$.mobile.loading( 'hide' );
	            break;

	            case 'alignmentResults':
	            	$.mobile.loading( 'hide' );
	            	app.ui.renderAlignmentResults(result.data);
	            break;
	        }


	    },

	    search: function() {

	    	if (!app.ui.hasSearchCriteria()) {
	    		app.ui.displayUserMessages({success: false, messages: ['Please enter search criteria']});
	    		return;
	    	}

	    	var searchInputValidationFailedFields = [];
			$('input[type=text]').each(function() {
				var $e = $(this);
				var val = $.trim( $e.val() );
				if ( (val.length != 0) && (val.length < 2) ) {
					searchInputValidationFailedFields.push( $e.attr('placeholder') );
				}
			});

			if (searchInputValidationFailedFields.length > 0) {
				var messages = [];
				$.each(searchInputValidationFailedFields, function(i, e) {
					messages.push('Your search criteria for \"' + e + '\" must contain 2 or more characters');
				});
				app.ui.displayUserMessages({success: false, messages: messages});
				return;
			}


		    $.mobile.loading( 'show', {text: 'Searching ...', textonly: false, textVisible: true} );

			$.each(app.searchFields, function(idx, sf) {
				var name = sf.apiQualifiedFieldName;
				var $src = $('#' + name);

				if ($src.size() === 0) {
					return;
				}

				if ($src.val() === $src.attr('placeholder')) {
					return;
				}

				if ($src.get(0).tagName.toLowerCase() === 'select') {
					if ( $src.find('option').first().val() === $src.val() ) {
						console.log('value of select list is ' + $src.val() + ' which is the label.  Not setting');
						return;
					}
				}

				var $dest = $('.apiname-' + name);
				$dest.val( $.trim( $src.val() ) );


				// set field match type radios
				var $radios = $dest.parent().parent().find('input[type=radio]');
				if ($radios.size() > 0) {

					var matchType = $src.parent().find('select').val();

					if (matchType != null) {

					$radios.each(function() {
						var $r = $(this);
						if ($r.val().toLowerCase() === matchType.toLowerCase()) {
							$r.attr("checked", "checked");
						} else {
							$r.removeAttr("checked");
						}
					});


					}
				}
			});

			var searchType = $('#search-individuals').hasClass('ui-btn-active') ? 'Individuals' : 'Organization';
			console.log('calling search(' + searchType + ')');
		    search( (searchType === 'Individuals' ? true : false), (searchType === 'Individuals' ? false : true));
	    },

	    data: {

	    	tranformSearchResults: function(objs) {
	        	$.each(objs, function(i,o) {
	        		o = app.data.transformAccountResult(o);

	        		$.each(o.otherAddrs, function(i, o) {
	        			o = app.data.transformAccountResult(o);
	        		});

	        	});
	        	return objs;
	    	},

	    	transformAccountResult: function(o) {
	        	$.each(o.srFields, function(idx, f) {
	        		o[f['apiname'].replace("ADD.", "ADD_")] = f['value'];
	        	});
	        	return o;
	    	}

	    },

	    ui: {

	    	hasSearchCriteria: function() {
	    		var hasCriteria = false;
				$.each(app.searchFields, function(idx, sf) {
					var name = sf.apiQualifiedFieldName;
					var $src = $('#' + name);

					if ($src.size() === 0) {
						return;
					}

					if ($src.val() === $src.attr('placeholder')) {
						return;
					}

					if ($src.get(0).tagName.toLowerCase() === 'select') {
						if ( $src.find('option').first().val() === $src.val() ) {
							console.log('value of select list is ' + $src.val() + ' which is the label.  Not setting');
							return;
						}
					}

					var $dest = $('.apiname-' + name);

					hasCriteria = hasCriteria || ( $.trim( $src.val() ).length > 0 );

				});
				return hasCriteria;
	    	},

	    	displayUserMessages: function(result) {
	    		var $e = $('#user-messages');
	    		$e.removeClass('alert alert-error alert-success');
	    		$e.addClass('alert alert-' + ((result.success === 'true') ? 'success' : 'error') );
	            if (result.messages && result.messages.length > 0) {

	            	$e.html('');
	            	var $ul = $('<ul/>')
	            	$.each(result.messages, function(idx, msg) {
	            		$ul.append('<li>' + msg + '</li>');
	            	});
	            	$e.append($ul);
	            	$e.show();
	            } else {
	            	$e.hide();
	            }

	    	},

	        renderSearchResults: function(result) {
	        	var objs = app.data.tranformSearchResults(result.data);
	        	app.data.accounts = objs;

	        	$('#results-section, #request-new-account').show();
	            app.ui.renderAccountList(objs);

						// set forground color to Red for Status Reason == 'Pending'
						$('strong:contains("PENDING")').css({color: 'red'});
						$('strong:contains("Pending")').css({color: 'red'});
						$('strong:contains("INACTIVE")').css({color: 'red'});
						$('strong:contains("Inactive")').css({color: 'red'});
						$('strong:contains("NEED MORE INFO")').css({color: 'red'});
						$('strong:contains("Need More Info")').css({color: 'red'});


	            if (objs.length > 0) {
					$('html, body').animate({
		         		scrollTop: $("#begin-search-results").offset().top
		     		}, 500);
	            }


	            // location.href = '#begin-search-results';
	        },

	        renderAccountList: function(objs) {

	        	$('#begin-search-results').html("Results - Found " + objs.length + " Match(es)")

	            var $c = $('#search-results-container');
	            $c.empty();

	            $.each(objs, function(i, o) {
	    	        $('#search-results-container').append( Mustache.to_html(app.tmpls['account.row'], o) );
	            });
	            $c.trigger('create');
	        },

	        sortAccountList: function(sortField, sortAsc) {
				app.data.accounts = app.data.accounts.sort(function(a1, a2) {
					var val1 = a1[sortField] ? a1[sortField] : "";
					var val2 = a2[sortField] ? a2[sortField] : "";

					if (val1 > val2) {
						return (sortAsc ? 1 : -1);
					} else if (val1 < val2) {
						return (sortAsc ? -1 : 1);
					} else {
						return 0;
					}

				});

				app.ui.renderAccountList(app.data.accounts);
	        },

	        updateSortDirection: function(sortAsc) {
				var $e = $('#sort-direction');
				var $icon = $e.find('.ui-icon');
				var $buttonText = $e.find('.ui-btn-text');
				$icon.removeClass('ui-icon-arrow-u ui-icon-arrow-d');
				var cls = (sortAsc ? 'ui-icon-arrow-u' : 'ui-icon-arrow-d');
				$icon.addClass(cls);
				app.ui.sortAccountList( $('#sort-by-field').val(), sortAsc);
				$buttonText.text(sortAsc ? 'ascending' : 'decending');
	        },

	        'renderAlignmentResults': function(result) {
	        	// var html = Mustache.to_html(app.tmpls['dialog.information'], {title: 'Alignment Successful', message: '<strong>' + app.selectedAccount.Name + '</strong> has been successfully aligned'});
	        	// var $d = $(html);

	        	// $.mobile.changePage($d);
	        }

	    }

	};

	jQuery(function($) {
		//livereload.reloadPageIfScriptChanges(/app\.js/, 2000);
		app.run();


	});

	jQuery('#main').live( 'pagecreate',function(event){

		// fix sort by layout to be inline
		setTimeout(function() {
			$('#sort-by-field').parent().parent().css({display: 'inline'});
			$('#sort-by-field').parent().children().first().find('.ui-icon').remove();

			$('#search-form fieldset').before( $('<input type="submit" style="margin-left: -1000px"></input>') );


			var inANI = '';
			var inSAP = '';
		    var sPageURL = window.location.search.substring(1);
			var sURLVariables = sPageURL.split('&');


			for (var i = 0; i < sURLVariables.length; i++)
			{
				var sParameterName = sURLVariables[i].split('=');
				if (sParameterName[0] == 'ANI')
				{
					 inANI = sParameterName[1];
					 $('#Address_vod__c-Phone_vod__c').val(inANI);
				}
				if(sParameterName[0] =='SAP_ID')
				{
					inSAP =sParameterName[1];
					$('#Account-Searchable_Id_MRK__c').val(inSAP);
				}
			}



			console.log('reading cookie');
			var defaultGasSearch = readCookie('defaultGasSearch');
			console.log('defaultGasSearch is: ' + defaultGasSearch);

			if(inANI == '' && inSAP ==''){
				if (defaultGasSearch == 'business') {
						$('#search-organizations').trigger('click');
				}  else {
						$('#search-individuals').trigger('click');
				}
			}else{
				$('#search-organizations').trigger('click');
				$('#search-btn').trigger('click');
			}



		}, 500);


	});

	//$(document).live('pageinit', app.run);

	jQuery(document).bind("mobileinit", function(){
		//console.log('mobileinit');
		// jQuery.mobile.page.prototype.options.domCache = false;
		// jQuery.mobile.autoInitializePage = false;
	});


})();

