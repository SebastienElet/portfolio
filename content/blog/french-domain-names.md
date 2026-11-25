+++
title = "Should I translate domain terms into English for coding agents?"
description = "I ran the same coding tasks with French and English domain terms in a TypeScript and SQLite codebase."
date = 2026-11-24
draft = false
authors = ["Sébastien Elet"]

[taxonomies]
tags = ["Engineering", "Coding agents"]
+++

In condominium management, a *lot* might be an apartment or a parking space. The same lot has a database key, a number the property manager sees and a share of voting rights. If the team talks about these in French, would a coding agent do better if the names in the code were in English?

English names might be more familiar to an agent. French names might make the relevant code easier to find when the task is written in French. I generated two versions of the same TypeScript and SQLite codebase. I changed the domain names while keeping the behavior, technical vocabulary and tests the same. I ran each task in French and English against both versions.

## Pass rates by model

The main study covered 40 tasks, including SQL queries, features and bug fixes. For each task, Sol made two attempts per language combination, Terra three and Luna four. The table counts passing submissions out of all attempts.

| Codex model (reasoning effort) | French task, French names | French task, English names | English task, French names | English task, English names |
|---|---:|---:|---:|---:|
| `gpt-6.1-sol` (`xhigh`) | 80/80 | 80/80 | 80/80 | 80/80 |
| `gpt-6.1-terra` (`medium`) | 120/120 | 120/120 | 120/120 | 118/120 |
| `gpt-6-luna` (`low`) | 117/160 | 108/160 | 117/160 | 119/160 |

Every Sol submission passed. Two Terra submissions failed. The largest observed gap was for Luna on French tasks, where the pass rate was **5.6 percentage points** higher with French names. The 95% interval ran from **−5.6 to +16.9 points**, so that result leaves open which naming language, if either, helps. On English tasks, Luna had two more passing submissions with English names.

In an earlier SQL task, I asked for a lot identifier. Two submissions returned the number the property manager sees. The grader expected the numeric database key, and both queries passed when I changed the column they returned. In the main study, I specified which value the query should return.

## Which terms I'd keep in French

I didn't see a clear gain from translating the domain terms, so I'd keep the terms the team uses. I'd name a call for funds `appelDeFonds` in TypeScript and `appel_de_fonds` in SQL, using the singular for entities and table names. I'd keep technical names such as `created_at` in English. When asking for a lot identifier, I'd name the exact value in the task and check for it in the test.
