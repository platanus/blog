---
title: Using restmod with ui-router
author: 
  - iobaixas
  - bunzli
layout: post
categories:
  - angular
  - restmod
  - ui-router
---


Here at Platan.us we love [ui-router][1], it makes a great backbone for most angular applications.

One of the ui-router core features is resolve, resolve is an optional map of dependencies which should be injected into the controller. If any of these dependencies are promises, they will be resolved and converted to a value before the controller is instantiated. (see [ui-router Resolve][2])

```javascript
angular.module('MyApp').config(function($stateProvide) {
  $stateProvider.state('myState', {
    resolve:{

      // Example using function with returned promise.
      // This is the typical use case of resolve.
      // You need to inject any services that you are
      // using, e.g. $http in this example
      promiseObj:  function($http){
        // $http returns a promise for the url data
        return $http({method: 'GET', url: '/bikes'});
      },

      // Another promise example. If you need to do some
      // processing of the result, use .then, and your
      // promise is chained in for free. This is another
      // typical use case of resolve.
      promiseObj2:  function($http){
        return $http({method: 'GET', url: '/bikes'})
          .then (function (data) {
            return doSomeStuffFirst(data);
          });
      }
    },

    // The controller waits for every one of the above items to be
    // completely resolved before instantiation. For example, the
    // controller will not instantiate until promiseObj's promise has
    // been resolved. Then those objects are injected into the controller
    // and available for use.
    controller: function($scope, promiseObj, promiseObj2){
      // You can be sure that promiseObj is ready to use!
      $scope.items = promiseObj.items;
      $scope.items = promiseObj2.items;
    }
  });
});
```

### The restmod way

Since we usually build our apps on top of RESTfull apis, we use [Restmod][3] to build the model layer. Restmod usually returns unresolved objects instead of promises, to wait for a restmod object to be resolved during ui-router resolve phase we use restmod's `$asPromise` method.

Given the following model definition:

```javascript
angular.module('MyApp').factory('Bike', function(restmod) {
  return restmod.model('/bikes');
});
```

The ui-router state definition would look like this:

```javascript
angular.module('MyApp').config(function($stateProvide) {
  $stateProvider.state('myState', {
    resolve:{
      promiseObj: function(Bike) {
        // $search will return the collection and $asPromise
        // will transform it to a promise that gets resolved
        // when the collection is populated.
        return Bike.$search().$asPromise():
      },

      promiseObj2: function($http){
        return Bike.$search().$asPromise().then(function(_bikes) {
          return doSomeStuffFirst(_bikes);
        });
      }
    },

    controller: function($scope, promiseObj, promiseObj2){
      $scope.bikes = promiseObj;
      $scope.bikes = promiseObj2;
    }
  });
});
```

[1]: https://github.com/angular-ui/ui-router
[2]: https://github.com/angular-ui/ui-router/wiki#resolve
[3]: https://github.com/platanus/angular-restmod
