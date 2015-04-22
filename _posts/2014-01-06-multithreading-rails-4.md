---
title: Multithreading and Rails 4
author: aarellano
layout: post
tags:
    - rails
    - multithreading
redirect_from: rails/multithreading/2014/01/06/multithreading-rails-4.html
---

Ok, Rails 4 is threadsafe by default, so what does that mean? Are our apps faster now? It means that *Rails 4 is multithreaded*? Well, the truth is that this is not a big change in the code of Rails itself, is *just* a different configuration default. Actually, the very same result can be achieved when running Rails 3.2 by uncommenting the `config.threadsafe!` option in the production environment file. But it is a meaningful change since it pops up the parallelism topic within the Rails community (this post is an example of that).

So, what is the threadsafe thing doing? Let's give a look to the [`threadsafe!` method][1]:

```ruby
def threadsafe!
  @preload_frameworks = true
  @cache_classes = true
  @dependency_loading = false
  @allow_concurrency = true
  self
end
```

The first three options are basically making Rails threadsafe by removing code autoloading, and the last one is removing the `Rack::Lock` middleware from the app stack. [This middleware][2] wraps a [mutex][3] around each request, to ensure that code that's not threadsafe won't be run in different threads. Imagine it as a huge semaphore for all our requests, that only allow one request to be processed at a time.

You can check this by running `rake middleware` in a Rails 4 application. You will see the the `Rack::Lock` present, but not when you run it in production `rake middleware RAILS_ENV=production`. Yes, this means that we do need to worry about writing threadsafe code.

A nice way to try this out is by creating an action with a delay in it, like this:

```ruby
class PlatanusController < ApplicationController
  def eat
    sleep 1
    render text: "a banana\n"
  end
end
```

Then if we run our server in production mode `rails s -e production` we should be able to get multiple requests handled simultaneously, right? So, using some zsh magic, we can use the `repeat` command and like this `repeat 5 (curl http://localhost:3000/platanus/eat &)`. Even that WEBrick is a multi threaded server, what I see in the output are responses separtaed by one second each one: not multi threading here. After some time wondering what was going on, I figured out that the `Rack::Lock` middleware is being used when running WEBrick, as a way to remain backwards compatible with the weirdos that are using it in production. And since this *workaround* is being done in the [rails server command][4], it doesn't show up when running `rake middleware`.

So let's use puma now. Just add it to the Gemfile and then run `rails s -e production` and make concurrent requests. Now we do see all of the responses at once. Bien! That's a real Rails application running multiple threads. Well, that's not 100% true if we're running puma under MRI, because a [GIL] [5] is in place; JRuby or Rubinius would give us even a better performance.

Here at Platanus we like [Unicorn][6] a lot, so what about multi processing? Well, in this case the `Rack::Lock` is meaningless, and we shouldn't see any difference when running our code with `threadsafe!` enabled. If you increase the number of workers to 5 (this was the number of requests we were making in our test), then we should see all the responses at once as well, regardless of the `@allow_concurrency` option. But of course, we aren't sharing any memory here.

### Conclusion

If we want to take advantage of running multi threaded applications, we need to use a capable server like puma, and be sure that we're *using* thread safe code. I say *using* and not writing, because this is also true for any *gem* that we may be using. That could be painful if gems are not well documented. Also, using JRuby or Rubinius seems to be a better option for multithreading to avoid the MRI's GIL.

Multi processes servers, like Unicorn, don't share memory, so to allow parallelism they need to multiply the memory needed. But since memory is cheap, and writing code is not, this sounds like a good option too. Also, we can keep using non thread safe libraries.

In any case, removing the `Rack::Lock` middleware seems a good move, since you don't want it for multithreading, or don't need it for multi processes. Kudos for the Rails collaborators!

#### Also check

* [Removing config.threadsafe!](http://tenderlovemaking.com/2012/06/18/removing-config-threadsafe.html)
* [I like Unicorn because it's Unix](http://tomayko.com/writings/unicorn-is-unix)
* [Working with Ruby Threads](http://www.jstorimer.com/products/working-with-ruby-threads)
* [Does ruby have real multithreading?](http://stackoverflow.com/questions/56087/does-ruby-have-real-multithreading)


[1]: https://github.com/rails/rails/blob/568394659c3e56581c684df77c0cc0e6e264a99f/railties/lib/rails/application/configuration.rb#L99-105
[2]: https://github.com/rack/rack/blob/master/lib/rack/lock.rb
[3]: http://www.ruby-doc.org/core-2.0.0/Mutex.html
[4]: https://github.com/rails/rails/blob/master/railties/lib/rails/commands/server.rb#L81-87
[5]: http://en.wikipedia.org/wiki/Global_Interpreter_Lock
[6]: http://unicorn.bogomips.org/
