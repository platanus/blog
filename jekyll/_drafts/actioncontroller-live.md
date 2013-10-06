---
title: Rails 4 and Live Streaming
author: Andres
layout: post
categories:
    - rails
    - streaming
---

This is one of the coolest things that Rails 4 brought for us: the ability to keep a persistent connection from the clients to the server. [Live][1] is a new module that we can mix in our controllers, allowing them to stream data to the clients. This module makes use of [Server-sent event][2], that's part of HTML5 (the "HTML5 Rocks" folks wrote a [superb tutorial about SSE][3]).





[1]: https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/metal/live.rb
[2]: http://en.wikipedia.org/wiki/Server-sent_events
[3]: http://www.html5rocks.com/en/tutorials/eventsource/basics/