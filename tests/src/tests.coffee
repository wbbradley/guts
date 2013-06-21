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
				title = $element.children('#bmvsm-title').text()
				description = $element.children('#bmvsm-description').text()
				expect(title).toEqual(@model.get('title'))
				expect(description).toEqual(@model.get('description'))

			it "Rerenders when the model is changed", ->
				new_title = "I am a new test title"
				@model.set('title', new_title)
				$new_title = $element.children('#bmvsm-title').text()
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
				console.log $element.children().text()
				$current_title = $element.children('#bmvsm-title').text()
				expect(original_title).toEqual($current_title)
				$element.empty()

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
				first_title = $element.children('#bmvmm-first-model-title').text()
				second_title = $element.children('#bmvmm-second-model-title').text()
				expect(first_title).toEqual(@model_one.get('title'))
				expect(second_title).toEqual(@model_two.get('title'))

			it "Rerenders when either model is changed", ->
				first_model_new_title = "I am the first new title!"
				@model_one.set('title', first_model_new_title)
				$first_model_new_title = $element.children('#bmvmm-first-model-title').text()
				expect(first_model_new_title).toEqual($first_model_new_title)

				second_model_new_title = "I am the second new title!"
				@model_two.set('title', second_model_new_title)
				$second_model_new_title = $element.children('#bmvmm-second-model-title').text()
				expect(second_model_new_title).toEqual($second_model_new_title)
			
			afterEach ->
				$element.empty()