---
layout: post
title: Creating a simple AWS S3 private Docker Registry
author: nicolasmery
tags:
  - docker
  - private registry
  - s3
  - aws
---

The objective of this post its to show how with a few lines of code you can have a Private Docker Registry running on your own AWS infrastructure. Also this way of running a registry can be run on each machine and generating traffic only to S3 so your registry would have HA by default and the security restrictions that S3 provides.

## Steps

- Create a S3 bucket.

- Create a IAM Role with this Policy:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::my_registry_bucket/*"
    }
  ]
}
```

With this we are giving full access to our registry bucket so the container can store the images in it.

- Start your Docker Enabled machine.

- Use this script to run your Private Registry.

```bash
#!/bin/sh
docker run -d -p 80:5000 \
-e "REGISTRY_STORAGE=s3" \
-e "REGISTRY_STORAGE_S3_REGION=us-east-1" \
-e “REGISTRY_STORAGE_S3_BUCKET=my_registry_bucket" \
-e "REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=inmemory" \
registry:2
```

You should be careful with only 2 things here. The S3_REGION and the S3_BUCKET that should match to your registry bucket.

Our registry should be working now on localhost port 5000.

- Pull, Tag, Push

We can test if everything is running ok pushing a version of busybox to our Private Registry.

```bash
docker pull busybox
docker tag busybox localhost:5000/busybox
docker push localhost:5000/busybox
```

Only images tagged as `localhost:5000/...` will be pushed to our registry.


