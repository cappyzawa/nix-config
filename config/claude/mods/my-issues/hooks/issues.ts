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
    tldr: `${issue.repo}#${issue.number} を読んで認識を合わせる: ${issue.title}`,
    prompt: [
      `このセッションでは GitHub Issue ${issue.url} (${issue.repo}#${issue.number}) を扱う。`,
      '最初のターンは内容を理解して認識を合わせるためのもので、作業には入らない。',
      '',
      `1. \`gh issue view ${issue.number} --repo ${issue.repo} --comments\` で Issue を読み、関係するコードも読む。`,
      '2. 何が問題か、なぜ問題か、どうなれば完了かを、自分の言葉で説明する。',
      '3. 不明な点と、私に判断してほしい点を挙げる。',
      '',
      'この最初のターンはここで止めて、私の返事を待つ。作業に移るかどうかは、その返事で私が決める。',
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
