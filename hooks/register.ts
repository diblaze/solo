import type { Register } from 'claude-code'

// The model writes bash; the Bash tool runs the login shell. Under zsh that
// breaks on unquoted-variable word splitting, `=word` expansion (`echo ====`),
// 1-indexed arrays, unmatched globs and BASH_REMATCH. ksh emulation gives the
// bash behaviour for all of them in the same shell, so `cd` still persists.
// ponytail: emulation, not real bash — bash-only builtins (mapfile, read -a)
// still fail; wrap in `bash -c` per command if those start to matter.
const PREFIX = 'emulate ksh; setopt bash_rematch\n'

export const register: Register = on => {
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const shell = await $.env.get('SHELL')
    const isZsh = shell?.endsWith('/zsh') === true

    return next(isZsh && !e.command.startsWith(PREFIX) ? { ...e, command: PREFIX + e.command } : e)
  })
}
