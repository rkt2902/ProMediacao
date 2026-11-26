// invite-mediator: o admin convida um mediador para um escritório.
// Corpo: { email, office_id, full_name? }. Só papel admin (lido da base de dados a partir do JWT).
import { admin, requireCaller } from "../_shared/clients.ts";
import { ApiError, cleanEmail, cleanName, cleanUuid, serveFn } from "../_shared/http.ts";

serveFn(async (req, body) => {
  const caller = await requireCaller(req);
  if (caller.role !== "admin") throw new ApiError(403, "forbidden");

  const email = cleanEmail(body.email);
  const officeId = cleanUuid(body.office_id);
  // O nome é opcional no convite; sem ele usa-se a parte local do email (o mediador corrige-o depois).
  const fullName = body.full_name == null || body.full_name === ""
    ? cleanName(email.split("@")[0])
    : cleanName(body.full_name);

  const { data: office } = await admin.from("offices").select("id").eq("id", officeId).maybeSingle();
  if (!office) throw new ApiError(404, "not_found");

  // Resposta neutra para email já usado (não diz se é mediador, cliente ou admin).
  const escaped = email.replace(/[\\%_]/g, "\\$&");
  const { data: taken } = await admin.from("profiles").select("id").ilike("email", escaped).limit(1);
  if (taken && taken.length > 0) throw new ApiError(409, "cannot_invite");

  // Cria o utilizador e envia o convite (o mediador define a palavra-passe pelo link).
  const { data: invited, error: inviteError } = await admin.auth.admin.inviteUserByEmail(email, {
    redirectTo: Deno.env.get("AUTH_REDIRECT_URL"),
    data: { full_name: fullName }, // só informativo: o papel NUNCA vem dos metadados
  });
  if (inviteError || !invited.user) {
    console.error("invite_error", inviteError?.code ?? String(inviteError?.status ?? "unknown"));
    if (inviteError?.status === 422) throw new ApiError(409, "cannot_invite");
    throw new ApiError(502, "send_failed");
  }
  const userId = invited.user.id;

  // Perfil e pertença (um único escritório: a chave primária de office_members garante-o).
  const { error: profileError } = await admin
    .from("profiles")
    .insert({ id: userId, role: "mediador", full_name: fullName, email });
  if (!profileError) {
    const { error: memberError } = await admin
      .from("office_members")
      .insert({ user_id: userId, office_id: officeId });
    if (!memberError) return { ok: true };
    console.error("member_error", memberError.code ?? "unknown");
  } else {
    console.error("profile_error", profileError.code ?? "unknown");
  }

  // Falhou a meio: desfaz para não deixar um utilizador sem perfil (o perfil apaga-se em cascata).
  await admin.auth.admin.deleteUser(userId);
  throw new ApiError(500, "server_error");
});
