using System.Globalization;
using Ejemplo.Web.Datos;
using Microsoft.AspNetCore.Components;

namespace Ejemplo.Web.Components.Pages;

// Lógica de la página (datos, filtros, cálculos). La mantiene Desarrollo.
public partial class Oportunidades
{
    private static readonly CultureInfo Moneda = CultureInfo.GetCultureInfo("es-AR");

    [Inject] private OportunidadesService Servicio { get; set; } = default!;

    private IReadOnlyList<Oportunidad> todas = [];

    private string Busqueda { get; set; } = "";

    private IEnumerable<Oportunidad> Filtradas =>
        string.IsNullOrWhiteSpace(Busqueda)
            ? todas
            : todas.Where(o => o.Cliente.Contains(Busqueda, StringComparison.OrdinalIgnoreCase)
                            || o.Obra.Contains(Busqueda, StringComparison.OrdinalIgnoreCase));

    private int Abiertas => todas.Count(o => o.Etapa != Etapa.Ganada);

    private decimal MontoTotal => todas.Sum(o => o.Monto);

    protected override async Task OnInitializedAsync() =>
        todas = await Servicio.ListarAsync();

    private static string Plata(decimal monto) => monto.ToString("C0", Moneda);

    // El color de cada etapa lo define el .razor.css a partir de esta clase.
    private static string ClaseEtapa(Etapa etapa) => $"etapa--{etapa.ToString().ToLowerInvariant()}";

    private static string NombreEtapa(Etapa etapa) => etapa switch
    {
        Etapa.Prospecto => "Prospecto",
        Etapa.Cotizada => "Cotizada",
        Etapa.Negociacion => "Negociación",
        Etapa.Ganada => "Ganada",
        _ => etapa.ToString(),
    };
}
