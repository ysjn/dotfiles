const { execFileSync } = require('node:child_process');

let numbers = new Map();
let refreshedAt = -Infinity;

function labelWithIndex(label, workspaceId) {
  const now = Date.now();
  if (now - refreshedAt >= 1000) {
    refreshedAt = now;
    numbers = new Map();
    try {
      const output = execFileSync(process.env.HERDR_BIN_PATH || 'herdr', ['workspace', 'list'], {
        encoding: 'utf8', timeout: 2000,
      });
      const workspaces = JSON.parse(output).result.workspaces;
      numbers = new Map(workspaces
        .filter(ws => typeof ws.workspace_id === 'string' && Number.isInteger(ws.number) && ws.number > 0)
        .map(ws => [ws.workspace_id, ws.number]));
    } catch {
      // Keep labels readable without publishing stale shortcut numbers.
    }
  }
  const number = numbers.get(workspaceId);
  return number === undefined ? label : `${number} ${label}`;
}

module.exports = { workspace: labelWithIndex, branch: labelWithIndex };

let taskTitles = new Map();
let taskTitlesAt = -Infinity;

function taskTitle(original, paneId) {
  const now = Date.now();
  if (now - taskTitlesAt >= 1000) {
    taskTitlesAt = now;
    taskTitles.clear();
    try {
      const output = execFileSync(process.env.HERDR_BIN_PATH || 'herdr', ['agent', 'list'], {
        encoding: 'utf8', timeout: 1000,
      });
      for (const agent of JSON.parse(output).result.agents) {
        const task = agent.tokens?.task;
        if (typeof task === 'string' && task.trim()) taskTitles.set(agent.pane_id, task);
      }
    } catch {
      // 取得できなければ元のタイトルを使う。
    }
  }
  return taskTitles.get(paneId) ?? original;
}

module.exports.title = taskTitle;
