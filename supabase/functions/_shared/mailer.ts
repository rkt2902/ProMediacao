// Envio de email transacional (não Auth) por API HTTP de um fornecedor.
//
// Porquê: o email por defeito do Supabase só envia emails de AUTENTICAÇÃO (link
// mágico, convite, recuperação), com template fixo no plano gratuito e poucos
// envios por hora. Não envia um email arbitrário como o "pedido criado". Ativar
// "SMTP próprio" no painel do Auth também não chega: isso só muda o canal dos
// emails de autenticação. Este módulo fala diretamente com a API do fornecedor.
//
// Configuração (segredos das funções; os mesmos do aviso sem link da 001):
//   NOTICE_EMAIL_API_KEY   chave da API do fornecedor (nunca no repositório)
//   NOTICE_EMAIL_FROM      remetente, ex.: "ProDossier <no-reply@dominio.pt>"
//   NOTICE_EMAIL_API_URL   opcional. Por defeito Resend (https://api.resend.com/emails).
//                          Brevo: https://api.brevo.com/v3/smtp/email (formato detetado pelo host).
// Sem chave ou remetente: isConfigured() = false e nada é enviado.

export interface OutgoingEmail {
  to: string;
  subject: string;
  html: string;
  text: string;
}

export type SendResult = "sent" | "failed";

function config() {
  const apiKey = Deno.env.get("NOTICE_EMAIL_API_KEY") ?? "";
  const from = Deno.env.get("NOTICE_EMAIL_FROM") ?? "";
  const apiUrl = Deno.env.get("NOTICE_EMAIL_API_URL") || "https://api.resend.com/emails";
  return { apiKey, from, apiUrl };
}

export function isEmailConfigured(): boolean {
  const { apiKey, from } = config();
  return Boolean(apiKey && from);
}

/** "Nome <email@x>" -> { name, email }; "email@x" -> { email }. */
function parseFrom(from: string): { name?: string; email: string } {
  const m = from.match(/^\s*(.*?)\s*<\s*([^>\s]+)\s*>\s*$/);
  if (m) return m[1] ? { name: m[1].replace(/^"|"$/g, ""), email: m[2] } : { email: m[2] };
  return { email: from.trim() };
}

/** Envia um email. Nunca lança: devolve "failed" e regista só o código (sem emails). */
export async function sendEmail(mail: OutgoingEmail): Promise<SendResult> {
  const { apiKey, from, apiUrl } = config();
  if (!apiKey || !from) return "failed";

  let host = "";
  try {
    host = new URL(apiUrl).host;
  } catch {
    console.error("email_error", "bad_api_url");
    return "failed";
  }
  const isBrevo = host === "api.brevo.com";

  const request = isBrevo
    ? {
      headers: { "api-key": apiKey, "Content-Type": "application/json", Accept: "application/json" },
      body: {
        sender: parseFrom(from),
        to: [{ email: mail.to }],
        subject: mail.subject,
        htmlContent: mail.html,
        textContent: mail.text,
      },
    }
    : {
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: { from, to: [mail.to], subject: mail.subject, html: mail.html, text: mail.text },
    };

  try {
    const res = await fetch(apiUrl, {
      method: "POST",
      headers: request.headers,
      body: JSON.stringify(request.body),
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) {
      console.error("email_error", res.status);
      return "failed";
    }
    return "sent";
  } catch {
    console.error("email_error", "network");
    return "failed";
  }
}
