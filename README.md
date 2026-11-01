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
at the repository root and is loaded directly by the homepage template to render
the CV. Update that file to change the CV content.

## License

This project is under the MIT License. Please, see [`LICENSE`](LICENSE).
