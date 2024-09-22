var app = angular.module('app.services', []);

var l = function () {
};

app.provider('DynamicApex', function DynamicApexProvider() {

    this.$get = ['$templateCache', 'ForceTKClient', function dynamicApexFactory($templateCache, ForceTKClient) {

        return {
            execute: function (className, methodName, methodParams, callback) {

                var classCode = $templateCache.get('apex-templates/' + className + '.tmpl.cls');
                var wrapperCode = $templateCache.get('apex-templates/DynamicApexExecutionWrapper.tmpl.cls');
                var methodWrapperCode = $templateCache.get('apex-templates/DynamicApexMethodWrapper.tmpl.cls');

                _.templateSettings.interpolate = /{{([\s\S]+?)}}/g;

                var wrappedMethodCode = _.template(methodWrapperCode, {methodName: methodName});
                classCode = classCode.substring(0, classCode.lastIndexOf('}')) + wrappedMethodCode + "\n}";


                var methodParams = {max: 5};
                var apexCode = _.template(wrapperCode,
                    {
                        userCode: classCode,
                        className: className,
                        methodName: methodName + 'Wrapper',
                        paramsAsJson: JSON.stringify(methodParams)
                    }
                );


                ForceTKClient.client({namedLoginParams: 'd11-admin'}).then(function (c) {
                    c.ajax('/v29.0/tooling/executeAnonymous/?anonymousBody=' + encodeURIComponent(apexCode), function (result) {
                        // *** NOTE ***: this does not return the debug output results
                        callback(null, {apexCode: apexCode, result: result});
                    }, function (err) {
                        callback(err);
                    });

                }, function (err) {
                    callback(err);
                });


            }
        };

    }];
})

app.factory('Utl', [function () {
    return {
        valueForPath: function (obj, path) {
            var paths = path.split('.')
                , current = obj
                , i;

            for (i = 0; i < paths.length; ++i) {
                if (current[paths[i]] == undefined) {
                    return undefined;
                } else {
                    current = current[paths[i]];
                }
            }
            return current;
        }
    }
}]);

app.factory('SurveyServices', ['ForceTKClient', function (ForceTKClient) {
    var _client = null;

    return {
        setClient: function (client) {
            _client = client;
        },
        markLatest: function (items) {

            _.forEach(items, function (item) {
                // item.latest = false;
                item.latest = item.Survey_Target_vod__r.MRK_Most_Recent__c;
            });

            /*
            // dynamically calculates most recent
            var groups = _.groupBy(items, function (item) {
                return (item.Survey_vod__c + item.Survey_Target_vod__r.Account_vod__c);
            })
            _.forEach(groups, function (items) {
                _.sortBy(items, function (item) {
                    return item.Survey_Target_vod__r.LastModifiedDate;
                })[items.length - 1].latest = true;
            });
            */
        },

        updateWithPercentComplete: function (surveyTargets, surveyQuestions) {
            var groups = _.groupBy(surveyQuestions, 'Survey_vod__c');
            _.forEach(surveyTargets, function (item) {

                var answeredCount = 0;
                for (var i = 0; i < 25; i++) {
                    var num = i + 1;
                    var answer = item[('A' + num)];
                    if ((answer != null) && (answer !== '')) {
                        answeredCount++;
                    }
                }

                item['percentComplete'] = (answeredCount / (groups[item.Survey_vod__c].length)) * 100;

            });
        },

        getAccounts: function (cb) {
            var soql = 'select Id, Name from Account';

            _client.queryAll(soql, function (result) {
                cb(null, result);
            }, function (err) {
                cb(err);
            });

        },

        getRecordTypeDataForSurveyObjects: function (cb) {
            var soql = "select Description, DeveloperName, Id, IsActive, IsPersonType, LastModifiedById, LastModifiedDate, Name, NamespacePrefix, SobjectType, SystemModstamp from RecordType where SobjectType IN ('Survey_vod__c', 'Survey_Target_vod__c', 'Question_Response_vod__c', 'Question_vod__c', 'Survey_Question_vod__c')";

            _client.queryAll(soql, function (result) {
                cb(null, result);
            }, function (err) {
                cb(err);
            });

        },

        getRecordTypeNameForRecordTypeId: function (recordTypeRecords, recordTypeId) {
            return _.find(recordTypeRecords, function (r) {
                return r.Id === recordTypeId;
            }).Name;
        },

        createSurveyTarget: function (opts) {
            var r = opts.surveyMetadata;
            var account = opts.account;

            var rec = {
                "Survey_vod__c": r.Survey_vod__c,
                "Name": r.Survey_vod__r.Name,
                "OwnerId": "005U0000000XMVTIA4",
                "Account_vod__c": account.Id,
                "Account_Display_Name_vod__c": account.Name,
                "Channels_vod__c": r.Survey_vod__r.Name,
                "Status_vod__c": opts.status,
                "Territory_vod__c": "",
                "Start_Date_vod__c": r.Survey_vod__r.Start_Date_vod__c,
                "End_Date_vod__c": r.Survey_vod__r.End_Date_vod__c
            };

            return rec;
        },

        generateRandomResponseForQuestion: function (opts) {
            var that = this;

            var r = opts.surveyMetadata;

            var recordTypeName = that.getRecordTypeNameForRecordTypeId(that._surveyRecordTypeDataRecords, r.RecordTypeId)

            var isTextLike = _.contains(['Text_vod', 'Long_Text_vod', 'Description_vod'], recordTypeName);
            var randomText = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod";

            var isSelectLike = _.contains(['Picklist_vod', 'Radio_vod', 'Multiselect_vod'], recordTypeName);

            var isDate = _.contains(['Date_vod'], recordTypeName);
            var isDateTime = _.contains(['Datetime_vod'], recordTypeName);
            var isNumber = _.contains(['Number_vod'], recordTypeName);

            var response = null

            var obj = {};

            if (isSelectLike) {

                var selectComponents = r.Answer_Choice_vod__c.split(';');
                var responses = _.filter(selectComponents, function (val, idx) {
                    return (idx % 2) == 0;
                });

                obj['Response_vod__c'] = _.sample(responses);
            } else if (isDate) {
                obj['Date_vod__c'] = '2014-06-16';
            } else if (isDateTime) {
                obj['Datetime_vod__c'] = '2014-04-17T16:00:00.000Z';
            } else if (isNumber) {
                obj['Number_vod__c'] = 10;
            } else if (isTextLike) {
                obj['Text_vod__c'] = randomText;
            }

            return obj;

        },

        createQuestionResponse: function (opts) {
            var that = this;
            var r = opts.surveyMetadata;
            var responseValues = that.generateRandomResponseForQuestion(opts);

            var rec = {
                "Answer_Choice_vod__c": r.Answer_Choice_vod__c,
                "Order_vod__c": r.Order_vod__c,
                "Question_Text_vod__c": r.Text_vod__c,
                "Required_vod__c": r.Required_vod__c,
                "Survey_Question_vod__c": r.Id,
                "Survey_Target_vod__c": opts.surveyTarget.Id,
                /* "Response_vod__c": "if !text; resp", */
                /* "Text_vod__c": "if text; text", */
                "Type_vod__c": r.RecordTypeId
            };

            _.extend(rec, responseValues);

            return rec;
        },

        getAllSurveyMetadata: function (cb) {
            var soql = "select Answer_Choice_vod__c, CreatedById, CreatedDate, External_ID_vod__c, Id, IsDeleted, IsLocked, LastModifiedById, LastModifiedDate, Max_Score_vod__c, MayEdit, Min_Score_vod__c, Name, Order_vod__c, Question_vod__c, RecordTypeId, Required_vod__c, Survey_vod__c, SystemModstamp, Text_vod__c, Survey_vod__r.Name, Survey_vod__r.RecordTypeId, Survey_vod__r.Channels_vod__c, Survey_vod__r.Start_Date_vod__c, Survey_vod__r.End_Date_vod__c, Survey_vod__r.Status_vod__c, Survey_vod__r.Product_vod__c, Survey_vod__r.Territory_vod__c, Survey_vod__r.Expired_vod__c, Survey_vod__r.External_ID_vod__c from Survey_Question_vod__c";

            _client.queryAll(soql, function (result) {
                cb(null, result);
            }, function (err) {
                cb(err);
            });

        },

        generateRandomSurveyTargetAndQuestionResponses: function (cb) {
            var that = this;
            var surveyIds = _.keys(that._surveyQuestionsGroupedBySurvey);

            // pick random survey
            var surveyId = _.sample(surveyIds);

            // get the survey questions
            var surveyQuestions = that._surveyQuestionsGroupedBySurvey[surveyId];

            var surveyTargetRecord = that.createSurveyTarget({
                surveyMetadata: surveyQuestions[0],
                account: _.sample(that._accountRecords),
                status: "Submitted_vod"
            });

            _client.create('Survey_Target_vod__c',
                surveyTargetRecord,
                function (result) {
                    console.log('Survey_Target_vod__c create result:', result);

                    if (result.success) {
                        var fns = [];
                        var questionResponses = [];

                        _.each(surveyQuestions, function (sq) {
                            var opts = {
                                surveyMetadata: sq,
                                surveyTarget: {Id: result.id}
                            };
                            var questionResponse = that.createQuestionResponse(opts);
                            questionResponses.push(questionResponse);

                            var fn = (function (questionResponse) {

                                return function (cb) {
                                    _client.create('Question_Response_vod__c',
                                        questionResponse,
                                        function (result) {
                                            cb(null, result);
                                        },
                                        function (err) {
                                            cb(err);
                                        });
                                };

                            })(questionResponse);

                            fns.push(fn);

                        });

                        async.parallelLimit(fns, 2, cb);

                    } else {
                        console.log('Survey_Target_vod__c create err (success == false)', result);
                    }

                },
                function (err) {
                    console.log('Survey_Target_vod__c create err:', err);
                    cb(err);
                }
            );

        },

        generateSurveyTargetsAndResponses: function (surveyTargetsToGenerateCount, cb) {
            var that = this;

            async.parallel({
                accounts: function (cb) {
                    that.getAccounts(cb);
                },
                surveyMetadata: function (cb) {
                    that.getAllSurveyMetadata(cb);
                },
                surveyRecordTypeData: function (cb) {
                    that.getRecordTypeDataForSurveyObjects(cb);
                }
            }, function (err, result) {

                // save all our data to *this* object
                that._accountRecords = result.accounts.records;
                that._surveyMetadataRecords = result.surveyMetadata.records;
                that._surveyQuestionsGroupedBySurvey = _.groupBy(that._surveyMetadataRecords, 'Survey_vod__c');
                that._surveyRecordTypeDataRecords = result.surveyRecordTypeData.records;
                that._surveyQuestionsGroupedByObjectType = _.groupBy(that._surveyRecordTypeDataRecords, 'SobjectType');


                var counter = 0;
                async.whilst(
                    function () {
                        return counter < surveyTargetsToGenerateCount;
                    },
                    function (callback) {
                        counter++;
                        that.generateRandomSurveyTargetAndQuestionResponses(function (err, result) {
                            cb(err, result);
                            callback(err);
                        });
                    },
                    function (err) {
                        console.log('whilst done', err);
                    }
                );

            })

        }

    };
}]);

app.provider('ForceTKClient', function ForceTKClientProvider() {

    // production
    var servicesHostname = 'force-services.herokuapp.com';

    // local dev with nodemon
    //var servicesHostname = 'localhost:3000';

    var defaults = {
        loginUrl: location.protocol + '//' + servicesHostname + '/services/login',
        proxyUrl: location.protocol + '//' + servicesHostname + '/services/sfdcproxy',
        host: 'login.salesforce.com',
        api: 'v29.0'
    };


    this.setDefaults = function (value) {
        _.defaults(defaults, value);
    }

    var defaultLoginParams = {};

    this.setDefaultLoginParams = function (params) {
        defaultLoginParams = params;
    };

    var namedLoginParams = {};
    this.setNamedLoginParams = function (name, params) {
        namedLoginParams[name] = params;
    };


    this.$get = ['$http', '$q', '$routeParams', '$cookies', function ($http, $q, $routeParams, $cookies) {

        function isRunningOnSalesforce() {
            return location.hostname.match(/(salesforce.com)|(force.com)/) != null;
        }

        function instanceUrlFromHostname(hostname) {
            var elements = hostname.split(".");

            var instance = null;
            if (elements.length == 4 && elements[1] === 'my') {
                instance = elements[0] + '.' + elements[1];
            } else if (elements.length == 3) {
                instance = elements[0];
            } else {
                instance = elements[1];
            }

            this.instanceUrl = "https://" + instance + ".salesforce.com";
        }

        function createQueryString(params) {
            return _.map(params, function (val, key) {
                return key + '=' + encodeURIComponent(val);
            }).join('&');
        }

        var _clientCache = {};

        return {
            isRunningOnSalesforce: isRunningOnSalesforce,

            createClientFactory: function (opts) {
                var that = this;

                var obj = {

                    client: function () {
                        // check if already exists in cache
                        if (_clientCache[opts.name]) {
                            // TODO: add check to see if the session is still valid
                            var delay = $q.defer();
                            delay.resolve(_clientCache[opts.name]);
                            return delay;
                        }

                        // inject namedLoginParams property if name is defined
                        if (opts.name && (typeof opts.namedLoginParams === "undefined" )) {
                            opts.namedLoginParams = opts.name;
                        }

                        return that.client(opts);
                    }

                };

                return obj;
            },

            client: function (options) {
                var delay = $q.defer();

                options = options || {};
                _.defaults(options, defaults);
                var proxyUrl = isRunningOnSalesforce() ? null : options.proxyUrl,
                    sessionId = isRunningOnSalesforce() ? (top.window.__sessionId__ || window.__sessionId__ || $cookies.sid) : $routeParams['__sessionId__'],
                    apiVersion = options.api,
                    instanceUrl = isRunningOnSalesforce() ? null : ( $routeParams['__instanceUrl__'] || ($routeParams['__hostname__'] ? instanceUrlFromHostname($routeParams['__hostname__']) : null ) );

                if (sessionId && options.api && (isRunningOnSalesforce() && instanceUrl == null)) {
                    var c = new forcetk.Client(null, null, proxyUrl);
                    c.setSessionToken(sessionId, options.api, instanceUrl);
                    c.useCache();
                    c.cache.flush();

                    if (options.name) {
                        _clientCache[options.name] = c;
                    }

                    setTimeout(function () {
                        delay.resolve(c);
                    }, 1);
                } else {
                    var loginParams = options['namedLoginParams'] ? namedLoginParams[options['namedLoginParams']] : defaultLoginParams;
                    this.login(loginParams)
                        .then(function (c) {
                            delay.resolve(c);
                        }, function (error) {
                            delay.reject(error);
                        });
                }

                return delay.promise;

            },

            login: function (options) {

                _.defaults(options, defaults);

                var delay = $q.defer();

                $.support.cors = true;


                $.ajax({
                    url: options.loginUrl + '?' + createQueryString(options), // add data to query string for IE support
                    data: options,
                    //contentType: 'text/plain', // possibly uncomment for IE
                    type: 'POST',
                    dataType: 'json'
                }).success(function (result) {
                    result.sessionId = result.sessionId || result.oauth.access_token;
                    if (result.sessionId) {
                        l('result.sessionId: ' + result.sessionId);
                        //console.log('result:\n' + JSON.stringify(result));
                        var c = new forcetk.Client(null, null, options.proxyUrl);
                        //var instanceUrl = result.serverUrl.substring(0, result.serverUrl.indexOf(".salesforce.com") + ".salesforce.com".length);
                        var instanceUrl = result.oauth.instance_url;
                        c.setSessionToken(result.sessionId, options.api, instanceUrl);
                        c.useCache();
                        c.cache.flush();
                        delay.resolve(c);
                    } else {
                        delay.reject('login failed: ' + JSON.stringify(result));
                    }

                })
                    .error(function (error) {
                        delay.reject(error);
                    });

                return delay.promise;
            },

            createWrappers: function (client) {

                var queryWrapper = function (soql, resultProcessFn, cb) {

                    var delay = $q.defer();

                    client().then(function (c) {
                        c.queryAll(soql,
                            function (result) {
                                delay.resolve(resultProcessFn ? resultProcessFn(result) : result);
                                if (cb) {
                                    cb(null, result);
                                }
                            }, function (err) {
                                if (err) {
                                    if (cb) {
                                        cb(err);
                                    }
                                    return delay.reject(err);
                                }
                            });

                    }, function (err) {
                        if (err) {
                            return cb(err);
                        }
                    });

                    return delay.promise;
                };


                return {
                    queryWrapper: queryWrapper
                };
            }

        };
    }]
});

app.provider('ForceClientFactory', function ForceClientFactoryProvider() {

    var _clientDefinitions = {};
    this.addClientDefinition = function (name, params) {
        _clientDefinitions[name] = params;
    };

    var _clientCache = {};

    this.$get = ['$q', 'ForceTKClient', function ($q, ForceTKClient) {
        var obj = {

            // must be running in context of salesforce host OR
            // sid cookie set OR
            // __sessionId__ set on window object
            getClient: function () {
                return ForceTKClient.client();
            },

            getClientNamed: function (name) {
                var delay = $q.defer();

                if (!_clientCache[name]) {
                    ForceTKClient.client({namedLoginParams: name})
                        .then(function (c) {
                            // cache client
                            _clientCache[name] = c;
                            delay.resolve(c);
                        }, function (err) {
                            delay.reject(err);
                        });
                } else {
                    setTimeout(function () {
                        delay.resolve(_clientCache[name])
                    }, 1);
                }

                return delay.promise;
            }

        };
        return obj;
    }];

});

app.provider('AuditServices', function AuditServicesProvider() {

    var _objectNameToBaseSoql = {
        "BMP__Audit_Definition__c": "select BMP__Fields__c, BMP__Keyword_Collection__c, BMP__Keyword_Collection__r.Name, BMP__Keyword_Collection__r.BMP__Keywords__c, BMP__Keyword_Collection_IDs__c, BMP__Object_Name__c, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Name, OwnerId from BMP__Audit_Definition__c",
        "BMP__Keyword_Collection__c": "select BMP__Keywords__c, CreatedById, CreatedBy.Name, CreatedDate, Id, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Name, OwnerId from BMP__Keyword_Collection__c"
    };


    this.$get = ['$q', 'ForceClientFactory', function ($q, ForceClientFactory) {


        var obj = {

            client: function () {
                var clientName = '2demo-admin';
                return ForceClientFactory.getClientNamed(clientName)
            },

            getAuditResults: function () {
                var soql = 'select BMP__Audit_Definition__c, BMP__External_ID__c, BMP__Field_Name__c, BMP__Field_Value__c, BMP__Keywords_Matched__c, BMP__Resolution__c, BMP__Scan_TImestamp__c, BMP__Status__c, BMP__Target_Record__c, CreatedById, CreatedDate, Id, IsDeleted, LastModifiedById, LastModifiedDate, Name, OwnerId, SystemModstamp, BMP__Target_Record_Name__c, BMP__Target_Record_CreatedById__c, BMP__Target_Record_CreatedDate__c, BMP__Target_Record_LastModifiedById__c, BMP__Target_Record_LastModifiedDate__c, BMP__Target_Record_CreatedById__r.Name, BMP__Target_Record_LastModifiedById__r.Name, BMP__Audit_Definition__r.BMP__Object_Name__c, BMP__Audit_Definition__r.BMP__Keyword_Collection__c, BMP__Audit_Definition__r.BMP__Keyword_Collection__r.BMP__Keywords__c from BMP__Audit_Result__c';

                var delay = $q.defer();

                this.client().then(function (c) {
                    c.queryAll(soql, function (result) {
                        delay.resolve(result.records);
                    })
                });

                return delay.promise;

            },

            getAuditRules: function () {
                var soql = 'select BMP__Fields__c, BMP__Keyword_Collection__c, BMP__Keyword_Collection__r.Name, BMP__Keyword_Collection__r.BMP__Keywords__c, BMP__Keyword_Collection_IDs__c, BMP__Object_Name__c, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Name, OwnerId from BMP__Audit_Definition__c';
                var delay = $q.defer();

                this.client().then(function (c) {
                    c.queryAll(soql, function (result) {
                        delay.resolve(result.records);
                    })
                });

                return delay.promise;

            },

            getKeywordCollections: function () {
                var soql = _objectNameToBaseSoql['BMP__Keyword_Collection__c'];

                var delay = $q.defer();

                this.client().then(function (c) {
                    c.queryAll(soql, function (result) {
                        delay.resolve(result.records);
                    })
                });

                return delay.promise;

            },

            getObjectMetadata: function () {
                var delay = $q.defer();

                this.client()
                    .then(function (c) {
                        c.describeGlobal(function (result) {

                            var filteredSobjects = _.filter(result.sobjects, function (so) {
                                return so.layoutable !== false;
                            });

                            var meta = _.map(filteredSobjects, function (so) {
                                return _.pick(so, ['name', 'label'])
                            });
                            delay.resolve(meta);
                        }, function (err) {
                            delay.reject(err);
                        });
                    });

                return delay.promise;
            },

            getAuditableFieldsForObject: function (objectName) {
                var delay = $q.defer();

                var auditableFieldTypes = ['string', 'textarea'];

                this.client()
                    .then(function (c) {
                        c.describe(objectName, function (result) {

                            var fields = _.remove(result.fields, function (f) {
                                return  _.contains(auditableFieldTypes, f.type);
                            });
                            delay.resolve(fields);
                        }, function (err) {
                            delay.reject(err);
                        });
                    });

                return delay.promise;

            },

            saveRecord: function(objectName, item) {
                var that = this;

                var delay = $q.defer();

                var errorHndlr = function (err) {
                    delay.reject(err);
                };

                var successHndlr = function (obj) {

                    // once saved, query the full record again because only the id is returned for an insert
                    // and for an update it's best to grab the latest in case there were any changes to
                    // related objects
                    var soql = _objectNameToBaseSoql[objectName] + " where Id = '" + (obj ? obj.id : item.Id) + "'";

                        that.client()
                            .then(function (c) {
                                c.queryAll(soql, function(result) {
                                    delay.resolve(result.records[0]);
                                }, errorHndlr)
                            }, errorHndlr);

                };

                this.client()
                    .then(function (c) {

                        if (!item.Id) {
                            c.createByRemovingExtraValues(objectName, item, successHndlr, errorHndlr);
                        } else {
                            c.updateByRemovingExtraValues(objectName, item.Id, item, successHndlr, errorHndlr);
                        }

                    }, errorHndlr);

                return delay.promise;
            },


            saveAuditDefinition: function(item) {
                return this.saveRecord('BMP__Audit_Definition__c', item);
            },

            saveKeywordCollection: function(item) {
                return this.saveRecord('BMP__Keyword_Collection__c', item);
            }

        };


        return obj;
    }];
});

app.provider('FlagServices', function FlagServicesProvider() {

    var _baseSoql = 'select CreatedById, CreatedDate, End_Date_MRK__c, External_ID_MRK__c, Id, Active_Attachment_MRK__c, IsDeleted, IsLocked, LastModifiedById, LastModifiedBy.Name, Product_MRK__c,Product_MRK__r.Name, Product_IDs_MRK__c, Sales_Team_IDs_MRK__c, LastModifiedDate, LastReferencedDate, LastViewedDate, MayEdit, Name, OwnerId, Start_Date_MRK__c, SystemModstamp, (select Id, Name, ParentId, ContentType, BodyLength, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById from Attachments), (select Id, Product_MRK__c, Product_MRK__r.Name from Product_Flags__r) from Flag_MRK__c';
    var _orderBy = 'order by LastModifiedDate desc';

    function productsSoql() {
        return "select Id, Name, Description_vod__c, External_ID_vod__c, Master_Product_Id_MRK__c from Product_vod__c where Product_Type_vod__c = 'Detail' and Active_MRK__c = true order by Name";
    }

    function salesTeamsSoql() {
        return "select Active_MRK__c, Id, Name, Sales_Team_Code_MRK__c from Sales_Team_MRK__c where Active_MRK__c = true order by Name";
    }

    function allItemsSoql() {
        return _baseSoql + ' ' + _orderBy;
    }

    function itemByIdSoql(recordId) {
        return _baseSoql + ' WHERE Id = \'' + recordId + '\'';
    }

    this.$get = ['$q', 'ForceTKClient', function ($q, ForceTKClient) {

        var _client = null;
        var _clientsCache = {};

        function client(cb) {
            var delay = $q.defer();

            if (!_client) {
                ForceTKClient.client(ForceTKClient.isRunningOnSalesforce() ? null : {namedLoginParams: 'd4-admin'}).then(function (c) {
                    _client = c;
                    if (cb) cb(null, c);
                    delay.resolve(c);
                }, function (err) {
                    if (cb) cb(err);
                    delay.reject(err);
                });
            } else {
                setTimeout(function () {
                    if (cb) cb(null, _client);
                    delay.resolve(_client);
                }, 1);
            }

            return delay.promise;

        }

        function namedClient(namedLoginParams, cb) {
            var delay = $q.defer();

            if (_clientsCache[namedLoginParams] == null) {
                ForceTKClient.client({namedLoginParams: namedLoginParams}).then(function (c) {
                    _clientsCache[namedLoginParams] = c;
                    if (cb) cb(null, c);
                    delay.resolve(c);
                }, function (err) {
                    if (cb) cb(err);
                    delay.reject(err);
                });
            } else {
                setTimeout(function () {
                    if (cb) cb(null, _clientsCache[namedLoginParams]);
                    delay.resolve(_clientsCache[namedLoginParams]);
                }, 1);
            }

            return delay.promise;

        }

        var queryWrapperWithNamedClient = function (namedLoginParams, soql, resultProcessFn, cb) {

            var delay = $q.defer();

            namedClient(namedLoginParams, function (err, c) {
                if (err) {
                    return cb(err);
                }
                c.queryAll(soql,
                    function (result) {
                        delay.resolve(resultProcessFn ? resultProcessFn(result) : result);
                        if (cb) {
                            cb(null, result);
                        }
                    }, function (err) {
                        if (err) {
                            if (cb) {
                                cb(err);
                            }
                            return delay.reject(err);
                        }
                    });

            });

            return delay.promise;

        };

        var queryWrapper = function (soql, resultProcessFn, cb) {

            var delay = $q.defer();

            client(function (err, c) {
                if (err) {
                    return cb(err);
                }
                c.queryAll(soql,
                    function (result) {
                        delay.resolve(resultProcessFn ? resultProcessFn(result) : result);
                        if (cb) {
                            cb(null, result);
                        }
                    }, function (err) {
                        if (err) {
                            if (cb) {
                                cb(err);
                            }
                            return delay.reject(err);
                        }
                    });

            });

            return delay.promise;

        };

        var updateWrapper = function (objtype, id, fields, cb) {

            var delay = $q.defer();

            client(function (err, c) {
                if (err) {
                    return cb(err);
                }
                c.update(objtype, id, fields,
                    function (result) {
                        delay.resolve(result);
                        if (cb) {
                            cb(null, result);
                        }
                    }, function (err) {
                        if (err) {
                            if (cb) {
                                cb(err);
                            }
                            return delay.reject(err);
                        }
                    });

            });

            return delay.promise;

        };

        var apexRestWrapper = function (url, cb) {

            var delay = $q.defer();

            client(function (err, c) {
                if (err) {
                    return cb(err);
                }
                c.apexrest(url,
                    function (result) {
                        delay.resolve(result);
                        if (cb) {
                            cb(null, result);
                        }
                    }, function (err) {
                        if (err) {
                            if (cb) {
                                cb(err);
                            }
                            return delay.reject(err);
                        }
                    });

            });

            return delay.promise;
        };


        return {
            getProducts: function (cb) {
                return queryWrapper(productsSoql(), function (r) {
                    return r.records;
                }, cb);
            },

            getSalesTeams: function (cb) {
                return queryWrapper(salesTeamsSoql(), function (r) {
                    return r.records;
                }, cb);
            },

            getItems: function (cb) {
                return queryWrapper(allItemsSoql(), function (r) {
                    return r.records;
                }, cb);
            },

            getItemById: function (recordId, cb) {
                return queryWrapper(itemByIdSoql(recordId), function (r) {
                    return r.records[0];
                }, cb);
            },

            getIdListFromAttachment: function (attachmentRecordId, offset) {
                var that = this;
                var delay = $q.defer();
                var allIDs = [];
                var maxElements = 5000;

                if (!offset) {
                    offset = 0;
                }

                var attachmentOffsetsUrl = "/mrk/flag?action=getOffsetsForAttachment&recordId=" + attachmentRecordId + "&offset=" + offset + "&maxElements=" + maxElements;
                apexRestWrapper(attachmentOffsetsUrl, function (err, result) {
                    if (err) {
                        return console.log('err', err);
                    }
                    console.log('getOffsetsForAttachment result', result);

                    var offsetList = JSON.parse(result.offsetList);
                    var counter = 0;
                    var fns = [];
                    _.each(offsetList, function (offset) {
                        var url = "/mrk/flag?action=getIdListFromAttachment&recordId=" + attachmentRecordId + "&offset=" + offset + "&maxElements=" + maxElements;

                        var fn = (function (urk) {

                            return function (cb) {
                                apexRestWrapper(url, function (err, result) {
                                    counter++;
                                    delay.notify({"progress": (counter / offsetList.length)});
                                    cb(err, result);
                                });
                            }

                        })(url);
                        fns.push(fn);
                    });

                    async.parallelLimit(fns, 1, function (err, result) {
                        if (err) {
                            return delay.reject(err);
                        }
                        delay.resolve(result);
                    });

                    /*
                     var url = "/mrk/flag?action=getIdListFromAttachment&recordId=" + attachmentRecordId + "&offset=" + offset + "&maxElements=" + maxElements;
                     var cb = function(err, result) {

                     if (err) { return delay.reject(err); }

                     var ids = JSON.parse(result.ids);
                     allIDs = allIDs.concat(ids);
                     console.log('complete', result.complete, 'offset', result.offset);

                     if (result.complete === 'false') {
                     var url = "/mrk/flag?action=getIdListFromAttachment&recordId=" + attachmentRecordId + "&offset=" + result.offset + "&maxElements=" + maxElements;
                     apexRestWrapper(url, cb);
                     } else {
                     delay.resolve(allIDs);
                     }

                     }
                     apexRestWrapper(url, cb);
                     */
                });

                return delay.promise;

            },

            findMatchingRecordsForAttachmentIds: function (attachmentRecordId, cb) {
                var delay = $q.defer();
                client(function (err, c) {
                    if (err) {
                        return cb(err);
                    }

                    var url = "/v29.0/sobjects/Attachment/" + attachmentRecordId + "/Body";
                    c.ajax(url, function (result) {
                        delay.resolve(result);
                        if (cb) {
                            cb(null, result);
                        }
                    }, function (err) {
                        if (err) {
                            if (cb) {
                                cb(err);
                            }
                            return delay.reject(err);
                        }
                    });

                    /*
                     c.retrieve('Attachment', attachmentRecordId, null,
                     function(result) {
                     delay.resolve(result);
                     if (cb) { cb(null, result); }
                     }, function(err) {
                     if (err) {
                     if (cb) { cb(err); }
                     return delay.reject(err);
                     }
                     });
                     */

                });
                return delay.promise;
            },

            findMatchingRecordsForIdsMatchingField: function (ids, fieldName, cb) {
                var delay = $q.defer();

                // remove blank ids
                ids = _.filter(ids, function (id) {
                    return id.trim().length > 0;
                })

                var maxCharsInSOQL = 2000;
                var soqlTmpl = "select Id, Merck_ID_MRK__c FROM Account WHERE " + fieldName + "  IN (<%= idsString %>)"

                var soqlCharCounter = soqlTmpl.length;

                var idBatches = [];
                var idBatch = [];
                _.each(ids, function (id) {
                    var len = (id.length + 3)

                    soqlCharCounter += len;

                    if (soqlCharCounter < maxCharsInSOQL) {
                        idBatch.push(id)
                    } else {
                        idBatches.push(idBatch);
                        idBatch = [];
                        soqlCharCounter = soqlTmpl.length;
                        soqlCharCounter += len;
                        idBatch.push(id);
                    }

                });
                // push last batch on
                idBatches.push(idBatch);

                console.log('idBatches.length: ' + idBatches.length);

                var executionBatches = [];
                _.each(idBatches, function (ids) {
                    var soql = _.template(soqlTmpl, {idsString: _.map(ids, function (id) {
                        return '\'' + id + '\'';
                    }).join(',') });
                    executionBatches.push({ids: ids, soql: soql});
                });

                var fns = [];
                var counter = 0;
                _.each(executionBatches, function (executionBatch) {

                    var fn = (function (executionBatch) {

                        return function (cb) {
                            console.log('executing batch for ' + executionBatch.ids.length + ' ids');
                            queryWrapper(executionBatch.soql, null, function (err, result) {
                                //queryWrapperWithNamedClient('f2-admin', executionBatch.soql, null, function(err, result) {
                                counter++;
                                delay.notify({"progress": counter / executionBatches.length})
                                executionBatch.result = result;
                                if (err) {
                                    console.log('err soql: ', executionBatch.soql, 'err', err);
                                }
                                cb(err, executionBatch);
                            });

                        };

                    })(executionBatch);

                    fns.push(fn);

                });

                var maxParallelQueriesAtATime = 10;
                async.parallelLimit(fns, maxParallelQueriesAtATime, function (err, results) {

                    if (err) {
                        delay.reject(err);
                        return console.log('err:\n' + JSON.stringify(err));
                    }

                    // *** TODO: make me a param
                    var targetRecId = '0123456789';

                    var bulkRecs = [];
                    var allIDs = [];
                    _.each(results, function (result) {

                        var recs = result.result.records;

                        allIDs = allIDs.concat(_.map(recs, function (r) {
                            return r.Id;
                        }));

                        if (result.ids.length !== recs.length) {
                            // console.log('no match');
                        } else {
                            // console.log('match');
                        }


                        bulkRecs = bulkRecs.concat(_.map(recs, function (r) {
                            return {"Account__c": r.Id, "Flag__c": targetRecId};
                        }));

                    });

                    /*
                     console.log('bulkRecs.length: ' + bulkRecs.length);

                     conn.bulk.pollTimeout = 100000;
                     while (bulkRecs.length > 0) {
                     var recs = bulkRecs.slice(0, 10000);
                     bulkRecs = bulkRecs.slice(10000);

                     console.log('calling bulk load');
                     conn.bulk.load("Account_Flag__c", "insert", recs, function(err, rets) {
                     if (err) { return console.error(err); }
                     for (var i=0; i < rets.length; i++) {
                     if (rets[i].success) {
                     console.log("#" + (i+1) + " loaded successfully, id = " + rets[i].id);
                     } else {
                     console.log("#" + (i+1) + " error occurred, message = " + rets[i].errors.join(', '));
                     }
                     }

                     });

                     }
                     */

                    delay.resolve(allIDs);
                    cb(err, allIDs);

                });

                return delay.promise;
            },

            executeOperation: function (opts) {
                var delay = $q.defer();

                var operation = opts.operation,
                    flagRecordId = opts.flagRecordId,
                    attachmentRecordId = opts.attachmentRecordId,
                    ids = opts.ids,
                    batchSize = opts.batchSize,
                    parallelLimit = opts.parallelLimit;

                var fns = [];
                var counter = 0;
                while (ids.length > 0) {
                    var batchIDs = ids.slice(0, batchSize);
                    ids = ids.slice(batchSize + 1);

                    var url = "/mrk/flag?action=" + operation + "&flagRecordId=" + flagRecordId + "&attachmentRecordId=" + attachmentRecordId + "&ids=" + encodeURIComponent(batchIDs.join(','));

                    var fn = (function () {
                        return function (cb) {
                            apexRestWrapper(url, function (err, result) {
                                cb(err, result);
                                counter++;
                                delay.notify({"progress": (counter / fns.length)})
                            });
                        }
                    })(url);

                    fns.push(fn);
                }

                async.parallelLimit(fns, parallelLimit, function (err, result) {
                    if (err) {
                        return delay.reject(err);
                    }
                    delay.resolve(result);
                })

                return delay.promise;

            },

            updateFlagWithFieldValues: function (recordId, fieldValues, cb) {
                var delay = $q.defer();

                updateWrapper('Flag_MRK__c', recordId, fieldValues, function (err, result) {
                    if (err) {
                        if (cb) {
                            cb(err);
                        }
                        return delay.reject(err);
                    }
                    if (cb) {
                        cb(null, result);
                    }
                    delay.resolve(result);
                });

                return delay.promise;
            },

            getAccountFlagsForFlagId: function (recordId) {
                var delay = $q.defer();

                var soql = "select Account_MRK__c, External_ID_MRK__c, Flag_MRK__c, Id from Account_Flag__c where Flag_MRK__c = '" + recordId + "'";

                queryWrapper(soql, null, function (err, result) {
                    if (err) {
                        return delay.reject(err);
                    }
                    delay.resolve(result);
                });
                return delay.promise;
            },

            inactivateAccountFlagsForFlagId: function (recordId) {
                var that = this;
                var delay = $q.defer();

                that.getAccountFlagsForFlagId(recordId)
                    .then(function (result) {

                        var accountFlagIDs = _.map(result.records, function (r) {
                            return r.Id;
                        })

                        var opts = {
                            "operation": "inactivateAccountFlags",
                            "flagRecordId": recordId,
                            "ids": accountFlagIDs,
                            "batchSize": 300,
                            "parallelLimit": 2
                        };

                        that.executeOperation(opts)
                            .then(function (result) {
                                //delay.resolve(result);

                                updateWrapper('Flag_MRK__c', recordId, {"Active_Attachment_MRK__c": null})
                                    .then(function (result) {
                                        delay.resolve(result);
                                    }, function (err) {
                                        delay.reject(err);
                                    }, function (update) {
                                        delay.notify(update);
                                    });

                            }, function (err) {
                                delay.reject(err);
                            }, function (update) {
                                delay.notify(update);
                            }
                        );

                    }, function (err) {
                        delay.reject(err);
                    }, function (update) {
                        delay.notify(update);
                    });

                return delay.promise;
            }

        };
    }];

});

app.provider('MyServices', function MyServicesProvider() {

    this.$get = ['$q', function ($q) {


        return {

            run: function () {
                var delay = $q.defer();

                setTimeout(function () {
                    delay.resolve('MyServices.run result')
                }, 1000);

                return delay.promise;
            }

        };


    }];

});

app.provider('UIServices', function UIServicesProvider() {

    this.$get = ['$q', function ($q) {


        return {

            createMultiSelectItems: function (opt) {

                var items = _.map(opt.items, function (e) {
                    var idsString = opt.item[opt.selectedSourceFieldName];
                    var ids = idsString ? opt.item[opt.selectedSourceFieldName].split(';') : [];
                    return {text: e[opt.textFieldName], selected: _.contains(ids, e[opt.selectedFieldName]), id: e[opt.selectedFieldName]};
                });

                opt.scope.$watch(opt.watchExpression, function (oldVal, newVal) {
                    var selectedItems = _.filter(items, function (e) {
                        return e.selected;
                    })
                    opt.item[opt.selectedSourceFieldName] = _.map(selectedItems, function (e) {
                        return e.id;
                    }).join(';');
                    console.log('item', opt.item);
                }, true);


                return items;
            }



        };


    }];

});

app.config(function ($provide) {
    $provide.decorator('MyServices',
        ['$q', '$delegate', '$injector', '$rootScope',
            function ($q, $delegate, $injector, $rootScope) {
                //return $injector.get('storageServiceFile');
                //return $delegate;
                var delay = $q.defer();

                setTimeout(function () {
                    delay.resolve('MyServices.run result')
                }, 1000);

                //return delay.promise;
                //return $delegate;
                return 'hello';

            }]);
});
/**
 * Created by brianpfeil on 7/27/14.
 */

var app = angular.module('app.controllers', []);

app.controller('HomeCtrl', ['$scope', '$location', '$route', 'MyServices', function ($scope, $location, $route, MyServices) {
    //$location.path('survey-target-list');


    $scope.routes = _.map($route.routes, function (val, key) {
        return key;
    });
    $scope.debug = JSON.stringify($route.routes, undefined, 2);

    $scope.visit = function (path) {
        $location.path(path);
    }

    //$scope.msg = 'Please select a route';
    $scope.msg = MyServices;

    /*
     angular.forEach($route.routes,function (config, route) {
     if(config.name===routeName){
     routes.push(route);
     }
     });
     */

}]);

app.controller('SurveyTargetListCtrl', ['$rootScope', '$scope', '$route', '$routeParams', '$http', '$location', 'ForceTKClient', 'SurveyServices', 'Utl', function ($rootScope, $scope, $route, $routeParams, $http, $location, ForceTKClient, SurveyServices, Utl) {

    $scope.newSurveyTargetActionEnabled = ($routeParams['newSurveyTargetActionEnabled'] === 'true')
    $scope.loading = true;
    $scope.newSurveyTarget = function () {
        top.location = '/apex/Add_Survey_Target_vod?acctid=';
    }

    $scope.refreshHandler = function (e) {

        $scope.fetchAndProcessData(function () {
            $scope.$apply();
        });

        //$location.path('survey-target-list');
        //top.location = top.location;
    }

    var filterFns = [
        function surveyNameFilter(e, idx) {
            return ($scope.selectedSurvey === 'All Surveys')
                || ($scope.selectedSurvey === e['SurveyName']);
        },

        function surveyStatusFilter(e, idx) {
            return ($scope.selectedStatus === 'All')
                || ($scope.selectedStatus === e['Status'])
                || (($scope.selectedStatus === 'Latest') && (e.latest));
        },

        function surveyFreshnessFilter(e, idx) {
            return ($scope.selectedFreshness === 'All')
                || (($scope.selectedFreshness === 'Latest') && (e.latest));
        }



    ];

    $scope.update = function () {

        if ($scope.items) {
            $scope.items.length = 0;
        }

        angular.forEach($scope.allItems, function (e, idx) {

            var match = _.every(filterFns, function (fn) {
                return fn(e, idx);
            })
            if (match) {
                $scope.items.push(e);
            }

        });

    };

    $scope.$watch('selectedStatus', $scope.update);
    $scope.$watch('selectedFreshness', $scope.update);

    function createFields(options) {
        var fields = [
            {
                name: 'Action',
                display: 'Action',
                path: '',
                render: function (data, type, row, meta) {
                    return row.latest ? '<a href="javascript:void(0)" onclick="top.location=\'/apex/Survey_Target_Execution_vod?id=' + row.Survey_Target_vod__c + '\'">Edit</a>' : '';
                },
                width: '50px'
            },
            {
                name: 'SurveyName',
                display: 'Survey',
                path: 'Survey_Target_vod__r.Name',
                linkPath: 'Survey_Target_vod__c'
            },
            {
                name: 'AccountName',
                display: 'Account',
                path: 'Survey_Target_vod__r.Account_vod__r.Formatted_Name_vod__c',
                linkPath: 'Survey_Target_vod__r.Account_vod__c'
            },
            {
                name: 'OwnerName',
                display: 'Owner',
                path: 'Survey_Target_vod__r.Owner.Name',
                linkPath: 'Survey_Target_vod__r.OwnerId'
            },
            {
                name: 'Status',
                display: 'Status',
                path: 'Survey_Target_vod__r.Status_vod__c',
                render: function (data, type, row, meta) {
                    return data.replace('_vod', '').replace('_', ' ');
                }
            },
            {
                name: 'LastModifiedDate',
                display: 'Date',
                fmt: function (item, field, val) {
                    return val.split('T')[0];
                },
                path: 'Survey_Target_vod__r.CreatedDate',
                render: function (data, type, row, meta) {
                    return data.split('T')[0];
                }
            },
            {
                name: 'Latest',
                display: 'Most Recent',
                fmt: function (item, field, val) {
                    return val ? '*' : '';
                },
                path: 'latest',
                render: function (data, type, row, meta) {
                    return data ? '*' : '';
                }

            },
            {
                name: 'Percent Complete',
                display: 'Percent Complete',
                render: function (data, type, row, meta) {
                    var percent = data.toFixed();
                    return '<div class="progress"><div class="progress-bar" role="progressbar" aria-valuenow="' + percent + '" aria-valuemin="0" aria-valuemax="100" style="width: ' + percent + '%;">' + percent + '%</div></div>';
                },
                path: 'percentComplete'
            }

        ];

        if (options && options['includeDetails']) {

            for (var i = 0; i < 25; i++) {
                var num = i + 1;

                _.each(['Q', 'A'], function (e) {

                    fields.push({
                        name: e + num,
                        display: e + num,
                        path: (e + num),
                        render: function (data, type, row, meta) {
                            return data ? data : '';
                        }
                    });

                });

            }

        }
        return fields;
    }

    $scope.$watch('detailFilter', function (newVal, oldVal) {

        $scope.dt.visibleColumns(function (idx) {
            return (newVal === 'Detail') ? true : idx > 7;
        }, (newVal === 'Detail') ? true : false);


        //$scope.fields = createFields({includeDetails: (newVal === 'Detail')});
    });

    $scope.fields = createFields({includeDetails: false});

    $scope.visibleItemCount = function () {
        return angular.element('.item-row').size();
    }

    $scope.reverseSort = false;
    $scope.sortField = 'SurveyName';
    $scope.orderBy = function (field) {
        if ($scope.sortField === field.name) {
            $scope.reverseSort = !$scope.reverseSort;
        } else {
            $scope.reverseSort = false;
            $scope.sortField = field.name;
        }
    }

    $scope.cellDisplay = function (item, field) {
        var displayValue = Utl.valueForPath(item, field.path);
        if (field.fmt) {
            displayValue = field.fmt(item, field, displayValue);
        }
        if (field.linkPath) {
            return '<a href="/' + Utl.valueForPath(item, field.linkPath) + '" target="_top">' + displayValue + '</a>';
        } else {
            return displayValue;
        }

    }

    $scope.detail = function (item) {
        $location.path('/survey-target-detail/' + item.Survey_Target_vod__c);
    }

    var errorFn = function (err) {
        l(JSON.stringify(err));
    };

    $scope.fetchData = function (cb) {

        $rootScope.allItems = [];
        $rootScope.items = [];

        //ForceTKClient.client({namedLoginParams: 'd1-admin'}).then(function(c) {
        ForceTKClient.client().then(function (c) {
            // fetch current userid
            c.userid(function (result) {
                var userid = result;

                async.parallel({
                    surveyQuestions: function (cb) {

                        c.query('select Id, Order_vod__c, Survey_vod__c from Survey_Question_vod__c', function (result) {
                            cb(null, result.records);
                        }, function (err) {
                            cb(err);
                        })

                    },
                    surveyTargets: function (cb) {
                        c.surveyTargetsFlattenedForAllUsersAccounts(userid, function (result) {
                            cb(null, result);
                        }, function (err) {
                            cb(err);
                        })
                    }
                }, function (err, results) {
                    cb(err, results);
                });

            }, function (err) {

            });


        }, cb);

    }


    $scope.mockFetchData = function (cb) {
        $.get('data/survey-response-dataset.json')
            .then(function (result) {
                cb(null, result);
            });
    }

    $scope.processData = function (results) {
        var surveyQuestions = results.surveyQuestions;
        var surveyTargets = results.surveyTargets;
        surveyTargets = _.sortBy(surveyTargets, function (item) {
            return (item.Survey_Target_vod__r.Name + item.Survey_Target_vod__r.Account_vod__r.Name);
        });
        SurveyServices.markLatest(surveyTargets);
        SurveyServices.updateWithPercentComplete(surveyTargets, surveyQuestions);
        console.log(surveyTargets);
        $rootScope.allItems = surveyTargets;
        $rootScope.items = _.clone($rootScope.allItems);

        $scope.availableSurveys = _.uniq(_.pluck($rootScope.allItems, 'SurveyName')).sort();
        $scope.availableSurveys.unshift('All Surveys');
        $scope.selectedSurvey = 'All Surveys';

        // set defaults
        $scope.selectedFreshness = 'Latest';
        $scope.selectedStatus = 'All';
        $scope.detailFilter = 'Detail';

        $scope.$apply();
    }

    $scope.fetchAndProcessData = function (cb) {
        $scope.loading = true;
        $scope.fetchData(function (err, results) {
            if (err) {
                console.log(err);
            }
            if (!err) {
                $scope.processData(results);
            }
            $scope.loading = false;
            $scope.$apply();
            if (cb) {
                cb();
            }
        });

    }

    if (!$rootScope.allItems) {
        $scope.fetchAndProcessData();
    }

    $scope.myOptions = { data: 'items' };

    // ***


    function fieldsToColumnsForDataTables(fields) {
        return _.map(fields, function (f) {
            var col = {
                "title": f.display,
                "data": f.path
            };

            if (f.render) {
                col['render'] = f.render;
            }

            if (f.width) {
                col['width'] = f.width;
            }
            return col;
        });
    }


    /*
     $t.dataTable({
     data: [],
     columns: columns
     "dom": '<"top"iflp<"clear">>rt<"bottom"iflp<"clear">>'
     });
     */

    // create data table
    var columns = fieldsToColumnsForDataTables(createFields({includeDetails: true}));
    var dt = $scope.dt = new DataTable({
        elementId: '#survey-targets-table',
        data: [],
        columns: columns
    });
    dt.addColumnSearch();

    /*
     dt.visibleColumns(function(idx){
     return idx > 7;
     }, false);
     */

    // show all
    dt.visibleColumns(function (idx) {
        return true;
    }, true);


    $scope.$watchCollection('items', function () {
        $scope.dt.setData($scope.items || []);
    });


}]);

app.controller('SurveyTargetDetailCtrl', ['$rootScope', '$scope', '$routeParams', function ($rootScope, $scope, $routeParams) {

    angular.forEach($rootScope.items, function (item) {
        if (item.Survey_Target_vod__c == $routeParams.surveyTargetId) {
            $scope.item = item;
        }
    });

}]);

app.controller('DetailCtrl', ['$scope', function ($scope) {
    $scope.message = 'All details all the time';
}]);

app.controller('JqueryDatatableExampleCtrl', ['$scope', function ($scope) {

    var data = [
        {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006XuwMAE"}, "Survey_Target_vod__c": "a2bZ00000007jdvIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007jdvIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLejIAG", "Name": "One Time Test 01", "Account_vod__c": "001Z000000g8gk2IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk2IAA"}, "Name": "Robert Ang"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T15:43:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 Test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006XuwMAE", "Name": "QR00000002", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KB6IAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLejIAG", "OwnerName": "Sales User", "SurveyName": "One Time Test 01", "AccountName": "Robert Ang", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Q1 Test", "A1": "yes", "Q2": "Q2 test", "A2": "no", "latest": true, "$$hashKey": "0Q6"},
        {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006YPaMAM"}, "Survey_Target_vod__c": "a2bZ00000007ji2IAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007ji2IAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLejIAG", "Name": "One Time Test 01", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T15:43:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 Test", "MRK_Answer__c": "yes", "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006YPaMAM", "Name": "QR00000008", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KB6IAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLejIAG", "OwnerName": "Sales User", "SurveyName": "One Time Test 01", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Q1 Test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "latest": true, "$$hashKey": "0Q5"},
        {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006Yk5MAE"}, "Survey_Target_vod__c": "a2bZ00000007jnOIAQ", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007jnOIAQ"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLejIAG", "Name": "One Time Test 01", "Account_vod__c": "001Z000000g8gjUIAQ", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjUIAQ"}, "Name": "Amy Baker"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T15:43:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 Test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006Yk5MAE", "Name": "QR00000012", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KB6IAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLejIAG", "OwnerName": "Sales User", "SurveyName": "One Time Test 01", "AccountName": "Amy Baker", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Q1 Test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "latest": true, "$$hashKey": "0Q4"},
        {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006YlhMAE"}, "Survey_Target_vod__c": "a2bZ00000007jniIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007jniIAA"}, "OwnerId": "005U0000000qVRHIA2", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000qVRHIA2"}, "Name": "Vaccine User"}, "Survey_vod__c": "a2cZ0000001GLejIAG", "Name": "One Time Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T15:43:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 Test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006YlhMAE", "Name": "QR00000020", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KB6IAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLejIAG", "OwnerName": "Vaccine User", "SurveyName": "One Time Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Q1 Test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "latest": true, "$$hashKey": "0Q7"},
        {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006ZxAMAU"}, "Survey_Target_vod__c": "a2bZ00000007p6cIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p6cIAA"}, "OwnerId": "005U0000000qVRHIA2", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000qVRHIA2"}, "Name": "Vaccine User"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-03-20T21:05:30.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006ZxAMAU", "Name": "QR00000022", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Vaccine User", "SurveyName": "Recurring Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-03-20", "Q1": "Q1 test", "A1": "", "Q2": "Q2 test", "A2": "yes", "latest": false, "$$hashKey": "0Q9"}
        /*
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006ZxFMAU"}, "Survey_Target_vod__c": "a2bZ00000007p6hIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p6hIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-03-20T21:05:30.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006ZxFMAU", "Name": "QR00000024", "Required_vod__c": false, "Response_vod__c": "no", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Sales User", "SurveyName": "Recurring Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-03-20", "Q1": "Q1 test", "A1": "no", "Q2": "Q2 test", "A2": "yes", "latest": false, "$$hashKey": "0QA"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006ZxKMAU"}, "Survey_Target_vod__c": "a2bZ00000007p6mIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p6mIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-03-20T21:05:30.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006ZxKMAU", "Name": "QR00000026", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Sales User", "SurveyName": "Recurring Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-03-20", "Q1": "Q1 test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "latest": false, "$$hashKey": "0QB"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006ZxPMAU"}, "Survey_Target_vod__c": "a2bZ00000007p6rIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p6rIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-03-20T21:05:30.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006ZxPMAU", "Name": "QR00000028", "Required_vod__c": false, "Response_vod__c": "no", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Sales User", "SurveyName": "Recurring Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-03-20", "Q1": "Q1 test", "A1": "no", "Q2": "Q2 test", "A2": "no", "latest": false, "$$hashKey": "0QC"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006ZxZMAU"}, "Survey_Target_vod__c": "a2bZ00000007p6wIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p6wIAA"}, "OwnerId": "005U0000000qVRHIA2", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000qVRHIA2"}, "Name": "Vaccine User"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-03-20T21:05:30.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006ZxZMAU", "Name": "QR00000030", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Vaccine User", "SurveyName": "Recurring Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-03-20", "Q1": "Q1 test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "latest": false, "$$hashKey": "0QD"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006exlMAA"}, "Survey_Target_vod__c": "a2bZ00000007p9gIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p9gIAA"}, "OwnerId": "005U0000001hxEtIAI", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hxEtIAI"}, "Name": "Erika Carlucci"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-03T12:25:37.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006exlMAA", "Name": "QR00000215", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Erika Carlucci", "SurveyName": "Recurring Test 01", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-03", "Q1": "Q1 test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "Q3": "ABCD", "A3": "Yes", "latest": false, "$$hashKey": "0Q8"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006aLlMAI"}, "Survey_Target_vod__c": "a2bZ00000007p9qIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007p9qIAA"}, "OwnerId": "005U0000001hxR2IAI", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hxR2IAI"}, "Name": "Maura Abate"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-03-20T21:08:46.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006aLlMAI", "Name": "QR00000036", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Maura Abate", "SurveyName": "Recurring Test 01", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-03-20", "Q1": "Q1 test", "A1": "yes", "Q2": "Q2 test", "A2": "no", "latest": true, "$$hashKey": "0QE"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006aMLMAY"}, "Survey_Target_vod__c": "a2bZ00000007pA0IAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pA0IAI"}, "OwnerId": "005U0000001hxR2IAI", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hxR2IAI"}, "Name": "Maura Abate"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-03T19:15:56.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "1a. Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 20, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006aMLMAY", "Name": "QR00000059", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Maura Abate", "SurveyName": "HCP Customer Profile", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-03", "Q1": "1a. Number of people typically at RFM?", "A1": 20, "Q2": "1b. Best days for RFM in this office?", "A2": "Test", "Q3": "1c. Food considerations in this office?", "A3": "Test", "Q4": "1d. Special protocol in this office?", "A4": "Test", "Q5": "2a. Hobbies customer has?", "A5": "Test", "Q6": "2b. What sports does customer play?", "A6": "Test", "Q7": "2c. Customer's favorite sports team?", "A7": "Test", "Q8": "3a. Customer's spouse's name?", "A8": "Test", "Q9": "3b. Customer's children's names/ages?", "A9": "Test", "Q10": "3c. Sports customer's children play?", "A10": "Test", "Q11": "3d. Customer born/raised where?", "A11": "Test", "Q12": "3e. Pets customer has?", "A12": "Test", "Q13": "4a. Undergraduate school attended?", "A13": "Test", "Q14": "4b. Medical school attended?", "A14": "Test", "Q15": "4c. Residency done where?", "A15": "Test", "Q16": "4d. Other training obtained where?", "A16": "Test", "Q17": "5a. Participates-Patient Assist. Pgm?", "A17": "Test", "Q18": "5b. Interested-Patient Assist. Pgm?", "A18": "Yes", "Q19": "5c. Interested-Merck Prod Promo Pgms?", "A19": "No", "Q20": "6. Cust positions (MedDir, etc.)?", "A20": "Test", "Q21": "7a. Will customer attend MMF programs?", "A21": "No", "Q22": "7b. Cust prefers what type of program?", "A22": "Live EMF", "latest": false, "$$hashKey": "0PZ"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006exqMAA"}, "Survey_Target_vod__c": "a2bZ00000007pJRIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pJRIAY"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GLeoIAG", "Name": "Recurring Test 01", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-03T12:25:57.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Q1 test", "MRK_Answer__c": null, "Answer_Choice_vod__c": "yes;0;no;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006exqMAA", "Name": "QR00000218", "Required_vod__c": false, "Response_vod__c": "yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KBGIA2", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GLeoIAG", "OwnerName": "Sales User", "SurveyName": "Recurring Test 01", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-03", "Q1": "Q1 test", "A1": "yes", "Q2": "Q2 test", "A2": "yes", "Q3": "ABCD", "A3": "Yes", "latest": true, "$$hashKey": "0QF"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006fO2MAI"}, "Survey_Target_vod__c": "a2bZ00000007pKeIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pKeIAI"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM44IAG", "Name": "HCP - Total Office Call Initiative", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-24T19:16:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Manages Pharma Representative Interactions", "MRK_Answer__c": null, "Answer_Choice_vod__c": "Primary Function;0;Secondary Function;0;Tertiary Function;0;Fourth Function;0;Fifth Function;0;Sixth Function;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006fO2MAI", "Name": "QR00000221", "Required_vod__c": false, "Response_vod__c": "Primary Function", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KWnIAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GM44IAG", "OwnerName": "Sales User", "SurveyName": "HCP - Total Office Call Initiative", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-24", "Q1": "Manages Pharma Representative Interactions", "A1": "Primary Function", "Q2": "Schedules Pharma Appointments", "A2": "Primary Function", "Q3": "Escorts Pharma Respresentatives in Office", "A3": "Primary Function", "Q4": "Schedules Patient Appointments", "A4": "Primary Function", "Q5": "Greets / Checks In Patients & Updates Patient Records / Chart", "A5": "Primary Function", "Q6": "Takes Inbound Calls from Patients", "A6": "", "Q7": "Triages Patients (Generally Urgent Care or Walk-In Clinics)", "A7": "", "Q8": "Takes Vital Signs", "A8": "", "Q9": "Updates Family & Medical History & Initial Charting", "A9": "", "Q10": "Conducts Patient Exam", "A10": "", "Q11": "Performs Diagnosis", "A11": "", "Q12": "Conducts Research to Form Diagnosis & Select Treatment(s)", "A12": "", "Q13": "Communicates Diagnosis / Selects Treatment Option(s) (Including Preventative)", "A13": "", "Q14": "Explains Diagnosis", "A14": "", "Q15": "Explains Treatment Option(s)", "A15": "", "Q16": "Generates via EMR / Writes Prescriptions", "A16": "", "Q17": "Recommends Need for Further Testing, Evaluation (Referrals)", "A17": "", "Q18": "Manages Samples, Coupons, Vouchers", "A18": "", "Q19": "Manages Patient Education Resources", "A19": "", "Q20": "Delivers patient Education", "A20": "", "Q21": "Delivers Diet and Exercise Counseling", "A21": "", "Q22": "Conducts Patient Monitoring (Case Management)", "A22": "", "Q23": "Manages Patient Assistance Program Information & Administration", "A23": "", "Q24": "Manages Office Staff and Schedules", "A24": "", "Q25": "Fills Prescriptions", "A25": "", "Q26": "Manages Pharmacy Inbound Calls and Requests for Refills and Renewals of Rxs", "A26": "", "Q27": "Completes Prior Authorizations", "A27": "", "Q28": "Performs Laboratory Testing", "A28": "", "Q29": "Performs Diagnostic testing", "A29": "", "Q30": "Performs Testing - Radiological / Other", "A30": "", "latest": false, "$$hashKey": "0PE"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006fOWMAY"}, "Survey_Target_vod__c": "a2bZ00000007pKjIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pKjIAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM44IAG", "Name": "HCP - Total Office Call Initiative", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-24T19:16:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Manages Pharma Representative Interactions", "MRK_Answer__c": null, "Answer_Choice_vod__c": "Primary Function;0;Secondary Function;0;Tertiary Function;0;Fourth Function;0;Fifth Function;0;Sixth Function;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006fOWMAY", "Name": "QR00000251", "Required_vod__c": false, "Response_vod__c": "Primary Function", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KWnIAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GM44IAG", "OwnerName": "Sales Manager", "SurveyName": "HCP - Total Office Call Initiative", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-24", "Q1": "Manages Pharma Representative Interactions", "A1": "Primary Function", "Q2": "Schedules Pharma Appointments", "A2": "Primary Function", "Q3": "Escorts Pharma Respresentatives in Office", "A3": "Primary Function", "Q4": "Schedules Patient Appointments", "A4": "Primary Function", "Q5": "Greets / Checks In Patients & Updates Patient Records / Chart", "A5": "Primary Function", "Q6": "Takes Inbound Calls from Patients", "A6": "Secondary Function", "Q7": "Triages Patients (Generally Urgent Care or Walk-In Clinics)", "A7": "Secondary Function", "Q8": "Takes Vital Signs", "A8": "Secondary Function", "Q9": "Updates Family & Medical History & Initial Charting", "A9": "Secondary Function", "Q10": "Conducts Patient Exam", "A10": "Secondary Function", "Q11": "Performs Diagnosis", "A11": "", "Q12": "Conducts Research to Form Diagnosis & Select Treatment(s)", "A12": "", "Q13": "Communicates Diagnosis / Selects Treatment Option(s) (Including Preventative)", "A13": "", "Q14": "Explains Diagnosis", "A14": "", "Q15": "Explains Treatment Option(s)", "A15": "", "Q16": "Generates via EMR / Writes Prescriptions", "A16": "", "Q17": "Recommends Need for Further Testing, Evaluation (Referrals)", "A17": "", "Q18": "Manages Samples, Coupons, Vouchers", "A18": "", "Q19": "Manages Patient Education Resources", "A19": "", "Q20": "Delivers patient Education", "A20": "", "Q21": "Delivers Diet and Exercise Counseling", "A21": "", "Q22": "Conducts Patient Monitoring (Case Management)", "A22": "", "Q23": "Manages Patient Assistance Program Information & Administration", "A23": "", "Q24": "Manages Office Staff and Schedules", "A24": "", "Q25": "Fills Prescriptions", "A25": "", "Q26": "Manages Pharmacy Inbound Calls and Requests for Refills and Renewals of Rxs", "A26": "", "Q27": "Completes Prior Authorizations", "A27": "", "Q28": "Performs Laboratory Testing", "A28": "", "Q29": "Performs Diagnostic testing", "A29": "", "Q30": "Performs Testing - Radiological / Other", "A30": "", "latest": false, "$$hashKey": "0PF"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006fP0MAI"}, "Survey_Target_vod__c": "a2bZ00000007pKoIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pKoIAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM44IAG", "Name": "HCP - Total Office Call Initiative", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Late_Submission_vod", "LastModifiedDate": "2014-04-24T19:54:46.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Manages Pharma Representative Interactions", "MRK_Answer__c": null, "Answer_Choice_vod__c": "Primary Function;0;Secondary Function;0;Tertiary Function;0;Fourth Function;0;Fifth Function;0;Sixth Function;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006fP0MAI", "Name": "QR00000281", "Required_vod__c": false, "Response_vod__c": "Primary Function", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KWnIAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GM44IAG", "OwnerName": "Sales Manager", "SurveyName": "HCP - Total Office Call Initiative", "AccountName": "Keith Alexander", "Status": "Late_Submission_vod", "LastModifiedDate": "2014-04-24", "Q1": "Manages Pharma Representative Interactions", "A1": "Primary Function", "Q2": "Schedules Pharma Appointments", "A2": "Primary Function", "Q3": "Escorts Pharma Respresentatives in Office", "A3": "Primary Function", "Q4": "Schedules Patient Appointments", "A4": "Primary Function", "Q5": "Greets / Checks In Patients & Updates Patient Records / Chart", "A5": "Primary Function", "Q6": "Takes Inbound Calls from Patients", "A6": "Primary Function", "Q7": "Triages Patients (Generally Urgent Care or Walk-In Clinics)", "A7": "Primary Function", "Q8": "Takes Vital Signs", "A8": "Tertiary Function", "Q9": "Updates Family & Medical History & Initial Charting", "A9": "Primary Function", "Q10": "Conducts Patient Exam", "A10": "Primary Function", "Q11": "Performs Diagnosis", "A11": "Sixth Function", "Q12": "Conducts Research to Form Diagnosis & Select Treatment(s)", "A12": "", "Q13": "Communicates Diagnosis / Selects Treatment Option(s) (Including Preventative)", "A13": "", "Q14": "Explains Diagnosis", "A14": "", "Q15": "Explains Treatment Option(s)", "A15": "", "Q16": "Generates via EMR / Writes Prescriptions", "A16": "", "Q17": "Recommends Need for Further Testing, Evaluation (Referrals)", "A17": "", "Q18": "Manages Samples, Coupons, Vouchers", "A18": "", "Q19": "Manages Patient Education Resources", "A19": "", "Q20": "Delivers patient Education", "A20": "", "Q21": "Delivers Diet and Exercise Counseling", "A21": "", "Q22": "Conducts Patient Monitoring (Case Management)", "A22": "", "Q23": "Manages Patient Assistance Program Information & Administration", "A23": "", "Q24": "Manages Office Staff and Schedules", "A24": "", "Q25": "Fills Prescriptions", "A25": "", "Q26": "Manages Pharmacy Inbound Calls and Requests for Refills and Renewals of Rxs", "A26": "", "Q27": "Completes Prior Authorizations", "A27": "", "Q28": "Performs Laboratory Testing", "A28": "", "Q29": "Performs Diagnostic testing", "A29": "", "Q30": "Performs Testing - Radiological / Other", "A30": "", "latest": true, "$$hashKey": "0PH"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006fnUMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pNTIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pNTIAY"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk2IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk2IAA"}, "Name": "Robert Ang"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-09T19:00:47.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 10, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006fnUMAQ", "Name": "QR00000311", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Robert Ang", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-09", "Q1": "Number of people typically at RFM?", "A1": 10, "Q2": "Best days for RFM in this office?", "A2": "Wednesday", "Q3": "Food considerations in this office?", "A3": "None", "Q4": "Special protocol in this office?", "A4": "NA", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "Tennis", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "Yes", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "No", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "No", "Q22": "Cust prefers what type of program?", "A22": "Lecture", "latest": false, "$$hashKey": "0PW"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006fnqMAA"}, "Survey_Target_vod__c": "a2bZ00000007pNYIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pNYIAY"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjUIAQ", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjUIAQ"}, "Name": "Amy Baker"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-09T19:01:38.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 20, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006fnqMAA", "Name": "QR00000333", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Amy Baker", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-09", "Q1": "Number of people typically at RFM?", "A1": 20, "Q2": "Best days for RFM in this office?", "A2": "Monday", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": true, "$$hashKey": "0PR"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006foCMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pNdIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pNdIAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-09T19:07:09.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006foCMAQ", "Name": "QR00000355", "Required_vod__c": false, "Response_vod__c": "8", "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-09", "Q1": "Number of people typically at RFM?", "A1": "8", "Q2": "Best days for RFM in this office?", "A2": "Monday", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PJ"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006g2eMAA"}, "Survey_Target_vod__c": "a2bZ00000007pOCIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pOCIAY"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-10T19:38:57.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": "50", "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006g2eMAA", "Name": "QR00000399", "Required_vod__c": false, "Response_vod__c": "10", "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-10", "Q1": "Number of people typically at RFM?", "A1": "10", "Q2": "Best days for RFM in this office?", "A2": "Friday", "Q3": "Food considerations in this office?", "A3": "Italian", "Q4": "Special protocol in this office?", "A4": "None", "Q5": "Hobbies customer has?", "A5": "Football", "Q6": "What sports does customer play?", "A6": "Tennis", "Q7": "Customer's favorite sports team?", "A7": "Jets", "Q8": "Customer's spouse's name?", "A8": "Michelle", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Tennis", "Q11": "Customer born/raised where?", "A11": "Italy", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "Yes", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "Yes", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "Yes", "Q22": "Cust prefers what type of program?", "A22": "Lecture", "latest": false, "$$hashKey": "0PT"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006g30MAA"}, "Survey_Target_vod__c": "a2bZ00000007pOHIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pOHIAY"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001GM44IAG", "Name": "HCP - Total Office Call Initiative", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-24T19:16:01.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Manages Pharma Representative Interactions", "MRK_Answer__c": null, "Answer_Choice_vod__c": "Primary Function;0;Secondary Function;0;Tertiary Function;0;Fourth Function;0;Fifth Function;0;Sixth Function;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006g30MAA", "Name": "QR00000421", "Required_vod__c": false, "Response_vod__c": "Secondary Function", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008KWnIAM", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001GM44IAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "HCP - Total Office Call Initiative", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-24", "Q1": "Manages Pharma Representative Interactions", "A1": "Secondary Function", "Q2": "Schedules Pharma Appointments", "A2": "Primary Function", "Q3": "Escorts Pharma Respresentatives in Office", "A3": "Primary Function", "Q4": "Schedules Patient Appointments", "A4": "Primary Function", "Q5": "Greets / Checks In Patients & Updates Patient Records / Chart", "A5": "Primary Function", "Q6": "Takes Inbound Calls from Patients", "A6": "Secondary Function", "Q7": "Triages Patients (Generally Urgent Care or Walk-In Clinics)", "A7": "Secondary Function", "Q8": "Takes Vital Signs", "A8": "Secondary Function", "Q9": "Updates Family & Medical History & Initial Charting", "A9": "Secondary Function", "Q10": "Conducts Patient Exam", "A10": "Secondary Function", "Q11": "Performs Diagnosis", "A11": "", "Q12": "Conducts Research to Form Diagnosis & Select Treatment(s)", "A12": "", "Q13": "Communicates Diagnosis / Selects Treatment Option(s) (Including Preventative)", "A13": "", "Q14": "Explains Diagnosis", "A14": "", "Q15": "Explains Treatment Option(s)", "A15": "", "Q16": "Generates via EMR / Writes Prescriptions", "A16": "Secondary Function", "Q17": "Recommends Need for Further Testing, Evaluation (Referrals)", "A17": "", "Q18": "Manages Samples, Coupons, Vouchers", "A18": "Tertiary Function", "Q19": "Manages Patient Education Resources", "A19": "", "Q20": "Delivers patient Education", "A20": "Secondary Function", "Q21": "Delivers Diet and Exercise Counseling", "A21": "", "Q22": "Conducts Patient Monitoring (Case Management)", "A22": "Tertiary Function", "Q23": "Manages Patient Assistance Program Information & Administration", "A23": "", "Q24": "Manages Office Staff and Schedules", "A24": "Fifth Function", "Q25": "Fills Prescriptions", "A25": "", "Q26": "Manages Pharmacy Inbound Calls and Requests for Refills and Renewals of Rxs", "A26": "", "Q27": "Completes Prior Authorizations", "A27": "Tertiary Function", "Q28": "Performs Laboratory Testing", "A28": "", "Q29": "Performs Diagnostic testing", "A29": "Sixth Function", "Q30": "Performs Testing - Radiological / Other", "A30": "", "latest": false, "$$hashKey": "0PG"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gYXMAY"}, "Survey_Target_vod__c": "a2bZ00000007pSYIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pSYIAY"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-16T15:34:19.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gYXMAY", "Name": "QR00000541", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-16", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Tuesday, Wednesday, FRI", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PK"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gxOMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pU0IAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pU0IAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-17T14:12:26.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gxOMAQ", "Name": "QR00000563", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-17", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Tuesday, Wednesday, FRI", "Q3": "Food considerations in this office?", "A3": "Spicy", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PL"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gxkMAA"}, "Survey_Target_vod__c": "a2bZ00000007pU5IAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pU5IAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-28T15:31:46.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "2", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 2, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gxkMAA", "Name": "QR00000585", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-28", "Q1": "Number of people typically at RFM?", "A1": 2, "Q2": "Best days for RFM in this office?", "A2": "Thurs", "Q3": "Food considerations in this office?", "A3": "Pizza and matzah", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "Quiddich", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PM"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gy6MAA"}, "Survey_Target_vod__c": "a2bZ00000007pUFIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pUFIAY"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk2IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk2IAA"}, "Name": "Robert Ang"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-17T15:39:26.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 11, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gy6MAA", "Name": "QR00000607", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Robert Ang", "Status": "Saved_vod", "LastModifiedDate": "2014-04-17", "Q1": "Number of people typically at RFM?", "A1": 11, "Q2": "Best days for RFM in this office?", "A2": "Wednesday, Friday", "Q3": "Food considerations in this office?", "A3": "None", "Q4": "Special protocol in this office?", "A4": "NA", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "Tennis", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "Yes", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "No", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "No", "Q22": "Cust prefers what type of program?", "A22": "Lecture", "latest": false, "$$hashKey": "0PX"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gyYMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pUUIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pUUIAY"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-17T16:55:43.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 10, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gyYMAQ", "Name": "QR00000629", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-17", "Q1": "Number of people typically at RFM?", "A1": 10, "Q2": "Best days for RFM in this office?", "A2": "MMMMMMMM", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PN"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gyuMAA"}, "Survey_Target_vod__c": "a2bZ00000007pUZIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pUZIAY"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-17T16:55:57.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 10, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gyuMAA", "Name": "QR00000651", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-17", "Q1": "Number of people typically at RFM?", "A1": 10, "Q2": "Best days for RFM in this office?", "A2": "MMMMMMMMJJJ", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PO"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gzVMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pUeIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pUeIAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-17T18:00:28.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gzVMAQ", "Name": "QR00000673", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-17", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Monday, Wednesday", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "Yes", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "Yes", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "Yes", "Q22": "Cust prefers what type of program?", "A22": "Physician Facilitated Interaction(PFI)", "latest": false, "$$hashKey": "0PP"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006gzrMAA"}, "Survey_Target_vod__c": "a2bZ00000007pUjIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pUjIAI"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk2IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk2IAA"}, "Name": "Robert Ang"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-17T18:45:39.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 10, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006gzrMAA", "Name": "QR00000695", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Robert Ang", "Status": "Saved_vod", "LastModifiedDate": "2014-04-17", "Q1": "Number of people typically at RFM?", "A1": 10, "Q2": "Best days for RFM in this office?", "A2": "Wednesday, Thursday, Friday, Monday, Tuesday", "Q3": "Food considerations in this office?", "A3": "None", "Q4": "Special protocol in this office?", "A4": "NA", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "Tennis", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "Yes", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "No", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "No", "Q22": "Cust prefers what type of program?", "A22": "Lecture", "latest": true, "$$hashKey": "0PY"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006h79MAA"}, "Survey_Target_vod__c": "a2bZ00000007pW3IAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pW3IAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-18T19:03:22.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "100", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006h79MAA", "Name": "QR00000744", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-18", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Tuesday, Wednesday, FRI", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PQ"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006h7VMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pW8IAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pW8IAI"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-28T20:49:26.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "100", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006h7VMAQ", "Name": "QR00000766", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales Manager", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-28", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Tuesday, Wednesday, FRI, Sunday", "Q3": "Food considerations in this office?", "A3": "test", "Q4": "Special protocol in this office?", "A4": "test", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0Q3"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hJCMAY"}, "Survey_Target_vod__c": "a2bZ00000007pZvIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pZvIAI"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-22T19:36:44.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "100", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hJCMAY", "Name": "QR00000788", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-22", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Tuesday, Wednesday, FRI", "Q3": "Food considerations in this office?", "A3": "Pizza", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PS"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hJYMAY"}, "Survey_Target_vod__c": "a2bZ00000007pa0IAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pa0IAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-22T19:36:55.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "100", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 100, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hJYMAY", "Name": "QR00000810", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-22", "Q1": "Number of people typically at RFM?", "A1": 100, "Q2": "Best days for RFM in this office?", "A2": "Tuesday, Wednesday, FRI", "Q3": "Food considerations in this office?", "A3": "Pizza", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "Swimming", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "Hockey", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "USMA", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "MedDir", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PI"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hPmMAI"}, "Survey_Target_vod__c": "a2bZ00000007pbcIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pbcIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T17:54:09.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hPmMAI", "Name": "QR00000832", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Sales User", "SurveyName": "Test All Scenarios", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "free text", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "US", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "USA;Canada", "Q5": "Question 5 : Number as Answer Type.", "A5": "", "Q6": "Question 6 : Date as Answer Type.", "A6": "", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "", "Q9": "Question 9 : Description as Answer Type.", "A9": "", "latest": false, "$$hashKey": "0QK"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hPvMAI"}, "Survey_Target_vod__c": "a2bZ00000007pbhIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pbhIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T17:54:09.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hPvMAI", "Name": "QR00000841", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Sales User", "SurveyName": "Test All Scenarios", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "free text", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "US", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "USA;Canada", "Q5": "Question 5 : Number as Answer Type.", "A5": "", "Q6": "Question 6 : Date as Answer Type.", "A6": "2014-04-23", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "2014-04-23T19:28:00.000+0000", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "", "Q9": "Question 9 : Description as Answer Type.", "A9": "", "latest": false, "$$hashKey": "0QL"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hQ9MAI"}, "Survey_Target_vod__c": "a2bZ00000007pbmIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pbmIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T17:54:09.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hQ9MAI", "Name": "QR00000850", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Sales User", "SurveyName": "Test All Scenarios", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "free text", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "US", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "USA;Canada", "Q5": "Question 5 : Number as Answer Type.", "A5": 95, "Q6": "Question 6 : Date as Answer Type.", "A6": "2014-04-23", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "2014-04-23T19:28:00.000+0000", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "long text response", "Q9": "Question 9 : Description as Answer Type.", "A9": "", "latest": false, "$$hashKey": "0QM"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hVJMAY"}, "Survey_Target_vod__c": "a2bZ00000007pbrIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pbrIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T17:54:09.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hVJMAY", "Name": "QR00000859", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Sales User", "SurveyName": "Test All Scenarios", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "free text", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "UK", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "USA;Canada;China", "Q5": "Question 5 : Number as Answer Type.", "A5": 100, "Q6": "Question 6 : Date as Answer Type.", "A6": "2014-04-23", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "2014-04-23T19:28:00.000+0000", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "long text response", "Q9": "Question 9 : Description as Answer Type.", "A9": "", "latest": false, "$$hashKey": "0QN"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hZoMAI"}, "Survey_Target_vod__c": "a2bZ00000007pc1IAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pc1IAA"}, "OwnerId": "005U0000002WKgbIAG", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000002WKgbIAG"}, "Name": "Sales Director"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-14T17:54:09.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hZoMAI", "Name": "QR00000868", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Sales Director", "SurveyName": "Test All Scenarios", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-14", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "", "Q5": "Question 5 : Number as Answer Type.", "A5": "", "Q6": "Question 6 : Date as Answer Type.", "A6": "", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "", "Q9": "Question 9 : Description as Answer Type.", "A9": "", "latest": true, "$$hashKey": "0QO"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hpvMAA"}, "Survey_Target_vod__c": "a2bZ00000007pdYIAQ", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pdYIAQ"}, "OwnerId": "005U0000001hxR2IAI", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hxR2IAI"}, "Name": "Maura Abate"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-24T20:49:27.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "10", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 10, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hpvMAA", "Name": "QR00000877", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Maura Abate", "SurveyName": "HCP Customer Profile", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-24", "Q1": "Number of people typically at RFM?", "A1": 10, "Q2": "Best days for RFM in this office?", "A2": "Weekdays", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0Q0"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006hrAMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pddIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pddIAA"}, "OwnerId": "005U0000001hxR2IAI", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hxR2IAI"}, "Name": "Maura Abate"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-24T20:49:48.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "10", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 10, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006hrAMAQ", "Name": "QR00000899", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Maura Abate", "SurveyName": "HCP Customer Profile", "AccountName": "Ruby Caine", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-24", "Q1": "Number of people typically at RFM?", "A1": 10, "Q2": "Best days for RFM in this office?", "A2": "Weekdays", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "No", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "No", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "Yes", "Q22": "Cust prefers what type of program?", "A22": "Live EMF", "latest": false, "$$hashKey": "0Q1"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006iUsMAI"}, "Survey_Target_vod__c": "a2bZ00000007peCIAQ", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007peCIAQ"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006iUsMAI", "Name": "QR00000921", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "", "Q3": "Adult protocol/standing orders in place?", "A3": "", "Q4": "Primary Contract", "A4": "", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QV"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006ipUMAQ"}, "Survey_Target_vod__c": "a2bZ00000007pghIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pghIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-28T04:03:32.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "1", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 1, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006ipUMAQ", "Name": "QR00000930", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-28", "Q1": "Number of people typically at RFM?", "A1": 1, "Q2": "Best days for RFM in this office?", "A2": "2", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": false, "$$hashKey": "0PU"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006iqzMAA"}, "Survey_Target_vod__c": "a2bZ00000007phBIAQ", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007phBIAQ"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006iqzMAA", "Name": "QR00000952", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales Manager", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QR"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006isaMAA"}, "Survey_Target_vod__c": "a2bZ00000007phQIAQ", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007phQIAQ"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006isaMAA", "Name": "QR00000961", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QS"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006isyMAA"}, "Survey_Target_vod__c": "a2bZ00000007phkIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007phkIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006isyMAA", "Name": "QR00000970", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "text", "Q5": "Secondary Contract", "A5": "John", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "Direct", "latest": false, "$$hashKey": "0QT"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006it7MAA"}, "Survey_Target_vod__c": "a2bZ00000007phpIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007phpIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "No", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006it7MAA", "Name": "QR00000979", "Required_vod__c": false, "Response_vod__c": "No", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "No", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "No", "Q4": "Primary Contract", "A4": "text", "Q5": "Secondary Contract", "A5": "John", "Q6": "Group Purchasing Organization", "A6": "text", "Q7": "Primary Wholesaler", "A7": "update saved", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "Direct", "latest": false, "$$hashKey": "0QU"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006itGMAQ"}, "Survey_Target_vod__c": "a2bZ00000007phuIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007phuIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006itGMAQ", "Name": "QR00000988", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "", "Q5": "Secondary Contract", "A5": "text", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QP"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006itPMAQ"}, "Survey_Target_vod__c": "a2bZ00000007phzIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007phzIAA"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006itPMAQ", "Name": "QR00000997", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales Manager", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "Joe", "Q5": "Secondary Contract", "A5": "text", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QW"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006iwZMAQ"}, "Survey_Target_vod__c": "a2bZ00000007piEIAQ", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007piEIAQ"}, "OwnerId": "005U0000000XMVqIAO", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVqIAO"}, "Name": "Sales Manager"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-29T03:42:12.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006iwZMAQ", "Name": "QR00001028", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales Manager", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Saved_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "Joe", "Q5": "Secondary Contract", "A5": "text", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QX"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006jIiMAI"}, "Survey_Target_vod__c": "a2bZ00000007pkiIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pkiIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T17:45:07.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006jIiMAI", "Name": "QR00001037", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": false, "$$hashKey": "0QY"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006jIrMAI"}, "Survey_Target_vod__c": "a2bZ00000007pknIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pknIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T17:46:42.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006jIrMAI", "Name": "QR00001046", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Sales User", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "Yes", "Q4": "Primary Contract", "A4": "sdf", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": true, "$$hashKey": "0QZ"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006jJKMAY"}, "Survey_Target_vod__c": "a2bZ00000007pksIAA", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007pksIAA"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gjpIAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjpIAA"}, "Name": "Keith Alexander"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-04-29T17:53:05.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": "4", "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": 4, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006jJKMAY", "Name": "QR00001055", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Sales User", "SurveyName": "HCP Customer Profile", "AccountName": "Keith Alexander", "Status": "Submitted_vod", "LastModifiedDate": "2014-04-29", "Q1": "Number of people typically at RFM?", "A1": 4, "Q2": "Best days for RFM in this office?", "A2": "", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": true, "$$hashKey": "0PV"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006kPlMAI"}, "Survey_Target_vod__c": "a2bZ00000007qDLIAY", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007qDLIAY"}, "OwnerId": "005U0000002WKlbIAG", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000002WKlbIAG"}, "Name": "Account Executive"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8fMhIAI", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8fMhIAI"}, "Name": "Cable & Cage Medical Associates"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-13T16:01:46.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "No", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006kPlMAI", "Name": "QR00001117", "Required_vod__c": false, "Response_vod__c": "No", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Account Executive", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Cable & Cage Medical Associates", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-13", "Q1": "Pediatric protocol/standing orders in place?", "A1": "No", "Q2": "Adolescent protocol/standing orders in place?", "A2": "Yes", "Q3": "Adult protocol/standing orders in place?", "A3": "No", "Q4": "Primary Contract", "A4": "Mark Sallinger", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "McKesson", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "Direct", "latest": true, "$$hashKey": "0QQ"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006lJiMAI"}, "Survey_Target_vod__c": "a2bZ00000007qHhIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007qHhIAI"}, "OwnerId": "005U0000000XMVTIA4", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000000XMVTIA4"}, "Name": "Sales User"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8gjUIAQ", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gjUIAQ"}, "Name": "Amy Baker"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-05-14T17:57:11.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006lJiMAI", "Name": "QR00001126", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Sales User", "SurveyName": "Test All Scenarios", "AccountName": "Amy Baker", "Status": "Saved_vod", "LastModifiedDate": "2014-05-14", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "", "Q5": "Question 5 : Number as Answer Type.", "A5": "", "Q6": "Question 6 : Date as Answer Type.", "A6": "", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "", "Q9": "Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey.Description as Answer Type. Informative Text on the Survey", "A9": "", "latest": true, "$$hashKey": "0QI"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006lecMAA"}, "Survey_Target_vod__c": "a2bZ00000007qPpIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007qPpIAI"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8fMZIAY", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8fMZIAY"}, "Name": "AIDS Services Center of Panoramic"}, "Status_vod__c": "Submitted_vod", "LastModifiedDate": "2014-05-16T14:39:27.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006lecMAA", "Name": "QR00001135", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "Test All Scenarios", "AccountName": "AIDS Services Center of Panoramic", "Status": "Submitted_vod", "LastModifiedDate": "2014-05-16", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "UK", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "China;Japan", "Q5": "Question 5 : Number as Answer Type.", "A5": "", "Q6": "Question 6 : Date as Answer Type.", "A6": "2014-05-16", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "2014-05-16T15:30:00.000+0000", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "", "Q9": "Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey.Description as Answer Type. Informative Text on the Survey", "A9": "", "latest": false, "$$hashKey": "0QG"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006lelMAA"}, "Survey_Target_vod__c": "a2bZ00000007qPuIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007qPuIAI"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8fMZIAY", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8fMZIAY"}, "Name": "AIDS Services Center of Panoramic"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-05-16T14:40:07.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006lelMAA", "Name": "QR00001144", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "Test All Scenarios", "AccountName": "AIDS Services Center of Panoramic", "Status": "Saved_vod", "LastModifiedDate": "2014-05-16", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "Yes", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "Test", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "US", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "China;Japan;USA;Canada;UK;Brazil", "Q5": "Question 5 : Number as Answer Type.", "A5": 12, "Q6": "Question 6 : Date as Answer Type.", "A6": "2014-05-16", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "2014-05-16T15:30:00.000+0000", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "Test", "Q9": "Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey.Description as Answer Type. Informative Text on the Survey", "A9": "", "latest": true, "$$hashKey": "0QH"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ00000006lfEMAQ"}, "Survey_Target_vod__c": "a2bZ00000007qQdIAI", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000007qQdIAI"}, "OwnerId": "005Z0000001qQ06IAE", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005Z0000001qQ06IAE"}, "Name": "Ankur Mehrotra"}, "Survey_vod__c": "a2cZ0000001HLvhIAG", "Name": "Test All Scenarios", "Account_vod__c": "001Z000000g8fMhIAI", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8fMhIAI"}, "Name": "Cable & Cage Medical Associates"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-05-16T17:42:23.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Question 1 : Picklist Yes & No as Answer Type.", "MRK_Answer__c": null, "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ00000006lfEMAQ", "Name": "QR00001153", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008LmgIAE", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HLvhIAG", "OwnerName": "Ankur Mehrotra", "SurveyName": "Test All Scenarios", "AccountName": "Cable & Cage Medical Associates", "Status": "Saved_vod", "LastModifiedDate": "2014-05-16", "Q1": "Question 1 : Picklist Yes & No as Answer Type.", "A1": "", "Q2": "Question 2 : Free Text as Answer Type.", "A2": "", "Q3": "Question 3 : Radio Button as Answer Type.", "A3": "", "Q4": "Question 4 : Multi Select as Answer Type.", "A4": "", "Q5": "Question 5 : Number as Answer Type.", "A5": "", "Q6": "Question 6 : Date as Answer Type.", "A6": "2014-05-16", "Q7": "Question 7 : Datetime as Answer Type.", "A7": "2014-05-16T17:39:00.000+0000", "Q8": "Question 8 : Long Text as Answer Type.", "A8": "", "Q9": "Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey. Description as Answer Type. Informative Text on the Survey.Description as Answer Type. Informative Text on the Survey", "A9": "", "latest": true, "$$hashKey": "0QJ"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ0000000AlNFMA0"}, "Survey_Target_vod__c": "a2bZ00000009Qa2IAE", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000009Qa2IAE"}, "OwnerId": "005U0000001hxR2IAI", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hxR2IAI"}, "Name": "Maura Abate"}, "Survey_vod__c": "a2cZ0000001HMkVIAW", "Name": "Vaccine Account Key Facts", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-30T15:37:27.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Pediatric protocol/standing orders in place?", "MRK_Answer__c": "Yes", "Answer_Choice_vod__c": "Yes;0;No;0", "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ0000000AlNFMA0", "Name": "QR00001077", "Required_vod__c": false, "Response_vod__c": "Yes", "Score_vod__c": 0, "Survey_Question_vod__c": "a2aZ00000008LzQIAU", "Type_vod__c": "012U0000000Zaj9IAC", "Survey_vod__c": "a2cZ0000001HMkVIAW", "OwnerName": "Maura Abate", "SurveyName": "Vaccine Account Key Facts", "AccountName": "Ruby Caine", "Status": "Saved_vod", "LastModifiedDate": "2014-04-30", "Q1": "Pediatric protocol/standing orders in place?", "A1": "Yes", "Q2": "Adolescent protocol/standing orders in place?", "A2": "", "Q3": "Adult protocol/standing orders in place?", "A3": "", "Q4": "Primary Contract", "A4": "", "Q5": "Secondary Contract", "A5": "", "Q6": "Group Purchasing Organization", "A6": "", "Q7": "Primary Wholesaler", "A7": "", "Q8": "Primary Physician Distributor", "A8": "", "Q9": "Merck Vaccine Channel Preference", "A9": "", "latest": true, "$$hashKey": "0R0"},
         {"attributes": {"type": "Question_Response_vod__c", "url": "/services/data/v29.0/sobjects/Question_Response_vod__c/a2XZ0000000AlNOMA0"}, "Survey_Target_vod__c": "a2bZ00000009Qa7IAE", "Survey_Target_vod__r": {"attributes": {"type": "Survey_Target_vod__c", "url": "/services/data/v29.0/sobjects/Survey_Target_vod__c/a2bZ00000009Qa7IAE"}, "OwnerId": "005U0000001hx4IIAQ", "Owner": {"attributes": {"type": "Name", "url": "/services/data/v29.0/sobjects/User/005U0000001hx4IIAQ"}, "Name": "Henry Adams"}, "Survey_vod__c": "a2cZ0000001GM3pIAG", "Name": "HCP Customer Profile", "Account_vod__c": "001Z000000g8gk0IAA", "Account_vod__r": {"attributes": {"type": "Account", "url": "/services/data/v29.0/sobjects/Account/001Z000000g8gk0IAA"}, "Name": "Ruby Caine"}, "Status_vod__c": "Saved_vod", "LastModifiedDate": "2014-04-30T15:41:23.000+0000"}, "Order_vod__c": 0, "Question_Text_vod__c": "Number of people typically at RFM?", "MRK_Answer__c": null, "Answer_Choice_vod__c": null, "Text_vod__c": null, "Number_vod__c": null, "Date_vod__c": null, "Datetime_vod__c": null, "Id": "a2XZ0000000AlNOMA0", "Name": "QR00001086", "Required_vod__c": false, "Response_vod__c": null, "Score_vod__c": null, "Survey_Question_vod__c": "a2aZ00000008KU3IAM", "Type_vod__c": "012U0000000Zaj8IAC", "Survey_vod__c": "a2cZ0000001GM3pIAG", "OwnerName": "Henry Adams", "SurveyName": "HCP Customer Profile", "AccountName": "Ruby Caine", "Status": "Saved_vod", "LastModifiedDate": "2014-04-30", "Q1": "Number of people typically at RFM?", "A1": "", "Q2": "Best days for RFM in this office?", "A2": "", "Q3": "Food considerations in this office?", "A3": "", "Q4": "Special protocol in this office?", "A4": "", "Q5": "Hobbies customer has?", "A5": "", "Q6": "What sports does customer play?", "A6": "", "Q7": "Customer's favorite sports team?", "A7": "", "Q8": "Customer's spouse's name?", "A8": "", "Q9": "Customer's children's names/ages?", "A9": "", "Q10": "Sports customer's children play?", "A10": "", "Q11": "Customer born/raised where?", "A11": "", "Q12": "Pets customer has?", "A12": "", "Q13": "Undergraduate school attended?", "A13": "", "Q14": "Medical school attended?", "A14": "", "Q15": "Residency done where?", "A15": "", "Q16": "Other training obtained where?", "A16": "", "Q17": "Participates-Patient Assist. Pgm?", "A17": "", "Q18": "Interested-Patient Assist. Pgm?", "A18": "", "Q19": "Interested-Merck Prod Promo Pgms?", "A19": "", "Q20": "Cust positions (MedDir, etc.)?", "A20": "", "Q21": "Will customer attend MMF programs?", "A21": "", "Q22": "Cust prefers what type of program?", "A22": "", "latest": true, "$$hashKey": "0Q2"}
         */
    ];

    var $t = $('#jquery-datatables-example');

    var columns = [
        {
            "data": "Survey_Target_vod__r",
            "title": "Survey",
            "render": function (data, type, row, meta) {
                return '<a href="">' + data.Name + '</a>';
            }
        },
        {
            "data": "Survey_Target_vod__r.Account_vod__r.Name",
            "title": "Account"
        }
    ];

    $t.dataTable({
        data: data,
        columns: columns
    });

    var thHtml = _.map(columns, function (c) {
        return '<th>' + c.title + '</th>'
    }).join("\n");

    $t.append('<tfoot><tr>' + thHtml + '</tr></tfoot>');


    $t.find('tfoot th').each(function () {
        var title = $t.find('thead th').eq($(this).index()).text();
        $(this).html('<input type="text" placeholder="Search ' + title + '" />');
    });

    // DataTable
    var table = $t.DataTable();

    // Apply the filter
    $t.find("tfoot input").on('keyup change', function () {
        table
            .column($(this).parent().index() + ':visible')
            .search(this.value)
            .draw();
    });


    $scope.setData = function (data) {
        $t.DataTable().clear();
        $t.DataTable().rows.add(data);
        $t.DataTable().draw();
    }

    /*
     setInterval(function() {
     $scope.setData(data.slice(0, Math.floor(Math.random() * data.length) ))
     }, 2000);
     */

}]);

app.controller('DynamicApexExampleCtrl', ['$scope', 'DynamicApex', function ($scope, DynamicApex) {

    DynamicApex.execute('UserTerritoryFetch', 'fetch', {max: 5}, function (err, result) {
        if (err) {
            console.log('error');
            $scope.apexCode = JSON.stringify(err);
            $scope.$apply();
        }

        if (!err) {
            console.log('success');
            console.log(result);
            $scope.apexCode = result.apexCode;
            $scope.result = JSON.stringify(result.result);
            $scope.$apply();
        }
    });


}]);

app.controller('FlagManagerCtrl', ['$scope', '$rootScope', 'items', 'FlagServices', 'ForceTKClient', '$location', '$route', function ($scope, $rootScope, items, FlagServices, ForceTKClient, $location, $route) {

    $rootScope.items = items;

    $scope.view = function ($event, item) {
        $event.preventDefault();
        $scope.item = item;
        $('#editModal').modal();
    }

    $scope.edit = function ($event, item) {
        $event.preventDefault();
        $scope.newItem = false;
        $scope.item = item;
        $('#editModal').modal();
    }

    $scope.addItem = function () {
        $scope.newItem = true;
        $scope.item = {};
        $('#editModal').modal();
    }

    $scope.inactivate = function ($event, item) {
        $event.preventDefault();
        console.log(item);
    }

    $scope.navigate = function ($event, url) {
        $event.preventDefault();
        alert(url);
        top.location = url;
    }

    $scope.saveItem = function (item) {

        var hndlr = function (obj) {
            console.log(obj);
            $('#editModal').modal('hide');
        };

        console.log(item);

        ForceTKClient.client({namedLoginParams: 'd4-admin'})
            .then(function (c) {

                if (!item.Id) {
                    c.createByRemovingExtraValues('Flag_MRK__c', item, hndlr, hndlr);
                } else {
                    c.updateByRemovingExtraValues('Flag_MRK__c', item.Id, item, hndlr, hndlr);
                }

            }, function (err) {
                console.log('ForceTKClient.client err', err);
            });

    }


}]);

app.controller('SurveyServicesCtrl', ['$scope', 'client', 'SurveyServices', 'ForceTKClient', function ($scope, client, SurveyServices, ForceTKClient) {
    $scope.surveyTargetsCount = 1;
    $scope.counter = 0;
    SurveyServices.setClient(client);

    $scope.generateSurveyTargetsAndResponses = function () {
        $scope.running = true;
        $scope.counter = 0;
        $scope.percentComplete = ($scope.counter / parseInt($scope.surveyTargetsCount)) * 100;

        SurveyServices.generateSurveyTargetsAndResponses(parseInt($scope.surveyTargetsCount), function (err, result) {
            if (err) {
                return console.log('err: ' + err);
            }
            ++$scope.counter;
            console.log(result);

            $scope.percentComplete = ($scope.counter / parseInt($scope.surveyTargetsCount)) * 100;

            if ($scope.counter >= $scope.surveyTargetsCount) {
                $scope.running = false;
            }

            $scope.$apply();
        });

    }

}]);

app.controller('FlagDetailCtrl', ['$scope', '$rootScope', '$routeParams', 'item', 'products', 'salesTeams', 'FlagServices', 'ForceTKClient', '$location', '$route', 'UIServices', function ($scope, $rootScope, $routeParams, item, products, salesTeams, FlagServices, ForceTKClient, $location, $route, UIServices) {


    item.products = UIServices.createMultiSelectItems({
        scope: $scope,
        item: item,
        items: products,
        selectedSourceFieldName: 'Product_IDs_MRK__c',
        textFieldName: 'Name',
        selectedFieldName: 'Id',
        watchExpression: 'item.products'
    });

    item.salesTeams = UIServices.createMultiSelectItems({
        scope: $scope,
        item: item,
        items: salesTeams,
        selectedSourceFieldName: 'Sales_Team_IDs_MRK__c',
        textFieldName: 'Name',
        selectedFieldName: 'Id',
        watchExpression: 'item.salesTeams'
    });

    $scope.item = item;
    $scope.cache = {};

    function promptForConfirmation(opts, cb) {
        $scope.confirmationViewTitle = opts.title;
        $scope.confirmationViewMessage = opts.message;
        $('#confirmation-modal').modal();
        $scope.confirmCallback = cb;
    }

    $scope.confirmation = function (selection) {
        $scope.confirmCallback(selection);
        $scope.confirmCallback = null;
    }

    $scope.activateInactivateButtonLabel = function (item, att) {
        return (item.Active_Attachment_MRK__c === att.Id) ? "Inactivate" : "Activate";
    }

    $scope.navigate = function ($event, url) {
        $event.preventDefault();
        alert(url);
        top.location = url;
    }

    $scope.addAttachment = function (item) {
        top.location = '/p/attach/NoteAttach?pid=' + item.Id + '&parentname=0&retURL=' + encodeURIComponent(location.href);
    }

    $scope.saveItem = function (item) {

        var hndlr = function (obj) {
            console.log(obj);
            $('#editModal').modal('hide');
        };

        console.log(item);

        ForceTKClient.client({namedLoginParams: 'd4-admin'})
            .then(function (c) {

                if (!item.Id) {
                    c.createByRemovingExtraValues('Flag_MRK__c', item, hndlr, hndlr);
                } else {
                    c.updateByRemovingExtraValues('Flag_MRK__c', item.Id, item, hndlr, hndlr);
                }

            }, function (err) {
                console.log('ForceTKClient.client err', err);
            });

    }

    $scope.viewContentsOfAttachmentWithId = function (att) {
        var startTimestamp = new Date();

        $scope.progressViewElapsedTime = 0;
        $scope.progressViewTitle = 'Unpacking IDs from ' + att.Name;
        $scope.progress0 = 0;
        $('#progress-modal-view-contents').modal();

        var interval = setInterval(function () {
            $scope.progressViewElapsedTime = (((new Date()) - startTimestamp) / 1000).toFixed();
            $scope.$apply();
        }, 1000);

        var attachmentRecordId = att.Id;

        FlagServices.getIdListFromAttachment(attachmentRecordId)
            .then(function (result) {


                var allIDs = [];
                _.each(result, function (result) {
                    var ids = result.ids.split(',');
                    allIDs = allIDs.concat(ids);
                })
                $scope.cache[attachmentRecordId] = allIDs

                var ids = result[0].ids.split(',');
                $scope.attachmentContents = 'Preview of ' + ids.length + ' of a total of ' + allIDs.length + ' id(s)\n\n' + ids.join('\n');


                $('#progress-modal-view-contents').modal('hide');
                $('#modal-view-contents').modal();

                $scope.progress0 = 0;
                $scope.progress1 = 0;
                clearInterval(interval);

            }, function (err) {
                console.log(err);
                $scope.attachmentContents = err.responseText;
                $('#modal-view-contents').modal();
            }, function (update) {
                $scope.progress0 = ((update.progress * 100) / 2).toFixed(0);
            });
    }

    $scope.activateAttachment = function (att) {
        var startTimestamp = new Date();

        var _activateAttachment = function (att) {

            $scope.progressViewElapsedTime = 0;
            $scope.progressViewTitle = 'Unpacking IDs from ' + att.Name;
            $scope.progress0 = 0;
            $('#progress-modal-view-contents').modal();

            var interval = setInterval(function () {
                $scope.progressViewElapsedTime = (((new Date()) - startTimestamp) / 1000).toFixed();
                $scope.$apply();
            }, 1000);

            var attachmentRecordId = att.Id;

            FlagServices.getIdListFromAttachment(attachmentRecordId)
                .then(function (result) {

                    var allIDs = [];
                    _.each(result, function (result) {
                        var ids = result.ids.split(',');
                        allIDs = allIDs.concat(ids);
                    })
                    $scope.cache[attachmentRecordId] = allIDs

                    $scope.progressViewTitle = 'Finding ID matches for ' + att.Name;
                    $scope.progress1 = 0;
                    FlagServices.findMatchingRecordsForIdsMatchingField(allIDs, 'Merck_ID_MRK__c', function (err, result) {

                    }).then(function (result) {
                        console.log(result);
                        var accountIDs = result;
                        var opts = {
                            "operation": "insertAccountFlags",
                            "flagRecordId": $scope.item.Id,
                            "attachmentRecordId": att.Id,
                            "ids": accountIDs,
                            "batchSize": 500,
                            "parallelLimit": 2
                        };

                        FlagServices.executeOperation(opts)
                            .then(function (result) {
                                console.log(opts.operation + " result", result);


                                FlagServices.updateFlagWithFieldValues($scope.item.Id, {"Active_MRK__c": true, "Active_Attachment_MRK__c": attachmentRecordId})
                                    .then(function (result) {
                                        console.log('updateFlagWithFieldValues result', result);
                                        $scope.progressViewTitle = "Successfully activated " + accountIDs.length + " account flags";
                                        $scope.progressViewCloseShow = true;
                                    }, function (err) {
                                        console.log('updateFlagWithFieldValues err', err);
                                    });

                            }, function (err) {
                                console.log(opts.operation + " err", err);
                            }, function (update) {
                                $scope.progress2 = ((update.progress * 100) / 2).toFixed(0);
                            }
                        );

                        clearInterval(interval);
                    }, function (err) {
                        console.log('err', err);
                    }, function (update) {
                        $scope.progress1 = ((update.progress * 100) / 2).toFixed(0);
                    })

                    window.result = result;
                    var ids = result[0].ids.split(',');
                    $scope.attachmentContents = 'Preview of ' + ids.length + ' of a total of ' + allIDs.length + ' id(s)\n\n' + ids.join('\n');
                }, function (err) {
                    console.log(err);
                    $scope.attachmentContents = err.responseText;
                    $('#modal-view-contents').modal();
                }, function (update) {
                    $scope.progress0 = ((update.progress * 100) / 2).toFixed(0);
                });

        };

        if (item.Active_Attachment_MRK__c != null) {
            FlagServices.inactivateAccountFlagsForFlagId(item.Id)
                .then(function (result) {
                    console.log('inactivateAccountFlagsForFlagId result', result);
                    _activateAttachment(att);
                }, function (err) {
                    console.log('inactivateAccountFlagsForFlagId err', err);
                }, function (update) {

                });
        } else {
            _activateAttachment(att);
        }

    }

    $scope.toggleActivationForAttachment = function (att) {

        // inactivate
        if (item.Active_Attachment_MRK__c === att.Id) {
            FlagServices.inactivateAccountFlagsForFlagId(item.Id)
                .then(function (result) {
                    console.log('inactivateAccountFlagsForFlagId result', result);

                }, function (err) {
                    console.log('inactivateAccountFlagsForFlagId err', err);
                }, function (update) {

                });

        } else if (item.Active_Attachment_MRK__c != null) { // existing activated attachment
            promptForConfirmation({
                "title": "Activate Confirmation",
                "message": "Activating " + att.Name + " will inactivate the currently active attachment.  Do you want to continue?"
            }, function (selection) {
                if (selection === 'yes') {

                    FlagServices.inactivateAccountFlagsForFlagId(item.Id)
                        .then(function (result) {
                            console.log('inactivateAccountFlagsForFlagId result', result);
                            $scope.activateAttachment(att);
                        }, function (err) {
                            console.log('inactivateAccountFlagsForFlagId err', err);
                        }, function (update) {

                        });
                }
            });

        } else { // no activated attachment, so activate
            $scope.activateAttachment(att);
        }

    }

    $scope.findMatchingRecordsForAttachmentWithId = function (attachmentRecordId) {
        FlagServices.findMatchingRecordsForAttachmentIds(attachmentRecordId)
            .then(function (result) {
                console.log(result);
            }, function (err) {
                console.log(err);
            });
    }

    $scope.deleteAccountFlags = function (item) {
        var accountFlagIDs = [];

        FlagServices.getAccountFlagsForFlagId(item.Id)
            .then(function (result) {
                console.log("getAccountFlagsForFlagId result", result);

                var accountFlagIDs = _.map(result.records, function (r) {
                    return r.Id;
                })
                console.log('accountFlagIDs', accountFlagIDs);

                var opts = {
                    "operation": "deleteAccountFlags",
                    "flagRecordId": item.Id,
                    "ids": accountFlagIDs,
                    "batchSize": 300,
                    "parallelLimit": 2
                };

                FlagServices.executeOperation(opts)
                    .then(function (result) {
                        console.log(opts.operation + " result", result);
                    }, function (err) {
                        console.log(opts.operation + " err", err);
                    }, function (notify) {
                        $scope.progress2 = ((update.progress * 100) / 2).toFixed(0);
                    }
                );


            }, function (err) {
                console.log("getAccountFlagsForFlagId err", err);
            }, function (notify) {

            }
        );

    }


}]);

app.controller('JSForcePlaygroundCtrl', ['$scope', 'ForceTKClient', function ($scope, ForceTKClient) {

    $scope.runBatchTest = function () {

        ForceTKClient.client()
            .then(function (c) {

                var conn = new jsforce.Connection({
                    serverUrl: location.protocol + '//' + location.host,
                    sessionId: c.sessionId
                });

                var genericHandler = function (err, result) {
                    if (err) {
                        return console.log('err', err);
                    }
                    console.log('result', result);
                };

                conn.query('select Id, Name from Account', genericHandler);

                conn.sobject("Account").insertBulk([], genericHandler);

            }, function (err) {

            });


    }

}]);

app.controller('DataAuditManagerCtrl', ['$scope', '$route', '$sce', 'AuditServices', 'objectMetadata', 'data', 'UIServices', function ($scope, $route, $sce, AuditServices, objectMetadata, data, UIServices) {
    $scope.alerts = [];
    $scope.addAlert = function(type, msg) {
        $scope.alerts.push({type: type, msg: msg});
    };
    $scope.closeAlert = function(index) {
        $scope.alerts.splice(index, 1);
    };

    var createErrorHandler = function(name) {
        return function(err) {
            $scope.addAlert('error', name + ': ' + err);
            console.log('Error: ' + name, err);
        };
    }

    var enhanceData = function (items, metadata) {

        _.each(items, function (e) {
            e.objectLabel = metadata[e.BMP__Audit_Definition__r.BMP__Object_Name__c].label;
            var fields = metadata[e.BMP__Audit_Definition__r.BMP__Object_Name__c].fields;
            e.fieldLabel = _.find(fields, function (f) {
                return f.name === e.BMP__Field_Name__c;
            }).label;
        });
        return items;
    }

    var enhanceAuditRules = function(items, metadata) {
        _.each(items, function (e) {
            e.objectLabel = metadata[e.BMP__Object_Name__c].label;

            var apiFieldNames = e.BMP__Fields__c.split(';');
            var fields = metadata[e.BMP__Object_Name__c].fields;
            var fieldLabels = [];
            _.each(apiFieldNames, function(f) {
                var fieldMetadata = _.find(fields, function(fieldMetadata) {
                    return f === fieldMetadata.name;
                });
                fieldLabels.push(fieldMetadata.label);
            });
            e.fieldLabels = fieldLabels.join('; ');

        });
        return items;
    }

    var createSelectableKeywordCollections = function(keywordCollections, currentSelectedKewordCollectionIDs) {
        return _.map(keywordCollections, function(kwc) {
            var item = _.cloneDeep(kwc);
            _.assign(item, {text: kwc.Name, selected: _.contains(currentSelectedKewordCollectionIDs, kwc.Id)})
            return item;
        });
    };

    $scope.keywordCollectionNamesFromKeywordCollectionIdsString = function(keywordCollectionIdsString) {
        if (keywordCollectionIdsString == null) {
            return '';
        }

        return _.map(keywordCollectionIdsString.split(';'), function(id) {
            return _.find(data.keywordCollections, function(kwc) {
               return (id === kwc.Id);
            }).Name;
        }).join('; ');
    }

    $scope.data = data;
    $scope.objectMetadata = objectMetadata;
    $scope.items = enhanceData(data.auditResults, data.metadata);
    $scope.metadata = data.metadata;

    $scope.objectChanged = function() {

        AuditServices.getAuditableFieldsForObject($scope.item.BMP__Object_Name__c)
            .then(function(fields) {
                _.each(fields, function(f) {
                    f.name = f.name;
                    f.text = f.label;
                    f.selected = false;
                });
                $scope.item.fieldsForSelectedObject = fields;
                //$scope.item.fieldsForSelectedObject.length = 0;
                //Array.prototype.push.apply($scope.item.fieldsForSelectedObject, fields);
            });
    }

    $scope.auditRules = enhanceAuditRules(data.auditRules, data.metadata);

    $scope.actions = function (item) {
        return '<a href="/' + item.BMP__Target_Record__c + '" target="_blank">view</a> | <a href="#">notify user via email</a>'
    }

    $scope.highlight = function (item) {
        var html = item.BMP__Field_Value__c.replace(item.BMP__Keywords_Matched__c, '<span style="background-color: yellow;">' + item.BMP__Keywords_Matched__c + '</span>');
        return $sce.trustAsHtml(html);
    }

    $scope.addItem = function () {
        $scope.newItem = true;
        $scope.item = {};
        $scope.item.fieldsForSelectedObject = [{text: '', selected: false}];
        //$scope.item.keywordCollections = createSelectableKeywordCollections(data.keywordCollections, []);

        $scope.item.keywordCollections = UIServices.createMultiSelectItems({
            scope: $scope,
            item: $scope.item,
            items: data.keywordCollections,
            selectedSourceFieldName: 'BMP__Keyword_Collection_IDs__c',
            textFieldName: 'Name',
            selectedFieldName: 'Id',
            watchExpression: 'item.keywordCollections'
        });


        // BMP__Keyword_Collection_IDs__c
        $('#editModal').modal();
    }

    $scope.saveItem = function(item) {

        $scope.item.BMP__Fields__c = _($scope.item.fieldsForSelectedObject).filter(function(f) {
            return f.selected;
        }).map(function(f) { return f.name; }).join(';');

        AuditServices.saveAuditDefinition(item).then(function(result) {
            console.log('AuditServices.saveAuditDefinition result', result);
            $scope.item.Id = result.id;
            $scope.addAlert('success', 'Audit Rule "' + result.Name + '" successfully saved');
            $('#editModal').modal('hide');
        }, createErrorHandler('AuditServices.saveAuditDefinition'))
    }

    $scope.editKeywordCollection = function(item) {

        if (item === 'new') {
            $scope.kwc = {type: type};
        } else {
            $scope.kwc = item;
        }

        $('#keywordCollectionEditModal').modal();
    }

    $scope.saveKeywordCollection = function(item) {

        AuditServices.saveKeywordCollection(item).then(function(result) {
            console.log('AuditServices.saveKeywordCollection result', result);
            if (item.type === 'new') {
                $scope.data.keywordCollections.push(result);
            }
            $scope.addAlert('success', 'Keyword Collection "' + result.Name + '" successfully saved');
            $('#keywordCollectionEditModal').modal('hide');
        }, createErrorHandler('AuditServices.saveKeywordCollection'));
    };

    $scope.isRuleFormValid = function() {
        var item = $scope.item;
        if (!item) {
            return false;
        }
        var requiredRuleFieldNames = ['Name', 'BMP__Object_Name__c', 'BMP__Keyword_Collection_IDs__c' /*, 'BMP__Fields__c' */];
        return !_.some(requiredRuleFieldNames, function(fieldName) {
            return  !item.hasOwnProperty(fieldName) || _.isEmpty(item[fieldName]);
        })
    }


}]);

app.controller('AngularMultiSelectExampleCtrl', ['$scope', function ($scope) {
    $scope.items = [
        {
            text: 'General',
            selected: true
        },
        {
            text: 'JANUVIA',
            selected: false
        }
    ];
}]);

app.controller('AngularUIModalExample', ['$scope', '$log', '$modal', function($scope, $log, $modal) {

    $scope.items = ['Apple', 'Orange', 'Pear'];

    $scope.open = function (size) {

        var modalInstance = $modal.open({
            templateUrl: 'myModalContent.html',
            controller: ModalInstanceCtrl,
            size: size,
            resolve: {
                items: function () {
                    return $scope.items;
                }
            }
        });

        modalInstance.result.then(function (selectedItem) {
            $scope.selected = selectedItem;
        }, function () {
            $log.info('Modal dismissed at: ' + new Date());
        });
    };

    var ModalInstanceCtrl = function ($scope, $modalInstance, items) {

        $scope.items = items;
        $scope.selected = {
            item: $scope.items[0]
        };

        $scope.ok = function () {
            $modalInstance.close($scope.selected.item);
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    };

}]);

app.controller('TerritoryHierarchyCtrl', ['$scope', 'ForceTKClient', function ($scope, ForceTKClient) {

    ForceTKClient.client().then(function (c) {

        var queries = {
            'territories': 'select Id, Name, Description, ParentTerritoryId from Territory',
            'userTerritories': 'select Id, IsActive, TerritoryId, UserId from UserTerritory',
            'users': 'select Id, Name, Username from User'
        };

        c.queries(queries, function (results) {
            console.log(results);
            _.each(results.territories.records, function (t) {

                var userTerritory = _.find(results.userTerritories.records, function (ut) {
                    return t.Id === ut.TerritoryId;
                });

                if (userTerritory) {

                    var user = _.find(results.users.records, function (u) {
                        return userTerritory.UserId === u.Id;
                    });

                    t['FullName'] = user.Name || '';
                    t['Username'] = user.Username || '';

                }

            });
            render({data: results.territories.records});
        }, function (err) {
            console.log(err);
        });

    });

    function render(options) {

        $.getScript('https://www.google.com/jsapi', function () {
            console.log('jsapi loaded');

            function drawChart() {
                console.log('drawChart()');
                var data = new google.visualization.DataTable();
                data.addColumn('string', 'Name');
                data.addColumn('string', 'Parent');

                var rows = _.map(options.data, function (e) {
                    return [
                        {v: e.Id, f: '<div><strong>' + e.FullName + '</strong><br/><br/>' + e.Name + '<br/><br/><em>' + e.Description + '</em><div>'},
                        (e.ParentTerritoryId || '')
                    ];
                });
                console.log(rows);
                data.addRows(rows);

                var chart = new google.visualization.OrgChart(document.getElementById('chart_div'));

                google.visualization.events.addListener(chart, 'ready', function (e) {

                    chart.setSelection([
                        {row: 55}
                    ]);

                    $('html, body').animate({
                        scrollTop: $(".google-visualization-orgchart-nodesel").offset().top,
                        scrollLeft: $(".google-visualization-orgchart-nodesel").offset().left - (screen.width / 2)
                    }, 1500);
                });


                chart.draw(data, {allowCollapse: true, allowHtml: true});
            }

            google.load(
                'visualization',
                '1',
                {
                    packages: ['orgchart'],
                    'callback': function () {
                        console.log('orgchart loaded');
                        drawChart();
                    }
                }
            );

        });

    }

}]);

function DataTable(options) {
    this.options = options || {};
    this.$e = $(options['elementId']);
    this.$e.dataTable({
        data: options.data,
        columns: options.columns,
        processing: true,
        "order": [
            [ 5, "desc" ]
        ]
    });

    this.table = this.$e.DataTable();
    window.$tbl = this.$e;
}

DataTable.prototype.setData = function (data) {
    this.data = data;
    this.table.clear();
    this.table.rows.add(data);
    this.table.draw();
}

DataTable.prototype.hideColumns = function (columns) {
    //this.table.columns(0).visible(false);
}

DataTable.prototype.visibleColumns = function (fn, visible) {
    var that = this;
    console.log('start - visibleColumns');

    this.table.columns().each(function (indexArray) {
        _.each(indexArray, function (idx) {
            if (fn(idx)) {
                that.table.columns(idx).visible(visible);
                var $th = $(that.$e.find('tfoot th').get(idx));
                if (visible) {
                    $th.show();
                } else {
                    $th.hide();
                }

            }
        });

    });

    console.log('end - visibleColumns');
    //this.table.columns(0).visible(false);
}

DataTable.prototype.addColumnSearch = function () {
    var that = this;
    var columns = this.options.columns;
    var $t = this.$e;

    var thHtml = _.map(columns, function (c) {
        return '<th>' + c.title + '</th>'
    }).join("\n");

    $t.append('<tfoot><tr>' + thHtml + '</tr></tfoot>');

    var first = true;
    $t.find('tfoot th').each(function () {
        var title = $t.find('thead th').eq($(this).index()).text();
        if (first) {
            first = false;
        } else {
            $(this).html('<input type="text" placeholder="Search ' + title + '" />');
        }
    });

    // Apply the filter
    $t.find("tfoot input").on('keyup change', function () {
        that.table
            .column($(this).parent().index() + ':visible')
            .search(this.value)
            .draw();
    });

}

function DynamicApex() {
}

DynamicApex.prototype.execute = function (apexScriptTemplateName, params, callback) {
    // get <apexScriptTemplateName> template and merge with params
    // prepend apex wrapper code: <all apex code> = wrapper + generated code from apex template
    // wrapper code includes generated id.  this id is used to retrieve results
    // executeAnonymous(<all apex code>)
    // fetch results from DynamicApex object using generated id
    // callback(results)
}

var da = new DynamicApex();
da.execute('userTerritoryFetch', {}, function (results) {

});

(function () {

    window.__appVersion__ = '0.8.1';

// for IE
    if (typeof console === "undefined" || typeof console.log === "undefined") {
        console = {};
        console.log = function () {
        };
    }

    var logEntries = [];
    var $logContainer;

    function l(o) {
        console.log(o);
        logEntries.push(o);
    }

    function showLogConsole() {
        var logElementId = 'log-console';
        var $logContainer = $('#' + logElementId);
        if ($logContainer.size() == 0) {
            $logContainer = $('<div id="' + logElementId + '" class="log-console-overlay"></div>');
            $('body').append($logContainer);
        }

        //$logContainer.html('');
        for (var i = 0; i < logEntries.length; i++) {
            var o = logEntries[i];
            var $logEntry = $('<div/>');
            $logEntry.html('<pre>' + JSON.stringify(o) + '</pre>');
            $logContainer.append($logEntry); //log to container
        }

    }

    var app = angular
        .module('app', ['ngRoute', 'ngResource', 'ngCookies', 'ngSanitize', 'ngTouch', 'ui.bootstrap', 'multi-select', 'ui.select2', 'templates-main', 'app.services', 'app.controllers']);

    app.config(function ($routeProvider) {
        $routeProvider
            .when('/', {
                templateUrl: 'partials/home.html',
                controller: 'HomeCtrl'
            })
            .when('/detail', {
                templateUrl: 'partials/detail.html',
                controller: 'DetailCtrl'
            })
            .when('/survey-target-list', {
                templateUrl: 'partials/survey-target-list.html',
                controller: 'SurveyTargetListCtrl'
            })
            .when('/survey-target-detail/:surveyTargetId', {
                templateUrl: 'partials/survey-target-detail.html',
                controller: 'SurveyTargetDetailCtrl'
            })
            .when('/territory-hierarchy', {
                templateUrl: 'partials/territory-hierarchy.html',
                controller: 'TerritoryHierarchyCtrl'
            })
            .when('/dynamic-apex-example', {
                templateUrl: 'partials/dynamic-apex-example.html',
                controller: 'DynamicApexExampleCtrl'
            }).when('/jquery-datatable-example', {
                templateUrl: 'partials/jquery-datatable-example.html',
                controller: 'JqueryDatatableExampleCtrl'
            }).when('/flag-manager', {
                templateUrl: 'partials/flag-manager.html',
                controller: 'FlagManagerCtrl',
                resolve: {
                    items: ['FlagServices', function (FlagServices) {
                        return FlagServices.getItems();
                    }]
                }
            }).when('/flag-detail/:recordId', {
                templateUrl: 'partials/flag-detail.html',
                controller: 'FlagDetailCtrl',
                resolve: {
                    item: ['$q', 'FlagServices', '$route', function ($q, FlagServices, $route) {
                        if ($route.current.params.recordId === 'new') {
                            var delay = $q.defer();
                            setTimeout(function () {
                                delay.resolve({});
                            }, 1);
                            return delay.promise;
                        } else {
                            return FlagServices.getItemById($route.current.params.recordId);
                        }
                    }],
                    products: ['FlagServices', function (FlagServices) {
                        return FlagServices.getProducts();
                    }],
                    salesTeams: ['FlagServices', function (FlagServices) {
                        return FlagServices.getSalesTeams();
                    }]

                }
            })
            .when('/survey-services', {
                templateUrl: 'partials/survey-services.html',
                controller: 'SurveyServicesCtrl',
                resolve: {
                    client: ['$q', 'ForceTKClient', function ($q, ForceTKClient) {
                        var delay = $q.defer();

                        ForceTKClient.client({namedLoginParams: 'surveys-end-user'}).then(function (c) {
                            delay.resolve(c);
                        }, function (err) {
                            delay.reject(err);
                        });

                        return delay.promise;
                    }]
                }
            })
            .when('/jsforce-playground', {
                templateUrl: 'partials/jsforce-playground.html',
                controller: 'JSForcePlaygroundCtrl'
            })
            .when('/angular-multi-select-example', {
                templateUrl: 'partials/angular-multi-select-example.html',
                controller: 'AngularMultiSelectExampleCtrl'
            })
            .when('/data-audit-manager', {
                templateUrl: 'partials/data-audit-manager.html',
                controller: 'DataAuditManagerCtrl',
                resolve: {
                    objectMetadata: ['AuditServices', function(AuditServices) {
                       return AuditServices.getObjectMetadata();
                    }],
                    data: ['$q', 'AuditServices', function ($q, AuditServices) {

                        var promisesObj = {
                            auditResults: AuditServices.getAuditResults(),
                            auditRules: AuditServices.getAuditRules(),
                            keywordCollections: AuditServices.getKeywordCollections()
                        };

                        return $q.all(promisesObj)
                            .then(function(values) {

                                // fetch object level metadata for all objects referenced by a rule
                                var allResultObjectNames = _.map(values.auditResults, function (r) {
                                    return r.BMP__Audit_Definition__r.BMP__Object_Name__c;
                                });

                                var allRuleObjectNames = _.map(values.auditRules, function(r) { return r.BMP__Object_Name__c; });
                                var uniqObjectNames = _.uniq(allResultObjectNames.concat(allRuleObjectNames));

                                var promises = [];
                                _.each(uniqObjectNames, function (objectName) {
                                    var delay = $q.defer();
                                    AuditServices.client()
                                        .then(function (c) {
                                            c.describe(objectName,
                                                function (result) {
                                                    var obj = {};
                                                    obj[objectName] = result;
                                                    delay.resolve(obj);
                                                }, function (err) {
                                                    delay.reject(err);
                                                });

                                        });
                                    promises.push(delay.promise);
                                });

                                return $q.all(promises)
                                    .then(function (results) {
                                        var metadata = {};
                                        _.each(results, function (result) {
                                            _.extend(metadata, result);
                                        });
                                        values['metadata'] = metadata;
                                        return values;
                                    });

                            });

                    }]
                }
            })
            .when('/angular-ui-modal-example', {
                templateUrl: 'partials/angular-ui-modal-example.html',
                controller: 'AngularUIModalExample'
            })
            .otherwise({
                redirectTo: '/'
            });
    });

    app.config(function ($sceProvider) {
        // Completely disable SCE to support IE7.
        //$sceProvider.enabled(false);
    });

    app.config(['$httpProvider', function ($httpProvider) {
        //Enable cross domain calls
        $httpProvider.defaults.useXDomain = true;

        //$httpProvider.defaults.headers.post["Content-Type"] = "application/x-www-form-urlencoded";

        //Remove the header used to identify ajax call  that would prevent CORS from working
        delete $httpProvider.defaults.headers.common['X-Requested-With'];
    }]);

    app.config(['ForceTKClientProvider', function (ForceTKClientProvider) {
        ForceTKClientProvider.setDefaultLoginParams(
            {
                host: 'test.salesforce.com',
                username: 'sales.user@merck.com.hhusd1',
                password: 'Winter15!'
            }
        );

        ForceTKClientProvider.setNamedLoginParams('surveys-end-user',
            {
                host: 'test.salesforce.com',
                username: 'sales.user@merck.com.hhusd1',
                password: 'Winter15!'
            }
        );


        ForceTKClientProvider.setNamedLoginParams('d11-admin',
            {
                host: 'test.salesforce.com',
                username: 'brian_pfeil@merck.com.hhusd11',
                password: 'Winter2014'
            }
        );


        ForceTKClientProvider.setNamedLoginParams('d1-admin',
            {
                host: 'test.salesforce.com',
                username: 'brian.pfeil@merck.com.hhusd1',
                password: 'ji7shmyt3'
            }
        );


        ForceTKClientProvider.setNamedLoginParams('d4-admin',
            {
                host: 'test.salesforce.com',
                username: 'brian.pfeil@merck.com.hhusd4',
                password: 'moj9be6sw'
            }
        );

        ForceTKClientProvider.setNamedLoginParams('f2-admin',
            {
                host: 'test.salesforce.com',
                username: 'config.test@merck.com.hhusf2',
                password: 'T3st@246'
            }
        );

        ForceTKClientProvider.setNamedLoginParams('2demo-admin',
            {
                host: 'login.salesforce.com',
                username: 'brian.pfeil@2demo.com',
                password: 'method00xSf0DOuNhpE8fwsy1iyV9BmqE'
            }
        );


    }]);

    app.config(['ForceClientFactoryProvider', function (ForceClientFactoryProvider) {

        ForceClientFactoryProvider.addClientDefinition('d1-admin',
            {
                host: 'test.salesforce.com',
                username: 'brian.pfeil@merck.com.hhusd1',
                password: 'ji7shmyt3'
            }
        );


        ForceClientFactoryProvider.addClientDefinition('d4-admin',
            {
                host: 'test.salesforce.com',
                username: 'brian.pfeil@merck.com.hhusd4',
                password: 'moj9be6sw'
            }
        );

        ForceClientFactoryProvider.addClientDefinition('f2-admin',
            {
                host: 'test.salesforce.com',
                username: 'config.test@merck.com.hhusf2',
                password: 'T3st@246'
            }
        );

        ForceClientFactoryProvider.addClientDefinition('2demo-admin',
            {
                host: 'login.salesforce.com',
                username: 'brian.pfeil@2demo.com',
                password: 'method00xSf0DOuNhpE8fwsy1iyV9BmqE'
            }
        );

    }]);

    angular.element(document).ready(function () {

        /*
         $('html')
         .attr('xmlns:ng', 'http://angularjs.org')
         .attr('id', 'ng-app')
         .attr('ng-app', 'app');

         */

        if ($("[ng-view]").size() == 0) {
            l('adding app container div');
            var $appContainer = $('body').append($('<div></div>')).find('div');
            $appContainer
                .attr('id', 'ng-app')
                .attr('ng-app', '')
                .attr('ng-view', '')
                .addClass('ng-app:app');
        }

        if (window != window.top) {
            $('body').addClass('container-no-margins');
        }

        setTimeout(function () {
            //angular.bootstrap($appContainer.get(0), ['app']);
            //l('executing: angular.bootstrap');
            angular.bootstrap(document, ['app']);
        }, 500);

        /*
         var $appContainerElement = $('#survey-analytics-app-container');
         if ($appContainerElement.size() > 0) {
         $appContainerElement
         .attr('ng-app', '')
         .attr('ng-view', '');

         setTimeout(function() {
         angular.bootstrap($appContainerElement.get(0), ['app']);
         }, 500);
         } else {

         setTimeout(function() {
         var $container = $('body')
         .append('<div></div>')
         .attr('ng-app', '')
         .attr('ng-view', '');

         angular.bootstrap($container.get(0), ['app']);
         }, 500);

         }
         */

        /*
         if (location.host.match(/salesforce\.com/) != null) {
         $('#bodyCell')
         .html('')
         .append('<div ng-app ng-view></div>');

         } else {

         if ($('[ng-app],[ng-view]').size() == 0) {
         console.log('adding ng-app and ng-view attributes for angular.bootstrap');
         $('body')
         .attr('ng-app', '')
         .attr('ng-view', '')
         .html('');
         }

         }
         */
    });

})();
