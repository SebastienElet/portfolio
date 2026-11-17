# Cloudflare Pages deployment

[SebastienElet/portfolio](https://github.com/SebastienElet/portfolio) is deployed
through Cloudflare Pages' Git integration. GitHub Pages is no longer used.

## Project settings

In **Workers & Pages**, select the existing Pages project and check these
[build settings](https://developers.cloudflare.com/pages/configuration/build-configuration/):

| Setting | Value |
| --- | --- |
| Git repository | `SebastienElet/portfolio` |
| Production branch | `main` |
| Framework preset | Zola |
| Root directory | Repository root (leave blank) |
| Build command | `zola build` |
| Build output directory | `public` |
| Environment variable, Production | `ZOLA_VERSION=0.23.6` |
| Environment variable, Preview | `ZOLA_VERSION=0.23.6` |

Set `ZOLA_VERSION` separately for **Production and Preview** under Settings >
Environment variables, then trigger a new deployment. Version `0.23.6` matches
the local build and the template component syntax used by this site; do not rely
on the build image's default. Cloudflare documents the override in its
[build image reference](https://developers.cloudflare.com/pages/configuration/build-image/).
Use the same Zola version locally and update both environment settings together.

There is no Wrangler configuration or Node dependency. Although Pages supports
[`pages_build_output_dir`](https://developers.cloudflare.com/pages/functions/wrangler-configuration/),
Wrangler's `vars` configure Functions bindings rather than this build-time pin.
The Git build command and `ZOLA_VERSION` remain dashboard settings.

## Previews and custom domain

Keep automatic production deployments and preview builds enabled for all
non-production branches. Pushes to `main` deploy production; pull requests and
other branches produce
[preview deployments](https://developers.cloudflare.com/pages/configuration/preview-deployments/).
Check the Cloudflare Pages check and its deployment URL on each PR.

Stylesheet and favicon URLs are relative to the site root, so previews load their
own assets. `config.toml` keeps `https://sebastien.elet.fr` as the site's base URL
for canonical and sharing URLs. To use preview URLs for generated absolute links
and metadata too, replace the shared build command with
[Cloudflare's environment-aware variant](https://developers.cloudflare.com/pages/framework-guides/deploy-a-zola-site/):

```sh
if [ "$CF_PAGES_BRANCH" = "main" ]; then zola build; else zola build --base-url "$CF_PAGES_URL"; fi
```

This preserves the configured production URL on `main` and uses the deployment
URL for other branches.

In the project's **Custom domains**, associate `sebastien.elet.fr` and confirm
that its status and HTTPS certificate are active. Let Cloudflare create the
record for that domain in the existing Cloudflare DNS zone. A `CNAME` file in
the build output does not configure a Pages custom domain and has been removed.
No registrar or nameserver migration is needed for this deployment.

## Response headers and maintenance

Zola copies `static/_headers` into `public/_headers`, which
[Pages interprets](https://developers.cloudflare.com/pages/configuration/headers/)
as response headers. Verify them on the deployed preview with `curl -I`;
`zola serve` does not apply Pages headers.

The CSP permits same-origin resources and production assets in previews, blocks
scripts, objects, forms and framing, and allows HTTPS/data images. Generated CV
HTML currently has no scripts or inline styles. Inline styles remain permitted
for Zola syntax highlighting and future article markup. Review the CSP before
adding JavaScript, external fonts or Cloudflare script injection such as Web
Analytics. HSTS applies only to the serving hostname, without `includeSubDomains`
or preload. Browsers must revalidate cached responses because asset filenames
are not fingerprinted; Cloudflare still handles CDN caching.

No `_redirects` file is needed: no legacy path mapping or additional hostname
redirect is currently established. Configure a redirect only for a verified
source hostname or obsolete route.

There is no GitHub Actions workflow: Pages already builds and deploys PRs and
production. Consequently there is no `github-actions` Dependabot entry. If an
Actions workflow is added, pin each action to its full commit SHA with an exact
version comment and restore Dependabot with `cooldown: { default-days: 3 }`.

## Disconnect Vercel (Sébastien)

After verifying the Cloudflare production site, assets and HTTPS:

1. In the Vercel portfolio project's **Settings > Git**, disconnect
   `SebastienElet/portfolio` to stop its deployment attempts, then delete that
   Vercel project.
2. In GitHub **Settings > Applications > Installed GitHub Apps > Vercel**,
   remove this repository's access. Uninstall the app only if no other repository
   uses it.
3. In the repository's branch protection/rulesets, remove a required Vercel check
   if one is configured. Verify that a subsequent PR update no longer triggers
   Vercel. Historical failed checks can remain visible; ignore them during this
   transition and require the Cloudflare check before merging.

These account changes must be performed manually by Sébastien. Preserve any
unrelated Vercel projects and domain records.
