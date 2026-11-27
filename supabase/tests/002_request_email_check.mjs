// QA 002: verificação do email do pedido (módulo puro supabase/functions/_shared/request_email.ts).
// Correr: node --experimental-strip-types supabase/tests/002_request_email_check.mjs
// (Node >= 22.6; sem rede, sem segredos). Termina com código 1 se algum caso falhar.
//
// Casos: escape de HTML em todos os campos vindos da base de dados, assunto numa só
// linha, mensagem com quebras de linha, mensagem nula/só espaços, 1 / 3 / 4 / 13 tipos,
// email sem lista de documentos nem notas, link escapado, emojis.
import { renderRequestEmail, escapeHtml } from "../functions/_shared/request_email.ts";

const results = [];
function check(id, desc, ok, got = "") {
  results.push(`${ok ? "PASS" : "FAIL"} | ${id} | ${desc}${ok ? "" : ` | obtido: ${got}`}`);
}

const base = {
  officeName: "Seguros Lda",
  mediatorName: "Ana",
  typeNames: ["Automóvel"],
  message: null,
  url: "https://app.exemplo.pt/pedidos",
  recipientEmail: "cliente@example.invalid",
  sentAt: new Date("2026-11-27T10:14:00Z"),
};

// M01 escape: escritório, mediador, tipo, mensagem e email com HTML
{
  const evil = `<img src=x onerror="alert('1')">&`;
  const e = renderRequestEmail({
    ...base,
    officeName: `Esc ${evil}`,
    mediatorName: `Med ${evil}`,
    typeNames: [`Tipo ${evil}`],
    message: `Msg ${evil}`,
    recipientEmail: `a${evil}@x.pt`,
  });
  const raw = /<img src=x/i.test(e.html) || /onerror="alert/.test(e.html);
  check("M01", "HTML de todos os campos escapado (sem <img> nem atributos injetados)", !raw,
    e.html.match(/.{0,40}<img.{0,40}/i)?.[0] ?? "");
  check("M01b", "escapeHtml cobre & < > \" '", escapeHtml(`&<>"'`) === "&amp;&lt;&gt;&quot;&#39;", escapeHtml(`&<>"'`));
}

// M02 assunto numa só linha (sem injeção de cabeçalhos)
{
  const e = renderRequestEmail({ ...base, officeName: "A\r\nBcc: x@y.pt", typeNames: ["Vida\nX"] });
  check("M02", "assunto sem CR/LF", !/[\r\n]/.test(e.subject), JSON.stringify(e.subject));
}

// M03 mensagem multilinha vira <br> e não traz texto cru
{
  const e = renderRequestEmail({ ...base, message: "Linha 1\nLinha 2 <b>" });
  check("M03", "mensagem com quebras: <br> e <b> escapado", e.html.includes("Linha 1<br>Linha 2 &lt;b&gt;"), "");
}

// M04 mensagem nula / só espaços: sem bloco de mensagem
{
  const a = renderRequestEmail({ ...base, message: null });
  const b = renderRequestEmail({ ...base, message: "   " });
  check("M04", "sem mensagem: sem rótulo 'Mensagem de'", !a.html.includes("Mensagem de") && !b.html.includes("Mensagem de") && !b.text.includes("Mensagem de"), "");
}

// M05 assunto por número de tipos
{
  const s = (types) => renderRequestEmail({ ...base, typeNames: types }).subject;
  const one = s(["Automóvel"]);
  const three = s(["Vida", "Saúde", "Pets"]);
  const four = s(["Vida", "Saúde", "Pets", "Obras"]);
  const thirteen = s(Array.from({ length: 13 }, (_, i) => `T${i + 1}`));
  check("M05", "assunto 1 / 3 / 4 / 13 tipos",
    one === "Seguros Lda pede-lhe elementos para Automóvel" &&
      three === "Seguros Lda pede-lhe elementos para Vida, Saúde e Pets" &&
      four === "Seguros Lda pede-lhe elementos para 4 seguros" &&
      thirteen === "Seguros Lda pede-lhe elementos para 13 seguros",
    [one, three, four, thirteen].join(" / "));
  const e13 = renderRequestEmail({ ...base, typeNames: Array.from({ length: 13 }, (_, i) => `T${i + 1}`) });
  check("M05b", "13 tipos listados no corpo (HTML e texto)",
    Array.from({ length: 13 }, (_, i) => `T${i + 1}`).every((t) => e13.html.includes(t) && e13.text.includes(`- ${t}`)), "");
}

// M06 o email não leva a lista de documentos nem notas (o input nem as tem) e diz-o
{
  const e = renderRequestEmail({ ...base, typeNames: ["Vida"] });
  check("M06", "aviso 'a lista ... não vai neste email' e sem palavras da lista",
    e.text.includes("a lista de documentos e dados não vai neste email") &&
      !/Cartão de Cidadão|exames|relatórios/i.test(e.html + e.text), "");
}

// M07 link escapado no href e emojis intactos
{
  const e = renderRequestEmail({ ...base, url: `https://app.pt/pedidos?a=1&b="x"`, message: "Olá 👋 👨‍👩‍👧" });
  check("M07", "href escapado e emojis preservados",
    e.html.includes(`href="https://app.pt/pedidos?a=1&amp;b=&quot;x&quot;"`) && e.html.includes("Olá 👋 👨‍👩‍👧"), "");
}

// M08 sem mediador (autor apagado): texto do escritório
{
  const e = renderRequestEmail({ ...base, mediatorName: "", message: "x" });
  check("M08", "sem autor: 'O escritório ...' e 'Mensagem do escritório'",
    e.text.includes("O escritório Seguros Lda criou") && e.text.includes("Mensagem do escritório:"), "");
}

const fails = results.filter((r) => r.startsWith("FAIL")).length;
console.log(`QA 002 email: ${results.length - fails} PASS, ${fails} FAIL\n${results.join("\n")}`);
process.exit(fails ? 1 : 0);
