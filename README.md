# Lector de Productos CFDI

Aplicación de escritorio en Flutter para importar facturas electrónicas CFDI
(XML del SAT), consultar sus conceptos y exportarlos a Excel.

## Funcionalidades

- **Importar XML**: carga uno o varios archivos CFDI a la vez. Antes de
  procesarlos puedes revisar la lista y quitar archivos. Al terminar, un
  resumen indica cuántos productos se agregaron y qué archivos fallaron y
  por qué.
- **Consultar productos**: tabla con proveedor, descripción, clave
  ProdServ, clave de unidad, cantidad, valor unitario, importe, fecha de
  emisión, folio, UUID y fecha de registro.
  - Ordenamiento por cualquier columna.
  - Búsqueda por descripción, clave, folio o UUID (no distingue acentos).
  - Filtro por proveedor.
  - Paginación de 10, 25, 50 o 100 filas.
- **Resumen**: total de productos, facturas (UUID únicos), proveedores e
  importe total de lo que está visible según los filtros.
- **Exportar a Excel**: genera un `.xlsx` con los productos visibles
  (respeta búsqueda, filtro y orden).
- Tema claro y oscuro (sigue al sistema por defecto).

### Atajos de teclado

| Atajo | Acción |
|---|---|
| `Ctrl+O` | Cargar archivos XML |
| `Ctrl+F` | Ir a la búsqueda |
| `Ctrl+E` | Exportar a Excel |

## Datos que se extraen del CFDI

| Campo en la app | Origen en el XML |
|---|---|
| Descripción, Clave ProdServ, Clave Unidad, Cantidad, Valor Unitario, Importe | Atributos de cada `cfdi:Concepto` |
| Proveedor | `cfdi:Emisor/@Nombre` |
| Fecha Emisión | `cfdi:Comprobante/@Fecha` |
| Folio | `cfdi:Comprobante/@Serie` y `@Folio` |
| UUID | `tfd:TimbreFiscalDigital/@UUID` |

## Instalación (Windows)

Cada push a `main` compila la app y genera un instalador con el workflow
[`build_windows.yml`](.github/workflows/build_windows.yml). Para
descargarlo:

1. Abre la pestaña **Actions** del repositorio y elige la ejecución más
   reciente de *Build Flutter Windows Installer*.
2. Descarga el artefacto **XMLParserSetup** y ejecuta
   `XMLParserSetup.exe`.

## Desarrollo

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install)
(Dart `^3.8.1`) y, para compilar en Windows, Visual Studio con la carga de
trabajo "Desarrollo para el escritorio con C++".

```bash
flutter pub get
flutter run -d windows      # o -d linux / -d macos
flutter analyze
flutter test
```

Para generar el instalador localmente:

```bash
flutter build windows --release
iscc windows/installer.iss   # requiere Inno Setup
```

### Estructura

```
lib/
  main.dart                 # arranque, registro de errores y tema
  models/products.dart      # modelo Product
  services/
    cfdi_parser.dart        # lectura del XML CFDI
    db.dart                 # base de datos SQLite
    excel_creator.dart      # exportación a .xlsx
  ui/
    pages/home_page.dart    # pantalla principal: filtros, resumen y tabla
    theme/app_theme.dart    # tema Material 3 (claro/oscuro)
    utils/formatters.dart   # formato de moneda, fechas y números
    widgets/                # tabla, diálogo de carga, tarjetas, etc.
```

### Dónde guarda los datos

- **Base de datos** (`xml_parser.db`): en el directorio de soporte de la
  app. En Windows es `%APPDATA%\com.example\xml_parser\`.
- **Registro de errores** (`flutter_log.txt`): en Windows,
  `%LOCALAPPDATA%\XMLParser\`.
