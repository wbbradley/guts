// Generated by CoffeeScript 1.6.3
/*
#    Guts Framework for Backbone views
*/


(function() {
  var BaseCollectionView, BasicModelView, CompositeModelForm, CompositeModelView, Guts, ModelFieldView, handlebars_render, isDescendant, moveChildren, render, verbose, _ref, _ref1, _ref2, _ref3, _ref4,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  verbose = false;

  handlebars_render = function(template_name, context) {
    var output, template;
    template = App.Handlebars[template_name];
    if (template) {
      if (verbose) {
        console.log("Rendering template '" + template_name + "'");
      }
      output = template(context);
      return output;
    } else {
      throw "handlebars_render : error : couldn't find template '" + template_name + "'";
    }
  };

  render = handlebars_render;

  isDescendant = function(parent, child) {
    var node;
    node = child.parentNode;
    while (node !== null) {
      if (node === parent) {
        return true;
      }
      node = node.parentNode;
    }
    return false;
  };

  moveChildren = function(elFrom, elTo) {
    var _results;
    if (elTo.childNodes.length) {
      throw 'moveChildren : error : destination tag should not have any children';
    }
    _results = [];
    while (elFrom.childNodes.length) {
      _results.push(elTo.appendChild(elFrom.childNodes[0]));
    }
    return _results;
  };

  BasicModelView = (function(_super) {
    __extends(BasicModelView, _super);

    function BasicModelView() {
      this.initialize = __bind(this.initialize, this);
      this.render = __bind(this.render, this);
      this.get_template = __bind(this.get_template, this);
      _ref = BasicModelView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    BasicModelView.prototype.get_template = function() {
      return this.options.template || this.template || this.className;
    };

    BasicModelView.prototype.render = function() {
      var context, model, model_name, template_result, _ref1;
      if (this.options.models) {
        context = {};
        _ref1 = this.options.models;
        for (model_name in _ref1) {
          model = _ref1[model_name];
          context[model_name] = model.toJSON();
          context[model_name + '_url'] = model.url;
          context[model_name + '_cid'] = model.cid;
        }
      } else {
        if (!this.model) {
          throw new Error('BasicModelView : error : model is not set');
        }
        context = {
          model: this.model.toJSON(),
          cid: this.model.cid,
          url: this.model.url
        };
      }
      template_result = render(this.get_template(), context);
      this.$el.html(template_result);
      return this;
    };

    BasicModelView.prototype.initialize = function() {
      var model, model_name, _ref1, _results;
      this.render();
      if (!(this.render_once || this.options.render_once)) {
        if (this.options.models) {
          _ref1 = this.options.models;
          _results = [];
          for (model_name in _ref1) {
            model = _ref1[model_name];
            _results.push(this.listenTo(model, 'change', this.render));
          }
          return _results;
        } else {
          return this.listenTo(this.model, 'change', this.render);
        }
      }
    };

    return BasicModelView;

  })(Backbone.View);

  CompositeModelView = (function(_super) {
    __extends(CompositeModelView, _super);

    function CompositeModelView() {
      this.initialize = __bind(this.initialize, this);
      this.render = __bind(this.render, this);
      this.reassign_child_views = __bind(this.reassign_child_views, this);
      this.get_template = __bind(this.get_template, this);
      _ref1 = CompositeModelView.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    CompositeModelView.prototype._rendered = false;

    CompositeModelView.prototype.get_template = function() {
      var template;
      template = this.template || this.options.template;
      if (this.className !== template) {
        throw "CompositeModelView : error : templates should be named after the semantic class (" + this.className + ", " + template + ")";
      }
      return template;
    };

    CompositeModelView.prototype.find_view_placeholder = function($el, child_view) {
      var $placeholder, placeholder, selector;
      selector = child_view.tagName ? child_view.tagName : '';
      selector += "." + child_view.className;
      $placeholder = $el.find(selector);
      if ($placeholder.length > 1) {
        throw "CompositeModelView : error : found too many placeholder elements when finding selector '" + selector + "'";
      }
      placeholder = $placeholder[0];
      if (!placeholder) {
        throw "CompositeModelView : error : couldn\'t find placeholder element to be replaced: selector = '" + selector + "'";
      }
      if (placeholder.children.length !== 0) {
        throw "CompositeModelView : error : found a placeholder node (selector is '" + selector + "') in your template that had children. Confused! Bailing out.";
      }
      return placeholder;
    };

    CompositeModelView.prototype.reassign_child_views = function() {
      var placeholder, view, _i, _len, _ref2;
      _ref2 = this._child_views;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        view = _ref2[_i];
        if (view && view.el) {
          if (isDescendant(this.el, view.el)) {
            throw 'CompositeModelView : error : existing view elements should not be magical children';
          }
          if (isDescendant(document, view.el)) {
            throw 'CompositeModelView : error : orphans should not have a home';
          }
          placeholder = this.find_view_placeholder(this.$el, view);
          moveChildren(view.el, placeholder);
          view.setElement(placeholder, true);
          if (!isDescendant(this.el, view.el)) {
            throw 'CompositeModelView : error : replaceChild didn\'t work as expected';
          }
          if (view.$el[0] !== view.el) {
            throw 'CompositeModelView : error : $el is confused';
          }
        }
      }
    };

    CompositeModelView.prototype.render = function() {
      var context, model, model_name, template_result, _ref2;
      if (this._rendered) {
        return this;
      }
      if (this.options.models) {
        context = {};
        _ref2 = this.options.models;
        for (model_name in _ref2) {
          model = _ref2[model_name];
          context[model_name] = model.toJSON();
          context[model_name + '_url'] = model.url;
          context[model_name + '_cid'] = model.cid;
        }
      } else {
        if (!this.model) {
          throw 'CompositeModelView : error : model is not set';
        }
        context = {
          model: this.model.toJSON(),
          cid: this.model.cid,
          url: this.model.url
        };
      }
      this._rendered = true;
      template_result = render(this.get_template(), context);
      this.$el.html(template_result);
      this.reassign_child_views();
      return this;
    };

    CompositeModelView.prototype.initialize = function() {
      var binding, model, model_name, template, view, _ref2, _ref3,
        _this = this;
      template = this.get_template();
      this._child_views = [];
      this.render();
      _ref2 = _.result(this.options, 'child_views') || _.result(this, 'child_views');
      for (binding in _ref2) {
        view = _ref2[binding];
        view = typeof view === 'function' ? view() : view;
        if (!view.className) {
          console.log("CompositeModelView : error : child view '" + binding + "' must be initialized with a \'className\'");
          throw view;
        }
        this[binding] = view;
        this._child_views.push(view);
      }
      delete this.child_views;
      this.reassign_child_views();
      if (this.render_on_change || this.options.render_on_change) {
        if (this.options.models) {
          _ref3 = this.options.models;
          for (model_name in _ref3) {
            model = _ref3[model_name];
            this.listenTo(model, 'change', function() {
              _this._rendered = false;
              return _this.render();
            });
          }
        } else {
          this.listenTo(this.model, 'change', function() {
            _this._rendered = false;
            return _this.render();
          });
        }
      }
      return this;
    };

    return CompositeModelView;

  })(Backbone.View);

  CompositeModelForm = (function(_super) {
    __extends(CompositeModelForm, _super);

    function CompositeModelForm() {
      this.events = __bind(this.events, this);
      this.keyup = __bind(this.keyup, this);
      this.file_chosen = __bind(this.file_chosen, this);
      this.submitted = __bind(this.submitted, this);
      this.save = __bind(this.save, this);
      this.initialize = __bind(this.initialize, this);
      this.rerender = __bind(this.rerender, this);
      _ref2 = CompositeModelForm.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    CompositeModelForm.prototype.rerender = function() {
      this._rendered = false;
      return this.render();
    };

    CompositeModelForm.prototype.initialize = function() {
      if (this.options.models) {
        throw 'CompositeModelForm : error : forms do not support multiple associated models';
      }
      CompositeModelForm.__super__.initialize.apply(this, arguments);
      return this.listenToOnce(this.model, 'change', this.rerender);
    };

    CompositeModelForm.prototype.save = function() {
      var _this = this;
      this.listenToOnce(this.model, 'sync', function() {
        if (verbose) {
          return console.log('save succeeded');
        }
      });
      return this.model.save();
    };

    CompositeModelForm.prototype.submitted = function(e) {
      e.preventDefault();
      return this.save;
    };

    CompositeModelForm.prototype.file_chosen = function(e) {
      var file, file_element, _i, _j, _len, _len1, _ref3, _ref4;
      if (typeof this.model.set_file_field !== 'function') {
        console.log('Guts.CompositeModelForm : warning : file inputs can be handled using Backbone.FormDataTransport.Model associated with this CompositeModelForm');
        return;
      }
      _ref3 = this.$('form input[type=file]');
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        file_element = _ref3[_i];
        if (file_element.files.length > 0) {
          _ref4 = file_element.files;
          for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++) {
            file = _ref4[_j];
            console.log("CompositeModelForm : info : loading file '" + file.name + "' from file field '" + file_element.name + "'");
            this.model.set_file_field(file_element.name, file);
            this.model.save();
          }
        }
      }
    };

    CompositeModelForm.prototype.keyup = function(e) {
      var data;
      data = Backbone.Syphon.serialize(this);
      this.model.set(data);
      if (this.timer) {
        window.clearTimeout(this.timer);
      }
      return this.timer = window.setTimeout(this.save, 2000);
    };

    CompositeModelForm.prototype.events = function() {
      var form_events;
      form_events = {
        'submit form': 'submitted',
        'keyup input': 'keyup',
        'keyup textarea': 'keyup',
        'change input[type=file]': 'file_chosen'
      };
      if (this.extra_events) {
        form_events = _.extend(form_events, _.result(this, 'extra_events'));
      }
      return form_events;
    };

    return CompositeModelForm;

  })(CompositeModelView);

  ModelFieldView = (function(_super) {
    __extends(ModelFieldView, _super);

    function ModelFieldView() {
      this.initialize = __bind(this.initialize, this);
      this.render = __bind(this.render, this);
      _ref3 = ModelFieldView.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    ModelFieldView.prototype.render = function() {
      var context, template_result, value;
      value = this.options.model.get(this.options.property);
      context = {};
      context[this.options.property] = value;
      template_result = render(this.get_template(), context);
      this.$el.html(template_result);
      return this;
    };

    ModelFieldView.prototype.initialize = function(options) {
      var _this = this;
      if (!this.get_template()) {
        this.render = function() {
          var value;
          value = _this.options.model.get(_this.options.property);
          if (value) {
            if (_this.options.unescaped) {
              _this.$el.html(value);
            } else {
              _this.$el.html(_.escape(value));
            }
          }
          return _this;
        };
      }
      if (this.options.is_form_field) {
        return this.listenToOnce(this.options.model, "change:" + this.options.property, this.render);
      } else {
        this.render();
        return this.listenTo(this.options.model, "change:" + this.options.property, this.render);
      }
    };

    return ModelFieldView;

  })(Backbone.View);

  BaseCollectionView = (function(_super) {
    __extends(BaseCollectionView, _super);

    function BaseCollectionView() {
      this.remove = __bind(this.remove, this);
      this.add = __bind(this.add, this);
      this.initialize = __bind(this.initialize, this);
      _ref4 = BaseCollectionView.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    BaseCollectionView.prototype.initialize = function(options) {
      if (!options.item_view_class) {
        throw 'BaseCollectionView : error : You must specify an item_view_class when creating a BaseCollectionView';
      }
      if (!options.collection) {
        throw 'BaseCollectionView : error : You must specify a collection when creating a BaseCollectionView';
      }
      if (options.model) {
        console.log('BaseCollectionView : warning : BaseCollectionView does not pay attention to \'model\'');
      }
      this._child_views = [];
      this.collection.each(this.add);
      this.listenTo(this.collection, 'add', this.add);
      return this.listenTo(this.collection, 'remove', this.remove);
    };

    BaseCollectionView.prototype.add = function(model) {
      var childEl, childView, el;
      childView = new this.options.item_view_class({
        model: model
      });
      this._child_views.push(childView);
      childEl = childView.render().el;
      return el = this.$el.append(childEl);
    };

    BaseCollectionView.prototype.remove = function(model) {
      var viewToRemove, _viewToRemove;
      _viewToRemove = _.where(this._child_views, function(view) {
        return view.model === model;
      });
      if (!_viewToRemove || !_viewToRemove[0]) {
        throw "BaseCollectionView : error : couldn\'t find view to remove from collection corresponding to model " + model.cid;
      }
      viewToRemove = _viewToRemove[0];
      this._child_views = _.where(this._child_views, function(view) {
        return view !== viewToRemove;
      });
      return this.$(viewToRemove.el).remove();
    };

    return BaseCollectionView;

  })(Backbone.View);

  Guts = (function() {
    function Guts() {}

    Guts.BasicModelView = BasicModelView;

    Guts.CompositeModelView = CompositeModelView;

    Guts.CompositeModelForm = CompositeModelForm;

    Guts.BaseCollectionView = BaseCollectionView;

    Guts.ModelFieldView = ModelFieldView;

    return Guts;

  })();

  this.Guts = Guts;

}).call(this);