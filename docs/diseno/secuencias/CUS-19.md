# CUS-19 Consultar saldo e historial de cliente

Diagrama de secuencia exportado de EA (3.3.19 CUS-19 Consultar saldo e historial de cliente).

## Participantes

- `Empleado` (Actor)
- `VistaCliente` (Sequence)
- `coordinador` : `ConsultarClienteCoordinator`
- `servicioClientes` : `ServicioClientes`
- `clientes` : `IClienteRepositorio`
- `cliente` : `Cliente`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- 1. `Empleado` → `VistaCliente`: buscarCliente(nombre)
- 2. `VistaCliente` → `coordinador`: buscarClientes(tienda, nombre)
- 3. `coordinador` → `servicioClientes`: buscarClientes(tienda, nombre)
- 4. `servicioClientes` → `clientes`: buscarPorNombre(tienda, nombre)
- 5. `clientes` → `servicioClientes`: clientes
- _Nota: Coincidencia parcial, sin mayúsculas ni tildes (RD-08); cada cliente llega con sus fiados y los abonos de cada fiado._
- 6. `servicioClientes` → `coordinador`: clientes
- 7. `coordinador` → `VistaCliente`: clientes
- 8. `VistaCliente` → `Empleado`: mostrar(clientes)
- _Nota: La pantalla también puede listar todos los fiados (listarFiados) o buscarlos por nombre del cliente (buscarFiadosPorCliente); el coordinador delega ambas en ServicioFiados._
- **[alt Resultado | no hay coincidencias]**
  - 9. `VistaCliente` → `Empleado`: mostrar("No se encontró el cliente")
  - _Nota: El cliente no está registrado: en CUS-07 se ofrece registrarlo._
- **[alt Resultado | el Empleado selecciona un cliente]**
  - 10. `Empleado` → `VistaCliente`: seleccionar(cliente)
  - 11. `VistaCliente` → `coordinador`: consultarSaldoTotal(cliente)
  - 12. `coordinador` → `servicioClientes`: consultarSaldoTotal(cliente)
  - 13. `servicioClientes` → `cliente`: calcularSaldoPendiente()
  - 14. `cliente` → `cliente`: obtenerFiadosPendientes()
  - 15. `cliente` → `servicioClientes`: saldoTotal
  - _Nota: Information Expert: suma getSaldoPendiente() de cada fiado en estado PENDIENTE (DA-69)._
  - 16. `servicioClientes` → `coordinador`: saldoTotal
  - 17. `coordinador` → `VistaCliente`: saldoTotal
  - 18. `VistaCliente` → `coordinador`: consultarHistorial(cliente)
  - 19. `coordinador` → `servicioClientes`: obtenerHistorial(cliente)
  - 20. `servicioClientes` → `cliente`: obtenerHistorial()
  - 21. `cliente` → `servicioClientes`: historial
  - _Nota: Information Expert: sus fiados del más reciente al más antiguo, cada uno con sus abonos._
  - 22. `servicioClientes` → `coordinador`: historial
  - 23. `coordinador` → `VistaCliente`: historial
  - 24. `VistaCliente` → `Empleado`: mostrar(saldoTotal, historial)
  - _Nota: El cliente y sus fiados vuelven al caso que incluyó la consulta: CUS-07 (fiado) o CUS-08 (abono)._
  - **[opt Eliminar datos | el titular pide eliminar sus datos]**
    - **ref** CUS-21 Eliminar datos de un cliente (extiende) — Solo si el cliente ya no debe; requiere confirmación explícita (RNF-26).
