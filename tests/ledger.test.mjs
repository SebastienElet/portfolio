import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

const repository = new URL('../', import.meta.url);
const fixtures = [
  { startDate: '2024-03', endDate: '2025-10', months: '19' },
  { startDate: '2022-03', endDate: '2024-02', months: '23' },
  { startDate: '2020-09', endDate: '2022-03', months: '18' },
  { startDate: '2017-03-01', endDate: '2020-08-31', months: '41' },
  { startDate: '2015-10-12', endDate: '2017-03-01', months: '16' },
  { startDate: '2011-02-01', endDate: '2015-09-23', months: '55' },
  { startDate: '2007-11-26', endDate: '2011-01-31', months: '38' },
  { startDate: '2024-01-31', endDate: '2024-02-29', months: '0' },
  { startDate: '2024-01-12', endDate: '2024-02-12', months: '1' },
  { startDate: '2024-03', months: '' },
  { startDate: '2024', endDate: '2025', months: '' },
  { startDate: '2025-10', endDate: '2024-03', months: '' },
  { endDate: '2024-03', months: '' },
  { startDate: '2024-01-12', endDate: '2024-01-12', months: '0' },
];

function render(work) {
  const directory = mkdtempSync(join(tmpdir(), 'portfolio-ledger-'));
  try {
    cpSync(new URL('templates/', repository), join(directory, 'templates'), { recursive: true });
    cpSync(new URL('data/', repository), join(directory, 'data'), { recursive: true });
    cpSync(new URL('content/', repository), join(directory, 'content'), { recursive: true });
    writeFileSync(join(directory, 'config.toml'), 'base_url = "https://example.org"\ntitle = "Ledger fixture"\ndefault_language = "en"\n');
    writeFileSync(join(directory, 'resume.json'), JSON.stringify({ basics: { name: 'Ledger fixture' }, work }));
    const result = spawnSync(process.env.ZOLA ?? 'zola', ['build'], { cwd: directory, encoding: 'utf8' });
    assert.equal(result.status, 0, result.error?.message ?? result.stdout + result.stderr);
    return readFileSync(join(directory, 'public/index.html'), 'utf8');
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

function monthsIn(html) {
  return [...html.matchAll(/<td class="entry-months"[^>]*>([\s\S]*?)<\/td>/g)].map(match => match[1].trim());
}

test('ledger renders whole elapsed months and excludes incomplete or reversed periods from its total', () => {
  const html = render(fixtures.map((fixture, index) => ({ ...fixture, name: `Entry ${index + 1}`, position: 'Engineer' })));
  assert.deepEqual(monthsIn(html), fixtures.map(fixture => fixture.months));
  assert.match(html, /<td class="total-months"[^>]*>\s*211\s*<\/td>/);
});

test('career total adds the seven closed roles without assigning an end date to the ongoing role', () => {
  const resume = JSON.parse(readFileSync(new URL('resume.json', repository), 'utf8'));
  const html = render(resume.work);
  assert.deepEqual(monthsIn(html), ['', '19', '23', '18', '41', '16', '55', '38']);
  assert.match(html, /<td class="total-months"[^>]*>\s*210\s*<\/td>/);
});
