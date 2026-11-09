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


test('task titles are cached per pane and fall back without retaining stale titles', () => {
  let now = 0;
  let failed = false;
  let agents = [
    { pane_id: 'wA:p1', tokens: { task: '表示名の更新' } },
    { pane_id: 'wA:p2', tokens: { task: 'スピナーの維持' } },
    { pane_id: 'wA:p3', tokens: { task: ' ' } },
    { pane_id: 'wA:p4', tokens: { task: 123 } },
  ];
  mock.method(Date, 'now', () => now);
  const command = mock.method(childProcess, 'execFileSync', (binary, args) => {
    assert.deepEqual(args, ['agent', 'list']);
    if (failed) throw new Error('Server unavailable');
    return JSON.stringify({ result: { agents } });
  });
  try {
    delete require.cache[require.resolve('./space-index.cts')];
    const hook = require('./space-index.cts');
    assert.equal(typeof hook.workspace, 'function');
    assert.equal(hook.branch, hook.workspace);
    assert.equal(hook.title('元の名前', 'wA:p1'), '表示名の更新');
    assert.equal(hook.title('元の名前', 'wA:p2'), 'スピナーの維持');
    assert.equal(hook.title('元の名前', 'wA:p3'), '元の名前');
    assert.equal(hook.title('元の名前', 'wA:p4'), '元の名前');
    assert.equal(hook.title('元の名前', 'missing'), '元の名前');
    assert.equal(command.mock.callCount(), 1);

    agents = [{ pane_id: 'wA:p1', tokens: { task: '別のタスク' } }];
    now = 999;
    assert.equal(hook.title('元の名前', 'wA:p1'), '表示名の更新');
    now = 1000;
    assert.equal(hook.title('元の名前', 'wA:p1'), '別のタスク');
    assert.equal(hook.title('元の名前', 'wA:p2'), '元の名前');

    now = 2000;
    failed = true;
    assert.equal(hook.title('元の名前', 'wA:p1'), '元の名前');
    now = 3000;
    failed = false;
    assert.equal(hook.title('元の名前', 'wA:p1'), '別のタスク');
  } finally {
    mock.restoreAll();
  }
});
