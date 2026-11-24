+++
title = "Should I translate domain names into English for coding agents?"
description = "A coding-agent experiment on French and English business names in TypeScript and SQL."
date = 2026-11-24
draft = false
authors = ["Sébastien Elet"]

[taxonomies]
tags = ["Engineering", "Coding agents"]
+++

In condominium management, a *lot* might be an apartment or a parking space. Its database key, the number shown to the property manager, and its share of voting rights are different things. If the team discusses those concepts in French, should the code use the same words, or would an English translation help a coding agent?

I started with two plausible ideas. English names might be more familiar to an agent. French names might make it easier to connect the code to a task written in French. To test these separately, I generated French and English versions of the domain names in the same TypeScript and SQLite codebase. The behavior, technical vocabulary and tests stayed the same. I gave both versions the same tasks in French and in English.

## What the comparison showed

The main study used 40 tasks, from SQL queries to features and bug fixes. Each task appeared in both languages and both naming variants. Sol had two attempts per combination, Terra three and Luna four. The table shows successful submissions out of all attempts.

| Codex model (reasoning effort) | French task, French names | French task, English names | English task, French names | English task, English names |
|---|---:|---:|---:|---:|
| `gpt-6.1-sol` (`xhigh`) | 80/80 | 80/80 | 80/80 | 80/80 |
| `gpt-6.1-terra` (`medium`) | 120/120 | 120/120 | 120/120 | 118/120 |
| `gpt-6-luna` (`low`) | 117/160 | 108/160 | 117/160 | 119/160 |

Sol and Terra rarely failed, leaving little room for the naming choice to make a visible difference. Luna showed the largest observed gap. For French tasks, French names led by **5.6 percentage points**, with a 95% interval from **−5.6 to +16.9 points**. On English tasks, the gap was just two submissions in favor of English names. So even where the tasks were hard enough to separate the models, the naming comparison remained uncertain.

The most useful lesson came from an ambiguous SQL task. I asked for a lot identifier. Two submissions returned the number the property manager sees, while the grader expected the numeric database key. Both queries passed when I changed that one column. In the main study I spelled out which value the query should return.

## What I would do

**Keep domain names in the language the team uses for the domain.** In this project, I would use French for business concepts in code, SQL tables and columns. That gives me names like `appelDeFonds` in TypeScript and `appels_de_fonds` in SQL, alongside familiar technical names like `created_at`. This comparison gave me no clear performance reason to translate the domain names for the agent. I would spend that effort making the business distinctions explicit in the tasks and tests.
