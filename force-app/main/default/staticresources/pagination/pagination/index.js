$(function() {

  var generateData = function(number) {
    var result = [];

    for (var i = 1; i < number + 1; i++) {
      result.push(i);
    }

    return result;
  };

  var generateObjData = function(number) {
    var result = [];

    for (var i = 1; i < number + 1; i++) {
      result.push({a: i});
    }

    return result;
  };

  //$.fn.pagination.defaults.inlineStyle = false;

  var demoConfigs = [
    {
      id: 1,
      desc: '',
      anchor: '',
      options: {
        dataSource: generateData(100)
      }
    }
  ];

  var hooks = [
    'beforeInit',
    'beforeRender',
    'beforePaging',
    'beforeDestroy',
    'beforeDisable',
    'beforeEnable',
    'beforePreviousOnClick',
    'beforePageOnClick',
    'beforeNextOnClick',
    'beforeGoInputOnEnter',
    'beforeGoButtonOnClick',
    'afterInit',
    'afterRender',
    'afterPaging',
    'afterDestroy',
    'afterDisable',
    'afterEnable',
    'afterPreviousOnClick',
    'afterPageOnClick',
    'afterNextOnClick',
    'afterGoInputOnEnter',
    'afterGoButtonOnClick',
    'afterIsFirstPage',
    'afterIsLastPage'
  ];


  var ctrl = {

    createDemo: function(config) {

      var self = this;
      var id = config.id;
      var desc = config.desc;
      var anchor = config.anchor;
      var options = config.options;

      if (!id) {
        id = Math.floor(Math.random() * 1000);
      }

      var key = 'demo' + id;
      var demoWrapper = $('#J-demo');
      var templates = $('#template-' + key);

      if (!templates.length) {
        templates = $('#template-demo');
      }

      var section = $(templates.html());

      demoWrapper.append(section);

      $('.demo-section-title', section)
          .text(desc)
          .before('<a name="'+ anchor +'"><\/a>');
      $('.preview', section).attr('id', key);

      var paginationWrapper = $('.preview', section);
      var dataContainer = $('.data-container', paginationWrapper);

      dataContainer.css({
        'min-height': Math.min(options.pageSize * 35, 175),
        'max-height': Math.min(options.pageSize * 35, 285)
      });

      !options.callback && (options.callback = function(data, pagination) {
        if (window.console) console.log(id, desc, data, pagination);

        dataContainer.html(self.template(data));
      });

      paginationWrapper.pagination(options);
    },

    createDemos: function() {
      var self = this;
      var demoWrapper = $('#J-demo');

      demoWrapper.html('');

      $.each(demoConfigs, function(index, config) {
        self.createDemo(config);
      });
    },

    template: function(data) {
      var html = '<ul>';

      if (data[0].published || data[0].title) {
        // data from flickr
        $.each(data, function(index, item) {
          html += '<li><a href="'+ item.link +'">'+ (item.title || item.link) +'<\/a><\/li>';
        });
      } else {
        $.each(data, function(index, item) {
          html += '<li>'+ item +'</li>';
        });
      }

      html += '</ul>';

      return html;
    },

    addHooks: function() {
      var eventsContainer = $('#J-events-container');
      var html = '';

      $.each(hooks, function(index, hook) {
        html += '<div class="event-item">' +
            '<label><input type="checkbox" value="'+ hook +'" id="checkbox-'+ hook +'" checked> '+ hook +'<\/label>' +
            '<\/div>'
      });

      eventsContainer.html(html);
    },

    registerHooks: function() {
      var start = (new Date()).getTime();
      var i = 0;

      function logEvent(event, data) {
        if (!$('#checkbox-' + event).is(':checked')) return;

        var logContainer = $('#J-log-container');

        var now = (new Date()).getTime();
        var diff = now - start;

        var logs = [i, "@" + diff / 1000, "[" + event + "]" ];

        var argstr = '&nbsp;Args: ';
        for (var j = 0, len = data.length; j < data.length; j++) {
          try{
            argstr += JSON.stringify(data[j]);
          } catch(e) {
            argstr += data[j].toString();
          }

          if (typeof argstr === 'undefined') continue;

          if (argstr.length > 32) {
            argstr += Object.prototype.toString.call(data[j]);
          }

          if (j < len - 1) {
            argstr += ',';
          }

          logs.push(argstr);

          argstr = '';
        }

        if (window.console) {
          console.log(i, "@" + diff / 1000, "[" + event + "]", data);
        }

        logContainer.append('<li>'+ logs.join(' ') + '<\/li>');

        logContainer.get(0).scrollTop = logContainer.get(0).scrollHeight;

        i++;
      }

      var config = demoConfigs[demoConfigs.length - 1].options;
      $.each(hooks, function(index, hook) {
        config[hook] = function() {
          logEvent(hook, arguments);
        };
      });
    },

    prettyprint: function() {
      $('pre').addClass('prettyprint linenums');

      window.prettyPrint && prettyPrint();
    },

    observer: function() {
      this.registerHooks();
      this.createDemos();
      this.addHooks();
      this.prettyprint();

      var actions = $('#J-actions');
      var logClear = $('#J-log-clear');
      var checkAll = $('#J-checkAll');
      var eventsContainer = $('#J-events-container');
      var gotoTop = $('#gototop');

      logClear.on('click', function() {
        $('#J-log-container').empty();
      });

      actions.on('click', '.button', function() {
        var current = $(this);
        var action = current.attr('data-action');
        var type = current.attr('data-type');
        var params = current.attr('data-params');
        var container = $('#demo11');
        var result;

        if (type === 'get') {
          result = container.pagination(action);

          if (action === 'getSelectedPageData') {
            try {
              result = JSON.stringify(result);
            }
            catch (e) {}
          }

          alert(result);
        }
        else {
          if (params) {
            container.pagination(action, params);
          }
          else {
            container.pagination(action);
          }
        }
      });

      checkAll.on('change', function() {
        $('input[type="checkbox"]', eventsContainer).each(function() {
          var current = $(this);
          current.prop('checked', !current.is(':checked'));
        });
      });

      gotoTop.on('click', function() {
        $('body').get(0).scrollTop = 0;
      });

    },

    init: function() {
      ctrl.observer();
    }
  };

  ctrl.init();
});