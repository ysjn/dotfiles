const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');

test('workspace numbers follow reordered spaces and fail without stale indices', () => {
  let now = 0;
  let rows = [{ workspace_id: 'wA', number: 2 }, { workspace_id: 'wB', number: 1 }];
  let failed = false;
  mock.method(Date, 'now', () => now);
  const command = mock.method(childProcess, 'execFileSync', (binary, args) => {
    assert.deepEqual(args, ['workspace', 'list']);
    if (failed) throw new Error('Server unavailable');
    return JSON.stringify({ result: { workspaces: rows } });
  });
  try {
    const hook = require('./space-index.cts');
    assert.equal(hook.workspace('project-a', 'wA'), '2 project-a');
    assert.equal(hook.branch('feature/b', 'wB'), '1 feature/b');
    assert.equal(hook.workspace('unknown', 'missing'), 'unknown');
    assert.equal(command.mock.callCount(), 1);

    now += 1000;
    rows = [{ workspace_id: 'wA', number: 1 }];
    assert.equal(hook.workspace('project-a', 'wA'), '1 project-a');
    assert.equal(hook.workspace('project-b', 'wB'), 'project-b');

    now += 1000;
    failed = true;
    assert.equal(hook.workspace('project-a', 'wA'), 'project-a');

    now += 1000;
    failed = false;
    rows = [{ workspace_id: 'wA', number: '9' }];
    assert.equal(hook.workspace('project-a', 'wA'), 'project-a');
  } finally {
    mock.restoreAll();
  }
});
