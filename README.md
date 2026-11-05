# CRM WhatsApp (kanban)

Quadro de vendas simples para quem vende pelo WhatsApp.
Colunas: **Chegou → Conversando → Orçamento enviado → Fechou / Perdeu**.

São só 3 arquivos estáticos (`index.html`, `config.js`, `schema.sql`), sem build e sem servidor próprio.

## Como colocar no ar (cerca de 10 minutos)

### 1. Criar o banco no Supabase
1. Crie uma conta em https://supabase.com e um projeto novo (o plano gratuito basta).
2. Abra **SQL Editor → New query**, cole o conteúdo de `schema.sql` e clique em **Run**.

### 2. Criar a senha de acesso
1. Vá em **Authentication → Users → Add user → Create new user**.
2. Use um e-mail qualquer (ex.: `loja@seunegocio.com`) e a senha que a equipe vai usar.
   Marque **Auto Confirm User**.
3. **Importante:** vá em **Authentication → Sign In / Providers** e **desligue "Allow new users to sign up"**.
   Assim ninguém consegue criar outra conta, e só quem sabe a senha entra.

### 3. Configurar o app
Abra **Project Settings → API** e copie a *Project URL* e a chave *anon public* para o `config.js`:

```js
window.CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi...",
  LOGIN_EMAIL: "loja@seunegocio.com",   // o mesmo e-mail do passo 2
  DDI_PADRAO: "55",
};
```

A chave *anon* pode ficar no navegador: os dados ficam protegidos pela regra de segurança (RLS),
que só libera o acesso para quem fez login.

### 4. Publicar
Qualquer hospedagem de site estático serve. A mais fácil é a **Netlify Drop**:
abra https://app.netlify.com/drop e arraste a pasta inteira. Também funciona com Vercel, GitHub Pages ou Cloudflare Pages.

No celular, abra o link e use **"Adicionar à tela inicial"** para ele virar um ícone, como se fosse um app.

## Uso
- **+** (botão verde) cria um contato em "Chegou"; o **+** no topo de cada coluna cria o contato direto nela.
- **Toque no card** para editar nome, telefone, valor, anotação ou mudar a etapa.
- **Arrastar:** no computador, clique e arraste. No celular, **segure o card meio segundo** e arraste.
  Para trocar de coluna no celular, também dá para tocar no card e escolher a etapa (é mais rápido).
- **Botão WhatsApp:** abre a conversa direto. Telefones sem DDI recebem +55 automaticamente.
- No topo: valor em negociação, vendas fechadas, taxa de conversão e ticket médio.
- **Busca** por nome, telefone ou anotação.
- Contatos em etapas abertas sem movimentação há 3 dias ou mais ganham o selo laranja **"parado X dias"** — sinal para chamar no WhatsApp.
- Se duas pessoas usam ao mesmo tempo, o quadro se atualiza sozinho.

## Trocar a senha
Supabase → **Authentication → Users** → clique no usuário → **Reset password** (ou crie outro usuário e troque o e-mail no `config.js`).
