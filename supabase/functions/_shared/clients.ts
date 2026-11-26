// Clientes Supabase e identificação do chamador.
// SUPABASE_URL, SUPABASE_ANON_KEY e SUPABASE_SERVICE_ROLE_KEY são injetadas pela
// plataforma nas edge functions: não se definem nem se guardam no repositório.
import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { ApiError } from "./http.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const noSession = { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false };

/** Service role: ignora RLS. Só no servidor e só depois de validar o chamador. */
export const admin = createClient(url, serviceKey, { auth: noSession });

/** Chave anon: usada só para pedir o envio do link mágico ao Supabase Auth. */
export const anon = createClient(url, anonKey, { auth: noSession });

/** Cliente que age COMO o utilizador (RLS e auth.uid() aplicam-se; a auditoria fica com o autor certo). */
export function asUser(jwt: string) {
  return createClient(url, anonKey, {
    auth: noSession,
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
}

export type Role = "admin" | "mediador" | "cliente";

export interface Caller {
  id: string;
  jwt: string;
  role: Role;
  officeId: string | null;
  fullName: string;
}

/** Valida o JWT e lê o papel na base de dados (nunca do corpo do pedido nem dos metadados do token). */
export async function requireCaller(req: Request): Promise<Caller> {
  const header = req.headers.get("authorization") ?? "";
  const jwt = header.toLowerCase().startsWith("bearer ") ? header.slice(7).trim() : "";
  if (!jwt) throw new ApiError(401, "unauthenticated");

  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) throw new ApiError(401, "unauthenticated"); // inclui a chave anon (sem utilizador)

  const { data: profile } = await admin
    .from("profiles")
    .select("role, full_name")
    .eq("id", data.user.id)
    .maybeSingle();
  if (!profile) throw new ApiError(403, "forbidden");

  let officeId: string | null = null;
  if (profile.role === "mediador") {
    const { data: member } = await admin
      .from("office_members")
      .select("office_id")
      .eq("user_id", data.user.id)
      .maybeSingle();
    officeId = member?.office_id ?? null;
  }

  return {
    id: data.user.id,
    jwt,
    role: profile.role as Role,
    officeId,
    fullName: profile.full_name as string,
  };
}
