import { expect, mock, test } from 'claude-code/testing'

const ran = async ($: Parameters<Parameters<typeof test>[1]>[0], on: Parameters<Parameters<typeof test>[1]>[1], shell: string, command: string) => {
  let seen = ''
  mock.env(on, { SHELL: shell })
  on('tool.call', { tool: 'Bash' }, (_$, e) => {
    seen = e.command
    return { result: { stdout: '', stderr: '', interrupted: false } }
  })
  await $.tool.call({ tool: 'Bash', command })
  return seen
}

test('zsh: Bash command runs under ksh emulation', async ($, on) => {
  expect(await ran($, on, '/usr/bin/zsh', 'echo ====')).toBe('emulate ksh; setopt bash_rematch\necho ====')
})

test('bash: command untouched', async ($, on) => {
  expect(await ran($, on, '/bin/bash', 'echo ====')).toBe('echo ====')
})
