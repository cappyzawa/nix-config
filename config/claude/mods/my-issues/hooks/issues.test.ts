import { expect, test } from 'claude-code/testing'

import { ALL_REPOS, groupByRepo, localRepoPath, parseIssues, taskFor } from './issues'

const hit = (repo: string, number: number, updatedAt: string, title = 't') => ({
  repository: { nameWithOwner: repo },
  number,
  title,
  url: `https://github.com/${repo}/issues/${number}`,
  updatedAt,
})

test('issues are listed most recently updated first', () => {
  const json = JSON.stringify([
    hit('o/a', 1, '2026-01-01T00:00:00Z'),
    hit('o/b', 2, '2026-03-01T00:00:00Z'),
  ])
  expect(parseIssues(json).map(i => i.number)).toEqual([2, 1])
})

test('a repo resolves to its ghq checkout under home', () => {
  expect(localRepoPath('/Users/me', 'arkedge/aegs')).toBe('/Users/me/ghq/src/github.com/arkedge/aegs')
})

test('a task title stays within the chip limit of 60 characters', () => {
  const [issue] = parseIssues(JSON.stringify([hit('o/a', 1, '2026-01-01T00:00:00Z', 'x'.repeat(100))]))
  expect(taskFor(issue, '/w').title.length).toBeLessThanOrEqual(60)
})

test('a task prompt names the issue URL so the new session can stand alone', () => {
  const [issue] = parseIssues(JSON.stringify([hit('o/a', 7, '2026-01-01T00:00:00Z')]))
  const task = taskFor(issue, '/w')
  expect(task.prompt).toContain('https://github.com/o/a/issues/7')
  expect(task.cwd).toBe('/w')
})

test('issues group by repo in order of their most recent update', () => {
  const issues = parseIssues(JSON.stringify([
    hit('o/a', 1, '2026-01-01T00:00:00Z'),
    hit('o/b', 2, '2026-03-01T00:00:00Z'),
    hit('o/a', 3, '2026-02-01T00:00:00Z'),
  ]))
  expect(groupByRepo(issues, ALL_REPOS).map(g => [g.repo, g.rows.map(r => r.number)])).toEqual([
    ['o/b', [2]],
    ['o/a', [3, 1]],
  ])
})

test('a repo filter keeps only that repo', () => {
  const issues = parseIssues(JSON.stringify([hit('o/a', 1, '2026-01-01T00:00:00Z'), hit('o/b', 2, '2026-03-01T00:00:00Z')]))
  expect(groupByRepo(issues, 'o/a').map(g => g.repo)).toEqual(['o/a'])
})
