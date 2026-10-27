namespace Ejemplo.Web.Datos;

// Datos de ejemplo en memoria. En un proyecto real esto llama al backend (ERP):
// es lógica de datos y la mantiene Desarrollo.
public class OportunidadesService
{
    private static readonly Oportunidad[] Datos =
    [
        new("Constructora Norte", "Torre Alvear", Etapa.Negociacion, 18_500_000m, 70),
        new("Grupo Delta", "Barrio Los Álamos", Etapa.Cotizada, 9_200_000m, 40),
        new("Obras del Sur", "Puente Ruta 3", Etapa.Prospecto, 32_000_000m, 10),
        new("Edificar SA", "Hospital Regional", Etapa.Ganada, 54_750_000m, 100),
        new("Pilar Inversiones", "Centro Logístico", Etapa.Negociacion, 21_300_000m, 65),
    ];

    public Task<IReadOnlyList<Oportunidad>> ListarAsync() =>
        Task.FromResult<IReadOnlyList<Oportunidad>>(Datos);
}
