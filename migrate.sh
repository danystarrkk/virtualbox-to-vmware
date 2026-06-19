#!/bin/bash

# ==========================================
# CONFIGURACIÓN Y MANEJO DE ERRORES
# ==========================================
set -e

# ==========================================
# FUNCIONES
# ==========================================

verificar_dependencias() {
  echo "[*] Verificando herramientas necesarias..."
  local dependencias=("tar" "virt-filesystems" "guestfish" "qemu-img")
  local falta_algo=false

  for cmd in "${dependencias[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "[!] Error: La herramienta '$cmd' no está instalada."
      falta_algo=true
    fi
  done

  if [ "$falta_algo" = true ]; then
    echo "[!] Por favor, instala las dependencias usando:"
    echo "sudo apt install libguestfs-tools qemu-img linux-image-generic"
    echo "Permisos necesarios: sudo chmod 0644 /boot/vmlinuz-*"
    echo "Limpiaar la cache: rm -rf /var/tmp/.guestfs-*"
    exit 1
  fi
  echo "[+] Todas las dependencias están instaladas."
}

descomprimir_ova() {
  local archivo_ova="$1"
  local dir_salida="$2"

  echo "[*] Fase 1: Creando directorio y descomprimiendo..."
  if [ ! -f "$archivo_ova" ]; then
    echo "[!] Error: El archivo '$archivo_ova' no existe."
    exit 1
  fi

  mkdir -p "$dir_salida"
  tar -xf "$archivo_ova" -C "$dir_salida"
  echo "[+] Descompresión completada en: $dir_salida"
}

encontrar_vmdk() {
  local dir_busqueda="$1"
  local archivo_vmdk

  echo "[*] Fase 2: Buscando archivo de disco virtual (.vmdk)..."
  archivo_vmdk=$(find "$dir_busqueda" -name "*.vmdk" | head -n 1)

  if [ -z "$archivo_vmdk" ]; then
    echo "[!] Error: No se encontró ningún archivo .vmdk dentro del OVA."
    exit 1
  fi

  echo "$archivo_vmdk"
}

convertir_disco_escribible() {
  local archivo_vmdk="$1"
  local archivo_temp="${archivo_vmdk}.temp"

  echo "[*] Fase 2.5: Convirtiendo el disco comprimido a formato escribible..."
  echo "[*] (Esto arreglará el error de superbloque y lo hará 100% compatible con VMware)"

  # -p muestra una barra de progreso. Convierte el disco y lo guarda en el temporal
  qemu-img convert -p -f vmdk -O vmdk "$archivo_vmdk" "$archivo_temp"

  # Reemplazamos el comprimido con el nuevo disco escribible
  mv "$archivo_temp" "$archivo_vmdk"
  echo "[+] Conversión completada."
}

encontrar_particion_raiz() {
  local archivo_disco="$1"
  local particiones
  local particion_raiz=""

  echo "[*] Fase 3: Inspeccionando el interior del disco para encontrar el sistema operativo..."

  particiones=$(virt-filesystems -a "$archivo_disco")

  for part in $particiones; do
    if guestfish -a "$archivo_disco" --ro -m "$part" is-dir /etc 2>/dev/null | grep -q "true"; then
      particion_raiz="$part"
      break
    fi
  done

  if [ -z "$particion_raiz" ]; then
    echo "[!] Error Crítico: No se pudo encontrar ninguna partición que contenga un sistema operativo válido (/etc)."
    exit 1
  fi

  echo "$particion_raiz"
}

confirmar_ejecucion() {
  local archivo_disco="$1"
  local particion="$2"
  local respuesta

  echo "--------------------------------------------------------"
  echo "[?] RESUMEN DE LA OPERACIÓN ANTES DE INYECTAR"
  echo "    - Disco objetivo: $archivo_disco"
  echo "    - Sistema operativo detectado en: $particion"
  echo "--------------------------------------------------------"
  read -p "¿Es correcto y deseas inyectar la red universal en esta partición? (s/n): " respuesta

  if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
    echo "[*] Operación cancelada por el usuario. Saliendo limpiamente."
    exit 0
  fi

  echo "[+] Confirmación recibida. Iniciando inyección..."
}

inyectar_red_universal() {
  local archivo_disco="$1"
  local particion_raiz="$2"

  echo "[*] Fase 4: Aplicando configuraciones de red agnósticas (Shotgun Approach)..."

  guestfish --rw -a "$archivo_disco" -m "$particion_raiz" <<EOF

mkdir-p /etc/netplan
write /etc/netplan/99-omni-dhcp.yaml "network:\n  version: 2\n  ethernets:\n    all_en:\n      match:\n        name: \"en*\"\n      dhcp4: true\n    all_eth:\n      match:\n        name: \"eth*\"\n      dhcp4: true\n"

mkdir-p /etc/NetworkManager/system-connections
write /etc/NetworkManager/system-connections/99-omni.nmconnection "[connection]\nid=Omni-DHCP\ntype=ethernet\nautoconnect=true\n\n[ethernet]\n\n[ipv4]\nmethod=auto\n\n[ipv6]\nmethod=auto\n"
chmod 0600 /etc/NetworkManager/system-connections/99-omni.nmconnection

touch /etc/network/interfaces
write-append /etc/network/interfaces "\n\n# --- INYECTADO POR SCRIPT ---\nallow-hotplug ens33\niface ens33 inet dhcp\nallow-hotplug eth0\niface eth0 inet dhcp\n"

mkdir-p /etc/systemd/network
write /etc/systemd/network/99-omni.network "[Match]\nName=en* eth*\n\n[Network]\nDHCP=yes\n"

EOF

  echo "--------------------------------------------------------"
  echo "[+] ¡OPERACIÓN COMPLETADA CON ÉXITO!"
  echo "[+] Tu máquina CTF ha sido parcheada. Puedes llevar el archivo:"
  echo "    $archivo_disco"
  echo "    hacia tu entorno VMware/Windows e importarlo de inmediato."
  echo "--------------------------------------------------------"
}

# ==========================================
# FLUJO PRINCIPAL (MAIN)
# ==========================================

if [ -z "$1" ]; then
  echo "Uso: $0 <archivo_maquina.ova>"
  exit 1
fi

OVA_FILE="$1"
BASENAME=$(basename "$OVA_FILE" .ova)
DIR_NAME="${BASENAME}_extracted"

# 0. Verificar dependencias
verificar_dependencias

# 1. Descomprimir
descomprimir_ova "$OVA_FILE" "$DIR_NAME"

# 2. Encontrar el disco
VMDK_TARGET=$(encontrar_vmdk "$DIR_NAME" | tail -n 1)
echo "[+] Disco encontrado: $VMDK_TARGET"

# 2.5 Convertir disco a escribible (Arreglo del Superbloque)
convertir_disco_escribible "$VMDK_TARGET"

# 3. Encontrar la partición raíz
PARTICION_OBJETIVO=$(encontrar_particion_raiz "$VMDK_TARGET" | tail -n 1)

# 4. Confirmar con el usuario
confirmar_ejecucion "$VMDK_TARGET" "$PARTICION_OBJETIVO"

# 5. Inyectar configuración
inyectar_red_universal "$VMDK_TARGET" "$PARTICION_OBJETIVO"

exit 0
