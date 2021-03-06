module.exports = (grunt) ->
  grunt.initConfig

    pkg: grunt.file.readJSON('package.json')

    coffee:
      options:
        sourceMap: true
      compile:
        files: [{
          expand: true
          cwd: 'src/'
          src: ['**/*.coffee']
          dest: 'gen/js'
          ext: '.js'
          }]

    watch:
      options:
        livereload: true

      coffee:
        files: 'src/**/*.coffee'
        tasks: ['coffee']

    tests:
      compile:
        files: [{
          expand: true
          cwd: 'tests/src'
          src: ['*.coffee', '../../src/guts.coffee']
          dest: '../gen'
          }]


  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask('default', ['coffee'])