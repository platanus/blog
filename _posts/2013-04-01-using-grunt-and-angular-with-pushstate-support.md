---
title: Using grunt and angular with pushstate support
author: blackjid
layout: post
tags:
    - grunt
    - angularjs
    - yeoman
redirect_from: grunt/angularjs/yeoman/2013/04/01/using-grunt-and-angular-with-pushstate-support.html
---

One of the neat things about [angularjs][1] routes system is the ability to use the html5 pushstate apis to remove the hash (#) from the url when creating a single page sites.

For this to work you need to tell your server that every request must be rewrited to `/index.html`, this way angular is goint to take care of the rest.

If you are using [yeoman 1.0][2] to scaffold your app, you should have a `Gruntfile.js` in the root of your project. You can add some rewrites using the [connect-modrewrite][3] module. *(Note: Remember to add the connect-modrewrite module to your `package.json`)*

    npm install connect-modrewrite



Require the module in your `Gruntfile.js` adding

```javascript
var modRewrite = require('connect-modrewrite');
```

Then in your livereload configuation add a section in the middlewares

```javascript
livereload: {
    options: {
      port: 9000,
      // Change this to '0.0.0.0' to access the server from outside.
      hostname: '0.0.0.0',
      middleware: function (connect) {
        return [
          modRewrite([
            '!(\\..+)$ / [L]'
          ]),
          lrSnippet,
          mountFolder(connect, '.tmp'),
          mountFolder(connect, yeomanConfig.app)
        ];
      }
    },
}
```

Here in the modRewrite middleware you can pass an array of rules that you want to rewrite (check [here][3] to see how to write this rules)

You have to be careful because if you are requesting a .js file or .css file you should serve that file and **not** rewrite the request. For this I use a regex that matches every url that has one of the most common extensions used in the web. *(Note the `!` at the beggining of the regex means that will invert the match)*

```javascript
'!\\.?(js|css|html|eot|svg|ttf|woff|otf|css|png|jpg|git|ico) / [L]'
```

## Additional things

### Enable pushstate in angular

You will need to enable the pushstate method within angular routes. In the `app.js` file inject the `locationProvider` and the html5Mode line in the config section.

```javascript
.config(['$routeProvider', '$locationProvider', function ($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true);  // Add this line
    $routeProvider
      .when('/', { ...
```

### Absolute urls

Also I was calling my scripts and css files with relatives urls and this only work if you start navigating from the root page.

Change this

```html
<script src="components/angular/angular.js"></script>
```

to this

```html
<script src="/components/angular/angular.js"></script>
```

Note the leading slash. Now the url is absolute.

[1]: http://angularjs.org/
[2]: http://yeoman.io/
[3]: https://github.com/tinganho/connect-modrewrite
