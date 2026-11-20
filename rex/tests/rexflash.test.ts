import assert from "node:assert/strict";
import childProcess from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { after, afterEach, mock, test } from "node:test";
import { isCode, openSelection, targetOf } from "../rexflash.ts";

const directory = mkdtempSync(join(tmpdir(), "rexflash-test-"));
const source = join(directory, "source with 'quotes' $(touch SHOULD_NOT_EXIST).ts");
const focusFile = join(directory, "focus");
const originalEnv = { ...process.env };
writeFileSync(source, Array.from({ length: 80 }, (_, index) => `const line${index + 1} = ${index + 1};\n`).join(""));
after(() => rmSync(directory, { recursive: true, force: true }));
afterEach(() => {
	mock.restoreAll();
	process.env = { ...originalEnv };
	process.exitCode = 0;
	rmSync(focusFile, { force: true });
});

test("relative paths, line and column resolve against the source cwd", () => {
	const result = targetOf("./" + source.slice(directory.length + 1) + ":42:5", directory);
	assert.equal(result.path, source);
	assert.equal(result.line, "42");
	assert.equal(result.column, "5");
	assert.equal(targetOf("~/dev/example.ts:3", directory).path, join(homedir(), "dev/example.ts"));
});

test("local file URIs preserve encoded names and accept both location formats", () => {
	const uri = pathToFileURL(source).href;
	assert.equal(targetOf(uri + ":42:5").path, source);
	assert.equal(targetOf(uri + ":42:5").line, "42");
	assert.equal(targetOf(uri + "#L42C5").column, "5");
	assert.equal(targetOf(source + "#L42").line, "42");
});

test("URLs retain ports and fragments and remote file URIs stay remote", () => {
	for (const uri of ["https://example.com:8443/code.ts#L42", "http://localhost:8080", "mailto:user@example.com", "urn:example:123", "file://other-host/tmp/code.ts:42"]) {
		assert.deepEqual(targetOf(uri), { openArg: uri });
	}
});

test("existing filenames take precedence over line suffixes", () => {
	const path = join(directory, "actual.ts:42");
	writeFileSync(path, "text");
	assert.equal(targetOf(path).path, path);
	assert.equal(targetOf(path).line, undefined);
});

test("invalid text and line numbers are rejected", () => {
	for (const text of ["", "line\nbreak", "null\0byte", source + ":0", source + ":1:0", source + ":9007199254740992"]) {
		assert.throws(() => targetOf(text));
	}
});

test("code extensions and MIME recognize source but exclude binary and ordinary text", () => {
	assert.equal(isCode("source.ts", "text/plain"), true);
	assert.equal(isCode("Makefile", "text/plain"), true);
	assert.equal(isCode("script", "text/x-shellscript"), true);
	assert.equal(isCode("config.json", "application/json"), true);
	assert.equal(isCode("icon.svg", "image/svg+xml"), true);
	assert.equal(isCode("empty.rs", "inode/x-empty"), true);
	assert.equal(isCode("source.ts", "video/mp2t"), false);
	assert.equal(isCode("notes.md", "text/plain"), false);
	assert.equal(isCode("manual.pdf", "application/pdf"), false);
});

test("code opens left of the explicit source pane with safe argv and line/column", () => {
	Object.assign(process.env, { REXFLASH_SOURCE_SESSION: "source-session", REXFLASH_SOURCE_BLOCK: "source-block", REXFLASH_FOCUS_FILE: focusFile });
	const calls: { command: string; args: string[] }[] = [];
	mock.method(childProcess, "spawnSync", (command: string, args: string[]) => {
		calls.push({ command, args });
		return { status: 0, stdout: command === "/usr/bin/file" ? "text/plain\n" : '{"block_ids":["new-editor","source-block"]}', stderr: "" };
	});
	openSelection(source + ":42:5");
	assert.deepEqual(calls[0].args, ["-Lb", "--mime-type", "--", source]);
	assert.deepEqual(calls[1].args.slice(0, 13), ["split", "-s", "source-session", "-b", "source-block", "--split=left", "--focus=false", "--shell=none", "-c", process.cwd(), "--json", "--", "/opt/homebrew/bin/nvim"]);
	assert.deepEqual(calls[1].args.slice(-2), ["--", source]);
	assert.equal(readFileSync(focusFile, "utf8"), "new-editor");
	assert.equal(existsSync("SHOULD_NOT_EXIST"), false);
	mock.restoreAll();
	const check = 'lua vim.fn.cursor(43,5); vim.api.nvim_exec_autocmds("User", {pattern="VeryLazy"}); vim.schedule(function() local ok = vim.fn.line(".") == 42 and vim.fn.col(".") == 5; if ok then vim.cmd("qa!") else vim.cmd("cquit") end end)';
	const result = childProcess.spawnSync("/opt/homebrew/bin/nvim", ["--headless", "-u", "NONE", "-i", "NONE", "-n", calls[1].args[13], "-c", check, "--", source], { encoding: "utf8", timeout: 10000 });
	assert.equal(result.status, 0, result.stderr);
});

test("binary files, ordinary files and URLs retain macOS Open", () => {
	const calls: { command: string; args: string[] }[] = [];
	mock.method(childProcess, "spawnSync", (command: string, args: string[]) => {
		calls.push({ command, args });
		return { status: 0, stdout: "application/octet-stream\n", stderr: "" };
	});
	openSelection(source);
	assert.equal(calls[1].command, "/usr/bin/open");
	assert.deepEqual(calls[1].args, [source]);
	openSelection("https://example.com:8443/code.ts#L42");
	assert.deepEqual(calls[2], { command: "/usr/bin/open", args: ["https://example.com:8443/code.ts#L42"] });
});

test("missing source context and failed splits report errors without opening a substitute", () => {
	mock.method(childProcess, "spawnSync", () => ({ status: 0, stdout: "text/plain\n", stderr: "" }));
	assert.throws(() => openSelection(source), /source pane context/);
	mock.restoreAll();
	Object.assign(process.env, { REXFLASH_SOURCE_SESSION: "s", REXFLASH_SOURCE_BLOCK: "b", REXFLASH_FOCUS_FILE: focusFile });
	mock.method(childProcess, "spawnSync", (command: string) => command === "/usr/bin/file"
		? { status: 0, stdout: "text/plain\n", stderr: "" }
		: { status: 1, stdout: "", stderr: "split failed" });
	assert.throws(() => openSelection(source), /split failed/);
	assert.equal(existsSync(focusFile), false);
});

test("the launcher preserves arguments and focuses the editor after upstream exits", () => {
	const args = ["hint", "--session", "original-session", "--block", "original-block", "--cwd", directory, "--config", '{"main_action":"a command"}'];
	const home = join(directory, "home with 'quotes'");
	const binDir = join(home, "dev/rexflash/target/release");
	mkdirSync(binDir, { recursive: true });
	writeFileSync(join(binDir, "rexflash"), `#!/bin/bash
printf '%s\\0' "$@" > "$TEST_OUTPUT/argv"
printf '%s\\n' "$REXFLASH_SOURCE_SESSION" "$REXFLASH_SOURCE_BLOCK" "$REXFLASH_FOCUS_FILE" > "$TEST_OUTPUT/context"
if [[ $TEST_PICK == 1 ]]; then printf new-editor > "$REXFLASH_FOCUS_FILE"; fi
printf 'upstream returned\\n' > "$TEST_OUTPUT/order"
exit "$TEST_STATUS"
`, { mode: 0o755 });
	const rex = join(home, "rex");
	writeFileSync(rex, `#!/bin/bash
printf '%s\\0' "$@" > "$TEST_OUTPUT/focus-argv"
printf 'editor focused\\n' >> "$TEST_OUTPUT/order"
`, { mode: 0o755 });
	for (const [pick, status] of [[1, 0], [0, 0], [1, 2]]) {
		rmSync(join(directory, "focus-argv"), { force: true });
		const result = childProcess.spawnSync(fileURLToPath(new URL("../rexflash", import.meta.url)), args, {
			encoding: "utf8",
			env: { ...process.env, HOME: home, PATH: "/usr/bin:/bin", REX_BIN: rex, TEST_OUTPUT: directory, TEST_PICK: String(pick), TEST_STATUS: String(status) },
		});
		assert.equal(result.status, status, result.stderr);
		assert.deepEqual(readFileSync(join(directory, "argv"), "utf8").split("\0").slice(0, -1), args);
		const [session, block, requestFile] = readFileSync(join(directory, "context"), "utf8").trimEnd().split("\n");
		assert.equal(session, "original-session");
		assert.equal(block, "original-block");
		assert.equal(existsSync(requestFile), false, "temporary focus request must be removed");
		if (pick && status === 0) {
			assert.deepEqual(readFileSync(join(directory, "focus-argv"), "utf8").split("\0").slice(0, -1), ["focus", "-s", session, "new-editor"]);
			assert.equal(readFileSync(join(directory, "order"), "utf8"), "upstream returned\neditor focused\n");
		} else {
			assert.equal(existsSync(join(directory, "focus-argv")), false);
		}
	}
});

test("the executable validates arguments with Rex's minimal PATH", () => {
	const result = childProcess.spawnSync(fileURLToPath(new URL("../rexflash", import.meta.url)), [], {
		encoding: "utf8",
		env: { ...process.env, PATH: "/usr/bin:/bin", NODE_VERSION: "" },
	});
	assert.equal(result.status, 1);
	assert.match(result.stderr, /Missing --session or --block/);
});

test("Open still starts Node through the nvm default with Rex's minimal PATH", () => {
	const result = childProcess.spawnSync(fileURLToPath(new URL("../rexflash", import.meta.url)), ["--open"], {
		input: "", encoding: "utf8",
		env: { ...process.env, PATH: "/usr/bin:/bin", NODE_VERSION: "" },
	});
	assert.equal(result.status, 1);
	assert.match(result.stderr, /Invalid Open target/);
});
