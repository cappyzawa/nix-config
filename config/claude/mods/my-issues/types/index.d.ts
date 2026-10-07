export type Issue = {
  repo: string
  number: number
  title: string
  url: string
  updatedAt: string
}

export type Row = Issue & { cloned: boolean }

export type RepoGroup = { repo: string; rows: Row[] }

export type Listing =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'failed'; message: string }
  | { kind: 'loaded'; rows: Row[] }

declare module 'claude-code' {
  interface PluginState {
    'my-issues': { listing: Listing; notice: string | null; repoFilter: string }
  }
}
