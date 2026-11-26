\set ON_ERROR_STOP on
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TEMP TABLE lignes_dvf (
    id_mutation text, date_mutation date, numero_disposition text, nature_mutation text,
    valeur_fonciere numeric, adresse_numero text, adresse_suffixe text, adresse_nom_voie text,
    adresse_code_voie text, code_postal text, code_commune text, nom_commune text,
    code_departement text, ancien_code_commune text, ancien_nom_commune text,
    id_parcelle text, ancien_id_parcelle text, numero_volume text,
    lot1_numero text, lot1_surface_carrez text, lot2_numero text, lot2_surface_carrez text,
    lot3_numero text, lot3_surface_carrez text, lot4_numero text, lot4_surface_carrez text,
    lot5_numero text, lot5_surface_carrez text, nombre_lots text, code_type_local text,
    type_local text, surface_reelle_bati numeric, nombre_pieces_principales text,
    code_nature_culture text, nature_culture text, code_nature_culture_speciale text,
    nature_culture_speciale text, surface_terrain numeric, longitude text, latitude text
);

\copy lignes_dvf FROM PROGRAM 'gzip -dc /dvf-input/2022.csv.gz' WITH (FORMAT csv, HEADER MATCH)
\copy lignes_dvf FROM PROGRAM 'gzip -dc /dvf-input/2025.csv.gz' WITH (FORMAT csv, HEADER MATCH)

CREATE TEMP VIEW ventes_appartements AS
SELECT
    extract(year FROM date_mutation)::integer AS annee,
    CASE WHEN min(code_commune) BETWEEN '69381' AND '69389' THEN '69123'
         ELSE min(code_commune) END AS commune,
    max(valeur_fonciere) / max(surface_reelle_bati) FILTER (WHERE type_local = 'Appartement') AS prix_m2
FROM lignes_dvf
GROUP BY extract(year FROM date_mutation), id_mutation
HAVING bool_and(nature_mutation IS NOT DISTINCT FROM 'Vente')
   AND count(DISTINCT code_commune) = 1
   AND count(*) FILTER (WHERE type_local = 'Appartement') = 1
   AND count(*) FILTER (WHERE type_local IS NOT NULL AND type_local NOT IN ('Appartement', 'Dépendance')) = 0
   AND count(DISTINCT valeur_fonciere) = 1
   AND max(valeur_fonciere) > 0
   AND max(surface_reelle_bati) FILTER (WHERE type_local = 'Appartement') > 0
   AND coalesce(max(surface_terrain), 0) = 0;

CREATE TEMP VIEW communes AS
SELECT
    feature #>> '{properties,code}' AS code,
    feature #>> '{properties,nom}' AS nom,
    ST_Transform(ST_GeomFromGeoJSON(feature -> 'geometry'), 2154) AS geometrie
FROM jsonb_array_elements(pg_read_file('/dvf-input/communes.geojson')::jsonb -> 'features') AS feature;

CREATE TEMP VIEW comparaisons AS
WITH statistiques AS (
    SELECT commune, annee, count(*) AS ventes,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY prix_m2)::numeric AS mediane
    FROM ventes_appartements
    GROUP BY commune, annee
)
SELECT c.*,
       coalesce(a.ventes, 0) AS ventes_2022,
       coalesce(b.ventes, 0) AS ventes_2025,
       CASE WHEN a.ventes >= 20 THEN a.mediane END AS prix_2022,
       CASE WHEN b.ventes >= 20 THEN b.mediane END AS prix_2025,
       CASE WHEN a.ventes >= 20 AND b.ventes >= 20
            THEN 100 * (b.mediane / a.mediane - 1) END AS variation
FROM communes c
LEFT JOIN statistiques a ON a.commune = c.code AND a.annee = 2022
LEFT JOIN statistiques b ON b.commune = c.code AND b.annee = 2025;

WITH cadre AS (
    SELECT ST_Extent(geometrie) AS emprise FROM communes
), echelle AS (
    SELECT ST_XMin(emprise) AS ouest, ST_YMax(emprise) AS nord,
           least(344 / (ST_XMax(emprise) - ST_XMin(emprise)),
                 380 / (ST_YMax(emprise) - ST_YMin(emprise))) AS facteur
    FROM cadre
), geometries_affichees AS (
    SELECT c.*, ST_Scale(ST_Translate(geometrie, -ouest, -nord), facteur, facteur) AS forme
    FROM comparaisons c CROSS JOIN echelle
), traces AS (
    SELECT *, ST_AsSVG(forme, 0, 2) AS trace
    FROM geometries_affichees
), panneaux(numero, titre, origine) AS (
    VALUES
        (1, '2022 · Prix médian', 40),
        (2, '2025 · Prix médian', 445),
        (3, 'Évolution 2022–2025', 850)
), classes(serie, rang, borne_exclue, couleur, libelle) AS (
    VALUES
        ('prix', 1, 3000, '#eff3ff', '&lt; 3 000'),
        ('prix', 2, 3750, '#bdd7e7', '3 000–3 750'),
        ('prix', 3, 4500, '#6baed6', '3 750–4 500'),
        ('prix', 4, 5250, '#3182bd', '4 500–5 250'),
        ('prix', 5, NULL, '#08519c', '≥ 5 250'),
        ('variation', 1, -15, '#8c2d04', '&lt; −15 %'),
        ('variation', 2, -5, '#e99562', '−15 à −5 %'),
        ('variation', 3, 5, '#f2efe7', '−5 à +5 %'),
        ('variation', 4, 15, '#80cdc1', '+5 à +15 %'),
        ('variation', 5, NULL, '#01665e', '≥ +15 %')
), cartes AS (
    SELECT p.numero,
           format('<g transform="translate(%s 0)"><text x="0" y="118" font-size="19" font-weight="600">%s</text><g transform="translate(44 135)" stroke="#fff" stroke-width=".85">%s%s</g></g>',
               p.origine, p.titre,
               string_agg(format('<path d="%s" fill="%s"><title>%s</title></path>',
                   t.trace, coalesce(cl.couleur, 'url(#peu-de-ventes)'),
                   replace(replace(t.nom, '&', '&amp;'), '<', '&lt;')
                   || ' · ' || coalesce(round(v.valeur)::text || v.unite, 'moins de 20 ventes')
                   || format(' · %s ventes en 2022, %s en 2025', t.ventes_2022, t.ventes_2025)
               ), '' ORDER BY t.code),
               (SELECT format('<text x="%s" y="%s" font-size="13" font-weight="650" text-anchor="middle" paint-order="stroke" stroke="#fbfaf7" stroke-width="3" stroke-linejoin="round" pointer-events="none">Lyon</text>',
                   round(ST_X(ST_PointOnSurface(forme))::numeric, 2),
                   round(-ST_Y(ST_PointOnSurface(forme))::numeric, 2))
                FROM traces WHERE code = '69123')) AS svg
    FROM panneaux p CROSS JOIN traces t
    CROSS JOIN LATERAL (
        SELECT CASE p.numero WHEN 1 THEN t.prix_2022 WHEN 2 THEN t.prix_2025 ELSE t.variation END,
               CASE p.numero WHEN 3 THEN ' %' ELSE ' €/m²' END,
               CASE p.numero WHEN 3 THEN 'variation' ELSE 'prix' END
    ) AS v(valeur, unite, serie)
    LEFT JOIN LATERAL (
        SELECT couleur FROM classes
        WHERE serie = v.serie AND v.valeur IS NOT NULL
          AND (v.valeur < borne_exclue OR borne_exclue IS NULL)
        ORDER BY rang LIMIT 1
    ) cl ON true
    GROUP BY p.numero, p.origine, p.titre
), legendes AS (
    SELECT serie, string_agg(format(
        '<g transform="translate(%s 0)"><rect width="68" height="10" fill="%s"/><text x="34" y="28" text-anchor="middle" font-size="10.5">%s</text></g>',
        (rang - 1) * 74, couleur, libelle), '' ORDER BY rang) AS svg
    FROM classes
    GROUP BY serie
)
SELECT '<svg xmlns="http://www.w3.org/2000/svg" width="1240" height="650" viewBox="0 0 1240 650" role="img" aria-labelledby="titre description">
<title id="titre">Prix des appartements dans la métropole de Lyon</title>
<desc id="description">Trois cartes communales comparent le prix médian au mètre carré en 2022 et 2025 et son évolution.</desc>
<defs><pattern id="peu-de-ventes" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="5" height="5" fill="#ecebe8"/><path d="M0 0V5" stroke="#94938f" stroke-width="1.5"/></pattern></defs>
<rect width="1240" height="650" fill="#fbfaf7"/>
<g fill="#172631" font-family="system-ui, sans-serif">
<text x="40" y="54" font-size="34" font-weight="650">Prix des appartements dans la métropole de Lyon</text>
<text x="41" y="82" font-size="16">Prix médians au m² parmi les ventes retenues, en euros courants</text>'
|| (SELECT string_agg(svg, '' ORDER BY numero) FROM cartes)
|| format('<g transform="translate(40 535)"><text y="-8" font-size="13" font-weight="600">Prix médian · €/m²</text>%s</g>', (SELECT svg FROM legendes WHERE serie = 'prix'))
|| format('<g transform="translate(850 535)"><text y="-8" font-size="13" font-weight="600">Variation du prix médian · %%</text>%s</g>', (SELECT svg FROM legendes WHERE serie = 'variation'))
|| '<rect x="40" y="584" width="18" height="12" fill="url(#peu-de-ventes)"/>
<text x="66" y="595" font-size="13">Moins de 20 ventes sur une année de la comparaison</text>
<text x="40" y="625" font-size="12">Sources · DVF géolocalisées (DGFiP, data.gouv.fr) et contours de l’API Géo. Lyon agrège ses neuf arrondissements.</text>
</g></svg>';
