templates = [
	'guts-basicmodelview-single-model-test',
	'guts-basicmodelview-multiple-model-test',
	'guts-compositemodelview-test',
	'guts-basecollectionview-test'
]

loadTemplates = ->
	templates_loaded = 0

	getTemplate = (template_name)->
		$.get "templates/#{template_name}.hbs", (template)->
			$template_script = $("<script type='text/x-handlebars-template' id='#{template_name}'></script>")
			$template_script.text(template)
			$('head').append($template_script)
			templates_loaded += 1
			if templates_loaded is templates.length
				window.runTests()
				jasmineEnv = jasmine.getEnv()
				htmlReporter = new jasmine.HtmlReporter()
				jasmineEnv.addReporter(htmlReporter)
				jasmineEnv.execute()

	getTemplate(template_name) for template_name in templates

$ ->
	do loadTemplates