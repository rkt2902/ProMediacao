// Email do pedido (feature 002): assunto, pré-cabeçalho, HTML e texto simples.
// Fonte de verdade da copy: docs/features/002-novo-pedido/03-design.md, secção
// "7. Email do pedido", e o render aprovado renders/email-pedido-*.png.
// Os ficheiros supabase/templates/request-created.{html,txt} são pré-visualizações
// geradas a partir DESTE módulo (valores do render); se a copy mudar, muda-se aqui
// e regeneram-se (ver supabase/functions/README.md).
//
// Módulo puro (sem APIs do Deno nem rede): corre em Deno e em Node, para testar.
//
// Regras de conteúdo (US 4.1): escritório, tipos pedidos, mensagem do mediador e
// link para a app. NUNCA a lista de documentos/dados, notas do tipo nem dados de
// saúde. Tudo o que vem da base de dados é escapado (HTML) e o assunto não leva
// quebras de linha.

export interface RequestEmailInput {
  officeName: string;
  /** Mediador que criou os pedidos (autor). Vazio se já não existir. */
  mediatorName: string;
  /** Nomes dos tipos, pela ordem do catálogo. 1 a 13. */
  typeNames: string[];
  /** Mensagem do mediador (até 500 caracteres) ou null. */
  message: string | null;
  /** Link "Ver os pedidos" (ex.: https://app.exemplo.pt/pedidos). */
  url: string;
  recipientEmail: string;
  sentAt: Date;
}

export interface RenderedEmail {
  subject: string;
  preheader: string;
  html: string;
  text: string;
}

const MONTHS = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

/** "27 nov 2026, 10:14", hora de Lisboa. */
export function formatSentAt(date: Date): string {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Lisbon",
    year: "numeric",
    month: "numeric",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? "";
  return `${Number(get("day"))} ${MONTHS[Number(get("month")) - 1]} ${get("year")}, ${get("hour")}:${get("minute")}`;
}

export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/** Uma linha, sem caracteres de controlo (evita injeção de cabeçalhos no assunto). */
function oneLine(value: string): string {
  // deno-lint-ignore no-control-regex
  return value.replace(/[\u0000-\u001f\u007f]+/g, " ").replace(/\s+/g, " ").trim();
}

/** "A", "A e B", "A, B e C". */
function joinTypes(names: string[]): string {
  if (names.length <= 1) return names[0] ?? "";
  return `${names.slice(0, -1).join(", ")} e ${names[names.length - 1]}`;
}

export function renderRequestEmail(input: RequestEmailInput): RenderedEmail {
  const office = oneLine(input.officeName);
  const mediator = oneLine(input.mediatorName);
  const types = input.typeNames.map(oneLine).filter(Boolean);
  const n = types.length;
  const message = input.message?.trim() ? input.message.trim() : null;
  const sentAt = formatSentAt(input.sentAt);

  // Assunto: tipos unidos por ", " e " e "; com mais de 3, "para N seguros".
  const subject = oneLine(
    n > 3 ? `${office} pede-lhe elementos para ${n} seguros` : `${office} pede-lhe elementos para ${joinTypes(types)}`,
  );
  const preheader = "Veja na app o que lhe pedem. A lista não vai neste email.";
  const title = n === 1
    ? `${office} pede-lhe elementos para o seguro ${types[0]}`
    : `${office} pede-lhe elementos para ${n} seguros`;
  const who = mediator ? `${mediator}, do escritório ${office},` : `O escritório ${office}`;
  const intro = n === 1
    ? `${who} criou um pedido para si no ProDossier. Na app vê a lista do que precisa de enviar.`
    : `${who} criou ${n} pedidos para si no ProDossier. Na app vê a lista do que precisa de enviar para cada um.`;
  const officeLine = mediator ? `${office}, enviado por ${mediator}` : office;
  const messageLabel = mediator ? `Mensagem de ${mediator}` : "Mensagem do escritório";
  const security = "Por segurança, a lista de documentos e dados não vai neste email: só a vê na app, depois de entrar.";
  const copyHint = "Se o botão não abrir, copie este endereço para o navegador:";
  const tagline = "O dossiê dos seus seguros, partilhado só com quem autorizar.";
  const sentLine = `Enviado a ${sentAt} para ${input.recipientEmail}`;

  // ---- texto simples (mesma copy) ------------------------------------------
  const text = [
    title,
    "",
    intro,
    "",
    "Pedidos:",
    ...types.map((t) => `- ${t}`),
    "",
    `Escritório: ${officeLine}`,
    ...(message ? ["", `${messageLabel}:`, message] : []),
    "",
    `Ver os pedidos: ${input.url}`,
    "",
    security,
    "",
    "--",
    "ProDossier",
    tagline,
    sentLine,
  ].join("\n");

  // ---- HTML (esqueleto de supabase/templates/magic-link.html) ---------------
  const e = escapeHtml;
  const sans = "font-family:'Atkinson Hyperlegible Next', 'Segoe UI', Helvetica, Arial, sans-serif;";
  const serif = "font-family:'Source Serif 4', Georgia, 'Times New Roman', serif;";
  const mono = "font-family:'Atkinson Hyperlegible Mono', Consolas, 'Courier New', monospace;";
  const label = (s: string) =>
    `<tr><td style="padding:4px 0;${sans}font-size:14px;line-height:20px;font-weight:bold;color:#454A55;">${e(s)}</td></tr>`;
  const url = e(input.url);
  const messageHtml = message ? e(message).replace(/\r?\n/g, "<br>") : "";

  const html = `<!doctype html>
<html lang="pt-PT">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>${e(subject)}</title>
</head>
<body style="margin:0;padding:0;background-color:#F6F3EC;color:#1B1E24;${sans}font-size:17px;line-height:26px;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:#F6F3EC;">${e(preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#F6F3EC" style="background-color:#F6F3EC;">
<tr><td align="center" style="padding:24px 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;">
<tr><td bgcolor="#FDFCF9" style="background-color:#FDFCF9;border:1px solid #D8D1C1;border-radius:10px;padding:32px 24px;">
<h1 style="margin:0 0 16px 0;${serif}font-size:26px;line-height:32px;font-weight:bold;color:#1B1E24;">${e(title)}</h1>
<p style="margin:0 0 16px 0;${sans}font-size:17px;line-height:26px;color:#1B1E24;">${e(intro)}</p>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#F3E6C4" style="background-color:#F3E6C4;border-radius:6px;margin:0 0 24px 0;">
<tr><td style="padding:16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
${label("Pedidos")}
<tr><td style="padding:0 0 12px 0;${serif}font-size:21px;line-height:28px;font-weight:bold;color:#1B1E24;">${types.map(e).join("<br>")}</td></tr>
${label("Escritório")}
<tr><td style="padding:0 0 12px 0;${sans}font-size:17px;line-height:26px;color:#1B1E24;">${e(officeLine)}</td></tr>
${message ? `${label(messageLabel)}
<tr><td style="padding:0;${sans}font-size:17px;line-height:26px;color:#1B1E24;word-break:break-word;">${messageHtml}</td></tr>` : ""}
</table>
</td></tr></table>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin:8px 0 20px 0;">
<tr><td align="center" bgcolor="#1B1E24" style="background-color:#1B1E24;border-radius:6px;">
<a href="${url}" style="display:block;padding:16px 24px;${sans}font-size:17px;line-height:24px;font-weight:bold;color:#F6F3EC;text-decoration:none;">Ver os pedidos</a>
</td></tr></table>
<p style="margin:0 0 12px 0;${sans}font-size:15px;line-height:22px;color:#454A55;">${e(security)}</p>
<p style="margin:0 0 12px 0;${sans}font-size:15px;line-height:22px;color:#454A55;">${e(copyHint)}</p>
<p style="margin:0 0 24px 0;${mono}font-size:13px;line-height:18px;color:#454A55;word-break:break-all;"><a href="${url}" style="color:#454A55;text-decoration:underline;">${url}</a></p>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="border-top:1px solid #D8D1C1;">
<tr><td style="padding-top:16px;">
<p style="margin:0;${serif}font-size:19px;line-height:24px;color:#1B1E24;"><span style="font-style:italic;font-weight:normal;color:#454A55;">Pro</span><span style="font-weight:bold;color:#1B1E24;">Dossier</span></p>
<p style="margin:4px 0 0 0;${sans}font-size:15px;line-height:22px;color:#454A55;">${e(tagline)}</p>
<p style="margin:4px 0 0 0;${mono}font-size:13px;line-height:18px;color:#62666F;word-break:break-all;">${e(sentLine)}</p>
</td></tr></table>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>
`;

  return { subject, preheader, html, text };
}
