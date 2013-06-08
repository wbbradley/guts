guts
====

Guts - a Backbone View Framework

The distribution is available in dist/guts.js.

To build dist/guts.js:

```
npm install
node_modules/.bin/coffee -o dist -c guts.coffee
echo `npm ll | grep ^guts | sed 's/@/-/'`.js
```
