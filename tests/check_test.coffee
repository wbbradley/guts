$ = require 'jquery'
page = require('webpage').create()

page.onConsoleMessage = (msg)->
	console.log msg

page.open 'http://localhost:8080', ->
	failure = page.evaluate ->
		response = false
		sync = setTimeout(->
			$body = $(document.body)
			response = $body.find('.failingAlert').length != 0
		, 1000)
		response
	exit_status = Number(!failure)
	phantom.exit(exit_status)