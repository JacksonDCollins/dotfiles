import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { Message } from "@earendil-works/pi-ai";
import { uuidv7 } from "@earendil-works/pi-ai";
import {
	convertToLlm,
	serializeConversation,
	type ExtensionAPI,
	type ExtensionContext,
	type SessionEntry,
} from "@earendil-works/pi-coding-agent";

const MAX_TITLE_LENGTH = 64;
const MAX_TRANSCRIPT_LENGTH = 12000;
const STORE_KEY = Symbol.for("dotfiles:auto-session-title");
const SYSTEM_PROMPT = `Name this coding-agent session from the user's prompt or transcript.
Return only a short title, 3-7 words, no quotes, no punctuation unless needed.
Be specific. Do not include "pi" or a project name.`;

type StoredTitle = { force: boolean; title: string };
type TitleStore = {
	nextId: number;
	pending: Map<string, number>;
	ready: Map<string, StoredTitle>;
};

function store(): TitleStore {
	const globalStore = globalThis as typeof globalThis & {
		[STORE_KEY]?: TitleStore;
	};
	globalStore[STORE_KEY] ??= {
		nextId: 1,
		pending: new Map(),
		ready: new Map(),
	};
	return globalStore[STORE_KEY];
}

function sessionKey(ctx: ExtensionContext): string | undefined {
	return (
		ctx.sessionManager.getSessionFile() ?? ctx.sessionManager.getSessionId()
	);
}

function cleanTitle(title: string): string {
	const cleaned = title.replace(/["'`]/g, "").replace(/\s+/g, " ").trim();

	if (!cleaned) {
		return "New session";
	}
	if (cleaned.length <= MAX_TITLE_LENGTH) {
		return cleaned;
	}
	return `${cleaned.slice(0, MAX_TITLE_LENGTH - 1).trimEnd()}…`;
}

function entryToMessage(entry: SessionEntry): AgentMessage | undefined {
	if (entry.type === "message") {
		return entry.message;
	}
	if (entry.type === "compaction") {
		return {
			role: "compactionSummary",
			summary: entry.summary,
			tokensBefore: entry.tokensBefore,
			timestamp: new Date(entry.timestamp).getTime(),
		};
	}
	return undefined;
}

function sessionTranscript(ctx: ExtensionContext): string {
	const messages: AgentMessage[] = [];
	for (const entry of ctx.sessionManager.getBranch()) {
		const message = entryToMessage(entry);
		if (message) {
			messages.push(message);
		}
	}
	const transcript = serializeConversation(convertToLlm(messages));
	return transcript.slice(-MAX_TRANSCRIPT_LENGTH);
}

async function titleFromText(
	text: string,
	ctx: ExtensionContext,
): Promise<string> {
	if (!ctx.model) {
		return cleanTitle(text);
	}

	const message: Message = {
		role: "user",
		content: [{ type: "text", text }],
		timestamp: Date.now(),
	};
	try {
		const response = await ctx.modelRegistry.complete(
			ctx.model,
			{ systemPrompt: SYSTEM_PROMPT, messages: [message] },
			{ cacheRetention: "none", sessionId: uuidv7() },
		);
		const titleParts: string[] = [];
		for (const part of response.content) {
			if (part.type === "text") {
				titleParts.push(part.text);
			}
		}

		return cleanTitle(titleParts.join(" ") || text);
	} catch {
		return cleanTitle(text);
	}
}

function setWindowTitle(pi: ExtensionAPI, ctx: ExtensionContext) {
	if (!ctx.hasUI) {
		return;
	}

	const session = pi.getSessionName();
	ctx.ui.setTitle(session ? `π - ${session}` : "π");
}

function applyReadyTitle(pi: ExtensionAPI, ctx: ExtensionContext): boolean {
	const key = sessionKey(ctx);
	const ready = key ? store().ready.get(key) : undefined;
	if (!key || !ready) {
		return false;
	}
	if (!ready.force && pi.getSessionName()) {
		store().ready.delete(key);
		return false;
	}

	pi.setSessionName(ready.title);
	store().ready.delete(key);
	setWindowTitle(pi, ctx);
	return true;
}

function queueTitle(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	text: string,
	force = false,
) {
	const key = sessionKey(ctx);
	const titles = store();
	if (!key || (!force && titles.pending.has(key))) {
		return;
	}

	const requestId = titles.nextId++;
	titles.pending.set(key, requestId);
	void titleFromText(text, ctx)
		.then((title) => {
			if (titles.pending.get(key) !== requestId) {
				return;
			}
			titles.pending.delete(key);
			titles.ready.set(key, { force, title });
			try {
				applyReadyTitle(pi, ctx);
			} catch {
				// The user may have switched sessions. Keep the title for session_start.
			}
		})
		.catch(() => {
			if (titles.pending.get(key) === requestId) {
				titles.pending.delete(key);
			}
		});
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("retitle", {
		description: "Regenerate the session title from the current conversation",
		handler: (_args: string, ctx: ExtensionContext) => {
			const transcript = sessionTranscript(ctx);
			if (!transcript) {
				ctx.ui.notify("No session messages to title", "error");
				return;
			}

			queueTitle(pi, ctx, transcript, true);
			ctx.ui.notify("Regenerating session title…", "info");
		},
	});

	pi.on(
		"session_start",
		(_event: { reason?: string }, ctx: ExtensionContext) => {
			applyReadyTitle(pi, ctx);
			setWindowTitle(pi, ctx);
		},
	);

	pi.on(
		"before_agent_start",
		(event: { prompt: string }, ctx: ExtensionContext) => {
			applyReadyTitle(pi, ctx);
			if (!pi.getSessionName()) {
				queueTitle(pi, ctx, event.prompt);
			}
			setWindowTitle(pi, ctx);
		},
	);

	pi.on(
		"session_info_changed",
		(_event: { name?: string }, ctx: ExtensionContext) => {
			setWindowTitle(pi, ctx);
		},
	);
}
