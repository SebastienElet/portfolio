+++
title = "Draft example: keeping software simple"
description = "An example post showing how to write a dated article with tags."
date = 2026-11-01
draft = true
authors = ["Sébastien Elet"]

[taxonomies]
tags = ["Engineering", "Simplicity"]
+++

**Draft example.** This is sample content for previewing the blog, not a published
article. Replace it with your own writing before publishing.

## Start with the problem

A useful design begins with a concrete behavior. Describe what someone needs to
do, which constraints matter, and how you will know the result works.

## Keep decisions close to the code

Prefer names and small, cohesive functions that make the intent clear. Introduce
an abstraction when several real use cases share the same rules.

## Verify the result

Choose a check that exercises the behavior you care about. A successful build is
useful evidence for a static site; a business invariant needs a check at the
boundary that owns it.
