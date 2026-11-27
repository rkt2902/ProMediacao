// send-request-email (feature 002, US 4.1 e 4.4): envia ao cliente titular UM email
// curto por criação de pedidos (os N pedidos de um batch juntos). Serve também o
// "Reenviar email" do mediador (mesma chamada, limite de 60 s por destinatário).
//
// Pedido : POST { batch_id } com o JWT de um mediador (Authorization: Bearer ...).
//          batch_id = o valor devolvido por public.create_requests (igual nos N pedidos).
// Sucesso: 200 { ok: true, delivered: "email", recipient_email, sent_at, next_allowed_at }
// Erros  : { error: { code, ...extra } } com códigos fixos (lista no README desta pasta).
//
// Garantias
//  * O email NUNCA desfaz nem altera os pedidos: esta função só lê. A app chama-a
//    depois de create_requests ter respondido; se falhar, os pedidos já existem e a
//    app mostra "Pedido criado, mas o email não foi enviado" + "Reenviar email".
//  * Autorização pela própria RLS da 002: os pedidos do batch são lidos com o JWT do
//    mediador, por isso só aparecem se o destino for o escritório dele E a concessão
//    do cliente estiver ATIVA nesse momento. A service role só é usada depois disso,
//    para nomes e o email do cliente, e para distinguir "acesso retirado" de "não existe".
//  * Destinatário: sempre o cliente titular dos pedidos (email do perfil), nunca um
//    endereço vindo do corpo do pedido.
//  * Conteúdo: escritório, tipos, mensagem do mediador (HTML escapado) e link para
//    /pedidos da app. Sem lista de documentos/dados, notas do tipo nem dados de saúde.
//    O link é o endereço da app, não um link de entrada: sem sessão, a app pede para
//    entrar (regra da 001: o mediador nunca dispara um link de entrada).
//  * Limite: claim_send_slot (001b), 60 s por destinatário, partilhado com os
//    convites. Conta a partir de cada tentativa de envio, também quando o
//    fornecedor falha ("bloqueado 60 s após cada envio", como na 001).
//  * Registos só com códigos, nunca emails nem nomes.
import { admin, asUser, requireCaller } from "../_shared/clients.ts";
import { ApiError, cleanUuid, serveFn } from "../_shared/http.ts";
import { claimSendSlot } from "../_shared/requests.ts";
import { isEmailConfigured, sendEmail } from "../_shared/mailer.ts";
import { renderRequestEmail } from "../_shared/request_email.ts";

const RESEND_WINDOW_SECONDS = 60; // o mesmo valor que claimSendSlot usa

/** Endereço "Ver os pedidos": APP_URL, ou a origem de AUTH_REDIRECT_URL (001). */
function requestsUrl(): string | null {
  const raw = Deno.env.get("APP_URL") || Deno.env.get("AUTH_REDIRECT_URL") || "";
  try {
    const u = new URL(raw);
    if (u.protocol !== "https:" && u.protocol !== "http:") return null;
    return `${u.origin}/pedidos`;
  } catch {
    return null;
  }
}

interface RequestRow {
  id: string;
  client_id: string;
  insurance_type_code: string;
  type_name: string;
  message: string | null;
  author_id: string | null;
}

serveFn(async (req, body) => {
  const caller = await requireCaller(req);
  if (caller.role !== "mediador" || !caller.officeId) throw new ApiError(403, "forbidden");
  const officeId = caller.officeId; // sempre o do chamador
  const batchId = cleanUuid(body.batch_id);

  // 1. Pedidos do batch que ESTE mediador vê (RLS: destino = o seu escritório e concessão ativa).
  const { data: visible, error: visibleError } = await asUser(caller.jwt)
    .from("requests")
    .select("id, client_id, insurance_type_code, type_name, message, author_id")
    .eq("batch_id", batchId);
  if (visibleError) {
    console.error("requests_read_error", visibleError.code ?? "unknown");
    throw new ApiError(500, "server_error");
  }

  // Todos os pedidos do batch (service role), para confirmar que o batch é deste escritório.
  const { data: all } = await admin.from("requests").select("id").eq("batch_id", batchId);
  const allIds = (all ?? []).map((r) => r.id as string);
  let ownIds = new Set<string>();
  if (allIds.length > 0) {
    const { data: recipients } = await admin
      .from("request_recipients")
      .select("request_id")
      .in("request_id", allIds)
      .eq("office_id", officeId);
    ownIds = new Set((recipients ?? []).map((r) => r.request_id as string));
  }
  // Batch inexistente ou de outro escritório: como se não existisse.
  if (allIds.length === 0 || ownIds.size !== allIds.length) throw new ApiError(404, "not_found");

  const rows = (visible ?? []) as RequestRow[];
  // O batch é deste escritório mas a RLS não o mostra: a concessão deixou de estar ativa.
  if (rows.length !== allIds.length) throw new ApiError(409, "client_not_available");

  const clientId = rows[0].client_id;
  if (rows.some((r) => r.client_id !== clientId)) {
    console.error("batch_inconsistent", "client");
    throw new ApiError(500, "server_error");
  }

  // 2. Fornecedor e link configurados? Verificado ANTES de gastar o limite de 60 s.
  const url = requestsUrl();
  if (!isEmailConfigured() || !url) throw new ApiError(503, "email_unavailable");

  // 3. Dados do email (service role, já autorizado acima)
  const { data: client } = await admin
    .from("profiles")
    .select("email, role")
    .eq("id", clientId)
    .maybeSingle();
  if (!client || client.role !== "cliente") throw new ApiError(404, "not_found");

  const { data: office } = await admin.from("offices").select("name").eq("id", officeId).maybeSingle();
  if (!office) throw new ApiError(500, "server_error");

  const authorId = rows.find((r) => r.author_id)?.author_id ?? null;
  const { data: author } = authorId
    ? await admin.from("profiles").select("full_name").eq("id", authorId).maybeSingle()
    : { data: null };

  // Tipos pela ordem do catálogo (a mesma da app e do render)
  const codes = [...new Set(rows.map((r) => r.insurance_type_code))];
  const { data: types } = await admin.from("insurance_types").select("code, sort_order").in("code", codes);
  const order = new Map((types ?? []).map((t) => [t.code as string, Number(t.sort_order)]));
  const sorted = [...rows].sort((a, b) => (order.get(a.insurance_type_code) ?? 99) - (order.get(b.insurance_type_code) ?? 99));

  // 4. Limite de 60 s por destinatário (429 too_soon com retry_after_seconds)
  await claimSendSlot(client.email);

  // 5. Montar e enviar
  const sentAt = new Date();
  const email = renderRequestEmail({
    officeName: office.name,
    mediatorName: author?.full_name ?? "",
    typeNames: sorted.map((r) => r.type_name),
    message: rows[0].message, // igual nos N pedidos do batch
    url,
    recipientEmail: client.email,
    sentAt,
  });
  const result = await sendEmail({ to: client.email, subject: email.subject, html: email.html, text: email.text });
  if (result !== "sent") {
    throw new ApiError(502, "send_failed", { retry_after_seconds: RESEND_WINDOW_SECONDS });
  }

  return {
    ok: true,
    delivered: "email",
    recipient_email: client.email,
    sent_at: sentAt.toISOString(),
    next_allowed_at: new Date(sentAt.getTime() + RESEND_WINDOW_SECONDS * 1000).toISOString(),
  };
});
