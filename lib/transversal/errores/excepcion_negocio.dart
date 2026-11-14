/// Error de una regla de negocio. [mensaje] está en el lenguaje del tendero y se
/// muestra tal cual en pantalla. Cada regla define su subclase.
class ExcepcionNegocio implements Exception {
  const ExcepcionNegocio(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
