# CUS-21 Eliminar datos de un cliente

Diagrama de secuencia exportado de EA (3.3.21 CUS-21 Eliminar datos de un cliente).

## Participantes

- `Empleado` (Actor)
- `VistaCliente` (Sequence)
- `coordinador` : `ConsultarClienteCoordinator`
- `servicioClientes` : `ServicioClientes`
- `clientes` : `IClienteRepositorio`
- `cliente` : `Cliente`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-19 Consultar saldo e historial de cliente — Punto de extensión: el titular pide eliminar sus datos. Resultado: cliente : Cliente.
- 1. `Empleado` → `VistaCliente`: eliminarCliente(cliente)
- 2. `VistaCliente` → `Empleado`: mostrar("¿Confirma que desea eliminar los datos del cliente?")
- _Nota: Confirmación explícita antes de llamar al coordinador (RNF-26)._
- 3. `Empleado` → `VistaCliente`: confirmar()
- 4. `VistaCliente` → `coordinador`: eliminarCliente(tienda, cliente)
- 5. `coordinador` → `servicioClientes`: eliminarCliente(tienda, cliente)
- 6. `servicioClientes` → `cliente`: puedeEliminarse()
- 7. `cliente` → `servicioClientes`: puede
- _Nota: Information Expert: verdadero si el cliente no tiene fiados pendientes (DA-69)._
- **[break Con deuda | puede = false (tiene fiados pendientes)]**
  - 8. `servicioClientes` → `coordinador`: error("El cliente tiene saldo pendiente")
  - 9. `coordinador` → `VistaCliente`: error("El cliente tiene saldo pendiente")
  - 10. `VistaCliente` → `Empleado`: mostrar("No se pueden eliminar los datos: el cliente aún debe")
- _Nota: Se eliminan los datos personales a solicitud del titular (RNF-16)._
- 11. `servicioClientes` → `clientes`: eliminar(tienda, cliente)
- 12. `servicioClientes` → `coordinador`: retorno
- 13. `coordinador` → `VistaCliente`: retorno
- 14. `VistaCliente` → `Empleado`: mostrar("Datos del cliente eliminados")
