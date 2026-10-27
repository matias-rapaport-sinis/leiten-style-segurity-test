namespace Ejemplo.Web.Datos;

public enum Etapa
{
    Prospecto,
    Cotizada,
    Negociacion,
    Ganada,
}

public record Oportunidad(string Cliente, string Obra, Etapa Etapa, decimal Monto, int Avance);
