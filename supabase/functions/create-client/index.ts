// create-client: o mediador cria um cliente (nome e email) e uma concessão PENDENTE
// para o seu escritório. Corpo: { full_name, email }. Só papel mediador com escritório.
//
// A resposta de sucesso é sempre a mesma ({ ok: true }) e nunca diz se o email já
// existia como cliente (de outro escritório) ou como outro papel.
import { admin, asUser, requireCaller } from "../_shared/clients.ts";
import { ApiError, cleanEmail, cleanName, serveFn } from "../_shared/http.ts";
import { claimSendSlot, deliverRequest } from "../_shared/requests.ts";

/** Procura um perfil pelo email, sem distinguir maiúsculas (e sem tratar % e _ como curingas). */
async function findProfileByEmail(email: string) {
  const escaped = email.replace(/[\\%_]/g, "\\$&");
  const { data } = await admin.from("profiles").select("id, role").ilike("email", escaped).limit(1);
  return data?.[0] ?? null;
}

serveFn(async (req, body) => {
  const caller = await requireCaller(req);
  if (caller.role !== "mediador" || !caller.officeId) throw new ApiError(403, "forbidden");
  const officeId = caller.officeId; // sempre o do chamador, nunca do corpo do pedido

  const email = cleanEmail(body.email);
  const fullName = cleanName(body.full_name);

  let profile = await findProfileByEmail(email);
  let created = false;

  if (!profile) {
    // Cliente novo. O email fica confirmado porque só quem o controla recebe o link.
    const { data, error } = await admin.auth.admin.createUser({ email, email_confirm: true });
    if (error || !data.user) {
      // Corrida com outro mediador ou email já usado fora de profiles: tenta de novo uma vez.
      profile = await findProfileByEmail(email);
      if (!profile) return { ok: true }; // sem revelar nada
    } else {
      const { error: profileError } = await admin
        .from("profiles")
        .insert({ id: data.user.id, role: "cliente", full_name: fullName, email });
      if (profileError) {
        console.error("profile_error", profileError.code ?? "unknown");
        await admin.auth.admin.deleteUser(data.user.id);
        throw new ApiError(500, "server_error");
      }
      profile = { id: data.user.id, role: "cliente" };
      created = true;
    }
  }

  // Email de um mediador ou admin: resposta de sucesso neutra, nada é criado.
  if (profile.role !== "cliente") return { ok: true };
  const clientId = profile.id as string;

  if (!created) {
    // Estados do PRÓPRIO escritório (o mediador já os vê na sua lista, nada de novo se revela).
    const { data: grants } = await admin
      .from("consent_grants")
      .select("status")
      .eq("client_id", clientId)
      .eq("office_id", officeId)
      .in("status", ["pendente", "ativa", "recusada"]);
    const statuses = (grants ?? []).map((g) => g.status);
    if (statuses.includes("pendente") || statuses.includes("ativa")) throw new ApiError(409, "already_client");
    if (statuses.includes("recusada")) throw new ApiError(409, "declined"); // recusada é final
  }

  // A concessão é criada COMO o mediador: RLS valida escritório, estado pendente e versão
  // do texto, e a auditoria regista o mediador como autor.
  const db = asUser(caller.jwt);
  const { data: version } = await db.rpc("current_consent_version");
  const { error: grantError } = await db.from("consent_grants").insert({
    client_id: clientId,
    office_id: officeId,
    status: "pendente",
    consent_version: version,
    created_by: caller.id,
  });
  if (grantError) {
    console.error("grant_error", grantError.code ?? "unknown");
    if (created) await admin.auth.admin.deleteUser(clientId); // não deixa um cliente sem pedido
    if (grantError.code === "23505") throw new ApiError(409, "already_client");
    throw new ApiError(500, "server_error");
  }

  // Envio (limite de 60 s por destinatário). Se ainda estiver no intervalo, o pedido já
  // existe e o mediador pode usar "Reenviar pedido" daqui a pouco.
  try {
    await claimSendSlot(email);
  } catch (e) {
    if (e instanceof ApiError && e.code === "too_soon") return { ok: true };
    throw e;
  }
  const { data: office } = await admin.from("offices").select("name").eq("id", officeId).maybeSingle();
  await deliverRequest({
    userId: clientId,
    email,
    mode: "auto",
    officeName: office?.name ?? "",
    mediatorName: caller.fullName,
  }); // falha de envio: 502 send_failed ("O cliente foi criado, mas o pedido não seguiu...")
  return { ok: true };
});
