---
title: Rails DB Connection Pool... even without a DB!
author: Andres
layout: post
categories:
    - rails
    - ActiveRecord
---

This is going to be a super short post, just a *sticky-post* to remember an important behavior of rails when we're dealing with multi-threaded or multi-process web servers.

As we know, there's a *pool size* configuration for our databases (more accurately, this pool is for ActiveRecord connections). ANd we can configure this variable if we want to manage a higher (or lower) number of connections. The thing is, this connections pool is still playing its role when we're not using a DB.

Of course it makes a lot of sense after you think about it, but it was something that I wasn't aware of till a few days ago.
