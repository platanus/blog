# Platanus Blog

## DEPRECATED

> Now we host our blog in medium and use their plaform to write

Usaremos [Jekyll][1] para generar nuestro blog como un sitio estático.

## Using the command line

##### Running server in development

To run jekyll on development just run the following. This will let you browse the blog in `locahost:4000`

```bash
jekyll serve --drafts

# to run with docker
scripts/draft_server
```

##### Create a post

```bash
jekyll post <post title>
```

Will create a new post in the `_posts` folder, ready to be published right away

##### Create a draft

Will create a new post in the `_drafts` folder, without the timestamp. This is the prefered way to create a post.

```bash
jekyll draft <draft post title>
```

##### Publish a draft

This will move the draft to the `_posts` folder and add the corresponding timestamp.

```bash
jekyll publish _draft/<draft file>
```

## Publish

To publish just merge a a branch to the `master` branch and the blog will be automatically rebuild and published

[1]: http://jekyllrb.com
