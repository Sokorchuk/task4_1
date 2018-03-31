#! /bin/bash
#
# task4_1.sh -- info script
#
# Copyright (C) 2018 Ihor P. Sokorchuk
# Developed for Mirantis Inc. by Ihor Sokorchuk
# Ihor P. Sokorchuk <ihor.sokorchuk@nure.ua>
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 2, as published by the Free Software Foundation.
#
# Usage: task4_1.sh
#
exec 1>task4_1.out

echo '--- Hardware ---'

if dmidecode &>/dev/null; then # root mode

   # CPU: Intel xeon 2675
   cpu_version=$(dmidecode -s processor-version 2>/dev/null)
   echo "CPU: ${cpu_version:=Unknown}"

   # RAM: xxxx 
   dmidecode -t 17 2>/dev/null | awk '#
   BEGIN {
      MemTotal=0;
   }
   (($1 == "Size:") && ($2 ~ /[0-9]+/) && ($3 == "MB")) {
      MemTotal =+ $2;
   }
   END {
      if (MemTotal > 0) print "RAM:", MemTotal, "MB";
   }
   #'

   # Motherboard: XXX XX / ??? / Unknown
   # System Serial Number: XXXXXX
dmidecode baseboard-manufacturer 2>/dev/null | awk '#
   BEGIN { manufacturer = product_name = serial_number = "Unknown"; }
   /^Base Board Information/ { base_board = 1; }
   /^ *$/ { base_board = 0; }
   ((base_board == 1) && /^\tManufacturer: /) { manufacturer = substr($0,16); }
   ((base_board == 1) && /^\tProduct Name: /) { product_name = substr($0,16); } 
   ((base_board == 1) && /^\tSerial Number: /) { serial_number = substr($0,17); }
   END { 
      if ((manufacturer ~ /^[ \t]*$/) && (product_name ~ /^[ \t]*$/)) { manufacturer = "Unknown"; }
      if (serial_number ~ /^[ \t]*$/) { serial_number = "Unknown"; }
      printf ("Motherboard: %s %s\nSystem Serial Number: %s\n", manufacturer, product_name, serial_number); 
   }
#'

else # users mode

   # CPU: Intel xeon 2675
   read etc etc etc cpu_version <<< "$(grep 'model name' /proc/cpuinfo)"
   echo "CPU: ${cpu_version:-Unknown}"

   # RAM: xxxx
   read etc memtotal <<< "$(grep MemTotal: /proc/meminfo)"
   echo "RAM: ${memtotal:-Unknown}"

   # Motherboard: XXX XX / ??? / Unknown
   echo 'Motherboard: Unknown'

   # System Serial Number: XXXXXX
   echo 'System Serial Number: Unknown'

fi

echo '--- System ---'

# OS Distribution: xxxxx (например Ubuntu 16.04.4 LTS)
echo -n 'OS Distribution: '
if test -f /etc/system-release; then
   head -n 1 /etc/system-release
elif type lsb_release &>/dev/null; then
   read etc distribution <<< $(lsb_release -d)
   echo "$distribution"
else
   echo 'Unknown'
fi

# Kernel version: xxxx (например 4.4.0-116-generic)
echo -n 'Kernel version: '
uname -r

# Installation date: xxxx
read etc etc install_date <<< $(dumpe2fs $(mount | grep 'on / ' | awk '{print $1}') 2>/dev/null | grep 'Filesystem created:')
[[ "$install_date" =~ ^\ *$ ]] && install_date='Unknown'
echo "Installation date: $install_date"

# Hostname: yyyyy
echo -n 'Hostname: '
uname -n

IFS=',' read -r -a uptime_arr <<< "$(uptime)"
uptime_str="${uptime_arr[0]##* up}"
uptime_str=${uptime_str//  / }
uptime_users="${uptime_arr[1]% *}"
uptime_users="${uptime_users// /}"

# Uptime: XX days
echo "Uptime:$uptime_str"

# Processes running: 56684
echo -n 'Processes running: '
proc_running=$(ps -A | wc -l)
let proc_running-- # w/o titles
echo $proc_running

# User logged in: 665
echo "User logged in: $uptime_users"

# <Iface #1 name>: IP/mask
# <Iface #2 name>: IP/mask
# ...
# <Iface #N name>: IP/mask
ip address show 2>/dev/null | awk '#
BEGIN {
   print "--- Network ---"
   }

/^[0-9]+/ {
   IfaceName = $2;
   ifaceAddr[IfaceName] = "--";
   }

$1 == "inet" {
   if (ifaceAddr[IfaceName] == "--") {
      ifaceAddr[IfaceName] = $2;
   } else {
      ifaceAddr[IfaceName] = ifaceAddr[IfaceName] ", " $2;
      }
   }

END {
   IfaceNum=1;
   for (IfaceName in ifaceAddr) {
      printf("%s %s\n", IfaceName, ifaceAddr[IfaceName]);
      IfaceNum++;
      }
   }
#'

