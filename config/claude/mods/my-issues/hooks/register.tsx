import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Listing, Row } from '../types'
import { ALL_REPOS, SEARCH_ARGV, groupByRepo, localRepoPath, parseIssues, taskFor } from './issues'

const PANE = 'my-issues'
const listing = atom({ plugin: 'my-issues', key: 'listing' } as const, { kind: 'idle' } as Listing)
const notice = atom({ plugin: 'my-issues', key: 'notice' } as const, null as string | null)
const repoFilter = atom({ plugin: 'my-issues', key: 'repoFilter' } as const, ALL_REPOS)

async function refresh($: EngineInterface) {
  await update($, listing, () => ({ kind: 'loading' }))
  const home = (await $.env.get('HOME')) ?? ''
  const { exitCode, stdout, stderr } = await $.process.run(SEARCH_ARGV)
  if (exitCode !== 0) {
    await update($, listing, () => ({ kind: 'failed', message: stderr.trim() }))
    return
  }
  const rows: Row[] = await Promise.all(
    parseIssues(stdout).map(async issue => ({
      ...issue,
      cloned: await $.fs.exists(localRepoPath(home, issue.repo)),
    })),
  )
  await update($, listing, () => ({ kind: 'loaded', rows }))
}

async function start($: EngineInterface, row: Row) {
  const home = (await $.env.get('HOME')) ?? ''
  const ran = await $.tool.call({
    tool: 'mcp__ccd_session__spawn_task',
    ...taskFor(row, localRepoPath(home, row.repo)),
  })
  const text = ran.deny !== undefined
    ? `spawn_task refused: ${ran.deny}`
    : ran.isError ? `spawn_task failed: ${ran.text}` : `Task chip created for ${row.repo}#${row.number}`
  await update($, notice, () => text)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'issues', description: 'List issues assigned to me' })
    return next(e)
  })

  on('command.run', { command: 'issues' }, async $ => {
    await $.ui.open({ id: PANE, title: 'Assigned issues' })
    void refresh($)
    return { text: 'Assigned issues pane opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Link, Select, Text } = $.ui.resolve(e)
    const state = await read($, listing)
    const message = await read($, notice)
    const filter = await read($, repoFilter)
    const rows = state.kind === 'loaded' ? state.rows : []
    const allGroups = groupByRepo(rows, ALL_REPOS)
    const options = [
      { value: ALL_REPOS, label: `All repos (${rows.length})` },
      ...allGroups.map(g => ({ value: g.repo, label: `${g.repo} (${g.rows.length})` })),
    ]

    return (
      <Box flexDirection="column" rowGap={1}>
        <Box columnGap={1} alignItems="center">
          <Select key="repo" options={options} value={filter} onSelect={value => update($, repoFilter, () => value)} />
          <Button key="reload" label="Reload" variant="secondary" onPress={() => refresh($)} />
        </Box>
        {message !== null && <Text dimColor>{message}</Text>}
        {state.kind === 'loading' && <Text dimColor>Loading…</Text>}
        {state.kind === 'failed' && <Text color="red">{state.message}</Text>}
        {state.kind === 'loaded' && rows.length === 0 && <Text dimColor>No open issues assigned.</Text>}
        {groupByRepo(rows, filter).map(group => (
          <Box key={group.repo} flexDirection="column">
            <Text bold>{group.repo} <Text dimColor>{group.rows.length}</Text></Text>
            {group.rows.map(row => (
              <Box key={row.url} columnGap={1} alignItems="center">
                <Box width={6} flexShrink={0}><Text dimColor>#{row.number}</Text></Box>
                <Box flexGrow={1} flexShrink={1}><Link href={row.url} label={row.title} /></Box>
                <Box flexShrink={0}>
                  {row.cloned
                    ? <Button key={`start-${row.url}`} label="✻" plain onPress={() => start($, row)} />
                    : <Text dimColor>no clone</Text>}
                </Box>
              </Box>
            ))}
          </Box>
        ))}
      </Box>
    )
  })
}
