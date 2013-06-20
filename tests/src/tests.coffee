Guts.render = (template_name, context)->
	source = $("##{template_name}").html()
	template = Handlebars.compile(source)
	if template
    return template(context)
  else
    throw "handlebars_render : error : couldn't find template '#{template_name}'"

window.runTests = ->
	describe "BasicModelView", ->
		$element = $("<div class='guts-basicmodelview-test'></div>")
		$('body').append($element)
		
		model = new TestBasicModelViewModel
			title: 'Test Model'
			description: 'I am for testing!'
		view = new TestBasicModelView
			model: model
			el: $('.guts-basicmodelview-test')

		it "Renders to the page", ->
			title = $element.children('#bmv-title').text()
			description = $element.children('#bmv-description').text()
			expect(title).toEqual(model.get('title'))
			expect(description).toEqual(model.get('description'))
			