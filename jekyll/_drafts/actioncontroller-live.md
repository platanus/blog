---
title: Rails 4 and Live Streaming
author: Andres
layout: post
categories:
    - rails
    - streaming
---

This is one of the coolest things that Rails 4 brought for us: the ability to keep a persistent connection from the clients to the server. [Live][1] is a new module that we can mix in our controllers, allowing them to stream data to the clients. This module is designed to be used along with [Server-sent event][2], that's part of HTML5 (the "HTML5 Rocks" folks wrote a [superb tutorial about SSE][3]).

OK, so let's give it a try. For instance, we could build a simple application that shows stocks prices, and keep them updated without requiring the users refreshing their browsers. The first thing is to include the `ActionController::Live` module in the controller that we intend to use to stream live content. I'm creating a simple _prices_ action that's going to stream the data back to the clients:

```ruby
class StocksController < ApplicationController
	include ActionController::Live

	def index
	end

	def prices
		5.times do |n|
			response.stream.write "#{n} \n"
			sleep 1
		end
		ensure
			response.stream.close
	end

end
```

And that's it. Thanks to the Live module the client will maintain a persistent connection to the server, and this controller will be able to send these 5 chunks of data without the client requesting them. If you try this running `rails s`, you will probably witness a browser loading for 5 seconds, and then showing the numbers from 0 to 4 all at once. That'll happen if you're using a server that buffers the server's responses, as WEBrick. So in order to send live streams we'd need to use a different server, like [Puma][4], [Thin][5] or [Rainbows][6]. I'll be using the former, just by adding its gem to the Gemfile, and then running again `rails s`.

Ok, so now we can try to send something more structured, and to do this we'll make use of the HTML5 _server-sent events_ implementation (as usual, not yet supported by IE, but I think that there are a couple of js libraries that you can load to make SSEs work in IE). We just need to create an `EventSource` object in the client, and subscribe it to a server stream source. In this example, that's the '/stocks/prices' resource (don't forget to add the routes, check the example code if you don't know how).

```coffee
source = new EventSource('/stocks/prices')
source.addEventListener 'prices', (e) ->
	console.log e.data
```

Now we only need to format the server response following the format that SSEs expects, and to set the `Content-Type` as `text/event-stream`:

```ruby
def prices
	response.headers['Content-Type'] = 'text/event-stream'
	response.stream.write "event: prices\n"
	response.stream.write "data: #{n} \n\n"
	sleep 1
end
```

From what I see in the [current version of the Live module][7], it seems that in a future release of rails we'll have a `SSE` class that's going to make things easier to comply with the SSEs format.

That's it. I see that there's a lot of potential here. I'd like to expand this example to a bi-directional communication application, probably using a pub-sub server, so stay tuned.

If you want to read more about rails live streaming, these are good resources:
http://tenderlovemaking.com/2012/07/30/is-it-live.html
http://edgeguides.rubyonrails.org/action_controller_overview.html#live-streaming-of-arbitrary-data


[1]: https://github.com/rails/rails/blob/4-0-stable/actionpack/lib/action_controller/metal/live.rb
[2]: http://en.wikipedia.org/wiki/Server-sent_events
[3]: http://www.html5rocks.com/en/tutorials/eventsource/basics/
[4]: http://puma.io/
[5]: http://code.macournoyer.com/thin/
[6]: http://rainbows.rubyforge.org/
[7]: https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/metal/live.rb