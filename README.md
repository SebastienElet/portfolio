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
`templates/`, styles in `sass/`, and assets in `static/`. Zola copies
`static/CNAME` into the generated site. The resume data stays in `resume.json`
at the repository root and is loaded by the homepage and `templates/partials/cv.html`
to render the complete CV. Update that file to change the CV content. Personal
copy and drawing annotations live in `data/about.toml`.

## Layout and sharing

`templates/base.html` provides the shared layout and metadata. Other templates
extend its `content` block. Use `nav_links` for navigation, `footer_content` for
footer links, and `extra_head` for additions such as feeds. To retain the default
links when extending a block, call `{{ super() }}`.

Page and section front matter can set `title` and `description`; otherwise metadata
uses the site title and description from `config.toml`. Social cards use the same
title and description. Override their image with:

```toml
[extra]
social_image = "images/my-social-card.png"
social_image_alt = "A description of the image"
```

Place images in `static/`; use a path relative to that directory or an absolute
HTTPS URL. The default is `static/images/social-card.png` (1200 × 630), with its
editable SVG source alongside it. Replace both when changing the default card.
Zola resolves local image URLs against `base_url`, which also supplies canonical
URLs. Its built-in `sitemap.xml` and `robots.txt` are enabled; the HTML head and
robots file reference the sitemap.

The stylesheet uses local system fonts and requires no JavaScript. Printing the
CV uses A4 with 15 mm margins, hides site navigation and footer, and keeps headings
with their content. Use the browser's print preview to check page breaks after
changing the resume. Disable browser-added headers and footers for a clean PDF.

## License

This project is under the MIT License. Please, see [`LICENSE`](LICENSE).
