+++
title = "From property sales to an SVG map with PostgreSQL"
description = "A PostGIS triptych compares apartment sale prices across the Lyon metropolitan area in 2022 and 2025."
date = 2026-11-26
draft = false
authors = ["Sébastien Elet"]

[taxonomies]
tags = ["PostgreSQL", "PostGIS"]
+++

In Lyon, the median sale price per square metre fell from €5,070 in 2022 to €4,456 in 2025. In Villeurbanne, it fell from €3,967 to €3,565. The gap between the two shrank by about €210 per square metre. How widespread was the fall across the metropolitan area?

The first two maps show the price level in each year using the same colour scale. The third shows the percentage change. PostgreSQL calculates the medians and PostGIS turns the municipal boundaries into paths for the SVG.

[![Three maps of the Lyon metropolitan area showing median apartment sale prices in 2022 and 2025, and the percentage change between them. Hatching marks municipalities with too few sales.](/blog/mapping-lyon-apartment-prices/prix-appartements.svg)](/blog/mapping-lyon-apartment-prices/prix-appartements.svg)

## Build one observation per sale

France's *Demandes de valeurs foncières* (DVF) records can contain several rows for one transaction. An apartment and a parking space can appear on separate rows, while the recorded transaction value covers both. Taking the median of the raw rows would give some transactions more weight than others. [Geocoded DVF dataset](https://www.data.gouv.fr/datasets/demandes-de-valeurs-foncieres-geolocalisees)

The query groups rows by year and transaction ID. It keeps ordinary sales in one municipality with exactly one apartment row, a positive apartment area and a single distinct positive transaction value. It allows rows for ancillary units such as parking spaces and excludes sales with another type of premises or a positive land area. It divides the full transaction value by the apartment's recorded built area. Lyon's nine arrondissements are grouped under Lyon's municipal code.

## Compare municipal medians

The `ventes_appartements` view returns one row per retained sale.

```sql
SELECT commune, annee, count(*) AS ventes,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY prix_m2) AS mediane
FROM ventes_appartements
GROUP BY commune, annee;
```

The query joins those results to the municipal boundaries by INSEE code. It displays a median only when at least 20 sales qualify in that municipality and year. The change map requires that minimum in both years. Hatching preserves the outline of each municipality that falls short. [Municipal boundaries from API Géo](https://geo.api.gouv.fr/epcis/200046977/communes?fields=nom%2Ccode&format=geojson&geometry=contour)

## Draw the same geometry three times

PostGIS reads the GeoJSON boundaries and projects them to Lambert-93. A shared bounding box gives all three panels the same origin and scale. The query moves the origin to the bounding box's upper-left corner using its west and north coordinates, `ouest` and `nord`, then fits the geometry to the panel. [PostGIS documentation for `ST_AsSVG`](https://postgis.net/docs/ST_AsSVG.html)

```sql
ST_AsSVG(
    ST_Scale(ST_Translate(geometrie, -ouest, -nord), facteur, facteur),
    0, 2
)
```

The function returns path data in absolute SVG coordinates, rounded to two decimal places. For each panel, the query sets the fill from the price or change band and adds a `<title>` with the value and sale counts. `string_agg` combines the paths into one SVG document.

The [complete SQL script](/blog/mapping-lyon-apartment-prices/prix-appartements.sql) reads `2022.csv.gz` and `2025.csv.gz` for département 69, and the boundary response as `communes.geojson`. It expects those files under `/dvf-input` in a local PostgreSQL 17 environment where both `psql` and the server can read them. The local database role must be able to read the GeoJSON via `pg_read_file`, and PostGIS must be available. Run the script with `psql -XqAt -f prix-appartements.sql > prix-appartements.svg`. [2022 DVF extract](https://files.data.gouv.fr/geo-dvf/latest/csv/2022/departements/69.csv.gz) · [2025 DVF extract](https://files.data.gouv.fr/geo-dvf/latest/csv/2025/departements/69.csv.gz)

## Read the change map

Of the 58 municipalities on the map, 35 met the sales threshold in both years. The median fell in 31. Lyon's median fell by 12.1%, compared with 10.1% in Villeurbanne and 7.9% in Caluire-et-Cuire. The figures compare the apartments that sold in each year. A shift in the sizes, streets or types of apartments sold can move the median even when prices for comparable properties stay flat.
