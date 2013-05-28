###
#    Guts Framework for Backbone views
###
#
# Handling subviews:
# http://stackoverflow.com/questions/9337927/how-to-handle-initializing-and-rendering-subviews-in-backbone-js
# Basic render strategy:
# http://ianstormtaylor.com/rendering-views-in-backbonejs-isnt-always-simple/
verbose = false

handlebars_render = (template_name, context) ->
  template = App.Handlebars[template_name]
  if template
    if verbose
      console.log 'Rendering template \'' + template_name + '\''
    output = template context
    return output
  else
    throw 'handlebars_render : error : couldn\'t find template \'' + template_name + '\''

render = handlebars_render

# BasicModelView always updates and is therefore only OK for basic templates
# that are not nested or involving forms.
class BasicModelView extends Backbone.View
    render: =>
      context =
        model: @model.toJSON()
        cid: @model.cid
        url: @model.url
      template_result = render (@template or @options.template), context
      # console.log 'BasicModelView : info : rendered "' + template_result + '"'
      @$el.html(template_result)
      @
  
    initialize: =>
      @render()
      @listenTo @model, 'change', @render
  
  
  class CompositeModelView extends Backbone.View
    _rendered: false
    render: =>
      if @_rendered
        # CompositeModelView should not need to render multiple times since it is
        # associated with a model and not individual fields
        return @
  
      if not @model
        throw 'CompositeModelView : error : model is not set'
  
      @_rendered = true
      context =
        model: @model.toJSON()
        cid: @model.cid
        url: @model.url
      template_result = render (@template or @options.template), context
      @$el.html(template_result)
      @
  
    initialize: =>
      @render()
      for binding, view of _.result(@, 'child_views')
        @[binding] = if typeof view is 'function' then view() else view
  
  class CompositeModelForm extends CompositeModelView
    rerender: =>
      @_rendered = false
      @render()
  
    initialize: =>
      super
      @listenToOnce @model, 'change', @rerender
  
    save: =>
      @listenToOnce @model, 'sync', =>
        if verbose
          console.log 'save succeeded'
      @model.save()
  
    submitted: (e) =>
      e.preventDefault()
      @save
  
    keyup: (e) =>
      data = Backbone.Syphon.serialize(@)
      @model.set data
  
      if @timer
        window.clearTimeout(@timer)
      @timer = window.setTimeout @save, 2000
  
    events: =>
      'submit form': 'submitted'
      'keyup input': 'keyup'
      'keyup textarea': 'keyup'
    
  
  class ModelFieldView extends Backbone.View
    render: =>
      value = @options.model.get(@options.property)
      context = {}
      context[@options.property] = value
      template_result = render (@template or @options.template), context
      @$el.html(template_result)
      @
  
    initialize: (options) =>
      if not (@template or @options.template)
        @render = =>
          value = @options.model.get(@options.property)
          if value
            if @options.unescaped
              @$el.html(value)
            else
              @$el.html(_.escape value)
          @
      if @options.is_form_field
        @listenToOnce @options.model, 'change:' + @options.property, @render
      else
        @render()
        @listenTo @options.model, 'change:' + @options.property, @render
  
  class ModelAttributeFieldView extends Backbone.View
    render: =>
      value = @options.model.get(@options.property)
      if value
        @$el.attr(@options.attribute, value)
      @
    initialize: (options) =>
      if @options.is_form_field
        @listenToOnce @options.model, 'change:' + @options.property, @render
      else
        @render()
        @listenTo @options.model, 'change:' + @options.property, @render
  
  class BaseCollectionView extends Backbone.View
    initialize: (options) =>
      if not options.item_view_class
        throw 'BaseCollectionView : error : no item_view_class specified'
      if not options.collection
        throw 'BaseCollectionView : error : empty or no collection specified'
  
      @_childViews = []
      @collection.each @add
  
      @listenTo @collection, 'add', @add
      @listenTo @collection, 'remove', @remove
   
    add: (model) =>
      childView = new @options.item_view_class
        model: model
      @_childViews.push childView
      @$el.append(childView.render().el)
  
    remove: (model) =>
      window.alert 'remove CALLED'
      viewToRemove = (_(@_childViews).select (cv) => return cv.model == model )[0]
      @_childViews = _(@_childViews).without(viewToRemove)
      @$(viewToRemove.el).remove()

# Export Guts
class Guts
  @BasicModelView:     BasicModelView
  @CompositeModelView: CompositeModelView
  @CompositeModelForm: CompositeModelForm
  @BaseCollectionView: BaseCollectionView
  @ModelFieldView:     ModelFieldView

@Guts = Guts
