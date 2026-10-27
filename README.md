# Prueba de concepto: Marketing cambia estilos sin poder tocar la lógica

Repo **de prueba** (personal, no de la organización) para validar cómo darle a **Marketing**
permiso para cambiar el aspecto de una app Blazor (CSS, imágenes, tipografías) sin que pueda
modificar marcado, lógica, datos, workflows ni deploys.

Todos los controles están del lado de GitHub. **No** se usan hooks de Claude ni variables de
rol: se descartaron porque quien usa Claude los puede cambiar. Lo que se configure en Claude
(incluido `CLAUDE.md`) solo orienta; no protege nada.

Sale de `ejemplos/estilos-separados/` y `docs/permisos-marketing.md` del repo
`grupoLeiten/leiten-oportunidades-blazor` (rama `claude/jolly-galileo-we03zz`), adaptado a un
repo personal y con un deploy de mentira para que el red team intente romperlo.

## 1. Archivos separados por dueño

```
Ejemplo.sln
src/Ejemplo.Web/                      (Blazor Server, .NET 9)
├── Components/
│   ├── Pages/
│   │   ├── Oportunidades.razor       ← marcado + clases            (Desarrollo)
│   │   ├── Oportunidades.razor.cs    ← lógica y datos              (Desarrollo)
│   │   └── Oportunidades.razor.css   ← estilos de la pantalla      (Marketing)
│   ├── Shared/TarjetaKpi.razor(.css)
│   └── Layout/MainLayout.razor(.css)
├── Datos/                            ← modelos y servicio de datos (Desarrollo)
└── wwwroot/
    ├── css/tema.css                  ← colores, tipografía, medidas (Marketing)
    ├── css/base.css                  ← estilos globales             (Marketing)
    └── img/  fonts/                                                 (Marketing)
```

- Los `.razor` no tienen estilos: solo clases. La única excepción es pasar un valor dinámico
  como variable CSS (`style="--avance: 70%"`); el `.razor.css` decide cómo se dibuja.
- Los `.razor.css` son **CSS aislado** de Blazor: solo afectan a su componente.
- `tema.css` concentra los colores: cambiar `--color-marca` cambia toda la app.

Correr local: `dotnet watch --project src/Ejemplo.Web` (o `dotnet build Ejemplo.sln`).

## 2. Controles (todos en GitHub)

| Capa | Archivo | Qué garantiza |
|---|---|---|
| **Rol** | Settings → Collaborators | Marketing es colaborador (rol **write**). Desarrollo es el dueño (**admin**). Solo admin cambia settings, rulesets, environments y secrets. |
| **Push ruleset** | `configuracion-github/ruleset-push-marketing.json` | Rechaza, en **cualquier rama**, pushes que toquen `.razor`, `.cs`, `.json`, `.js`, `.yml`, `.sh`, `.sln`, `.github/**`, `scripts/**`, `CLAUDE.md`, etc. Así Marketing no puede agregar un workflow propio. Bypass: solo admin. |
| **Ruleset de ramas** | `configuracion-github/ruleset-ramas.json` | `main`/`testing` solo por PR, 1 aprobación de Code Owner (no del autor), checks **`control-estilos`** y **`build`** en verde, sin force-push ni borrado. Bypass: solo admin. |
| **CODEOWNERS** | `.github/CODEOWNERS` | Todo lo que no sea estilos lo aprueba Desarrollo. |
| **CI `control-estilos`** | `.github/workflows/control-estilos.yml` + `scripts/verificar-estilos.sh` | Si el autor del PR no es admin/maintain (rol leído de la API, no del nombre de la rama): solo rutas de `.github/rutas-marketing.txt` y solo hacia `testing`. Para todos: rechaza estilos nuevos dentro de `.razor`. |
| **CI `build`** | `.github/workflows/build.yml` | `dotnet build` en cada PR y en cada push a `main`/`testing`. |
| **Environment `testing`** | Settings → Environments | Solo acepta la rama `testing`. Tiene el secret de mentira `SECRETO_PRUEBA`. |
| **Deploy de mentira** | `.github/workflows/deploy-testing.yml` | Push a `testing` o *Run workflow*. Usa el environment y muestra solo si el secret llegó y su longitud. Es el blanco del red team. |
| **Workflow permissions** | Settings → Actions | `GITHUB_TOKEN` read-only por defecto. |

`.github/rutas-marketing.txt` es la lista única de rutas de Marketing (la lee el CI); si se
cambia, actualizar también `CODEOWNERS` y, si hace falta, el push ruleset.

**Cómo detecta el CI a Marketing:** `gh api repos/<repo>/collaborators/<autor>/permission
--jq .role_name`. En un repo personal el dueño devuelve `admin` y los colaboradores `write`
(no existen otros roles); si la API falla, el rol queda `desconocido` y se trata como Marketing.

### Cómo queda cada caso

| Quién | Qué hace | Resultado esperado |
|---|---|---|
| Marketing | PR a `testing` que solo toca `*.css`, `img/`, `fonts/` | `control-estilos` y `build` en verde; 1 aprobación de Code Owner → merge |
| Marketing | Push de un `.razor`, `.cs` o workflow a su rama | Rechazado por el push ruleset (`GH013`) |
| Marketing | PR que toca algo fuera de sus rutas (si el push pasó) | `control-estilos` falla; merge bloqueado |
| Marketing | PR a `main` | `control-estilos` falla |
| Marketing | Push directo a `main`/`testing` | Rechazado por el ruleset de ramas |
| Marketing | *Run workflow* de `deploy-testing` desde su rama | Rechazado por el environment (rama no permitida); el secret no se entrega |
| Desarrollo | `style="color:red"` en un `.razor` | `control-estilos` falla (`ESTILOS_ESTRICTO=0` lo baja a aviso) |
| Desarrollo | Push directo a `testing` | Permitido (bypass de admin) |

## 3. Configuración en este repo personal

1. `main` con este contenido y la rama `testing` creada desde `main` (ya están).
2. Con `gh` logueado como dueño (o `GH_TOKEN` de un token admin del repo):
   ```bash
   bash configuracion-github/configurar-repo.sh matias-rapaport-sinis/leiten-style-segurity-test [usuario-marketing]
   ```
   Crea/actualiza los dos rulesets (por nombre), el environment `testing` restringido a la rama
   `testing`, el secret `SECRETO_PRUEBA` (valor al azar, no se imprime), activa
   `delete_branch_on_merge`, deja los workflow permissions en read-only y, si se pasa un
   usuario, lo invita como colaborador con permiso `push`. Es idempotente.
3. Agregar el usuario de Marketing en las líneas de estilos de `.github/CODEOWNERS`.

**Disponibilidad según el plan:** en repos personales, los rulesets y environments con reglas
de rama funcionan en repos **públicos** (cualquier plan) y en privados con **GitHub Pro**. El
**push ruleset** es otra historia: GitHub lo documenta para repos **privados o internos** de
planes pagos, así que en un repo personal (y en uno público) puede no estar disponible. El
script avisa y sigue; el resultado real queda en la tabla de estado de la configuración. Sin push ruleset, Marketing puede pushear cualquier archivo **a su
propia rama** (no a `main`/`testing`): `control-estilos`, CODEOWNERS y el environment siguen
frenando el merge y el secret; eso es justamente lo que tiene que probar el red team.

## 4. Cómo sería en una organización

- **Equipos** en vez de usuarios: `desarrollo` (rol **Maintain**) y `marketing` (rol **Write**),
  y `CODEOWNERS` con `@org/desarrollo` / `@org/marketing`.
- **Bypass** de los rulesets: admin (`RepositoryRole` 5) **y** maintain (`RepositoryRole` 2).
- **Push ruleset** disponible en repos privados con plan Team o superior.
- Org → Member privileges → destildar *Allow forking of private repositories*.
- Environments también para `production` (rama `main`); *required reviewers* en repos privados
  solo con Enterprise.
- El script original para organizaciones (crea equipos y les da permisos) está en
  `ejemplos/estilos-separados/configuracion-github/configurar-repo.sh` del repo de origen, y el
  paso a paso en `docs/permisos-marketing.md`.

## 5. Flujo de Marketing

```
git switch testing && git pull
git switch -c marketing/colores-kpi
(editar .css directo o pedírselo a Claude)
dotnet watch --project src/Ejemplo.Web     ← previsualizar
git commit -am "KPI destacado con color de marca"
git push -u origin marketing/colores-kpi
→ PR a testing → aprueba un Code Owner (no el autor) → merge → deploy-testing
```

## 6. Qué no cubre

- **CSS es poderoso:** con `display: none` o `content:` se puede ocultar o agregar texto
  visual. No modifica datos, pero conviene que Desarrollo revise PRs que oculten elementos.
- **Leer el código:** cualquiera con acceso puede clonar y leer todo (este repo además es
  público). Los secretos viven en GitHub, no en el repo.
- **Datos del ERP:** Marketing no recibe credenciales del ERP ni de Azure.
