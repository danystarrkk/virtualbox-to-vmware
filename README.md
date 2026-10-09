# ⚡ OmniNet — Universal Network Patcher for OVA

**Automatiza la configuración de red de máquinas virtuales CTF para facilitar su importación y ejecución en diferentes entornos de virtualización.**

OmniNet es un script Bash que permite extraer, inspeccionar y modificar imágenes de máquinas virtuales distribuidas en formato `.ova`, inyectando configuraciones DHCP en los principales sistemas de gestión de red de Linux.

Su objetivo es reducir los problemas de conectividad que aparecen al importar máquinas virtuales entre entornos como VMware y otros hipervisores, especialmente cuando cambian los nombres de las interfaces de red.

---

## ✨ Características

- 📦 **Extracción automática de OVA:** descomprime el paquete y localiza el disco virtual `.vmdk`.
- 💽 **Conversión del disco:** convierte el VMDK a una imagen reescrita mediante `qemu-img`.
- 🔍 **Detección del sistema operativo:** inspecciona las particiones para localizar la raíz de Linux.
- 🌐 **Configuración de red universal:** inyecta configuraciones DHCP para diferentes gestores de red.
- 🛠️ **Compatibilidad con múltiples interfaces:** contempla nombres como `ens33` y `eth0`, además de patrones `en*` y `eth*`.
- 🛡️ **Confirmación previa:** muestra el disco y la partición seleccionados antes de aplicar los cambios.
- ⚙️ **Automatización:** ejecuta el procedimiento completo con un único comando.

## 🧰 Requisitos

El script está diseñado para sistemas Linux con las siguientes herramientas:

| Herramienta        | Función                                         |
| ------------------ | ----------------------------------------------- |
| `tar`              | Extraer el archivo OVA                          |
| `qemu-img`         | Convertir el disco virtual                      |
| `virt-filesystems` | Inspeccionar sistemas de archivos y particiones |
| `guestfish`        | Examinar y modificar el disco virtual           |

### Instalación en Debian / Ubuntu

```bash
sudo apt update
sudo apt install tar libguestfs-tools qemu-utils
```

Comprueba que las herramientas estén disponibles:

```bash
command -v tar
command -v qemu-img
command -v virt-filesystems
command -v guestfish
```

> **Nota:** El script original sugiere instalar `linux-image-generic` y cambiar permisos de archivos del kernel. Estas acciones no deberían ejecutarse de forma preventiva sin comprobar primero si existe un problema real de inicialización de libguestfs.

## 🚀 Uso

### 1. Descargar o preparar el archivo OVA

Coloca el archivo de la máquina virtual en el directorio de trabajo. Por ejemplo:

```text
.
├── ominet.sh
└── target-machine.ova
```

### 2. Dar permisos de ejecución

```bash
chmod +x ominet.sh
```

### 3. Ejecutar el script

```bash
./ominet.sh target-machine.ova
```

Sustituye `target-machine.ova` por la ruta de tu archivo.

### 4. Confirmar la operación

El script extraerá el OVA, localizará el VMDK, lo convertirá e intentará identificar la partición raíz.

Antes de modificar el disco, mostrará un resumen similar a este:

```text
--------------------------------------------------------
[?] RESUMEN DE LA OPERACIÓN ANTES DE INYECTAR
    - Disco objetivo: target-machine_extracted/disk.vmdk
    - Sistema operativo detectado en: /dev/sda2
--------------------------------------------------------
¿Es correcto y deseas inyectar la red universal en esta partición? (s/n):
```

Comprueba que el disco y la partición sean correctos. Introduce `s` para continuar o `n` para cancelar.

### 5. Importar la máquina virtual

Una vez completada la modificación, importa el disco resultante en tu entorno de virtualización y verifica que la máquina obtenga una dirección IP.

**Importante:** OmniNet prepara configuraciones de red mediante DHCP, pero no garantiza que la máquina obtenga conectividad en todos los hipervisores o laboratorios.

## ⚙️ ¿Qué modifica?

El script intenta escribir configuraciones en las siguientes ubicaciones dentro del sistema de archivos invitado:

| Ruta                                                          | Propósito                           |
| ------------------------------------------------------------- | ----------------------------------- |
| `/etc/netplan/99-omni-dhcp.yaml`                              | Configuración DHCP para Netplan     |
| `/etc/NetworkManager/system-connections/99-omni.nmconnection` | Perfil Ethernet para NetworkManager |
| `/etc/network/interfaces`                                     | Configuración para ifupdown         |
| `/etc/systemd/network/99-omni.network`                        | Configuración para systemd-networkd |

Estas configuraciones están pensadas para cubrir distintas familias de gestión de red. No obstante, **escribir los archivos no significa que todos los gestores vayan a activarlos correctamente**: depende de los servicios instalados, de su configuración y de la compatibilidad de cada sistema operativo.

## 🔬 Flujo de ejecución

```text
OVA
 │
 ▼
Extracción del paquete
 │
 ▼
Localización del VMDK
 │
 ▼
Conversión del disco
 │
 ▼
Inspección de particiones
 │
 ▼
Detección de la raíz Linux
 │
 ▼
Confirmación del usuario
 │
 ▼
Inyección de configuraciones DHCP
 │
 ▼
Verificación e importación
```

## ⚠️ Consideraciones importantes

- **Trabaja con una copia del OVA original.** El script reemplaza el VMDK extraído tras convertirlo y modifica su sistema de archivos.
- **No todos los discos tienen una única partición raíz.** Sistemas con LVM, cifrado, Btrfs, particiones separadas o diseños complejos pueden requerir un tratamiento específico.
- **La conversión no garantiza compatibilidad con VMware.** La compatibilidad depende también del controlador virtual, del firmware, del formato de disco y de la configuración de la máquina.
- **Los nombres de interfaz varían.** Las reglas `en*` y `eth*` no cubren necesariamente todas las interfaces posibles, como algunas denominadas `ens*`, `enp*` o `eno*` si la expresión utilizada no coincide con ellas.
- **Los gestores de red pueden entrar en conflicto.** Netplan, NetworkManager, ifupdown y systemd-networkd no deben configurarse simultáneamente sin comprobar qué servicio administra realmente la interfaz.
- **Utiliza la herramienta únicamente con máquinas autorizadas**, como laboratorios propios, máquinas CTF y entornos de práctica.

## 🗺️ Estado del proyecto

OmniNet es una herramienta de automatización para preparar máquinas virtuales Linux. Su comportamiento depende de la estructura del OVA, del sistema invitado y del entorno de virtualización de destino.

Las pruebas con distintas distribuciones y configuraciones de red son necesarias antes de considerarla una solución universal.

## 📄 Licencia

Añade aquí la licencia que hayas elegido para el proyecto, por ejemplo, MIT, si deseas distribuirlo bajo esos términos.
