// Envio de pedidos ao cliente: limite de 60 s, link mágico ou aviso sem link.
import { admin, anon } from "./clients.ts";
import { ApiError } from "./http.ts";

const REDIRECT_URL = Deno.env.get("AUTH_REDIRECT_URL");

async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * Reserva o envio para este destinatário. Lança 429 "too_soon" se houve outro há
 * menos de 60 s. Corre sempre, exista ou não a conta, para a resposta ser igual.
 */
export async function claimSendSlot(email: string): Promise<void> {
  const { data, error } = await admin.rpc("claim_send_slot", {
    p_recipient_hash: await sha256Hex(email.trim().toLowerCase()),
    p_window_seconds: 60,
  });
  if (error) {
    console.error("throttle_error", error.code ?? "unknown");
    throw new ApiError(500, "server_error");
  }
  const wait = Number(data);
  if (wait > 0) throw new ApiError(429, "too_soon", { retry_after_seconds: wait });
}

/** Contexto mostrado no email do link: escritório e mediador do pedido pendente mais recente. */
export async function latestPendingContext(
  clientId: string,
): Promise<{ officeName: string; mediatorName: string } | null> {
  const { data: grant } = await admin
    .from("consent_grants")
    .select("office_id, created_by")
    .eq("client_id", clientId)
    .eq("status", "pendente")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!grant) return null;
  const { data: office } = await admin.from("offices").select("name").eq("id", grant.office_id).maybeSingle();
  const { data: mediator } = grant.created_by
    ? await admin.from("profiles").select("full_name").eq("id", grant.created_by).maybeSingle()
    : { data: null };
  if (!office) return null;
  return { officeName: office.name, mediatorName: mediator?.full_name ?? "" };
}

interface DeliverOptions {
  userId: string;
  email: string;
  /** "auto": cliente com conta recebe só aviso sem link; "link": envia sempre o link (pedido do próprio cliente). */
  mode: "auto" | "link";
  officeName: string;
  mediatorName: string;
}

/**
 * Entrega o pedido. "Tem conta" = já iniciou sessão alguma vez. Quem já tem conta
 * vê o pedido na app e recebe um aviso SEM link (um mediador nunca dispara um
 * link de entrada para quem já usa a app). Quem nunca entrou recebe o link mágico.
 */
export async function deliverRequest(opts: DeliverOptions): Promise<"link" | "notice" | "none"> {
  const { data: found } = await admin.auth.admin.getUserById(opts.userId);
  const user = found?.user;
  if (!user) throw new ApiError(500, "server_error");

  const hasAccount = Boolean(user.last_sign_in_at);
  if (opts.mode === "auto" && hasAccount) {
    return (await sendNotice(opts.email, opts.officeName, opts.mediatorName)) ? "notice" : "none";
  }

  // O modelo de email lê {{ .Data.office_name }} e {{ .Data.mediator_name }}: atualizamos
  // os metadados antes de pedir o link. Vazios = o modelo mostra a versão sem escritório.
  const { error: metaError } = await admin.auth.admin.updateUserById(opts.userId, {
    user_metadata: {
      ...(user.user_metadata ?? {}),
      office_name: opts.officeName,
      mediator_name: opts.mediatorName,
    },
  });
  if (metaError) {
    console.error("metadata_error", metaError.code ?? "unknown");
    throw new ApiError(502, "send_failed");
  }

  const { error } = await anon.auth.signInWithOtp({
    email: opts.email,
    options: { shouldCreateUser: false, emailRedirectTo: REDIRECT_URL },
  });
  if (error) {
    console.error("otp_error", error.code ?? String(error.status ?? "unknown"));
    throw new ApiError(502, "send_failed");
  }
  return "link";
}

/**
 * Aviso por email SEM link (só texto simples). Opcional: precisa de um fornecedor
 * de email (ver README). Sem configuração, não envia nada e o pedido continua
 * visível na app. Devolve true se o fornecedor aceitou o envio.
 */
async function sendNotice(email: string, officeName: string, mediatorName: string): Promise<boolean> {
  const apiKey = Deno.env.get("NOTICE_EMAIL_API_KEY");
  const from = Deno.env.get("NOTICE_EMAIL_FROM");
  if (!apiKey || !from) return false;
  const apiUrl = Deno.env.get("NOTICE_EMAIL_API_URL") ?? "https://api.resend.com/emails";

  const who = mediatorName ? `${mediatorName} (${officeName})` : officeName;
  const text = [
    "Bom dia,",
    "",
    `Tem um pedido de partilha de dados pendente de ${who} no ProDossier.`,
    "Abra a aplicação ProDossier com a sua conta para o aceitar ou recusar.",
    "",
    "Por segurança, este email não tem nenhum link. Se não esperava este pedido, ignore esta mensagem.",
  ].join("\n");

  try {
    const res = await fetch(apiUrl, {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from,
        to: [email],
        subject: "Tem um pedido pendente no ProDossier",
        text,
      }),
    });
    if (!res.ok) console.error("notice_error", res.status);
    return res.ok;
  } catch {
    console.error("notice_error", "network");
    return false;
  }
}
