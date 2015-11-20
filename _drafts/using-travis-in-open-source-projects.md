---
layout: post
title: Using Travis in Open-Source Projects
author: nicolasmery
tags:
    - travis
    - opensource
---

### What is Travis

Travis CI is a hosted continuous integration and deployment system. There are two versions of it,travis-ci.com for private repositories, and travis-ci.org for public repositories.

We will focus on travis-ci.org

### Use Cases

You will want to use Travis in one of these cases:

- 100% Free for Open Source.

- Don’t want to host & maintain your own CI solution.

- You care only about one system. Travis and most of CI-as-a-service solutions are not useful for multi-system acceptance testing. In most of the cases though is enough to split the multi-system testing on testing each system using mockups.

### Speed Up Tests

You can speed-up your tests on Jarvis following these best practices:

- [Exclude non-essential Dependencies](http://docs.travis-ci.com/user/languages/ruby/#Speed-up-your-build-by-excluding-non-essential-dependencies)

- [Cache Bundler](http://docs.travis-ci.com/user/caching/)

- [Parallelise](http://docs.travis-ci.com/user/speeding-up-the-build/#Parallelizing-your-builds-across-virtual-machines)

- [Run in the New Container Infrastructure](http://docs.travis-ci.com/user/migrating-from-legacy/#How-can-I-use-container-based-infrastructure%3F)(*Not recommended when your tests are DB hungry, travis right now doesn’t use in-memory db on the container infrastructure.*)

### Security

Currently travis allows encryption of environtment variables, notification settings, and deploy api keys.

http://docs.travis-ci.com/user/encryption-keys/

#### Example

Lets say we have an Open Source project like

https://github.com/platanus/pincers

```
git clone git@github.com:platanus/pincers.git

cd pincers

git checkout -b added_travis
```

In the root create the .travis.yml file:

```
---
language: ruby
script: bundle exec rspec spec
rvm:
  - 1.9.3
sudo: false
```

Now go to travis-ci.org and find the pincers repository. Change the settings so it will build on every PR and commit.

Now commit and push the changes.

```
git add .

git commit -m "chore(travis): added travis file"

git push origin added_travis
```

And do a PR

You will see how the travis build started. You can look inside the build and see logs in realtime.

### Embedding Status Images


In travis-ci.org click on the “build/passed” icon of the build. Then select the branch and copy the generated text. Paste it in the README file of Github.

In the example above this will result on something like this on the README file.

```
# Pincers ![Build Status][travis-badge]

[travis-badge]: https://travis-ci.org/platanus/pincers.svg?branch=master
```

### References

[https://github.com/travis-ci/travis-ci](https://github.com/travis-ci/travis-ci])
[http://docs.travis-ci.com/](http://docs.travis-ci.com/)
[http://docs.travis-ci.com/user/status-images/](http://docs.travis-ci.com/user/status-images/)
