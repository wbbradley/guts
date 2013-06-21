$ = require 'jquery'
Browser = require 'zombie'

browser = new Browser()

browser.visit('http://localhost:8080', ->
	$body = $(browser.body)
	failure = $body.find('.failingAlert').length != 0
	process.exit Number(failure)
)