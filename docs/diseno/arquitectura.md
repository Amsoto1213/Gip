# Arquitectura del sistema (componentes del diagrama 3.1.1)

- **Rendering (Flutter)**: Interfaz dibujada por Flutter en Android (APK) y en el navegador.
- **Lector 2D**: Lector USB o Bluetooth en modo teclado; cámara como respaldo.
- **UI Components: Vistas**: Pantallas de venta, inventario, fiados, caja, alertas y reportes.
- **UI Process Components: ViewModels**: Estado de pantalla, validación de formularios y llamada al coordinador del caso de uso.
- **Data Access: Repositorios**: Un repositorio drift por cada interfaz de repositorio (SQLite local).
- **Data Helpers: Base local, UdT**: Conexión a la base local, unidad de trabajo y exportación CSV/Excel.
- **Service Agents: Sync, PDF**: Sincronizador, cliente Supabase e impresión de etiquetas PDF.
- **Seguridad**: Supabase Auth, PIN local, permisos por rol, RLS por tienda y rol, cierre de sesión a los 15 min (RNF-12, 13, 17).
- **Gestión operacional**: Mensajes en lenguaje del tendero, indicador de sincronización, registro de errores y respaldos (RNF-06).
- **Comunicación**: HTTPS y JSON con la API de Supabase; cola de pendientes con reintento automático.
- **Data Sources: SQLite local, PostgreSQL**: SQLite local en el dispositivo y PostgreSQL en Supabase; 24 meses de histórico (RD-05).
- **Services: Supabase Auth y API, impresora**: Supabase Auth y API REST en contenedores Docker (RNF-21); impresora del sistema.
