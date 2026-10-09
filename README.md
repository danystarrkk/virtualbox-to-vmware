# 🛠️ Herramienta de preparación de máquinas virtuales Linux

Herramienta basada en Bash para inspeccionar y modificar discos virtuales distribuidos en formato `.ova`, orientada a preparar máquinas Linux para su importación y uso en diferentes entornos de virtualización.

Permite localizar el disco virtual de una máquina, identificar la partición que contiene el sistema operativo e inyectar configuraciones de red mediante DHCP. Está pensada principalmente para laboratorios de ciberseguridad, máquinas CTF y entornos de práctica donde pueden aparecer problemas de conectividad después de importar una máquina virtual.

## ✨ Características

- 📦 **Gestión de archivos OVA:** extrae el contenido del paquete y localiza el disco virtual VMDK.
- 💽 **Conversión de discos:** convierte la imagen VMDK mediante `qemu-img` para trabajar sobre una imagen reescrita.
- 🔍 **Inspección del sistema de archivos:** utiliza herramientas de libguestfs para examinar las particiones e identificar la raíz de Linux.
- 🌐 **Configuración de red:** incorpora perfiles DHCP para distintos gestores de red de Linux.
- 🔌 **Adaptación a interfaces de red:** contempla diferentes convenciones de nombres de interfaces Ethernet.
- ✅ **Confirmación antes de modificar:** presenta el disco y la partición seleccionados antes de aplicar los cambios.
- 🧰 **Orientada a laboratorios:** facilita la preparación de máquinas virtuales que requieren ajustes de red antes de su utilización.

## 🧰 Requisitos

La herramienta requiere un sistema Linux y las siguientes utilidades:

| Dependencia        | Propósito                             |
| ------------------ | ------------------------------------- |
| `bash`             | Ejecutar el script                    |
| `tar`              | Extraer el archivo OVA                |
| `qemu-img`         | Convertir el disco virtual            |
| `virt-filesystems` | Inspeccionar los sistemas de archivos |
| `guestfish`        | Examinar y modificar el disco virtual |

### Instalación en Debian / Ubuntu

```bash
sudo apt update
sudo apt install tar libguestfs-tools qemu-utils
```

Comprueba que las herramientas necesarias estén disponibles:

```bash
command -v tar
command -v qemu-img
command -v virt-filesystems
command -v guestfish
```

## 🚀 Uso

### 1. Preparar el archivo

Descarga o coloca el archivo `.ova` que deseas preparar en tu directorio de trabajo.

Ejemplo de estructura:

```text
.
├── script.sh
└── maquina-ctf.ova
```

### 2. Habilitar la ejecución

```bash
chmod +x script.sh
```

### 3. Ejecutar la herramienta

```bash
./script.sh maquina-ctf.ova
```

También puedes proporcionar una ruta al archivo:

```bash
./script.sh /ruta/a/maquina-ctf.ova
```

### 4. Revisar la partición detectada

La herramienta extraerá el paquete, localizará el disco virtual, realizará la conversión e intentará encontrar la partición que contiene el sistema operativo.

Antes de continuar, mostrará un resumen de la operación:

```text
--------------------------------------------------------
[?] RESUMEN DE LA OPERACIÓN ANTES DE INYECTAR
    - Disco objetivo: maquina-ctf_extracted/disk.vmdk
    - Sistema operativo detectado en: /dev/sda2
--------------------------------------------------------
¿Es correcto y deseas inyectar la red universal en esta partición? (s/n):
```

Verifica la información antes de confirmar. Introduce `s` para continuar o `n` para cancelar.

### 5. Importar y comprobar la máquina

Una vez completada la modificación, utiliza el disco resultante en tu entorno de virtualización y comprueba que el sistema invitado pueda configurar correctamente su interfaz de red y obtener una dirección IP.

## ⚙️ Configuraciones de red aplicadas

La herramienta intenta incorporar archivos de configuración en las siguientes ubicaciones del sistema invitado:

| Archivo                                                       | Gestor de red    |
| ------------------------------------------------------------- | ---------------- |
| `/etc/netplan/99-omni-dhcp.yaml`                              | Netplan          |
| `/etc/NetworkManager/system-connections/99-omni.nmconnection` | NetworkManager   |
| `/etc/network/interfaces`                                     | ifupdown         |
| `/etc/systemd/network/99-omni.network`                        | systemd-networkd |

Las configuraciones buscan habilitar la obtención automática de direcciones IP mediante DHCP.

**Nota:** la creación de estos archivos no garantiza que la conectividad funcione. El resultado depende del sistema operativo, de los servicios de red activos, de la configuración previa y del entorno de virtualización.

## 🔬 Flujo de trabajo

```text
Archivo OVA
    │
    ▼
Extracción del contenido
    │
    ▼
Localización del disco VMDK
    │
    ▼
Conversión de la imagen
    │
    ▼
Inspección de particiones
    │
    ▼
Identificación de la raíz Linux
    │
    ▼
Confirmación del usuario
    │
    ▼
Modificación de configuraciones
    │
    ▼
Importación y pruebas de conectividad
```

## ⚠️ Consideraciones y limitaciones

- **Conserva el archivo original.** La herramienta reemplaza el VMDK extraído por una imagen convertida y modifica archivos dentro del sistema invitado.
- **Verifica la partición raíz.** Los sistemas con LVM, cifrado, Btrfs, particiones separadas o distribuciones de disco no convencionales pueden necesitar un procedimiento diferente.
- **La conversión no garantiza compatibilidad total.** El arranque también depende del firmware, los controladores virtuales y la configuración de la máquina.
- **Comprueba los nombres de las interfaces.** Las reglas incluidas no cubren necesariamente todas las convenciones de nombres utilizadas por Linux.
- **Evita conflictos entre gestores de red.** La configuración debe adaptarse al servicio que realmente administra las interfaces del sistema invitado.
- **Revisa los cambios antes de arrancar.** Si el sistema ya dispone de configuraciones de red específicas, los nuevos archivos podrían entrar en conflicto con ellas.

Utiliza la herramienta únicamente con máquinas virtuales propias o con autorización para modificarlas.

## 🎯 Objetivo

Facilitar la preparación de discos virtuales Linux para laboratorios CTF y entornos de práctica, reduciendo el trabajo manual necesario para inspeccionar imágenes y ajustar sus configuraciones de red antes de importarlas.

La herramienta sirve como punto de partida para preparar máquinas virtuales; cada imagen debe verificarse individualmente para confirmar su compatibilidad y conectividad.
