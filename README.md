cv
==

My curriculum vitæ, built with [Zola](https://www.getzola.org/).

## Local development

Install Zola on macOS:

```sh
brew install zola
```

Preview the site at <http://127.0.0.1:1111>:

```sh
zola serve
```

Build the site into `public/`:

```sh
zola build
```

`config.toml` sets the site URL to `https://sebastien.elet.fr`. Templates live in
`templates/`, styles in `sass/`, and assets in `static/`. The resume data stays in
`resume.json` at the repository root and is loaded directly by the homepage
template to render the CV. Update that file to change the CV content.

## Deployment

Cloudflare Pages builds this repository through its Git integration. See the
[deployment guide](docs/deployment-cloudflare.md) for the `ZOLA_VERSION=0.23.6`
pin in Production and Preview, project settings, response headers and Vercel cleanup.

## Blog

The blog lives at `/blog/`, with an Atom feed at `/atom.xml`. Articles are Markdown
files in `content/blog/`, ordered by their front-matter `date` (newest first).
Set `title`, `description`, `date`, and optionally `[taxonomies]` with a `tags` array.
Tag lists appear at `/tags/` once a tagged article is published.

The included `draft-example.md` is sample content with `draft = true`. A normal
`zola build` or `zola serve` excludes it from pages, lists, tags, and the feed.
Preview drafts locally with:

```sh
zola serve --drafts
```

Keep production builds on `zola build` without `--drafts`. Replace the example
content before setting `draft = false` to publish a real article.

## License

This project is under the MIT License. Please, see [`LICENSE`](LICENSE).
