#    Guts Framework for Backbone views

# A helper function used in sanity testing the child view reassignment strategy
isDescendant = (parent, child) ->
  node = child.parentNode
  while node isnt null
    if node is parent
      return true
    node = node.parentNode
  false

# A helper function used to transfer child nodes from within an orphaned DOM
# element to its new home in its parent's DOM tree.
moveChildren = (elFrom, elTo) ->
  if elTo.childNodes.length
    throw 'moveChildren : error : destination tag should not have any children'

  while elFrom.childNodes.length
    elTo.appendChild elFrom.childNodes[0]


# BasicModelView is a simple, always-up-to-date view that knows how to
# render itself given a template or className. All Model based Views in Guts
# will attempt to render using their prescribed template.
# @example
#   view = new BasicModelView
#     model: myModel
#     template: 'my-template'
#     el: $('#my-model')
# It should not be necessary to call any methods on BasicModelView, except the
# constructor.
class BasicModelView extends Backbone.View
  # returns the name of the template to pass to
  # Guts.render at render stime. Template path resolution checks the following
  # locations in order: @options.template, @template, @className.
  get_template: =>
      @options.template or @template or @className

  render: =>
    if @options.models
      context = {}
      for model_name, model of @options.models
        context[model_name] = model.toJSON()
        context[model_name + '_url'] = model.url
        context[model_name + '_cid'] = model.cid
    else
      if not @model
        throw new Error 'BasicModelView : error : model is not set'
      context =
        model: @model.toJSON()
        cid: @model.cid
        url: @model.url
    helpers = (_.result @options, 'helpers') or (_.result @, 'helpers')
    template_result = Guts.render @get_template(), context, helpers
    @$el.html(template_result)
    @

  # @param [options] options can contain 'model', or 'models', as well as 'template'. See Backbone.View for more options.
  initialize: (options) =>
    @options = options
    @render()

    if not (@render_once or @options.render_once)
      if @options.models
        for model_name, model of @options.models
          @listenTo model, 'change', @render
      else
        @listenTo @model, 'change', @render
  
class CompositeModelView extends Backbone.View
  _rendered: false
  _fadedIn: true

  get_template: =>
    template = @template or @options.template or @className
    if @className isnt template
      throw "CompositeModelView : error : templates should be named after the semantic class (#{@className}, #{template})"
    template

  # find_view_placeholder is guaranteed to return a valid element that is the placeholder for this child_view
  # ... or throw
  find_view_placeholder: ($el, child_view) ->
    # Find the placeholder
    selector = ".#{child_view.className}"

    $placeholder = $el.find(selector)

    if $placeholder.length > 1
      throw "CompositeModelView : error : found too many placeholder elements when finding selector '#{selector}'"
    placeholder = $placeholder[0]
    if not placeholder
      return null
    if placeholder.children.length isnt 0
      throw "CompositeModelView : error : found a placeholder node (selector is '#{selector}') in your template that had children. Confused! Bailing out."
    return placeholder

  reassign_child_views: =>
    for view in @_child_views
      if view and view.el
        if isDescendant(@el, view.el)
          throw 'CompositeModelView : error : existing view elements should not be magical children'
        if isDescendant(document, view.el)
          throw 'CompositeModelView : error : orphans should not have a home'

        placeholder = @find_view_placeholder(@$el, view)
        if placeholder
          # get the children of the child view and move them into the new placeholder
          moveChildren view.el, placeholder

          # make sure the child view knows its new home
          view.setElement placeholder, true

          if not isDescendant(@el, view.el)
            throw 'CompositeModelView : error : replaceChild didn\'t work as expected'
          if view.$el[0] isnt view.el
            throw 'CompositeModelView : error : $el is confused'
    return
     
  render: =>
    if @_rendered
      # CompositeModelView should not need to render multiple times since it is
      # associated with a model and not individual fields
      return @

    if @options.models
      context = {}
      for model_name, model of @options.models
        context[model_name] = model.toJSON()
        context[model_name + '_url'] = model.url
        context[model_name + '_cid'] = model.cid
    else
      if not @model
        throw 'CompositeModelView : error : model is not set'
      context =
        model: @model.toJSON()
        cid: @model.cid
        url: @model.url
    extra_context = (_.result @options, 'context') or (_.result @, 'context')
    _.extend context, extra_context
    @_rendered = true
    helpers = (_.result @options, 'helpers') or (_.result @, 'helpers')
    template_result = Guts.render @get_template(), context, helpers
    orphans = @$el.children().detach()
    @$el.html(template_result)

    if not @_fadedIn and @options.fadeIn
      #@el.style.opacity = 0
      @el.style['background-color'] = 'lightyellow'
      @el.style['transition'] = 'opacity 1500ms, background-color 2000ms'
      resetStyle = () =>
        @el.style.opacity = 1
        @el.style['background-color'] = 'white'
      computed_style = window.getComputedStyle(@el)
      computed_style.opacity
      computed_style['background-color']
      resetStyle()
      @_fadedIn = true

    # Put the children back in their place
    @reassign_child_views()
    @

  rerender: =>
    @_rendered = false
    @render()

  initialize: (options) =>
    @options = options
    template = @get_template()
    @_child_views = []
    if @options.fadeIn
      @_fadedIn = false
    @render()
    childViews = (_.result(@options, 'child_views') or _.result(@, 'child_views')) or {}
    $dynoViewEls = @$('[data-guts-field]')
    for dynoViewEl in $dynoViewEls
      fieldName = dynoViewEl.getAttribute 'data-guts-field'
      fieldType = dynoViewEl.getAttribute('data-guts-type') or 'text'

      dynoView = new Guts.ModelFieldView
        model: @model
        property: fieldName
        unescaped: fieldType is 'raw'
        className: dynoViewEl.getAttribute 'class'
        tagName: dynoViewEl.tagName
      childViews["dyno_#{fieldName}_#{dynoView.cid}"] = dynoView

    for binding, view of childViews
      view = if typeof view is 'function' then view() else view
      if not view.className
        console.log "CompositeModelView : error : child view '#{binding}' must be initialized with a \'className\'"
        throw view
      @[binding] = view
      @_child_views.push view
    delete @child_views
    @reassign_child_views()

    render_when = @options.render_when or @render_when
    if render_when
      if not _.isArray render_when
        render_when = [render_when]

      for event_name in render_when
        console.log "Listening to #{event_name}"
        @listenTo @model, event_name, @rerender

    if @render_on_change or @options.render_on_change
      if @options.models
        for model_name, model of @options.models
          @listenTo model, 'change', @rerender
      else
        @listenTo @model, 'change', @rerender
    @

class CompositeModelForm extends CompositeModelView
  initialize: (options) =>
    if options.models
      throw 'CompositeModelForm : error : forms do not support multiple associated models'
    super
    @listenTo @model, 'change', @rerender

  submitted: (e) =>
    e.preventDefault()
    @_stop_listening()
    @model.save()
    return false

  _stop_listening: =>
    @stopListening @model, 'change'

  file_chosen: (e) =>
    @_stop_listening()

    # https://developer.mozilla.org/en-US/docs/Using_files_from_web_applications
    if typeof @model.set_file_field isnt 'function'
      console.log 'Guts.CompositeModelForm : warning : file inputs can be handled using Backbone.FormDataTransport.Model associated with this CompositeModelForm'
      return

    for file_element in @$('input[type=file]')
      if file_element.files.length > 0
        for file in file_element.files
          console.log "CompositeModelForm : info : loading file '#{file.name}' from file field '#{file_element.name}'"

          @model.set_file_field file_element.name, file
          @model.save()
          @listenToOnce @model, "change:#{file_element.name}", @rerender
    return


  keyup: (e) =>
    @_stop_listening()

    data = Backbone.Syphon.serialize(@)
    @model.set data

  change_select: =>
    data = Backbone.Syphon.serialize(@)
    @model.set data

    @rerender()
    @_stop_listening()

  events: =>
    'submit form': 'submitted'
    'keyup [contenteditable]': '_stop_listening'
    'keyup input': 'keyup'
    'change input': 'keyup'
    'keyup textarea': 'keyup'
    'change select': 'change_select'
    'change input[type=file]': 'file_chosen'
  

class ModelFieldView extends Backbone.View
  render: =>
    value = @options.model.get(@options.property)
    context = {}
    context[@options.property] = value
    helpers = (_.result @options, 'helpers') or (_.result @, 'helpers')

    if @model.has @options.property
      template_result = @model.get @options.property
    else
      template_result = _.result @model, @options.property

    if not @options.unescaped
      @$el.text(template_result)
    else
      @$el.html(template_result)
    @

  initialize: (options) =>
    @options = options
    if @options.is_form_field
      @listenToOnce @options.model, "change:#{@options.property}", @render
    else
      @render()
      @listenTo @options.model, "change:#{@options.property}", @render

class BaseCollectionView extends Backbone.View
  initialize: (options) =>
    @options = options
    if not options.item_view_class
      throw 'BaseCollectionView : error : You must specify an item_view_class when creating a BaseCollectionView'
    if not options.collection
      throw 'BaseCollectionView : error : You must specify a collection when creating a BaseCollectionView'
    if options.model
      console.log 'BaseCollectionView : warning : BaseCollectionView does not pay attention to \'model\''

    @_child_views = []
    @collection.each @add

    @listenTo @collection, 'add', @add
    @listenTo @collection, 'remove', @remove
    @render()
 
  add: (model) =>
    item_options = {}
    item_options.model = model
    if @options?.item_options
      _.extend item_options, _.result @.options, 'item_options'
    childView = new @options.item_view_class item_options

    comparator = @collection.comparator or @options.comparator or @comparator
    if comparator
      if typeof comparator is 'string'
        comparator_string = comparator
        comparator = (model) => model.get comparator_string
      if typeof comparator isnt 'function'
        throw "Guts : error : BaseCollectionView only understands function or string comparators"
      index = @collection.sortedIndex model, comparator
    else
      index = @_child_views.length

    childEl = childView.render().el

    if index < @_child_views.length
      referenceEl = @_child_views[index].el
      @el.insertBefore childEl, referenceEl
    else
      el = @$el.append(childEl)
    @_child_views.splice index, 0, childView

  remove: (model) =>
    viewToRemove = _.find @_child_views, (item) -> item.model is model
    if not typeof viewToRemove is 'object'
      throw "BaseCollectionView : error : couldn\'t find view to remove from collection corresponding to model #{model.cid}"
    # remove the view from our child views
    @_child_views = _.reject @_child_views, (view) -> view is viewToRemove
    @$(viewToRemove.el).remove()

  at: (index) =>
    return @_child_views[index]

class MultiCollection extends Backbone.Collection
  initialize: =>
    @index = {}

    for collection in options?.collections or []
      @addCollection(collection)

  addCollection: (collection) =>
    # for each collection add its items to our aggregated list
    collection.forEach (model) ->
      @addRelatedItem model
    @listenTo collection, 'add', @addRelatedItem
    @listenTo collection, 'remove', @removeRelatedItem
    return

  removeCollection: (collection) =>
    # for each collection add its items to our aggregated list
    collection.forEach (model) ->
      @removeRelatedItem model
    @stopListening collection, 'add'
    @stopListening collection, 'remove'
    return

  addRelatedItem: (model) =>
    key = model.id or model.get('id')
    if not key
      @listenToOnce model, 'sync', => @addRelatedItem model
    else
      # see if this model is in our list already
      if key of @index
        # this model already exists, bump its counter
        @index[key].count += 1
      else
        # this is a new model we don't yet know about
        @index[key] =
          model: model
          count: 1
        @add model
    return

  removeRelatedItem: (model) ->
    key = model.id or model.get('id')
    if not key
      @stopListening model, 'sync'
    else
      if key of @index
        existing = @index[key]
        if existing.count is 1
          # remove this item
          @remove existing.model
          delete @index[key]
        else
          existing.count -= 1
    return

if Backbone.MultiCollection
  console.log 'Guts : warning : someone has already installed a Backbone.MultiCollection'
else
  Backbone.MultiCollection = MultiCollection

# Export Guts
class Guts
  @BasicModelView:     BasicModelView
  @CompositeModelView: CompositeModelView
  @CompositeModelForm: CompositeModelForm
  @BaseCollectionView: BaseCollectionView
  @ModelFieldView:     ModelFieldView
  @render: (template_name, context, helpers) ->
    template = App.Handlebars[template_name]
    if template
      output = template context,
        helpers: _.defaults {}, helpers, Handlebars.helpers
      return output
    else
      throw "handlebars_render : error : couldn't find template '#{template_name}'"

@Guts = Guts
