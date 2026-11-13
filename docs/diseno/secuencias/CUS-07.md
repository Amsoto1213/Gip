# CUS-07 Registrar fiado

Diagrama de secuencia exportado de EA (3.3.7 CUS-07 Registrar fiado).

## Participantes

- `Empleado` (Actor)
- `VistaFiado` (Sequence)
- `coordinador` : `RegistrarFiadoCoordinator`
- `procesador` : `ProcesadorFiado`
- `servicioClientes` : `ServicioClientes`
- `servicioFiados` : `ServicioFiados`
- `clientes` : `IClienteRepositorio`
- `fiados` : `IFiadoRepositorio`
- `cliente` : `Cliente`
- `fiado` : `Fiado`

## Mensajes

Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).

- **ref** CUS-19 Consultar saldo e historial de cliente — El Empleado busca al cliente y ve su saldo pendiente. Resultado: cliente : Cliente, o ninguno si no está registrado.
- **[opt Cliente nuevo | el cliente no está registrado]**
  - 1. `Empleado` → `VistaFiado`: ingresarCliente(nombre, telefono)
  - 2. `VistaFiado` → `coordinador`: registrarCliente(tienda, nombre, telefono)
  - 3. `coordinador` → `servicioClientes`: registrarCliente(tienda, nombre, telefono)
  - **[break Nombre vacío | nombre vacío]**
    - 4. `servicioClientes` → `coordinador`: error("Nombre obligatorio")
    - 5. `coordinador` → `VistaFiado`: error("Nombre obligatorio")
    - 6. `VistaFiado` → `Empleado`: mostrar("El nombre del cliente es obligatorio")
  - 7. `servicioClientes` → `cliente`: Cliente(id, nombre, telefono)
  - 8. `servicioClientes` → `clientes`: guardar(tienda, cliente)
  - 9. `servicioClientes` → `coordinador`: cliente
  - 10. `coordinador` → `VistaFiado`: cliente
- 11. `Empleado` → `VistaFiado`: ingresarMonto(monto)
- 12. `VistaFiado` → `coordinador`: prepararFiado(cliente, monto)
- 13. `coordinador` → `servicioFiados`: crearFiado(cliente, monto)
- **[break Monto no válido | monto <= 0 (IE-06)]**
  - 14. `servicioFiados` → `coordinador`: error("Monto no válido")
  - 15. `coordinador` → `VistaFiado`: error("Monto no válido")
  - 16. `VistaFiado` → `Empleado`: mostrar("El monto del fiado debe ser mayor que cero")
- 17. `servicioFiados` → `fiado`: Fiado(id, monto, fecha, cliente)
- _Nota: Saldo pendiente = monto y estado PENDIENTE. No se guarda todavía: queda en memoria hasta confirmar la venta._
- _Nota: La pantalla agrega el fiado a formasPago y el caso vuelve a CUS-02._
- 18. `servicioFiados` → `coordinador`: fiado
- 19. `coordinador` → `VistaFiado`: fiado
- **ref** CUS-02 Registrar venta: ServicioVentas.confirmar — Dentro de la transacción de la venta, procesadorPara(fiado) devuelve el ProcesadorFiado, que llama a procesar(tienda, venta, fiado).
- 20. `procesador` → `servicioFiados`: registrarFiado(tienda, fiado)
- 21. `servicioFiados` → `fiado`: getCliente()
- 22. `fiado` → `servicioFiados`: cliente
- 23. `servicioFiados` → `cliente`: agregarFiado(fiado)
- 24. `servicioFiados` → `fiados`: crear(tienda, fiado)
- _Nota: Se guarda en la misma transacción que la venta: si la venta falla, el fiado tampoco se guarda (RNF-04)._
- 25. `servicioFiados` → `procesador`: retorno
