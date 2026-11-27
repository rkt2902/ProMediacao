// resend-request: dois usos, distinguidos pelo corpo.
//  (1) Mediador, "Reenviar pedido": { grant_id }. Exige JWT de mediador do escritório da concessão.
//      Responde { ok: true, delivered: "link" | "notice" | "none" } para o mediador saber se
//      saiu algum email ("none": nada enviado, o pedido só está visível na app do cliente).
//  (2) Cliente, "Enviar link de acesso" / link novo: { email }. Pode ser anónimo (ecrã de entrada).
//      Resposta SEMPRE igual ({ ok: true }, sem "delivered") exista ou não a conta; o trabalho
//      corre depois de responder.
// Ambos: no máximo um envio por destinatário a cada 60 s (429 "too_soon" com retry_after_seconds).
import { admin, requireCaller } from "../_shared/clients.ts";
import { ApiError, cleanEmail, cleanUuid, runInBackground, serveFn } from "../_shared/http.ts";
import { claimSendSlot, deliverRequest, latestPendingContext } from "../_shared/requests.ts";

async function mediatorResend(req: Request, grantIdRaw: unknown) {
  const caller = await requireCaller(req);
  if (caller.role !== "mediador" || !caller.officeId) throw new ApiError(403, "forbidden");
  const grantId = cleanUuid(grantIdRaw);

  const { data: grant } = await admin
    .from("consent_grants")
    .select("id, client_id, office_id, status")
    .eq("id", grantId)
    .maybeSingle();
  // Concessão de outro escritório = como se não existisse.
  if (!grant || grant.office_id !== caller.officeId) throw new ApiError(404, "not_found");
  if (grant.status !== "pendente") throw new ApiError(409, "not_pending"); // recusada é final; ativa não precisa

  const { data: client } = await admin.from("profiles").select("email").eq("id", grant.client_id).maybeSingle();
  if (!client) throw new ApiError(404, "not_found");

  await claimSendSlot(client.email);

  // Volta a pôr o pedido "em cima" para quem já tem conta (a app ordena por data de atualização).
  await admin.from("consent_grants").update({ updated_at: new Date().toISOString() }).eq("id", grant.id);

  const { data: office } = await admin.from("offices").select("name").eq("id", grant.office_id).maybeSingle();
  const delivered = await deliverRequest({
    userId: grant.client_id,
    email: client.email,
    mode: "auto", // cliente com conta: só aviso, sem link
    officeName: office?.name ?? "",
    mediatorName: caller.fullName,
  });
  return { ok: true, delivered };
}

async function clientSelfRequest(emailRaw: unknown) {
  const email = cleanEmail(emailRaw);
  await claimSendSlot(email); // igual para qualquer email, exista ou não

  const work = (async () => {
    const escaped = email.replace(/[\\%_]/g, "\\$&");
    const { data } = await admin
      .from("profiles")
      .select("id, role")
      .ilike("email", escaped)
      .limit(1);
    const profile = data?.[0];
    // Só clientes entram por link. Mediador e admin entram com palavra-passe; sem conta, nada a fazer.
    if (!profile || profile.role !== "cliente") return;
    const context = await latestPendingContext(profile.id);
    await deliverRequest({
      userId: profile.id,
      email,
      mode: "link", // o cliente pediu o seu próprio link de entrada
      officeName: context?.officeName ?? "",
      mediatorName: context?.mediatorName ?? "",
    });
  })();

  const pending = runInBackground(work);
  if (pending) await pending; // fora do runtime do Supabase (testes locais)
  return { ok: true };
}

serveFn((req, body) => {
  if (body.grant_id !== undefined) return mediatorResend(req, body.grant_id);
  return clientSelfRequest(body.email);
});
