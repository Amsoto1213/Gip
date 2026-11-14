import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores del inicio de sesión y del control de acceso (DI-05).

class ExcepcionDatoFaltante extends ExcepcionNegocio {
  const ExcepcionDatoFaltante(super.mensaje);
}

class ExcepcionCredencialesInvalidas extends ExcepcionNegocio {
  const ExcepcionCredencialesInvalidas()
    : super('Correo o contraseña incorrectos');
}

class ExcepcionSinConexion extends ExcepcionNegocio {
  const ExcepcionSinConexion()
    : super('Necesitas internet para entrar la primera vez');
}

class ExcepcionUsuarioNoRegistrado extends ExcepcionNegocio {
  const ExcepcionUsuarioNoRegistrado()
    : super(
        'Tu correo no está registrado en ninguna tienda. '
        'Pídele al propietario que te agregue',
      );
}

class ExcepcionUsuarioInactivo extends ExcepcionNegocio {
  const ExcepcionUsuarioInactivo()
    : super(
        'Tu usuario está desactivado. Habla con el propietario de la tienda',
      );
}

class ExcepcionUsuarioYaInactivo extends ExcepcionNegocio {
  const ExcepcionUsuarioYaInactivo() : super('El usuario ya está desactivado');
}

class ExcepcionSoloPropietario extends ExcepcionNegocio {
  const ExcepcionSoloPropietario()
    : super('Solo el propietario de la tienda puede hacer esto');
}
