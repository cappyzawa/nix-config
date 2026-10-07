import type { Issue } from '../types'

const TITLE_LIMIT = 60

export const SEARCH_ARGV = [
  'gh', 'search', 'issues',
  '--assignee=@me', '--state=open', '--archived=false', '--limit=100',
  '--json', 'repository,number,title,url,updatedAt',
] as const

type SearchHit = {
  repository: { nameWithOwner: string }
  number: number
  title: string
  url: string
  updatedAt: string
}

export function parseIssues(json: string): Issue[] {
  const hits = JSON.parse(json) as SearchHit[]
  return hits
    .map(hit => ({
      repo: hit.repository.nameWithOwner,
      number: hit.number,
      title: hit.title,
      url: hit.url,
      updatedAt: hit.updatedAt,
    }))
    .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
}

export function localRepoPath(home: string, repo: string): string {
  return `${home}/ghq/src/github.com/${repo}`
}

export function taskFor(issue: Issue, cwd: string) {
  const label = `${issue.repo}#${issue.number} ${issue.title}`
  const title = label.length > TITLE_LIMIT ? `${label.slice(0, TITLE_LIMIT - 1)}…` : label
  return {
    title,
    tldr: `Read ${issue.repo}#${issue.number} and align on it before any work: ${issue.title}`,
    prompt: [
      `This session is for the GitHub issue ${issue.url} (${issue.repo}#${issue.number}).`,
      'This first turn is for understanding it, not for working on it:',
      `1. Read it with \`gh issue view ${issue.number} --repo ${issue.repo} --comments\` and the code it touches.`,
      '2. Tell me, in your own words, what the problem is, why it matters, and what done looks like.',
      '3. List what is unclear or what you would need me to decide.',
      'Do not change any files, create branches, or start implementing. Stop after this and wait for my reply.',
    ].join('\n'),
    cwd,
  }
}

export const ALL_REPOS = ''

export function groupByRepo<R extends Issue>(rows: readonly R[], repoFilter: string): { repo: string; rows: R[] }[] {
  const groups = new Map<string, R[]>()
  for (const row of rows) {
    if (repoFilter !== ALL_REPOS && row.repo !== repoFilter) continue
    groups.set(row.repo, [...(groups.get(row.repo) ?? []), row])
  }
  return [...groups].map(([repo, rows]) => ({ repo, rows }))
}
