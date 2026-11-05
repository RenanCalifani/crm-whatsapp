-- Integração WhatsApp (n8n) -> CRM
-- Rode DEPOIS do schema.sql. Supabase: SQL Editor > New query > cole tudo > Run
-- Pode rodar mais de uma vez sem problema.

-- 1) Novas colunas
alter table public.leads add column if not exists ultima_mensagem  text not null default '';
alter table public.leads add column if not exists ultima_interacao timestamptz;
alter table public.leads add column if not exists origem           text not null default 'manual';

-- 2) "Chave" do telefone: deixa iguais os formatos (11) 98765-4321, 5511987654321
--    e 551187654321 (a Meta às vezes manda número brasileiro sem o 9).
create or replace function public.chave_telefone(t text)
returns text language plpgsql immutable as $$
declare d text := ltrim(regexp_replace(coalesce(t, ''), '\D', '', 'g'), '0');
begin
  if d = '' then return ''; end if;
  if length(d) <= 11 then d := '55' || d; end if;               -- sem DDI: Brasil
  if length(d) = 13 and left(d, 2) = '55' and substr(d, 5, 1) = '9' then
    d := left(d, 4) || substr(d, 6);                             -- tira o 9 do celular
  end if;
  return d;
end $$;

alter table public.leads add column if not exists telefone_chave text
  generated always as (public.chave_telefone(telefone)) stored;
create index if not exists leads_telefone_chave on public.leads (telefone_chave);

-- 3) Função chamada pelo n8n a cada mensagem recebida
--    - número novo .......................... cria card em "Chegou"
--    - já existe em etapa aberta ............ atualiza a última mensagem e sobe o card para o topo
--    - estava em Fechou/Perdeu há +7 dias ... cria um card novo (nova oportunidade)
create or replace function public.registrar_mensagem(
  p_telefone text,
  p_nome     text default '',
  p_mensagem text default ''
)
returns public.leads
language plpgsql security definer set search_path = public as $$
declare
  k text := public.chave_telefone(p_telefone);
  l public.leads;
  topo double precision;
begin
  if k = '' then raise exception 'telefone vazio'; end if;

  select * into l from leads
   where telefone_chave = k
   order by (status in ('fechou', 'perdeu')), coalesce(ultima_interacao, updated_at) desc
   limit 1;

  if l.id is null
     or (l.status in ('fechou', 'perdeu')
         and coalesce(l.ultima_interacao, l.updated_at) < now() - interval '7 days') then
    select coalesce(min(posicao), 1) - 1 into topo from leads where status = 'chegou';
    insert into leads (nome, telefone, status, posicao, origem, ultima_mensagem, ultima_interacao, anotacao)
    values (
      coalesce(nullif(trim(p_nome), ''), 'Cliente WhatsApp'),
      regexp_replace(p_telefone, '\D', '', 'g'),
      'chegou', topo, 'whatsapp', coalesce(p_mensagem, ''), now(),
      case when l.id is not null then 'Cliente voltou a chamar' else '' end
    )
    returning * into l;
  else
    if l.status not in ('fechou', 'perdeu') then
      select coalesce(min(posicao), 1) - 1 into topo from leads where status = l.status;
    else
      topo := l.posicao;
    end if;
    update leads
       set ultima_mensagem = coalesce(p_mensagem, ''),
           ultima_interacao = now(),
           posicao = topo
     where id = l.id
    returning * into l;
  end if;

  return l;
end $$;

-- Só o n8n (chave secreta / service_role) pode chamar essa função
revoke execute on function public.registrar_mensagem(text, text, text) from public, anon, authenticated;
grant  execute on function public.registrar_mensagem(text, text, text) to service_role;
