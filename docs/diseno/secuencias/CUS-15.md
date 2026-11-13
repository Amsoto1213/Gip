# CUS-15 Gestionar usuarios de la tienda

Diagrama de secuencia exportado de EA (3.3.15 CUS-15 Gestionar usuarios de la tienda).

## Participantes

- `Propietario` (Actor)
- `VistaUsuarios` (Sequence)
- `coordinador` : `GestionarUsuariosCoordinator`
- `servicioAcceso` : `ServicioAcceso`
- `servicioUsuarios` : `ServicioUsuarios`
- `usuarios` : `IUsuarioRepositorio`
- `empleado` : `Empleado`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Propietario` → `VistaUsuarios`: abrirUsuarios()
- _Nota: Control de acceso por rol detallado en CUS-05; cada operación del coordinador lo exige (RNF-12)._
- 2. `VistaUsuarios` → `coordinador`: listarUsuarios(tienda, usuario)
- 3. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
- 4. `servicioAcceso` → `coordinador`: retorno
- 5. `coordinador` → `servicioUsuarios`: listar(tienda)
- 6. `servicioUsuarios` → `usuarios`: listar(tienda)
- 7. `usuarios` → `servicioUsuarios`: usuarios
- 8. `servicioUsuarios` → `coordinador`: usuarios
- 9. `coordinador` → `VistaUsuarios`: usuarios
- 10. `VistaUsuarios` → `Propietario`: mostrar(usuarios)
- _Nota: Muestra los usuarios activos e inactivos de la tienda._
- **[alt Gestión | el Propietario crea un empleado]**
  - 11. `Propietario` → `VistaUsuarios`: ingresarEmpleado(nombre, cedula)
  - 12. `VistaUsuarios` → `coordinador`: crearEmpleado(tienda, nombre, cedula, usuario)
  - 13. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
  - 14. `servicioAcceso` → `coordinador`: retorno
  - 15. `coordinador` → `servicioUsuarios`: crearEmpleado(tienda, nombre, cedula)
  - 16. `servicioUsuarios` → `usuarios`: buscarPorCedula(tienda, cedula)
  - 17. `usuarios` → `servicioUsuarios`: existente
  - **[break Datos no válidos | nombre vacío o existente != null (cédula repetida)]**
    - 18. `servicioUsuarios` → `coordinador`: error("Datos no válidos")
    - 19. `coordinador` → `VistaUsuarios`: error("Datos no válidos")
    - 20. `VistaUsuarios` → `Propietario`: mostrar("El nombre es obligatorio y la cédula no puede estar repetida")
  - 21. `servicioUsuarios` → `empleado`: Empleado(id, nombre, cedula)
  - _Nota: Queda activo. La cuenta de acceso (correo y contraseña) la crea Supabase Auth, fuera de la Business Layer (DA-67)._
  - 22. `servicioUsuarios` → `usuarios`: guardar(tienda, empleado)
  - 23. `servicioUsuarios` → `coordinador`: empleado
  - 24. `coordinador` → `VistaUsuarios`: empleado
  - 25. `VistaUsuarios` → `Propietario`: mostrar("Empleado creado")
- **[alt Gestión | el Propietario desactiva un empleado]**
  - 26. `Propietario` → `VistaUsuarios`: desactivar(empleado)
  - 27. `VistaUsuarios` → `coordinador`: desactivarUsuario(tienda, empleado, usuario)
  - 28. `coordinador` → `servicioAcceso`: exigirPropietario(usuario)
  - 29. `servicioAcceso` → `coordinador`: retorno
  - 30. `coordinador` → `servicioUsuarios`: desactivar(tienda, empleado)
  - **[break Propietario | empleado is Administrador (el propietario no se desactiva)]**
    - 31. `servicioUsuarios` → `coordinador`: error("No se puede desactivar")
    - 32. `coordinador` → `VistaUsuarios`: error("No se puede desactivar")
    - 33. `VistaUsuarios` → `Propietario`: mostrar("El propietario no se puede desactivar")
  - 34. `servicioUsuarios` → `empleado`: desactivar()
  - _Nota: Information Expert: rechaza si ya está inactivo. El usuario no se borra: sus ventas y anulaciones siguen apuntando a él (RNF-15)._
  - 35. `servicioUsuarios` → `usuarios`: guardar(tienda, empleado)
  - 36. `servicioUsuarios` → `coordinador`: retorno
  - 37. `coordinador` → `VistaUsuarios`: retorno
  - 38. `VistaUsuarios` → `Propietario`: mostrar("Empleado desactivado")
