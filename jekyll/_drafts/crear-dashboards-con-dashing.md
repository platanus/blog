---
title: Crear dashboards con Dashing
author: Agustin
layout: post
categories:
    - dashboard
    - ruby on rails
---

Dashing es una gema que originalmente corre sobre sinatra, pero existe dashing-rails que es una versión modificada para funcionar con Rails 4. El origen de Dashing es, al igual que varios otros proyectos open source, el gran Shopify. 

Después de instalarlo, con las instrucciones que aparecen en el readme, resulta interesante ver cómo crear nuevos widgets y cómo conectarle los datos. 

Para crear un widget llamado bitcoin hacemos 

```bash
    rails g dashing:widget bitcoin
```
 lo cual crea tres archivos

* app/views/dashing/widgets/bitcoin.**html**
* app/assets/stylesheets/dashing/widgets/bitcoin.**scss**
* app/assets/javascripts/dashing/widgets/bitcoin.**coffee**

Un típico **bitcoin.html** sería más o menos así:

```html
<h1 class="title" data-bind="title"></h1>

<h2 class="value" data-bind="current | shortenedNumber | prepend prefix | append suffix"></h2>

<p class="change-rate">
  <i data-bind-class="arrow"></i><span data-bind="difference"></span>
</p>

<p class="more-info" data-bind="moreinfo"></p>

<p class="updated-at" data-bind="updatedAtMessage"></p>
```

el **bitcoin.scss** sería algo así:

```scss
// ----------------------------------------------------------------------------
// Sass declarations
// ----------------------------------------------------------------------------
$background-color:  #47bbb3;
$value-color:       #fff;

$title-color:       rgba(255, 255, 255, 0.7);
$moreinfo-color:    rgba(255, 255, 255, 0.7);

// ----------------------------------------------------------------------------
// Widget-number styles
// ----------------------------------------------------------------------------
.widget-number {

  background-color: $background-color;

  .title {
    color: $title-color;
  }

  .value {
    color: $value-color;
  }

  .change-rate {
    font-weight: 500;
    font-size: 30px;
    color: $value-color;
  }

  .more-info {
    color: $moreinfo-color;
  }

  .updated-at {
    color: rgba(0, 0, 0, 0.3);
  }

}
```
y **bitcoin.coffee**:

```coffeescript
class Dashing.Number extends Dashing.Widget

  @accessor 'current', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      last = parseInt(@get('last'))
      current = parseInt(@get('current'))
      if last != 0
        diff = Math.abs(Math.round((current - last) / last * 100))
        "#{diff}%"
    else
      ""

  @accessor 'arrow', ->
    if @get('last')
      if parseInt(@get('current')) > parseInt(@get('last')) then 'fa fa-arrow-up' else 'fa fa-arrow-down'

  onData: (data) ->
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"
```