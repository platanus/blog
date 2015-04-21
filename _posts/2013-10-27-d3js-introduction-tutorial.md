---
title: d3js Gentle Introduction
author: agustinf
layout: post
categories:
    - javascript
    - libraries
    - svg
    - graphics
---

d3js is pretty popular right now, but many times it is confused with a true graphic library, though it is not. d3js is more similar to jQuery than to Raphaël. d3js helps you manipulate the elements on your page (on the DOM, to be specific), just as jQuery does, but with special emphasis on creating and manipulating the elements based on *data*. I wanted to share a very basic example, and walk you through line by line, because I think the examples in d3js' page are a bit overwhelming and too eye catching, making everybody anxious. I won't even show you the result so you can see it as your own achievement.

I split a simple index.html almost line by line, I encourage you to copy line by line as it will serve you as a way to get all the details.

So let's begin with very simple stuff. You should clearly load d3 first, right?

```html
<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/d3/3.3.3/d3.min.js"></script>
```
 Now, lets declare a DIV with a SVG inside. Nada nuevo.

```html
<div id="graph">
    <svg width="950" height="950">
    </svg>
</div>
```

As you might know, SVG's are a great and standard way of drawing things in HTML and is gracefully accepted by most browsers. Lets make a nice SVG using nothing else but d3 (Read again that last phrase as if you were reading poetry, bet you love the rime.)

Let's open a script tag on your html and invent a simple data array. Let's imagine these are number of sales each month (cause they are growing!)

```html
<script type="text/javascript">
invented_data = [10,14,19,25,32,45,58,75,95];
```

I'll now declare a "doit" function that will receive a "data" array as a parameter. We start by creating a d3-object that represets the svg.

```javascript
function doit (data){
    svg = d3.select("svg"); // svg is a d3 object
    var square = svg.selectAll("rect") //square is also a d3 object
```

The "svg" d3-object we created by selecting a tag in the HTML has this nice "selectAll" function that doesn't really care if we don't yet have any rects in the SVG.

We will pass now the data onto the d3-object in a chained call

```javascript
.data(data)
````

Now a bit of d3 awesomeness. "enter" is a function that tells d3 that everything after it in the chain should be done with each element it encounters in the data array.

```javascript
.enter()
```

Do as I tell you d3!, for each element in the data array, you should append a rectangle

```javascript
.append("rect")
```

I say the "y" attribute of this "&lt;rect&gt;" element should be y="500"

```javascript
.attr("y",500)
```
Now I'm setting the height as 0. You might think I'm mad, but hang on with me.

```javascript
.attr("height",0)
.attr("width",20)
```

Now this is important. This tells d3 that attributes that I define from now on should be applied "slowly"... Liek saying "Hey d3, go and show what I've already told you to show, but slowly transform your looks as I will tell you after this..."

```javascript
.transition()
```

Now this one is a good one: the value of the attribute "y" here depends on the value of the corresponding element of the data array.

```javascript
.attr("y", function(d){return (500 - 10*d)})
```

The value of "x" here depends on the index of the array!

```javascript
.attr("x", function(d, i){return 40*i})
```

A few things you should be able to guess what they're for...

```javascript
.attr("height",function(d){return 10*d})
.attr("class","bar")
```

Wwooow... yes, you can set how "slowly" you want things to happen.

```javascript
.duration(1000)
};
```

//Now, let's call our function and close this script tag.

```javascript
doit(invented_data)
</script>
```

This example can easily get you started on d3, try it out and play a bit. I won't show what comes up to keep the mistery!
