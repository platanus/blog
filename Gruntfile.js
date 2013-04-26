'use strict';
var lrSnippet = require('grunt-contrib-livereload/lib/utils').livereloadSnippet;
var mountFolder = function (connect, dir) {
  return connect.static(require('path').resolve(dir));
};
var proxySnippet = require('grunt-connect-proxy/lib/utils').proxyRequest;

module.exports = function (grunt) {
  // load all grunt tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  // configurable paths
  var jekyllConfig = {
    root: 'jekyll',
    dist: 'jekyll/_site',
    posts: 'jekyll/_posts',
    drafts: 'jekyll/_drafts'
  };

  grunt.initConfig({
    jekyll: jekyllConfig,
    watch: {
      livereload: {
        files: [
          '<%= jekyll.posts %>/{,*/}*.md',
          '<%= jekyll.drafts %>/{,*/}*.md',
          '<%= jekyll.root %>/css/{,*/}*.css',
          '<%= jekyll.root %>/images/{,*/}*.{png,jpg,jpeg}'
        ],
        tasks: ['exec:compile','livereload']
      }
    },
    exec: {
      compile: {
        cmd: 'cd <%= jekyll.root %> && jekyll build --drafts'
      }
    },
    connect: {
      proxies: [
        {
          context: '/assets',
          host: 'platan.us',
          port: 80,
          changeOrigin: true
        }
      ],
      livereload: {
        options: {
          port: 9000,
          // Change this to '0.0.0.0' to access the server from outside.
          hostname: '0.0.0.0',
          middleware: function (connect) {
            return [
              proxySnippet,
              lrSnippet,
              mountFolder(connect, jekyllConfig.dist)
            ];
          }
        }
      }
    },
    open: {
      server: {
        url: 'http://localhost:<%= connect.livereload.options.port %>'
      }
    }
  });

  grunt.renameTask('regarde', 'watch');

  grunt.registerTask('server', [
    'configureProxies',
    'exec:compile',
    'livereload-start',
    'connect:livereload',
    'open',
    'watch'
  ]);

  grunt.registerTask('default', ['server']);
};
