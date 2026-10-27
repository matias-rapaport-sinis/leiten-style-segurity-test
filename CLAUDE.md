# Contexto para Claude — prueba de concepto de estilos separados

Repo personal **de prueba**: valida que Marketing pueda cambiar estilos sin tocar marcado,
lógica, datos, workflows ni deploys. Los controles están en GitHub (ver `README.md`); este
archivo solo orienta y no protege nada. `deploy-testing` es un deploy de mentira para el red
team: nunca imprimir `SECRETO_PRUEBA` ni agregar pasos que lo expongan.

Compilar: `dotnet build Ejemplo.sln` (.NET 9). Probar el control de rutas:
`bash scripts/verificar-estilos.sh testing testing write`.

## Cómo está organizado

Cada pantalla tiene tres archivos, y cada uno tiene un dueño:

| Archivo | Contiene | Dueño |
|---|---|---|
| `Pagina.razor` | Marcado y nombres de clase. **Nunca estilos.** | Desarrollo |
| `Pagina.razor.cs` | Lógica: datos, filtros, cálculos, llamadas al backend | Desarrollo |
| `Pagina.razor.css` | Estilos de esa pantalla (CSS aislado de Blazor) | Marketing |
| `wwwroot/css/tema.css` | Variables globales: colores, tipografía, radios, sombras | Marketing |
| `wwwroot/css/base.css` | Estilos globales (body, títulos, enlaces) | Marketing |
| `wwwroot/img/`, `wwwroot/fonts/` | Imágenes y tipografías | Marketing |

Las rutas de Marketing están en `.github/rutas-marketing.txt`.

## Reglas para Desarrollo

- **Nada de estilos en los `.razor`**: ni `<style>` ni `style="color: ..."`. Siempre clases.
  Para un valor dinámico, pasarlo como variable CSS: `style="--avance: @(x)%"`, y que el
  `.razor.css` decida cómo usarlo. El CI (`control-estilos`) rechaza el PR si no.
- Los nombres de clase son el contrato con Marketing: si se renombra o se borra una, actualizar
  el `.razor.css` en el mismo PR.
- Un componente hijo (ej. `NavLink`) no recibe el CSS aislado del padre: usar `::deep`.

## Reglas para Marketing (colaborador con rol Write en GitHub)

Los permisos los impone GitHub (push ruleset, CODEOWNERS, CI `control-estilos` y `build`,
rulesets de ramas y el environment `testing`); este archivo solo orienta.

- Solo editar CSS, imágenes y tipografías (rutas de `.github/rutas-marketing.txt`). GitHub
  rechaza el push de `.razor`, `.cs`, workflows y demás archivos de Desarrollo, y el CI falla
  si se escapa alguno.
- Usar las variables de `tema.css` en vez de colores sueltos; si falta una variable, agregarla ahí.
- Trabajar en una rama propia creada desde `testing` (ej. `marketing/<descripción>`) y abrir PR
  a `testing`. Nunca a `main`.
- Si el cambio necesita una clase nueva, cambiar textos o tocar lógica: **no intentarlo**.
  Redactar el pedido para Desarrollo (página, qué se quiere lograr y el nombre de clase sugerido).
