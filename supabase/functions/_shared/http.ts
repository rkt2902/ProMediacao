// Utilitários HTTP partilhados pelas funções de servidor.
// CORS mínimo, corpo limitado, erros sem detalhes técnicos.

// Origens autorizadas (só a app web). Vazio = nenhum cabeçalho CORS (apps nativas não precisam).
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

const MAX_BODY_BYTES = 4096;

/** Erro "esperado": o código é o que o cliente vê; nunca texto técnico. */
export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    public extra: Record<string, unknown> = {},
  ) {
    super(code);
  }
}

function corsHeaders(req: Request): Record<string, string> {
  const headers: Record<string, string> = { Vary: "Origin" };
  const origin = req.headers.get("origin");
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
    headers["Access-Control-Allow-Headers"] = "authorization, apikey, content-type, x-client-info";
    headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
    headers["Access-Control-Max-Age"] = "600";
  }
  return headers;
}

function json(req: Request, status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(req),
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

async function readBody(req: Request): Promise<Record<string, unknown>> {
  const declared = Number(req.headers.get("content-length") ?? "0");
  if (declared > MAX_BODY_BYTES) throw new ApiError(413, "invalid_input");
  const text = await req.text();
  if (text.length > MAX_BODY_BYTES) throw new ApiError(413, "invalid_input");
  try {
    const parsed = JSON.parse(text);
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch {
    // cai para o erro abaixo
  }
  throw new ApiError(400, "invalid_input");
}

/** Arranca a função: só POST, corpo JSON, erros normalizados. */
export function serveFn(
  handler: (req: Request, body: Record<string, unknown>) => Promise<Record<string, unknown> | void>,
) {
  Deno.serve(async (req) => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders(req) });
    if (req.method !== "POST") return json(req, 405, { error: { code: "method_not_allowed" } });
    try {
      const body = await readBody(req);
      const result = await handler(req, body);
      return json(req, 200, result ?? { ok: true });
    } catch (e) {
      if (e instanceof ApiError) return json(req, e.status, { error: { code: e.code, ...e.extra } });
      // Só o tipo do erro vai para o registo: mensagens podem conter emails.
      console.error("unhandled_error", e instanceof Error ? e.name : "unknown");
      return json(req, 500, { error: { code: "server_error" } });
    }
  });
}

/** Trabalho depois de responder (resposta igual e com o mesmo tempo, exista ou não a conta). */
export function runInBackground(work: Promise<unknown>): Promise<unknown> | void {
  const safe = work.catch((e) => {
    console.error("background_error", e instanceof Error ? e.name : "unknown");
  });
  // deno-lint-ignore no-explicit-any
  const runtime = (globalThis as any).EdgeRuntime;
  if (runtime?.waitUntil) {
    runtime.waitUntil(safe);
    return;
  }
  return safe; // fora do runtime do Supabase o chamador faz await
}

// ---- validação de entrada ---------------------------------------------------

export function cleanEmail(value: unknown): string {
  if (typeof value !== "string") throw new ApiError(400, "invalid_input");
  const email = value.trim().toLowerCase();
  if (email.length < 3 || email.length > 320 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ApiError(400, "invalid_input");
  }
  return email;
}

export function cleanName(value: unknown): string {
  if (typeof value !== "string") throw new ApiError(400, "invalid_input");
  // deno-lint-ignore no-control-regex
  const name = value.replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();
  if (name.length < 1 || name.length > 200 || /[<>]/.test(name)) throw new ApiError(400, "invalid_input");
  return name;
}

export function cleanUuid(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
  ) {
    throw new ApiError(400, "invalid_input");
  }
  return value.toLowerCase();
}
