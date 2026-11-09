'use strict';

const fs = require('node:fs');
const { homedir } = require('node:os');
const { join, dirname, resolve } = require('node:path');
const childProcess = require('node:child_process');
const RECHECK_INTERVAL_MS = 10 * 60 * 1000;

function promptContext(input, hookFile) {
  if (process.env.HERDR_ENV !== '1' || !input.session_id || !input.cwd) return;
  if (!['UserPromptSubmit', 'PostToolUse'].includes(input.hook_event_name)) return;
  const stateDir = join(process.env.CODEX_HOME || join(homedir(), '.codex'), 'herdr-title-hook');
  fs.mkdirSync(stateDir, { recursive: true, mode: 0o700 });
  const stamp = join(stateDir, `${encodeURIComponent(input.session_id)}.stamp`);
  const lock = `${stamp}.lock`;
  const postTool = input.hook_event_name === 'PostToolUse';
  if (postTool) {
    // Recover a lock left behind if Codex killed a timed-out hook.
    try {
      if (Date.now() - fs.statSync(lock).mtimeMs > 10_000) fs.rmdirSync(lock);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    try { fs.mkdirSync(lock); } catch (error) {
      if (error.code === 'EEXIST') return;
      throw error;
    }
  }
  try {
    if (postTool) {
      let last = 0;
      try { last = Number(fs.readFileSync(stamp, 'utf8')); } catch (error) {
        if (error.code !== 'ENOENT') throw error;
      }
      const elapsed = Date.now() - last;
      if (last > 0 && elapsed >= 0 && elapsed < RECHECK_INTERVAL_MS) return;
    }
    const result = paneContext(input, hookFile);
    if (result) fs.writeFileSync(stamp, String(Date.now()), { mode: 0o600 });
    return result;
  } finally {
    if (postTool) fs.rmdirSync(lock);
  }
}

function paneContext(input, hookFile) {
  let thread;
  const index = join(process.env.CODEX_HOME || join(homedir(), '.codex'), 'session_index.jsonl');
  for (const line of fs.readFileSync(index, 'utf8').split('\n')) {
    try {
      const row = JSON.parse(line);
      if (row.id === input.session_id) thread = row;
    } catch {
      // The final line can be incomplete while Codex is writing the index.
    }
  }
  const name = thread?.thread_name;
  if (typeof name !== 'string' || !name.trim()) return;

  const output = childProcess.execFileSync(process.env.HERDR_BIN_PATH || 'herdr', ['agent', 'list'], {
    encoding: 'utf8', timeout: 1000,
  });
  // A shared Codex daemon can inherit another client's HERDR_PANE_ID.
  const panes = JSON.parse(output).result.agents.filter(agent => {
    const title = agent.terminal_title_stripped || '';
    return agent.agent === 'codex'
      && (agent.foreground_cwd || agent.cwd) === input.cwd
      && (title === name || title.startsWith(`${name} | `));
  });
  if (panes.length !== 1) return;
  const paneId = panes[0].pane_id;

  const result = JSON.parse(childProcess.execFileSync('bash', [hookFile], {
    encoding: 'utf8', timeout: 2000, input: JSON.stringify(input),
    env: { ...process.env, HERDR_PANE_ID: paneId },
  }));
  const context = result.hookSpecificOutput;
  if (typeof context?.additionalContext !== 'string') return;
  context.hookEventName = input.hook_event_name;
  context.additionalContext = context.additionalContext
    .replace('If this prompt starts a new task or changes the current one, first run:',
      'Reassess the title against the latest work and current stage. If its source is terminal or the focus or stage has changed, run:')
    .replace('Skip it when the task is unchanged.', 'Keep an agent title only while it still describes the current work.');
  const command = `bash '${resolve(dirname(hookFile), '..', 'agent-title.sh')}'`;
  const quotedId = `'${paneId.replaceAll("'", "'\\''")}'`;
  context.additionalContext = context.additionalContext.replaceAll(command, `HERDR_PANE_ID=${quotedId} ${command}`);
  return result;
}

module.exports = { promptContext };

if (require.main === module) {
  try {
    const result = promptContext(JSON.parse(fs.readFileSync(0, 'utf8')), process.argv[2]);
    if (result) process.stdout.write(`${JSON.stringify(result)}\n`);
  } catch {
    // Missing context or a disconnected Herdr must not block the user prompt.
  }
}
