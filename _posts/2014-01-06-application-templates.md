---
title: Using templates to create new rails applications
author: Andres
layout: post
categories:
    - rails
    - templates
---

Rails 4 removed the option to override the behavior of the application builder, but we can use the Application Templates in order to customize the way our applications are created.

Rails has a [nice guide][1] to get started with app templates, but be sure to also check the [docs for Thor's actions][3].

You can look at the [application template][4] that we use at Platanus when we start a new project.

[1]: http://edgeguides.rubyonrails.org/rails_application_templates.html
[2]: http://rubydoc.info/github/wycats/thor/Thor/Actions
[3]: http://rubydoc.info/github/wycats/thor/Thor/Actions
[4]: https://github.com/platanus/guides/blob/master/setup/app_template.rb
