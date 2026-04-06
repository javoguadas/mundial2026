-- ============================================================
--  MUNDIAL 2026 — Script SQL para Supabase
--  Copia y pega este script completo en:
--  Supabase Dashboard → SQL Editor → New Query → RUN
-- ============================================================

-- ── 1. TABLA: profiles (datos públicos de usuarios) ────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nombre      text not null,
  username    text not null unique,
  email       text,
  es_admin    boolean default false,
  created_at  timestamptz default now()
);

-- ── 2. TABLA: partidos ─────────────────────────────────────
create table if not exists public.partidos (
  id                  int primary key,
  num                 int not null,
  grupo               text,         -- 'A'-'L' para fase de grupos, null para eliminatoria
  fase                text,         -- '16avos','Octavos','Cuartos','Semifinales','3er Lugar','Final'
  local               text not null,
  visitante           text not null,
  fecha               text not null,
  hora                text not null,
  estado              text default 'pendiente', -- 'pendiente','en vivo','finalizado'
  goles_local         int,
  goles_visitante     int,
  tiene_penales       boolean default false,
  penales_local       int,
  penales_visitante   int,
  puede_ir_a_penales  boolean default false,
  tarj_am             int default 0,
  tarj_rj             int default 0,
  offsides            int default 0,
  created_at          timestamptz default now()
);

-- ── 3. TABLA: equipos_stats ────────────────────────────────
create table if not exists public.equipos_stats (
  equipo    text primary key,
  goles     numeric(4,2) default 1.2,
  tarjetas  numeric(4,2) default 1.5,
  offsides  numeric(4,2) default 1.4,
  ranking   int          default 50
);

-- ── 4. TABLA: predicciones ─────────────────────────────────
create table if not exists public.predicciones (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  partido_id      int  not null references public.partidos(id),
  goles_local     int,
  goles_visitante int,
  created_at      timestamptz default now(),
  unique(user_id, partido_id)
);

-- ── 5. ROW LEVEL SECURITY ──────────────────────────────────

-- profiles: todos pueden leer, solo dueño puede editar
alter table public.profiles enable row level security;

create policy "Perfiles visibles para todos" on public.profiles
  for select using (true);

create policy "Usuario edita su propio perfil" on public.profiles
  for update using (auth.uid() = id);

create policy "Insertar propio perfil" on public.profiles
  for insert with check (auth.uid() = id);

-- Solo admin puede borrar profiles
create policy "Admin borra profiles" on public.profiles
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and es_admin = true)
  );

-- partidos: todos pueden leer, solo admin puede escribir
alter table public.partidos enable row level security;

create policy "Partidos visibles para todos" on public.partidos
  for select using (true);

create policy "Admin actualiza partidos" on public.partidos
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and es_admin = true)
  );

-- equipos_stats: todos pueden leer, solo admin puede escribir
alter table public.equipos_stats enable row level security;

create policy "Stats visibles para todos" on public.equipos_stats
  for select using (true);

create policy "Admin modifica stats" on public.equipos_stats
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and es_admin = true)
  );

-- predicciones: usuario solo ve y edita las suyas
alter table public.predicciones enable row level security;

create policy "Usuario ve sus predicciones" on public.predicciones
  for select using (auth.uid() = user_id);

create policy "Admin ve todas las predicciones" on public.predicciones
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and es_admin = true)
  );

create policy "Usuario guarda sus predicciones" on public.predicciones
  for insert with check (auth.uid() = user_id);

create policy "Usuario actualiza sus predicciones" on public.predicciones
  for update using (auth.uid() = user_id);

create policy "Usuario borra sus predicciones" on public.predicciones
  for delete using (auth.uid() = user_id);

-- ── 6. TRIGGER: crear profile al registrarse ───────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nombre, username, email, es_admin)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombre', 'Usuario'),
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    null,   -- no guardamos el email falso interno
    false
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 7. POBLAR PARTIDOS (los 104 partidos oficiales) ────────
-- Grupos (1-72)
insert into public.partidos (id,num,grupo,local,visitante,fecha,hora,puede_ir_a_penales) values
(1,1,'A','México','Sudáfrica','Jue 11 Jun','13:00',false),
(2,2,'A','Corea del Sur','Chequia','Jue 11 Jun','20:00',false),
(7,7,'B','Canadá','Bosnia y Herzegovina','Vie 12 Jun','13:00',false),
(19,19,'D','EEUU','Paraguay','Vie 12 Jun','19:00',false),
(8,8,'B','Catar','Suiza','Sáb 13 Jun','13:00',false),
(13,13,'C','Brasil','Marruecos','Sáb 13 Jun','16:00',false),
(14,14,'C','Haití','Escocia','Sáb 13 Jun','19:00',false),
(20,20,'D','Australia','Turqia','Sáb 13 Jun','22:00',false),
(25,25,'E','Alemania','Curasao','Dom 14 Jun','11:00',false),
(31,31,'F','Paises Bajos','Japón','Dom 14 Jun','14:00',false),
(26,26,'E','Costa de Marfil','Ecuador','Dom 14 Jun','17:00',false),
(32,32,'F','Suecia','Túnez','Dom 14 Jun','20:00',false),
(43,43,'H','España','Cabo Verde','Lun 15 Jun','10:00',false),
(37,37,'G','Bélgica','Egipto','Lun 15 Jun','13:00',false),
(44,44,'H','Arabia Saudí','Uruguay','Lun 15 Jun','16:00',false),
(38,38,'G','Irán','Nueva Zelanda','Lun 15 Jun','19:00',false),
(49,49,'I','Francia','Senegal','Mar 16 Jun','13:00',false),
(50,50,'I','Irak','Noruega','Mar 16 Jun','16:00',false),
(55,55,'J','Argentina','Argelia','Mar 16 Jun','19:00',false),
(56,56,'J','Austria','Jordania','Mar 16 Jun','22:00',false),
(61,61,'K','Portugal','RD Congo','Mié 17 Jun','11:00',false),
(67,67,'L','Inglaterra','Croacia','Mié 17 Jun','14:00',false),
(68,68,'L','Ghana','Panamá','Mié 17 Jun','17:00',false),
(62,62,'K','Uzbekistán','Colombia','Mié 17 Jun','20:00',false),
(3,3,'A','Chequia','Sudáfrica','Jue 18 Jun','10:00',false),
(9,9,'B','Suiza','Bosnia y Herzegovina','Jue 18 Jun','13:00',false),
(10,10,'B','Canadá','Catar','Jue 18 Jun','16:00',false),
(4,4,'A','México','Corea del Sur','Jue 18 Jun','19:00',false),
(21,21,'D','EEUU','Australia','Vie 19 Jun','13:00',false),
(15,15,'C','Escocia','Marruecos','Vie 19 Jun','16:00',false),
(16,16,'C','Brasil','Haití','Vie 19 Jun','19:00',false),
(22,22,'D','Turquía','Paraguay','Vie 19 Jun','22:00',false),
(33,33,'F','Paises Bajos','Suecia','Sáb 20 Jun','11:00',false),
(27,27,'E','Alemania','Costa de Marfil','Sáb 20 Jun','14:00',false),
(28,28,'E','Ecuador','Curasao','Sáb 20 Jun','18:00',false),
(34,34,'F','Túnez','Japón','Sáb 20 Jun','22:00',false),
(45,45,'H','España','Arabia Saudí','Dom 21 Jun','10:00',false),
(39,39,'G','Bélgica','Irán','Dom 21 Jun','13:00',false),
(46,46,'H','Uruguay','Cabo Verde','Dom 21 Jun','16:00',false),
(40,40,'G','Nueva Zelanda','Egipto','Dom 21 Jun','19:00',false),
(57,57,'J','Argentina','Austria','Lun 22 Jun','11:00',false),
(51,51,'I','Francia','Irak','Lun 22 Jun','15:00',false),
(52,52,'I','Noruega','Senegal','Lun 22 Jun','18:00',false),
(58,58,'J','Jordania','Argelia','Lun 22 Jun','21:00',false),
(63,63,'K','Portugal','Uzbekistán','Mar 23 Jun','11:00',false),
(69,69,'L','Inglaterra','Ghana','Mar 23 Jun','14:00',false),
(70,70,'L','Panamá','Croacia','Mar 23 Jun','17:00',false),
(64,64,'K','Colombia','Irak','Mar 23 Jun','20:00',false),
(11,11,'B','Suiza','Canadá','Mié 24 Jun','13:00',false),
(12,12,'B','Bosnia y Herzegovina','Catar','Mié 24 Jun','13:00',false),
(17,17,'C','Escocia','Brasil','Mié 24 Jun','16:00',false),
(18,18,'C','Marruecos','Haití','Mié 24 Jun','16:00',false),
(5,5,'A','Chequia','México','Mié 24 Jun','19:00',false),
(6,6,'A','Sudáfrica','Corea del Sur','Mié 24 Jun','19:00',false),
(29,29,'E','Curasao','Costa de Marfil','Jue 25 Jun','14:00',false),
(30,30,'E','Ecuador','Alemania','Jue 25 Jun','14:00',false),
(35,35,'F','Japón','Suecia','Jue 25 Jun','17:00',false),
(36,36,'F','Túnez','Paises Bajos','Jue 25 Jun','17:00',false),
(23,23,'D','Turquía','EEUU','Jue 25 Jun','20:00',false),
(24,24,'D','Paraguay','Australia','Jue 25 Jun','20:00',false),
(53,53,'I','Noruega','Francia','Vie 26 Jun','13:00',false),
(54,54,'I','Senegal','Irak','Vie 26 Jun','13:00',false),
(47,47,'H','Uruguay','España','Vie 26 Jun','18:00',false),
(48,48,'H','Cabo Verde','Arabia Saudí','Vie 26 Jun','18:00',false),
(41,41,'G','Egipto','Irán','Vie 26 Jun','21:00',false),
(42,42,'G','Nueva Zelanda','Bélgica','Vie 26 Jun','21:00',false),
(71,71,'L','Panamá','Inglaterra','Sáb 27 Jun','15:00',false),
(72,72,'L','Croacia','Ghana','Sáb 27 Jun','15:00',false),
(65,65,'K','RD Congo','Uzbekistán','Sáb 27 Jun','17:30',false),
(66,66,'K','Colombia','Portugal','Sáb 27 Jun','17:30',false),
(59,59,'J','Jordania','Argentina','Sáb 27 Jun','20:00',false),
(60,60,'J','Argelia','Austria','Sáb 27 Jun','20:00',false),
-- Eliminatoria (73-104)
(73,73,null,'2A','2B','Dom 28 Jun','13:00',true),
(74,74,null,'1E','3A/B/C/D/F','Lun 29 Jun','14:30',true),
(75,75,null,'1F','2C','Lun 29 Jun','19:00',true),
(76,76,null,'1C','2F','Lun 29 Jun','11:00',true),
(77,77,null,'1I','3C/D/F/G/H','Mar 30 Jun','15:00',true),
(78,78,null,'2E','2I','Mar 30 Jun','11:00',true),
(79,79,null,'1A','3C/E/F/H/I','Mar 30 Jun','19:00',true),
(80,80,null,'1L','3E/H/I/J/K','Mié 1 Jul','10:00',true),
(81,81,null,'1D','3B/E/F/I/J','Mié 1 Jul','18:00',true),
(82,82,null,'1G','3A/E/H/I/J','Mié 1 Jul','14:00',true),
(83,83,null,'2K','2L','Jue 2 Jul','13:00',true),
(84,84,null,'1H','2J','Jue 2 Jul','17:00',true),
(85,85,null,'1B','3E/F/G/I/J','Jue 2 Jul','21:00',true),
(86,86,null,'1J','2H','Vie 3 Jul','16:00',true),
(87,87,null,'1K','3D/E/I/J/L','Vie 3 Jul','19:30',true),
(88,88,null,'2D','2G','Vie 3 Jul','12:00',true),
(89,89,null,'W74','W77','Sáb 4 Jul','11:00',true),
(90,90,null,'W73','W75','Sáb 4 Jul','15:00',true),
(91,91,null,'W76','W78','Dom 5 Jul','14:00',true),
(92,92,null,'W79','W80','Dom 5 Jul','18:00',true),
(93,93,null,'W83','W84','Lun 6 Jul','13:00',true),
(94,94,null,'W81','W82','Lun 6 Jul','18:00',true),
(95,95,null,'W86','W88','Mar 7 Jul','10:00',true),
(96,96,null,'W85','W87','Mar 7 Jul','14:00',true),
(97,97,null,'W89','W90','Jue 9 Jul','14:00',true),
(98,98,null,'W93','W94','Vie 10 Jul','13:00',true),
(99,99,null,'W91','W92','Sáb 11 Jul','15:00',true),
(100,100,null,'W95','W96','Sáb 11 Jul','19:00',true),
(101,101,null,'W97','W98','Mar 14 Jul','13:00',true),
(102,102,null,'W99','W100','Mié 15 Jul','13:00',true),
(103,103,null,'L101','L102','Sáb 18 Jul','15:00',true),
(104,104,null,'W101','W102','Dom 19 Jul','13:00',true)
on conflict (id) do nothing;

-- Marcar fase de los partidos eliminatorios
update public.partidos set fase='16avos'    where id between 73 and 88;
update public.partidos set fase='Octavos'   where id between 89 and 96;
update public.partidos set fase='Cuartos'   where id between 97 and 100;
update public.partidos set fase='Semifinales' where id in (101,102);
update public.partidos set fase='3er Lugar' where id=103;
update public.partidos set fase='Final'     where id=104;

-- ── 8. POBLAR ESTADÍSTICAS INICIALES ─────────────────────
insert into public.equipos_stats (equipo,goles,tarjetas,offsides,ranking) values
('España',2.3,1.2,1.7,1),('Argentina',2.2,1.5,1.6,2),('Francia',2.0,1.4,1.5,3),
('Inglaterra',1.9,1.4,1.7,4),('Brasil',2.1,1.3,1.2,5),('Portugal',2.2,1.5,1.7,6),
('Paises Bajos',1.9,1.4,1.7,7),('Marruecos',1.5,1.7,1.3,8),('Bélgica',1.8,1.4,1.5,9),
('Alemania',2.0,1.4,1.8,10),('Croacia',1.6,1.4,1.5,11),('Senegal',1.8,1.5,1.4,12),
('Colombia',1.7,1.6,1.5,14),('EEUU',1.8,1.5,1.6,15),('México',1.8,1.8,2.1,16),
('Uruguay',1.7,1.5,1.3,17),('Suiza',1.7,1.3,1.4,18),('Japón',1.6,1.2,1.5,19),
('Irán',1.3,1.9,1.3,20),('Corea del Sur',1.6,1.5,1.8,22),
('Ecuador',1.4,1.6,1.5,23),('Austria',1.7,1.5,1.6,24),
('Australia',1.3,1.5,1.4,27),('Argelia',1.4,1.8,1.4,28),
('Canadá',1.5,1.4,1.6,29),('Egipto',1.4,1.7,1.4,31),
('Noruega',1.8,1.3,1.9,32),('Panamá',1.2,1.9,1.2,33),
('Costa de Marfil',1.5,1.7,1.4,37),('Escocia',1.4,1.6,1.7,38),
('Paraguay',1.2,1.9,1.3,40),('Túnez',1.2,1.8,1.3,47),
('Uzbekistán',1.1,1.7,1.3,52),('Catar',1.1,1.8,1.2,56),
('Sudáfrica',1.2,1.9,1.5,60),('Arabia Saudí',1.3,1.8,1.4,61),
('Jordania',1.0,1.8,1.1,64),('Cabo Verde',1.1,1.9,1.2,67),
('Ghana',1.2,1.8,1.3,72),('Curasao',0.9,2.0,1.0,81),
('Haití',0.8,2.1,1.1,83),('Nueva Zelanda',1.1,1.5,1.2,85),
('Bosnia y Herzegovina',1.5,1.5,1.5,35),('Suecia',1.4,1.6,1.4,43),
('Turquía',1.4,1.6,1.4,46),('Chequia',1.3,1.6,1.3,50),
('RD Congo',1.3,1.7,1.3,55),('Irak',1.2,1.7,1.2,58)
on conflict (equipo) do nothing;

-- ── LISTO ─────────────────────────────────────────────────
-- ⚠️  CONFIGURACIÓN OBLIGATORIA EN SUPABASE (sin esto no funciona el login):
-- 1. Authentication → Settings → Email Auth
--    - Desactiva "Confirm email" (toggle OFF) — los usuarios no tienen correo real
--    - Desactiva "Secure email change" (toggle OFF)
-- 2. Authentication → Settings → Email Auth → "Enable email provider" debe estar ON
--    (aunque no se muestre el email al usuario, Supabase lo necesita internamente)
