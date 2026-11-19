import childProcess from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { basename, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const rex = process.env.REX_BIN || join(homedir(), ".local/bin/rex");
const sourceExtensions = new Set(
	"c h cc hh cpp hpp cxx hxx m mm cs fs fsx vb go rs py pyi rb php java kt kts swift scala sc js jsx mjs cjs ts tsx mts cts vue svelte html htm css scss sass less sh bash zsh fish ps1 lua vim el ex exs erl hrl clj cljs cljc edn hs lhs ml mli r sql graphql gql proto nix json jsonc yaml yml toml xml xsl xslt svg tex typ".split(" "),
);
const sourceNames = new Set(["Makefile", "Dockerfile", "Containerfile", "Justfile", "justfile", "Rakefile", "Gemfile", "CMakeLists.txt", ".bashrc", ".zshrc", ".vimrc"]);

function run(command: string, args: string[]) {
	const result = childProcess.spawnSync(command, args, { encoding: "utf8" });
	if (result.error) throw result.error;
	if (result.status !== 0) throw new Error(`${basename(command)}: ${result.stderr?.trim() || `exit ${result.status}`}`);
	return result.stdout;
}

export function targetOf(text: string, cwd = process.cwd()) {
	if (!text || /[\x00-\x1f\x7f]/.test(text)) throw new Error("Invalid Open target");
	let path = text;
	let fragment = "";
	const isFileUri = /^file:/i.test(text);
	const absolute = (value: string) => resolve(cwd, value.startsWith("~/") ? join(homedir(), value.slice(2)) : value);
	if (isFileUri) {
		const url = new URL(text);
		if (url.hostname && url.hostname !== "localhost") return { openArg: text };
		fragment = url.hash;
		path = fileURLToPath(url);
	} else if (/^[a-z][a-z\d+.-]*:/i.test(text)) {
		const withoutLocation = text.replace(/:(\d+)(?::(\d+))?$/, "");
		if (text.includes("://") || (!existsSync(absolute(text)) && !existsSync(absolute(withoutLocation)))) {
			return { openArg: text };
		}
	}
	let line: string | undefined;
	let column: string | undefined;
	if (!existsSync(absolute(path))) {
		const hash = path.match(/^(.*?)#L(\d+)(?:C(\d+))?$/);
		const suffix = path.match(/^(.*?):(\d+)(?::(\d+))?$/);
		if (hash || suffix) [, path, line, column] = (hash || suffix)!;
	}
	const hash = fragment.match(/^#L(\d+)(?:C(\d+))?$/);
	if (hash) [, line, column] = hash;
	for (const position of [line, column]) {
		if (position !== undefined && (!Number.isSafeInteger(Number(position)) || Number(position) < 1)) {
			throw new Error("Line and column must be positive integers");
		}
	}
	path = absolute(path);
	return { path, line, column, openArg: isFileUri ? text : path };
}

export function isCode(path: string, mime: string) {
	const sourceMime = /^(?:text\/x-|application\/(?:javascript|typescript|json|xml|x-(?:javascript|shellscript|python|ruby))$)/.test(mime);
	const textual = mime.startsWith("text/") || sourceMime || mime === "image/svg+xml" || /^(?:application|inode)\/x-empty$/.test(mime);
	// shortcut: extensionless text/plain files use macOS Open; add their names when needed.
	return textual && (sourceMime || sourceExtensions.has(extname(path).slice(1).toLowerCase()) || sourceNames.has(basename(path)));
}

export function openSelection(text: string) {
	const target = targetOf(text);
	if (target.path && existsSync(target.path) && statSync(target.path).isFile()) {
		const mime = run("/usr/bin/file", ["-Lb", "--mime-type", "--", target.path]).trim();
		if (isCode(target.path, mime)) {
			const session = process.env.REXFLASH_SOURCE_SESSION;
			const block = process.env.REXFLASH_SOURCE_BLOCK;
			const focusFile = process.env.REXFLASH_FOCUS_FILE;
			if (!session || !block || !focusFile) throw new Error("Missing Rexflash source pane context");
			const editor = ["/opt/homebrew/bin/nvim"];
			if (target.line) {
				// LazyVim loads its UI after startup commands; reapply the position once its viewport settles.
				editor.push(`+lua local function jump() vim.fn.cursor(${Number(target.line)},${Number(target.column || 1)}); vim.cmd("normal! zz") end; `
					+ 'jump(); vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = function() vim.schedule(jump) end })');
			}
			editor.push("--", target.path);
			const created = JSON.parse(run(rex, ["split", "-s", session, "-b", block, "--split=left", "--focus=false", "--shell=none", "-c", process.cwd(), "--json", "--", ...editor]));
			const newBlock = created.block_ids?.[0];
			if (typeof newBlock !== "string" || !newBlock) throw new Error("Rex split returned no pane ID");
			writeFileSync(focusFile, newBlock, { mode: 0o600 });
			return;
		}
	}
	run("/usr/bin/open", [target.openArg]);
}

export function main(args: string[]) {
	if (args[0] === "--open") return openSelection(readFileSync(0, "utf8"));
	const session = args[args.indexOf("--session") + 1];
	const block = args[args.indexOf("--block") + 1];
	if (!args.includes("--session") || !session || !args.includes("--block") || !block) throw new Error("Missing --session or --block");
	const temporary = mkdtempSync(join(tmpdir(), "rexflash-"));
	const focusFile = join(temporary, "focus");
	try {
		const result = childProcess.spawnSync(join(homedir(), "dev/rexflash/target/release/rexflash"), args, {
			stdio: "inherit",
			env: { ...process.env, REXFLASH_SOURCE_SESSION: session, REXFLASH_SOURCE_BLOCK: block, REXFLASH_FOCUS_FILE: focusFile },
		});
		if (result.error) throw result.error;
		process.exitCode = result.status ?? 1;
		// Rexflash refocuses the source pane on exit, so focus the editor afterwards.
		if (result.status === 0 && existsSync(focusFile)) run(rex, ["focus", "-s", session, readFileSync(focusFile, "utf8")]);
	} finally {
		rmSync(temporary, { recursive: true, force: true });
	}
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	try {
		main(process.argv.slice(2));
	} catch (error) {
		console.error(`rexflash: ${error instanceof Error ? error.message : error}`);
		process.exitCode = 1;
	}
}
