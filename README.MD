# Platanus Blog

We are using [Jekyll][1] to generate a static site for our blog.

## Running in development

To run jekyll on development just run the following. This will let you browse the blog in `locahost:4000`

```bash
jekyll serve
```

## Create a post

We are not going to use the jekylls `draft post` support. Instead we will use githubs Pull Requests. 

This should be the workflow to create a new post

1. Create a branch for the new post
1. Add the new post to the `_posts` folder
1. Commit the post (you can commit unfinished post)
1. Push the branch
1. Create a Pull Request

Now you can work in you post locally, also commit changes whenever you want to share with the team and get feedback.

When your post is finished you can `squash` all commits into a single commit.

> You can use [sublime-jekyll][2] to make the post creation smoother.  

## Publish

To publish just merge a a branch to the `master` branch and the blog will be automatically rebuild and published

[1]: http://jekyllrb.com
[2]: https://github.com/23maverick23/sublime-jekyll
