Guts.render = (template_name, context)->
	source = $("##{template_name}").html()
	template = Handlebars.compile(source)
	if template
    return template(context)
  else
    throw "handlebars_render : error : couldn't find template '#{template_name}'"

window.runTests = ->
	describe "BasicModelView", ->

		describe "Single Model", ->
			$element = $("<div class='guts-basicmodelview-single-model-test'></div>")
			$('body').append($element)

			beforeEach ->
				@model = new TestBasicModelViewModel
					title: 'Test Model'
					description: 'I am for testing!'
				@view = new TestBasicModelView
					className: 'guts-basicmodelview-single-model-test'
					model: @model
					el: $element

			afterEach ->
				$element.empty()

			it "Renders to the page", ->
				title = @view.$el.children('#title').text()
				description = @view.$el.children('#description').text()
				expect(title).toEqual(@model.get('title'))
				expect(description).toEqual(@model.get('description'))

			it "Rerenders when the model is changed", ->
				new_title = "I am a new test title"
				@model.set('title', new_title)
				$new_title = @view.$el.children('#title').text()
				expect(new_title).toEqual($new_title)

		describe "Render Once Set to True", ->
			$element = $("<div class='guts-basicmodelview-single-model-test'></div>")
			$('body').append($element)

			model = new TestBasicModelViewModel
				title: 'Test Model'
			view = new TestBasicModelView
				className: 'guts-basicmodelview-single-model-test'
				model: model
				el: $element
				render_once: true

			it "Doesn't rerender when the model is changed", ->
				original_title = model.get('title')
				model.set('title', "I am a different title!")
				$current_title = view.$el.children('#title').text()
				expect(original_title).toEqual($current_title)

		describe "Multiple Models", ->
			$element = $("<div class='guts-basicmodelview-multiple-model-test'></div>")
			$('body').append($element)

			beforeEach ->
				@model_one = new TestBasicModelViewModel
					title: 'Test Model 1'
				@model_two = new TestBasicModelViewModel
					title: 'Test Model 2'
				@view = new TestBasicModelView
					className: 'guts-basicmodelview-multiple-model-test'
					el: $element
					models:
						first_model: @model_one
						second_model: @model_two

			it "Renders to the page", ->
				first_title = @view.$el.children('#first-model-title').text()
				second_title = @view.$el.children('#second-model-title').text()
				expect(first_title).toEqual(@model_one.get('title'))
				expect(second_title).toEqual(@model_two.get('title'))

			it "Rerenders when either model is changed", ->
				first_model_new_title = "I am the first new title!"
				@model_one.set('title', first_model_new_title)
				$first_model_new_title = @view.$el.children('#first-model-title').text()
				expect(first_model_new_title).toEqual($first_model_new_title)

				second_model_new_title = "I am the second new title!"
				@model_two.set('title', second_model_new_title)
				$second_model_new_title = @view.$el.children('#second-model-title').text()
				expect(second_model_new_title).toEqual($second_model_new_title)
			
			afterEach ->
				$element.empty()

	describe "Composite Model View", ->
		$element = $("<div class='guts-compositemodelview-test'></div>")
		$('body').append($element)

		generate_scaffolding = (jasmine_spec)->
			jasmine_spec.parent_model = new TestCompositeModelViewModel
					title: 'Parent Model'
					description: 'This is a parent view'
			jasmine_spec.child_model = new TestBasicModelViewModel
				title: 'Child Model'
				description: 'This is a child view'
			jasmine_spec.child_view = new TestBasicModelView
				className: 'guts-basicmodelview-single-model-test'
				model: jasmine_spec.child_model
			jasmine_spec.parent_view = new TestCompositeModelView
				className: 'guts-compositemodelview-test'
				model: jasmine_spec.parent_model
				el: $element
				render_on_change: true
				child_views: =>
					child: jasmine_spec.child_view

		describe "Basic Tests", ->

			beforeEach ->
				generate_scaffolding(@)

			it 'Renders to the page', ->
				parent_title = @parent_view.$el.children('#title').text()
				child_title = @child_view.$el.children('#title').text()
				expect(parent_title).toEqual(@parent_model.get('title'))
				expect(child_title).toEqual(@child_model.get('title'))

			it 'Doesnt rerender parent view when child view rerenders', ->
				spyOn(@parent_view, 'render')
				@child_model.set('title', 'doesnt matter')
				expect(@parent_view.render.calls.length).toEqual(0)

			it "Doesn't lose its child views when it rerenders", ->
				@parent_model.set('title', 'New Title')
				child_title = @parent_view.$el.find('.guts-basicmodelview-single-model-test #title').text()
				expect(child_title).toEqual(@child_model.get('title'))

			afterEach ->
				$element.empty()

		describe "Bad Child Templates", ->
			id = '#guts-compositemodelview-test'
			original_template = $(id).text()

			it "Throws error when multiple child templates are found", ->
				new_template = "#{original_template}<div class='guts-basicmodelview-single-model-test'></div>"
				$(id).text(new_template)
				try
					generate_scaffolding(@)
				catch error_message
					err = "CompositeModelView : error : found too many placeholder elements when finding selector '.#{@child_view.className}'"
					expect(error_message).toEqual(err)

			it "Throws error when no placeholder found", ->
				new_template = ""
				$(id).text(new_template)
				try
					generate_scaffolding(@)
				catch error_message
					err = "CompositeModelView : error : couldn't find placeholder element to be replaced: selector = '.#{@child_view.className}'"
					expect(error_message).toEqual(err)

			it "Throws error when placeholder has children", ->
				new_template = "<div class='guts-basicmodelview-single-model-test'><div></div></div>"
				$(id).text(new_template)
				try
					generate_scaffolding(@)
				catch error_message
					err = "CompositeModelView : error : found a placeholder node (selector is '.#{@child_view.className}')" +
								" in your template that had children. Confused! Bailing out."
					expect(error_message).toEqual(err)

			afterEach ->
				$(id).text(original_template)

	describe "Base Collection View", ->
		$element = $("<div class='guts-basecollectionview-test'></div>")
		$('body').append($element)

		beforeEach ->
			@model_one = new TestBasicModelViewModel
				title: 'First Model'
				description: 'I am the first model'
			@model_two = new TestBasicModelViewModel
				title: 'Second Model'
				description: 'I am the second model'
			@collection = new TestBaseCollectionViewCollection
				model: TestBasicModelViewModel
			@collection.remove(@collection.models[0])
			@collection.add([@model_one, @model_two])
			@view = new TestBaseCollectionView
				collection: @collection
				item_view_class: TestBasicModelView
				className: 'guts-basecollectionview-test'

		it "Renders to the page", ->
			expect(@view.$el.children().length).toEqual(2)

		it "Renders a new model into the right place", ->
			@new_model = new TestBasicModelViewModel
				title: 'Middle Model'
			@collection.add(@new_model)
			expect($(@view.$el.children()[1]).find('#title').text()).toEqual(@new_model.get('title'))

		it "Removes a model correctly", ->
			@collection.remove(@model_one)
			expect(@view.$el.children().length).toEqual(1)







