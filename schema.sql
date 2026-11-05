-- CRM WhatsApp — estrutura do banco
-- Cole tudo isto no Supabase: SQL Editor > New query > Run

create table if not exists public.leads (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  telefone    text not null default '',
  valor       numeric(12,2) not null default 0,
  anotacao    text not null default '',
  status      text not null default 'chegou'
              check (status in ('chegou','conversando','orcamento','fechou','perdeu')),
  posicao     double precision not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists leads_status_posicao on public.leads (status, posicao);

-- Atualiza updated_at automaticamente
create or replace function public.leads_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists leads_updated_at on public.leads;
create trigger leads_updated_at
  before update on public.leads
  for each row execute function public.leads_set_updated_at();

-- Segurança: só quem fez login acessa os dados
alter table public.leads enable row level security;

drop policy if exists "logado pode tudo" on public.leads;
create policy "logado pode tudo" on public.leads
  for all to authenticated
  using (true) with check (true);

-- Tempo real: quando alguém mexe num celular, os outros atualizam sozinhos
do $$
begin
  alter publication supabase_realtime add table public.leads;
exception when duplicate_object then null;
end $$;
