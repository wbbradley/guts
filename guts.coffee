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

isDescendant = (parent, child) ->
  node = child.parentNode
  while node isnt null
    if node is parent
      return true
    node = node.parentNode
  false


# BasicModelView always updates and is therefore only OK for basic templates
# that are not nested or involving forms.
class BasicModelView extends Backbone.View
    get_template: =>
      template = @template or @options.template
      if @className isnt template
        throw 'BasicModelView : error : templates should be named after the semantic class (className: ' + @className + ', template: ' + template + ')'
      template

    render: =>
      if @options.models
        context = {}
        for model_name, model of @options.models
          context[model_name] = model.toJSON()
          context[model_name + '_url'] = model.url
          context[model_name + '_cid'] = model.cid
      else
        context =
          model: @model.toJSON()
          cid: @model.cid
          url: @model.url
      template_result = render @get_template(), context
      # console.log 'BasicModelView : info : rendered "' + template_result + '"'
      @$el.html(template_result)
      @
  
    initialize: =>
      @render()
      if not @render_once and not @options.render_once
        if @options.models
          for model_name, model of @options.models
            @listenTo model, 'change', @render
        else
          @listenTo @model, 'change', @render
  
  class CompositeModelView extends Backbone.View
    _rendered: false

    get_template: =>
      template = @template or @options.template
      if @className isnt template
        throw 'CompositeModelView : error : templates should be named after the semantic class (' + @className + ', ' + template + ')'
      template

    reassign_child_views: =>
      for view in @_child_views
        if view and view.el
          if isDescendant(@el, view.el)
            throw 'CompositeModelView : error : existing view elements should not be magical children'
          if isDescendant(document, view.el)
            throw 'CompositeModelView : error : orphans should not have a home'
          parentNode = view.el.parentNode
          if parentNode
            parentNode.removeNode(view.el)
          selector = if view.tagName then view.tagName else ''
          selector += '.' + view.className
          $placeholder = @$(selector)
          if $placeholder.length > 1
            throw 'CompositeModelView : error : found too many placeholder elements when finding selector "' + selector + '"'
          placeholder = $placeholder[0]
          if not placeholder
            throw 'CompositeModelView : error : couldn\'t find placeholder element to be replaced: selector = "' + selector + '"'
          if placeholder.children.length isnt 0
            throw 'CompositeModelView : error : found a placeholder node (selector is "' + selector + '") in your template that had children. Confused! Bailing out.'
          parentNode = placeholder.parentNode
          parentNode.replaceChild(view.el, placeholder)
          if view.el.parentNode isnt parentNode
            throw 'CompositeModelView : error : replaceChild didn\'t work as expected'
          if view.$el[0] isnt view.el
            throw 'CompositeModelView : error : $el is confused'
      return
       
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
      template_result = render do @get_template, context
      @$el.html(template_result)

      # Put the children back in their place
      @reassign_child_views()
      @
  
    initialize: =>
      template = @get_template()
      @_child_views = []
      @render()
      for binding, view of _.result(@, 'child_views')
        view = if typeof view is 'function' then view() else view
        if not view.className
          console.log 'CompositeModelView : error : child view \'' + binding + '\' must be initialized with a \'className\''
          throw view
        @[binding] = view
        @_child_views.push view
      delete @child_views
      @reassign_child_views()
      @
  
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
      template_result = render @get_template(), context
      @$el.html(template_result)
      @
  
    initialize: (options) =>
      if not @get_template()
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
  
  class BaseCollectionView extends Backbone.View
    initialize: (options) =>
      if not options.item_view_class
        throw 'BaseCollectionView : error : You must specify an item_view_class when creating a BaseCollectionView'
      if not options.collection
        throw 'BaseCollectionView : error : You must specify a collection when creating a BaseCollectionView'
      if options.model
        console.log 'BaseCollectionView : warning : BaseCollectionView does not pay attention to \'model\''
  
      @_childViews = []
      @collection.each @add
  
      @listenTo @collection, 'add', @add
      @listenTo @collection, 'remove', @remove
   
    add: (model) =>
      childView = new @options.item_view_class
        model: model
      @_childViews.push childView
      childEl = childView.render().el
      el = @$el.append(childEl)
  
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
