import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores de la gestión de usuarios de la tienda (CUS-15).

/// Nombre o cédula vacíos, o cédula repetida en la tienda (CUS-15, paso 20).
class ExcepcionDatosUsuarioNoValidos extends ExcepcionNegocio {
  const ExcepcionDatosUsuarioNoValidos()
    : super('El nombre es obligatorio y la cédula no puede estar repetida');
}

/// Se intentó desactivar al propietario (CUS-15, paso 33).
class ExcepcionNoSePuedeDesactivar extends ExcepcionNegocio {
  const ExcepcionNoSePuedeDesactivar()
    : super('El propietario no se puede desactivar');
}

/// No hay red para leer o guardar los usuarios, que viven en el servidor
/// (DI-42).
class ExcepcionSinConexionUsuarios extends ExcepcionNegocio {
  const ExcepcionSinConexionUsuarios()
    : super('Necesitas internet para ver y cambiar los usuarios');
}

/// El correo no tiene forma de correo (DI-43).
class ExcepcionCorreoNoValido extends ExcepcionNegocio {
  const ExcepcionCorreoNoValido() : super('Escribe un correo válido');
}

/// La contraseña es más corta de lo que pide Supabase (DI-43).
class ExcepcionClaveNoValida extends ExcepcionNegocio {
  const ExcepcionClaveNoValida(int minimo)
    : super('La contraseña debe tener al menos $minimo caracteres');
}

/// Ya hay una cuenta con ese correo y no es la de este intento (DI-43).
class ExcepcionCorreoYaRegistrado extends ExcepcionNegocio {
  const ExcepcionCorreoYaRegistrado()
    : super('Ese correo ya tiene una cuenta. Usa otro correo');
}

/// Supabase rechazó crear la cuenta de acceso por otra razón, por ejemplo
/// porque los registros están desactivados (DI-43).
class ExcepcionCuentaNoCreada extends ExcepcionNegocio {
  const ExcepcionCuentaNoCreada()
    : super('No se pudo crear la cuenta de acceso. Inténtalo de nuevo');
}
