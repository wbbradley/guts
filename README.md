guts
====

Guts - a Backbone View Framework

The latest distribution is available in dist/guts.js.

To build dist/guts.js:

```shell
npm install
node_modules/.bin/coffee -o dist -c guts.coffee
cp dist/guts.js dist/`npm ll | grep ^guts | sed 's/@/-/'`.js
```
