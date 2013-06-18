datapoints = new Backbone.Collection [
	name: 'Bill', age: 27
	name: 'Alice', age: 28
	name: 'John', age: 18
	name: 'Mary', age: 58
]
$ ->
  selectView = new Guts.BaseCollectionView
    el: $('#sample-select')[0]
    collection: datapoints
    property: 'name'
    model_class:

