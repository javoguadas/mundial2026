# 🌐 GUÍA DE DEPLOY — Mundial 2026

## Resumen
- **Base de datos**: Supabase (PostgreSQL gratuito)
- **Hosting**: GitHub Pages (gratuito)
- **Dominio**: `https://TU-USUARIO.github.io/mundial2026/`

---

## PASO 1 — Crear cuenta en Supabase

1. Ve a **https://supabase.com** → **Start your project** → crea cuenta con Google o email
2. Clic en **New Project**
3. Llena:
   - **Name**: `mundial2026`
   - **Database Password**: anota esta contraseña (la necesitarás)
   - **Region**: elige la más cercana (ej: US East o South America)
4. Espera ~2 minutos mientras Supabase crea el proyecto

---

## PASO 2 — Ejecutar el SQL de configuración

1. En tu proyecto Supabase, ve a **SQL Editor** (menú izquierdo)
2. Clic en **New Query**
3. Abre el archivo `supabase_setup.sql` de esta carpeta
4. Copia TODO el contenido y pégalo en el editor
5. Clic en **RUN** (botón verde)
6. Deberías ver: `Success. No rows returned`

---

## PASO 3 — Obtener tus credenciales

1. Ve a **Project Settings** → **API** (menú izquierdo)
2. Copia:
   - **Project URL** (ej: `https://abcdefgh.supabase.co`)
   - **anon public** key (la llave larga bajo "Project API keys")

---

## PASO 4 — Configurar las credenciales en el código

Abre el archivo `js/supabase.js` y reemplaza las líneas:

```javascript
const SUPABASE_URL = 'https://TU_PROJECT_ID.supabase.co';  // ← pega tu URL aquí
const SUPABASE_KEY = 'TU_ANON_PUBLIC_KEY';                  // ← pega tu key aquí
```

**Ejemplo real:**
```javascript
const SUPABASE_URL = 'https://xyzabcdef123.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## PASO 5 — Crear tu cuenta de Administrador

1. En Supabase → **Authentication** → **Users** → **Add user**
2. Llena:
   - Email: tu correo
   - Password: tu contraseña
   - Clic **Create user**
3. Copia el UUID del usuario creado (columna "UID")
4. Ve a **SQL Editor** → **New Query** → ejecuta:

```sql
-- Reemplaza 'TU-UUID-AQUI' con el UUID de tu usuario
UPDATE public.profiles
SET es_admin = true
WHERE id = '115c28d2-6b44-403d-81bc-8eb934cc8860';
```

---

## PASO 6 — Configurar Auth (opcional pero recomendado)

Para que tus compañeros no necesiten confirmar email:

1. Supabase → **Authentication** → **Settings**
2. Baja hasta **Email Auth**
3. Desactiva **"Confirm email"** (toggle off)
4. Guarda

---

## PASO 7 — Subir a GitHub

### Si no tienes Git instalado:
Descarga desde https://git-scm.com/downloads

### Pasos:

```bash
# 1. Crear cuenta en https://github.com si no tienes

# 2. En GitHub, clic en "+" → "New repository"
#    Nombre: mundial2026
#    Visibilidad: Public (necesario para GitHub Pages gratis)
#    NO marques "Initialize this repository"
#    Clic "Create repository"

# 3. Abre terminal/cmd en la carpeta de tu proyecto y ejecuta:
git init
git add .
git commit -m "Mundial 2026 - primera versión"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/mundial2026.git
git push -u origin main
```

---

## PASO 8 — Activar GitHub Pages

1. En tu repositorio de GitHub → **Settings** → **Pages** (menú izquierdo)
2. En **Source** selecciona **Deploy from a branch**
3. Branch: **main** / Folder: **/ (root)**
4. Clic **Save**
5. Espera 1-2 minutos
6. Tu URL será: `https://TU-USUARIO.github.io/mundial2026/`

---

## ✅ Verificación final

Abre la URL de GitHub Pages y comprueba:
- [ ] Página de inicio carga correctamente
- [ ] Puedes registrarte con tu email
- [ ] El admin puede entrar y ver el panel
- [ ] Los partidos aparecen en el calendario
- [ ] Las predicciones se guardan correctamente

---

## 🔄 Actualizar el sitio (cuando hagas cambios)

```bash
git add .
git commit -m "descripción del cambio"
git push
```
GitHub Pages se actualiza automáticamente en ~1 minuto.

---

## ❓ Problemas comunes

**"Error: invalid API key"**
→ Revisa que pegaste correctamente la `anon public` key en `supabase.js`

**"Failed to fetch"**
→ Verifica que la URL de Supabase no tiene `/` al final

**Los usuarios no pueden entrar después de registrarse**
→ Desactiva "Confirm email" en Supabase Auth Settings (Paso 6)

**"permission denied for table partidos"**
→ El SQL del Paso 2 no se ejecutó correctamente. Vuelve a ejecutarlo.

---

## 📱 Estructura del proyecto

```
mundial2026/
  index.html              ← Página de inicio
  css/
    styles.css            ← Estilos
  js/
    supabase.js           ← ⚠️ AQUÍ van tus credenciales + todas las operaciones de BD
    app.js                ← Lógica del juego (predicciones, clasificación)
    auth-ui.js            ← Helpers de navegación
  pages/
    login.html            ← Inicio de sesión / Registro
    calendario.html       ← Todos los partidos
    grupos.html           ← Tablas de clasificación
    brackets.html         ← Bracket eliminatorio
    quiniela.html         ← Predicciones de usuarios
    lideres.html          ← Ranking de puntos
    predicciones.html     ← Análisis estadístico
    admin.html            ← Panel de administrador
  supabase_setup.sql      ← Script SQL (solo se usa una vez)
  README.md               ← Esta guía
```
