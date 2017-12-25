#!/usr/bin/env bash
## title........: ship.sh
## description..: a simple, handy network addressing multitool with plenty of features
## author.......: sotirios m. roussis a.k.a. xtonousou - xtonousou@gmail.com
## date.........: 20170911
## usage........: bash ship.sh [options]? [arguments]?
## bash version.: 3.2 or later
## license .....: gplv3+

### flags
if [[ "${COLOR}" -eq 1 ]]; then
  declare -ra color_arr=(
    "\e[1;0m"      # normal  ## color_arr[0]
    "\e[1;31;40m"  # red     ## color_arr[1]
    "\e[1;32;40m"  # green   ## color_arr[2]
    "\e[1;33;40m"  # orange  ## color_arr[3]
    "\e[1;34;40m"  # cyan    ## color_arr[4]
    "\e[1;35;40m"  # magenta ## color_arr[5]
  )
elif [[ "${COLOR}" -eq 2 ]]; then
  declare -ra color_arr=(
    "\e[1;0m"      # normal  ## color_arr[0]
    "\e[1;32;40m"  # green   ## color_arr[1]
    "\e[1;31;40m"  # red     ## color_arr[2]
    "\e[1;35;40m"  # magenta ## color_arr[3]
    "\e[1;33;40m"  # orange  ## color_arr[4]
    "\e[1;34;40m"  # cyan    ## color_arr[5]
  )
elif [[ "${COLOR}" -eq 3 ]]; then
  declare -ra color_arr=(
    "\e[1;0m"      # normal  ## color_arr[0]
    "\e[1;34;40m"  # cyan    ## color_arr[1]
    "\e[1;35;40m"  # magenta ## color_arr[2]
    "\e[1;32;40m"  # green   ## color_arr[3]
    "\e[1;31;40m"  # red     ## color_arr[4]
    "\e[1;33;40m"  # orange  ## color_arr[5]
  )
elif [[ "${COLOR}" -eq 4 ]]; then
  declare -ra color_arr=(
    "\e[1;0m"      # normal  ## color_arr[0]
    "\e[7;31;40m"  # red     ## color_arr[1]
    "\e[7;32;40m"  # green   ## color_arr[2]
    "\e[7;33;40m"  # orange  ## color_arr[3]
    "\e[7;34;40m"  # cyan    ## color_arr[4]
    "\e[7;35;40m"  # magenta ## color_arr[5]
  )
fi

[[ "${DEBUG}" -eq 1 ]] && set -x &> /dev/null
[[ "${SILENT}" -eq 1 ]] && readonly SILENT=1 &> /dev/null
[[ "${NOCHECK}" -eq 1 ]] && readonly NOCHECK=1 &> /dev/null

### script's info
readonly version="2.6.3"
readonly script_name="${0%.*}"

### author's info
readonly author="sotirios m. roussis"
readonly author_nickname="xtonousou"
readonly gmail="${author_nickname}@gmail.com"
readonly github="https://github.com/${author_nickname}"

### locations
readonly google="google.com"
readonly google_dns="8.8.8.8"
declare -ra public_ip_hosts_arr=(
  "icanhazip.com"
  "ident.me"
  "ipinfo.io/ip"
  "wgetip.com"
  "wtfismyip.com/text"
)

### timeouts
readonly short_timeout="2"
readonly timeout="6"
readonly long_timeout="17"

### dialogs
readonly dialog_under_development="under development"
readonly dialog_press_ctrlc="press [ctrl+c] to stop"
if [[ ! "${SILENT}" ]]; then
  readonly dialog_error="try ${script_name} -h or ${script_name} --help for more information"
  readonly dialog_aborting="aborting"
  readonly dialog_invalid_bash="bash 3.2 or newer is required"
  readonly dialog_no_arguments="no arguments"
  readonly dialog_no_internet="internet connection unavailable"
  readonly dialog_no_ipv6="ipv6 unavailable"
  readonly dialog_no_ipv6_module="ipv6 is supported but the 'ipv6' module is not loaded"
  readonly dialog_no_local_connection="local connection unavailable"
  readonly dialog_destination_unreachable="destination is unreachable"
  readonly dialog_server_is_down="destination is unreachable. server may be down or has connection issues"
  readonly dialog_no_valid_mask="the netmask is invalid"
  readonly dialog_no_valid_cidr="the cidr is invalid"
  readonly dialog_no_valid_addresses="no valid ipv4, ipv6 or mac addresses found"
  readonly dialog_no_tracepath6="tracepath6 is missing, will use tracepath with no ipv6 compatibility"
  readonly dialog_no_trace_command="you must install at least one of the following tools to perform this action: tracepath, traceroute, mtr"
  readonly dialog_root_permissions="${script_name} requires root privileges for this action"
fi

########################################################################
#                                                                      #
#  helpful functions to print or check, verify and test various things #
#                                                                      #
########################################################################

# initializes a set of regexps variables (ipv4, ipv6, with and without cidr).
init_regexes() {

  # mac
  regex_mac="([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}"
  # ipv4
  regex_ipv4="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|"
  regex_ipv4+="(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"
  # ipv4 with cidr notation
  regex_ipv4_cidr="(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|"
  regex_ipv4_cidr+="25[0-5])\.){3}([0-9]|""[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|"
  regex_ipv4_cidr+="25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))"
  # ipv6
  regex_ipv6="([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|"
  regex_ipv6+="([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:"
  regex_ipv6+="[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4})"
  regex_ipv6+="{1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|"
  regex_ipv6+="([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]"
  regex_ipv6+="{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:"
  regex_ipv6+="[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|"
  regex_ipv6+="fe08:(:[0-9a-fA-F]{1,4}){2,2}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4})"
  regex_ipv6+="{0,1}:){0,1}${regex_ipv4}|([0-9a-fA-F]{1,4}:){1,4}:${regex_ipv4}"
  # ipv6 with cidr notation
  regex_ipv6_cidr="^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|"
  regex_ipv6_cidr+="(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|"
  regex_ipv6_cidr+="2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|"
  regex_ipv6_cidr+=":))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|"
  regex_ipv6_cidr+=":((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|"
  regex_ipv6_cidr+="[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]"
  regex_ipv6_cidr+="{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|"
  regex_ipv6_cidr+="[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|"
  regex_ipv6_cidr+="(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|"
  regex_ipv6_cidr+="((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)"
  regex_ipv6_cidr+="(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]"
  regex_ipv6_cidr+="{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4})"
  regex_ipv6_cidr+="{0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|"
  regex_ipv6_cidr+="[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]"
  regex_ipv6_cidr+="{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|"
  regex_ipv6_cidr+="1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|"
  regex_ipv6_cidr+="(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}"
  regex_ipv6_cidr+=":((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|"
  regex_ipv6_cidr+="[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|"
  regex_ipv6_cidr+="1[0-1][0-9]|12[0-8]))?$"

  return 0
}

# convert a decimal to binary.
dec_to_bin() {

  local d2b

  d2b=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})

  printf "${d2b[${1}]}"

  return 0
}

# convert a decimal to a hexadecimal.
dec_to_hex() {

  printf "%#X" "${1}"

  return 0
}

# convert binary to a decimal.
bin_to_dec() {

  printf "$((2#${1}))"

  return 0
}

# returns the integer representation of an ip arg,
# passed in ascii dotted-decimal notation (x.x.x.x).
dotted_quad_ip_to_decimal() {

  local a b c d

  IFS=. read -r a b c d <<< "${1}"
  
  printf '%d\n' "$(( a * 256 ** 3 + b * 256 ** 2 + c * 256 + d ))"

  return 0
}

# prints a message while checking a network host.
print_check() {

  [[ ! "${SILENT}" ]] \
    && printf "checking ${color_arr[2]}%s${color_arr[0]} ..." "${1}"

  return 0
}

# clears previous line.
clear_line() {

  printf "\r\033[K"

  return 0
}

# prints a list of most common ports with protocols.
print_port_protocol_list() {

  local item

  declare -ra ports_array=(
    "20-21" "22" "23" "25" "53" "67-68" "69" "80" "110" "123" "137-139" "143"
    "161-162" "179" "389" "443" "636" "989-990"
  )

  declare -ra ports_tcp_udp_array=(
    "tcp" "tcp" "tcp" "tcp" "tcp/udp" "udp" "udp" "tcp" "tcp" "udp" "tcp/udp"
    "tcp" "tcp/udp" "tcp" "tcp/udp" "tcp" "tcp/udp" "tcp"
  )

  declare -ra ports_protocol_array=(
    "ftp" "ssh" "telnet" "smtp" "dns" "dhcp" "tftp" "http" "popv3" "ntp"
    "netbios" "imap" "snmp" "bgp" "ldap" "https" "ldaps" "ftp over tls/ssl"
  )

  for item in "${!ports_array[@]}"; do
    printf "%-17s%-8s%s\n" "${ports_protocol_array[item]}" "${ports_tcp_udp_array[item]}" "${ports_array[item]}"
  done

  return 0
}

# used with zero parameters: exit 1.
# used with one parameter  : echoes parameter, usually error dialogs.
# used with two parameters : invalid option, then echoes first parameter, usually error dialogs.
error_exit() {

  [[ ! "${SILENT}" ]] \
    && [[ -z "${1}" ]] && clear_line && exit 1 \
      || [[ -z "${2}" ]] \
        && clear_line \
        && printf "%s\n" "${1}" \
        && exit 1 \
      || clear_line \
        && printf "%s\n" "${script_name}: invalid option '${2}'" \
        && printf "%s\n" "${1}" && \
        exit 1 \
    || exit 1
}

# exits ship, if ping fails to reach $1 in an amount of time.
check_destination() {

  local clean_destination returned_value

  clean_destination=$(printf "${1}" | sed 's/^http\(\|s\):\/\///g' | cut --fields=1 --delimiter="/")

  timeout "${long_timeout}" ping -q -c 1 "${clean_destination}" &>/dev/null \
    || returned_value="${?}"

  [[ "${returned_value}" -ge 2 ]] && error_exit "${dialog_destination_unreachable}"

  return 0
}

check_http_code() {

  local http_code

  http_code=$(curl --location --output /dev/null --silent --head --write-out '%{http_code}\n' "${1}")

  return "${http_code}"
}

# checks network connection (local or internet).
check_connectivity() {

  case "${1}" in
  "--local")
    ip route | grep ^default &>/dev/null \
      || error_exit "${dialog_no_local_connection}"
  ;;
  "--internet")
    [[ $(check_http_code "google.com"; echo "${?}") = 200 ]] \
      || error_exit "${dialog_no_internet}"
  ;;
  esac

  return 0
}

# checks if a network address is valid.
check_dotted_quad_address() {

  local decimal_points IFS part_a part_b part_c part_d

  decimal_points=$(printf "${1}" | grep --only-matching "\\." | wc --lines)
  # check if there are three dots
  [[ "${decimal_points}" -ne 3 ]] && show_usage_ipcalc && error_exit

  IFS=.
  read -r part_a part_b part_c part_d <<< "${1}"

  # check for non numerical values
  [[ ! "${part_a}" =~ ^[0-9]+$ || ! "${part_b}" =~ ^[0-9]+$ || ! "${part_c}" =~ ^[0-9]+$ || ! "${part_d}" =~ ^[0-9]+$ ]] \
    && show_usage_ipcalc \
    && error_exit

  # check if any part is empty
  [[ ! "${part_a}" || ! "${part_b}" || ! "${part_c}" || ! "${part_d}" ]] \
    && show_usage_ipcalc \
    && error_exit

  # check if any part of the address is < 0 or > 255
  [[ "${part_a}" -lt 0 || "${part_a}" -gt 255 || "${part_b}" -lt 0 || "${part_b}" -gt 255 || "${part_c}" -lt 0 || "${part_c}" -gt 255 || "${part_d}" -lt 0 || "${part_d}" -gt 255 ]] \
    && show_usage_ipcalc \
    && error_exit

  IFS=

  return 0
}

# checks if ipv6 is available, if not exit.
check_ipv6() {

  grep -i "ipv6" "/proc/modules" &> /dev/null \
    || printf "%s\n" "${dialog_no_ipv6_module}"
  
  [[ -f "/proc/net/if_inet6" ]] \
    || error_exit "${dialog_no_ipv6}"

  return 0
}

# checks if an argument is passed, if not exit.
# $1=error message, $2=argument
check_for_missing_args() {

  [[ -z "${2}" ]] && error_exit "${1}"

  return 0
}

# numerical verification.
check_if_parameter_is_positive_integer() {

  [[ ! "${1}" =~ ^[0-9]+$ ]] \
    && error_exit "${1} is not a positive integer. ${dialog_aborting}" "${1}"

  return 0
}

# checks for root privileges.
check_root_permissions() {

  [[ "$(id -u)" -ne 0 ]] \
    && error_exit "${dialog_root_permissions}"

  return 0
}

# checks bash version. minimum is version 3.2.
check_bash_version() {

  [[ "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -lt 32 ]] \
    && error_exit "${dialog_invalid_bash}"

  return 0
}

# deletes every file that is created by this script. usually in /tmp.
mr_proper() {

  rm --recursive --force "/tmp/${script_name^^}"*

  return 0
}

# background tasks' handler.
handle_jobs() {

  local job

  for job in $(jobs -p); do
    wait "${job}"
  done

  return 0
}

# traps int and sigtstp.
trap_handler() {

  local yesno
  
  printf "\n"
  while [[ ! "${yesno}" =~ ^[YyNn]$ ]]; do
    printf "%s " "exit? [y/n]"
    read -r yesno &>/dev/null
  done

  [[ "${yesno}" = "N" ]] && yesno="n"
  [[ "${yesno}" = "Y" ]] && yesno="y"
  [[ "${yesno}" = "y" ]] && handle_jobs && exit 0

  return 0
}

########################################################################
#                                                                      #
#  main script's functions in alphabetical order based on show_usage() #
#                                                                      #
########################################################################

# prints active network interfaces with their ipv4 address.
show_ipv4() {

  local item
  declare -a ipv4_array
  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))

  for item in "${!interfaces_array[@]}"; do
    ipv4_array[item]=$(ip -4 address show dev "${interfaces_array[item]}" | awk -v family=inet '$0 ~ family {print $2}' | cut --delimiter="/" --fields=1)
    printf "%s %s\n" "${interfaces_array[item]}" "${ipv4_array[item]}"
  done

  return 0
}

# prints active network interfaces with their ipv6 address.
show_ipv6() {

  [[ ! "${NOCHECK}" ]] && check_ipv6

  local item
  declare -a ipv6_array
  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))

  for item in "${!interfaces_array[@]}"; do
    ipv6_array[item]=$(ip -6 address show dev "${interfaces_array[item]}" | awk -v family="inet6" 'tolower($0) ~ family {print $2}' | cut --delimiter="/" --fields=1)
    printf "%s %s\n" "${interfaces_array[item]}" "${ipv6_array[item]}"
  done

  return 0
}

# prints all "basic" info.
show_all() {

  [[ ! "${NOCHECK}" ]] && check_ipv6

  local mac_of driver_of gateway item
  declare -a ipv4_array ipv6_array
  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))

  for item in "${!interfaces_array[@]}"; do
    ipv4_array[item]=$(ip -4 address show dev "${interfaces_array[item]}" | awk -v family=inet '$0 ~ family {print $2}' | cut --delimiter="/" --fields=1)
    ipv6_array[item]=$(ip -6 address show dev "${interfaces_array[item]}" | awk -v family="inet6" 'tolower($0) ~ family {print $2}' | cut --delimiter="/" --fields=1)
    [[ -f "/sys/class/net/${interfaces_array[item]}/phy80211/device/uevent" ]] \
      && driver_of=$(awk -F '=' 'tolower($0) ~ /driver/{print $2}' "/sys/class/net/${interfaces_array[item]}/phy80211/device/uevent") \
      || driver_of=$(awk -F '=' 'tolower($0) ~ /driver/{print $2}' "/sys/class/net/${interfaces_array[item]}/device/uevent")
    mac_of=$(awk '{print $0}' "/sys/class/net/${interfaces_array[item]}/address" 2> /dev/null)
    gateway=$(ip route | awk "/${interfaces_array[item]}/ && tolower(\$0) ~ /default/ {print \$3}")
    printf "%s %s %s %s %s %s\n" "${interfaces_array[item]}" "${driver_of}" "${mac_of}" "${gateway}" "${ipv4_array[item]}" "${ipv6_array[item]}"
  done

  return 0
}

# prints all available network interfaces.
show_all_interfaces() {

  ip link show | \
    awk '/^[0-9]/{printf "%s ", $2}' | sed 's/://g' | sed 's/ *$//g'
  printf "\n"
}

# prints the driver used of active interface.
show_driver() {
  
  local driver_of item
  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))

  for item in "${!interfaces_array[@]}"; do
    [[ -f "/sys/class/net/${interfaces_array[item]}/phy80211/device/uevent" ]] \
      && driver_of=$(awk -F '=' 'tolower($0) ~ /driver/{print $2}' "/sys/class/net/${interfaces_array[item]}/phy80211/device/uevent") \
      || driver_of=$(awk -F '=' 'tolower($0) ~ /driver/{print $2}' "/sys/class/net/${interfaces_array[item]}/device/uevent")
    printf "%s %s\n" "${interfaces_array[item]}" "${driver_of}" 
  done

  return 0
}

# prints the external ip address/es. if $1 is empty prints user's public ip, if not, $1 should be like example.com. otherwise, if more arguments are passed, it prints their external ips with their domain name at right.
show_ip_from() {

  local http_code temp_file random_source input item host

  random_source="${public_ip_hosts_arr["$(( RANDOM % ${#public_ip_hosts_arr[@]} ))"]}"
  temp_file="/tmp/${script_name^^}.ips"
  
  touch "${temp_file}"

  if [[ -z "${1}" ]]; then
    [[ ! "${SILENT}" ]] && print_check "${random_source}"
    [[ ! "${NOCHECK}" ]] \
      && check_destination "${random_source}"

    clear_line
    [[ ! "${SILENT}" ]] && printf "%s" "grabbing ip ..."
    curl "${random_source}" --silent --output "${temp_file}"

    clear_line
    awk '{print $0}' "${temp_file}"
  elif [[ "${#}" -eq 1 ]]; then
    [[ ! "${SILENT}" ]] && print_check "${1}"
    [[ ! "${NOCHECK}" ]] && check_destination "${1}"

    clear_line    
    input=$(printf "${1}" | sed --expression='s/^http\(\|s\):\/\///g' --expression='s/^`//' --expression='s/`//' --expression='s/`$//' | cut --fields=1 --delimiter="/")

    ping_source() {
      for item in {1..10}; do
        ping -c 1 -w "${long_timeout}" "${input}" 2> /dev/null | awk -F '[()]' '/PING/{print $2}' >> "${temp_file}" &
      done
      handle_jobs
    }

    [[ ! "${SILENT}" ]] && printf "%s ${color_arr[2]}%s${color_arr[0]} %s" "pinging" "${1}" "..."
    ping_source

    clear_line
    sort --version-sort --unique "${temp_file}"
  elif [[ "${#}" -gt 1 ]]; then
    for host in "${@}"; do
      [[ ! "${SILENT}" ]] && print_check "${host}"
      [[ ! "${NOCHECK}" ]] && check_destination "${host}"

      clear_line    
      input=$(printf "${host}" | sed --expression='s/^http\(\|s\):\/\///g' --expression='s/^`//' --expression='s/`//' --expression='s/`$//' | cut --fields=1 --delimiter="/")

      [[ ! "${SILENT}" ]] && printf "%s ${color_arr[2]}%s${color_arr[0]} %s" "pinging" "${input}" "..."

      for item in {1..5}; do
        ( printf "%s %s\n" "$(ping -c 1 -w "${long_timeout}" "${input}" 2> /dev/null | awk -F '[()]' '/PING/{print $2}')" "${input}" &>> "${temp_file}" ) &
      done
      clear_line

      handle_jobs
      sort --version-sort --unique "${temp_file}"
    done
  fi

  return 0
}

# prints all valid ipv4, ipv6 and mac addresses extracted from file.
show_ips_from_file() {

  local file
    
  [[ -z "${1}" ]] && error_exit "no file was specified. ${dialog_aborting}"
  for file in "${@}"; do
    [[ ! -f "${file}" ]] && error_exit "${color_arr[3]}${file}${color_arr[0]} does not exist. ${dialog_aborting}"
  done

  local temp_file_ipv4 temp_file_ipv6 temp_file_mac
  local is_temp_file_ipv4_empty is_temp_file_ipv6_empty is_temp_file_mac_empty

  temp_file_ipv4="/tmp/${script_name^^}.ipv4"
  temp_file_ipv6="/tmp/${script_name^^}.ipv6"
  temp_file_mac="/tmp/${script_name^^}.mac"

  touch "${temp_file_ipv4}"
  touch "${temp_file_ipv6}"
  touch "${temp_file_mac}"

  init_regexes

  for file in "${@}"; do
    grep --extended-regexp --only-matching "${regex_ipv4}" "${file}" 2>/dev/null >> "${temp_file_ipv4}"
    grep --extended-regexp --only-matching "${regex_ipv6}" "${file}" 2>/dev/null >> "${temp_file_ipv6}"
    grep --extended-regexp --only-matching "${regex_mac}" "${file}" 2>/dev/null >> "${temp_file_mac}"
  done

  sort --version-sort --unique --output="${temp_file_ipv4}" "${temp_file_ipv4}"
  sort --version-sort --unique --output="${temp_file_ipv6}" "${temp_file_ipv6}"
  sort --version-sort --unique --output="${temp_file_mac}" "${temp_file_mac}"

  [[ -s "${temp_file_ipv4}" ]] && is_temp_file_ipv4_empty=0 || is_temp_file_ipv4_empty=1
  [[ -s "${temp_file_ipv6}" ]] && is_temp_file_ipv6_empty=0 || is_temp_file_ipv6_empty=1
  [[ -s "${temp_file_mac}" ]] && is_temp_file_mac_empty=0 || is_temp_file_mac_empty=1

  case "${is_temp_file_ipv4_empty}:${is_temp_file_ipv6_empty}:${is_temp_file_mac_empty}" in
  0:0:0) # ipv4, ipv6 and mac addresses
    paste "${temp_file_ipv4}" "${temp_file_ipv6}" "${temp_file_mac}" | \
      awk -F '\t' '{printf("%-15s │ %-39s │ %s\n", $1, tolower($2), tolower($3))}'
  ;;
  0:0:1) # only ipv4 and ipv6 addresses
    paste "${temp_file_ipv4}" "${temp_file_ipv6}" | \
      awk -F '\t' '{printf("%-15s │ %s\n", $1, tolower($2))}'
  ;;
  0:1:0) # only ipv4 and mac addresses
    paste "${temp_file_ipv4}" "${temp_file_mac}" | \
      awk -F '\t' '{printf("%-15s │ %s\n", $1, tolower($2))}'
  ;;
  0:1:1) # only ipv4 addresses
    paste "${temp_file_ipv4}" | \
      awk -F '\t' '{printf("%s\n", $1)}'
  ;;
  1:0:0) # only ipv6 and mac addresses
    paste "${temp_file_ipv6}" "${temp_file_mac}" | \
      awk -F '\t' '{printf("%-39s │ %s\n", tolower($1), tolower($2))}'
  ;;
  1:0:1) # only ipv6 addresses
    paste "${temp_file_ipv6}" | \
      awk -F '\t' '{printf("%s\n", tolower($1))}'
  ;;
  1:1:0) # only mac addresses
    paste "${temp_file_mac}" | \
      awk -F '\t' '{printf("%s\n", tolower($1))}'
  ;;
  1:1:1) # none
    error_exit "${dialog_no_valid_addresses}"
  ;;
  esac

  return 0
}

# prints active network interfaces and their gateway.
show_gateway() {
  
  local gateway item
  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))

  for item in "${!interfaces_array[@]}"; do
    gateway=$(ip route | awk "/${interfaces_array[item]}/ && tolower(\$0) ~ /default/ {print \$3}")
    printf "%s %s\n" "${interfaces_array[item]}" "${gateway}"
  done

  return 0
}

# scans live hosts on network and prints their ipv4 address with or without mac address. icmp and arp.
show_live_hosts() {
  
  [[ ! "${NOCHECK}" ]] && check_root_permissions
  
  local online_interface network_ip network_ip_cidr filtered_ip host

  online_interface=$(ip route get "${google_dns}" | awk -F 'dev ' 'NR == 1 {split($2, a, " "); print a[1]}')
  network_ip=$(ip route | awk "/${online_interface}/ && /src/ {print \$1}" | cut --fields=1 --delimiter="/")
  network_ip_cidr=$(ip route | awk "/${online_interface}/ && /src/ {print \$1}")
  filtered_ip=$(printf "${network_ip}" | awk 'BEGIN{FS=OFS="."} NF--')

  ip -statistics neighbour flush all &>/dev/null
  
  [[ ! "${SILENT}" ]] && printf "%s ${color_arr[2]}%s${color_arr[0]}, %s %s" "pinging" "${network_ip_cidr}" "please wait" "..."
  for host in {1..254}; do
    ping "${filtered_ip}.${host}" -c 1 -w "${long_timeout}" &>/dev/null &
  done
  handle_jobs
  
  clear_line
  init_regexes
  
  case "${1}" in
  "--normal")
    ip neighbour | \
      awk 'tolower($0) ~ /reachable|stale|delay|probe/{print $1}' | \
        sort --version-sort --unique
  ;;
  "--mac")      
    ip neighbour | \
      awk 'tolower($0) ~ /reachable|stale|delay|probe/{printf ("%5s\t%s\n", $1, $5)}' | \
        sort --version-sort --unique
  ;;
  esac

  return 0
}

# prints active network interfaces.
show_interfaces() {

  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))

  printf "%s\n" "${interfaces_array[@]}"

  return 0
}

# prints a list of private and reserved ips. $1 "normal" or "cidr".
show_bogon_ips() {

  local ip

  declare -ar ipv4_bogon_array=(
    "0.0.0.0" "10.0.0.0" "100.64.0.0" "127.0.0.0" "127.0.53.53" "169.254.0.0"
    "172.16.0.0" "192.0.0.0" "192.0.2.0" "192.168.0.0" "198.18.0.0"
    "198.51.100.0" "203.0.113.0" "224.0.0.0" "240.0.0.0" "255.255.255.255"
  )

  declare -ar ipv6_bogon_array=(
    "::" "::1" "::ffff:0:0" "::" "100::" "2001:10::" "2001:db8::" "fc00::"
    "fe80::" "fec0::" "ff00::"
  )

  declare -ar ipv4_cidr_bogon_array=(
    "0.0.0.0/8" "10.0.0.0/8" "100.64.0.0/10" "127.0.0.0/8" "127.0.53.53/8"
    "169.254.0.0/16" "172.16.0.0/12" "192.0.0.0/24" "192.0.2.0/24" "192.168.0.0/16"
    "198.18.0.0/15" "198.51.100.0/24" "203.0.113.0/24" "224.0.0.0/4" "240.0.0.0/4"
    "255.255.255.255/32"
  )

  declare -ar ipv6_cidr_bogon_array=(
    "::/128" "::1/128" "::ffff:0:0/96" "::/96" "100::/64" "2001:10::/28"
    "2001:db8::/32" "fc00::/7" "fe80::/10" "fec0::/10" "ff00::/8"
  )

  declare -ar ipv4_dialog_array=(
    "'this' network" "private-use networks" "carrier-grade nat" "loopback"
    "name collision occurrence" "link local" "private-use networks"
    "ietf protocol assignments" "test-net-1" "private-use networks"
    "network interconnect device benchmark testing" "test-net-2" "test-net-3"
    "multicast" "reserved for future use" "limited broadcast"
  )

  declare -ar ipv6_dialog_array=(
    "node-scope unicast unspecified address" "node-scope unicast loopback address"
    "ipv4-mapped addresses" "ipv4-compatible addresses"
    "remotely triggered black hole addresses"
    "overlay routable cryptographic hash identifiers (orchid)"
    "documentation prefix" "unique local addresses (ula)" "link-local unicast"
    "site-local unicast (deprecated)"
    "multicast (note: ff0e:/16 is global scope and may appear on the global internet)"
  )

  case "${1}" in
  "--normal")
    for ip in "${!ipv4_dialog_array[@]}"; do
      printf "%-16s%s\n" "${ipv4_bogon_array[ip]}" "${ipv4_dialog_array[ip]}"
    done
    
    for ip in "${!ipv6_dialog_array[@]}"; do
      printf "%-16s%s\n" "${ipv6_bogon_array[ip]}" "${ipv6_dialog_array[ip]}"
    done
  ;;
  "--cidr")
    for ip in "${!ipv4_dialog_array[@]}"; do
      printf "%-19s%s\n" "${ipv4_cidr_bogon_array[ip]}" "${ipv4_dialog_array[ip]}"
    done
    
    for ip in "${!ipv6_dialog_array[@]}"; do
      printf "%-19s%s\n" "${ipv6_cidr_bogon_array[ip]}" "${ipv6_dialog_array[ip]}"
    done
  ;;
  esac

  return 0
}

# prints active network interfaces with their mac address.
show_mac() {
  
  local mac_of item
  declare -ar interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))
  
  for item in "${!interfaces_array[@]}"; do
    mac_of=$(awk '{print $0}' "/sys/class/net/${interfaces_array[item]}/address" 2> /dev/null)
    printf "%s %s\n" "${interfaces_array[item]}" "${mac_of}"
  done

  return 0
}

# shows neighbor table.
show_neighbor_cache() {
  
  local temp_file

  temp_file="/tmp/${script_name^^}.file"

  touch "${temp_file}"

  ip neigh \
    | awk 'tolower($0) ~ /permanent|noarp|stale|reachable|incomplete|delay|probe/{printf ("%-16s%-20s%s\n", $1, $5, $6)}' >> "${temp_file}"
  
  awk '{print $0}' "${temp_file}" | sort --version-sort

  return 0
}

# prints connections and the count of them per ip.
show_port_connections() {
  
  [[ -z "${1}" ]] && print_port_protocol_list && exit 0
  
  [[ ! "${NOCHECK}" ]] && check_root_permissions
  [[ ! "${NOCHECK}" ]] && check_if_parameter_is_positive_integer "${1}"

  init_regexes
  
  clear
  while :; do
    clear
    if [[ ! "${SILENT}" ]]; then
      printf "%s\n\n" "${dialog_press_ctrlc}"
      printf "      ${color_arr[2]}%s${color_arr[1]} %s %s ${color_arr[2]}%s\n" "┌─>" "count" "port" "──┐"
      printf "      %s %s ${color_arr[1]}%s ${color_arr[2]}%s ${color_arr[1]}%s\n" "│" "┌───────>" "ipv4" "└─>" "${1}"
      printf "    ${color_arr[2]}%s %s%s${color_arr[0]}\n" "┌─┘" "└──────────────┐"
    fi
    ss --all --numeric --process | grep --extended-regexp "${regex_ipv4}" | grep ":${1}" | awk '{print $6}' | cut --delimiter=":" --fields=1 | sort --version-sort | uniq --count
    sleep 2
  done

  return 0
}

# prints hops to a destination. $1=--ipv4|--ipv6, $2=network destination.
show_next_hops() {
  
  local filtered_input protocol tracepath_cmd traceroute_cmd mtr_cmd temp_file

  temp_file="/tmp/${script_name^^}.file"

  touch "${temp_file}"

  hash tracepath &>/dev/null && tracepath_cmd=1 || tracepath_cmd=0
  hash traceroute &>/dev/null && traceroute_cmd=1 || traceroute_cmd=0
  hash mtr &>/dev/null && mtr_cmd=1 || mtr_cmd=0

  filtered_input=$(echo "${2}" | sed 's/^http\(\|s\):\/\///g' | cut --fields=1 --delimiter="/")

  [[ ! "${NOCHECK}" ]] && check_for_missing_args "${dialog_no_arguments}" "${filtered_input}"
  
  case "${1}" in
  "--ipv4")
    protocol=4
  ;;
  "--ipv6")
    check_ipv6
    protocol=6
  ;;
  esac

  print_check "${filtered_input}"

  [[ ! "${NOCHECK}" ]] && check_destination "${filtered_input}"

  init_regexes

  trace_hops() {
    # traceroute is deprecated, nevertheless it is preferred over all
    case "${tracepath_cmd}:${traceroute_cmd}:${mtr_cmd}" in
    # if none of the tools (tracepath, traceroute, mtr) is installed
    0:0:0)
      echo -e "${dialog_no_trace_command}"
    ;;
    # if it is installed 'mtr' only
    0:0:1)
      case "${protocol}" in
      4)
        mtr -"${protocol}" --report-cycles 2 --no-dns --report "${filtered_input}" 2> /dev/null | \
          grep --extended-regexp --only-matching "${regex_ipv4}"
        ;;
      6)
        mtr -"${protocol}" --report-cycles 2 --no-dns --report "${filtered_input}" 2> /dev/null | \
          grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    # if it is installed 'traceroute' only
    0:1:0)
      case "${protocol}" in
      4)
        timeout "${short_timeout}" traceroute -"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          tail --lines=+2 | \
            grep --extended-regexp --only-matching "${regex_ipv4}"
      ;;
      6)
        timeout "${short_timeout}" traceroute -"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          tail --lines=+2 | \
            grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    # if it is installed 'traceroute' and 'mtr' only
    0:1:1)
      case "${protocol}" in
      4)
        mtr -"${protocol}" --report-cycles 2 --no-dns --report "${filtered_input}" 2> /dev/null | \
          grep --extended-regexp --only-matching "${regex_ipv4}"
      ;;
      6)
        mtr -"${protocol}" --report-cycles 2 --no-dns --report "${filtered_input}" 2> /dev/null | \
          grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    # if it is installed 'tracepath' only
    1:0:0)
      # tracepath6 workaround: many linux distributions do not have tracepath6 (it is included in manpages tho :/)
      hash tracepath6 &>/dev/null && protocol=6
      [[ "${protocol}" -eq 4 ]] && echo -e "${dialog_no_tracepath6}"

      case "${protocol}" in
      4)
        timeout "${short_timeout}" tracepath"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          awk '{print $2}' | \
            grep --extended-regexp --only-matching "${regex_ipv4}"
      ;;
      6)
        timeout "${short_timeout}" tracepath"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          awk '{print $2}' | \
            grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    # if it is installed 'tracepath' and 'mtr' only
    1:0:1)
      case "${protocol}" in
      4)
        mtr -"${protocol}" --report-cycles 2 --no-dns --report "${filtered_input}" 2> /dev/null | \
          grep --extended-regexp --only-matching "${regex_ipv4}"
      ;;
      6)
        mtr -"${protocol}" --report-cycles 2 --no-dns --report "${filtered_input}" 2> /dev/null | \
          grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    # if it is installed 'tracepath' and 'traceroute' only
    1:1:0)
      case "${protocol}" in
      4)
        timeout "${short_timeout}" traceroute -"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          tail --lines=+2 | \
            grep --extended-regexp --only-matching "${regex_ipv4}"
      ;;
      6)
        timeout "${short_timeout}" traceroute -"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          tail --lines=+2 | \
            grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    # if it is installed 'tracepath', 'traceroute' and 'mtr'
    1:1:1)
      case "${protocol}" in
      4)
        timeout "${short_timeout}" traceroute -"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          tail --lines=+2 | \
            grep --extended-regexp --only-matching "${regex_ipv4}"
      ;;
      6)
        timeout "${short_timeout}" traceroute -"${protocol}" -n "${filtered_input}" 2> /dev/null | \
          tail --lines=+2 | \
            grep --extended-regexp --only-matching "${regex_ipv6}"
      ;;
      esac
    ;;
    esac >> "${temp_file}"
  }

  [[ ! "${SILENT}" ]] \
    && clear_line \
    && echo -ne "tracing path to ${color_arr[2]}${filtered_input}${color_arr[0]} ..."
  trace_hops

  # ensure that temp_file is written on /tmp
  while [[ ! -f "${temp_file}" ]]; do
    trace_hops
  done
  
  clear_line
  awk '!seen[$0]++ {print}' "${temp_file}"

  return 0
}

# shows broadcast, network address, cisco wildcard mask, class and host range by given ipv4 address and netmask.
show_ipcalc() {

  local nobinary html cidr decimal_points bits
  local hosts host_minimum host_minimum_binary host_maximum host_maximum_binary
  local class class_description ip ip_binary netmask netmask_binary
  local wildcard wildcard_binary network_address network_address_binary
  local broadcast_address broadcast_address_binary
  local ip_part_a ip_part_b ip_part_c ip_part_d
  local netmask_part_a netmask_part_b netmask_part_c netmask_part_d
  local part_a part_b part_c part_d

  nobinary=0
  html=0

  case "${1}" in
  "-b"|"--nobinary")
    nobinary=1
    shift
  ;;
  "-h"|"--html")
    html=1
    shift
  ;;
  esac

  case "${1}" in
  "-b"|"--nobinary")
    nobinary=1
    shift
  ;;
  "-h"|"--html")
    html=1
    shift
  ;;
  esac

  init_regexes

  # pass the input into a variable
  ip=$(grep --extended-regexp "${regex_ipv4}" <<< "${1}")
  # check only the ip part
  [[ ! "${NOCHECK}" ]] && check_dotted_quad_address "$(awk -F '/' '{print $1}' <<< "${ip}")"

  # if ipv4/cidr
  if grep --extended-regexp --only-matching "${regex_ipv4_cidr}" <<< "${1}" &> /dev/null; then
    cidr=$(awk -F '/' '{print $2}' <<< "${1}")
    # if no cidr is specified then pass the default value
    [[ ! "${cidr}" ]] && cidr="24" # default notation
    # check for non numerical cidr
    [[ ! "${cidr}" =~ ^[0-9]+$ ]] && error_exit "${dialog_no_valid_cidr}"
    # check if cidr is < 0 or > 32
    [[ "${cidr}" -lt 1 || "${cidr}" -gt 32 ]] && error_exit "${dialog_no_valid_cidr}"

    # calculate netmask
    netmask=$(( 0xffffffff ^ (( 1 << ( 32 - cidr )) -1 ) ))
    netmask=$(( ( netmask >> 24 ) & 0xff )).$(( ( netmask >> 16 ) & 0xff )).$(( ( netmask >> 8 ) & 0xff )).$(( netmask & 0xff ))

    IFS=.
    # split netmask into multiple parts for better ease
    read -r netmask_part_a netmask_part_b netmask_part_c netmask_part_d <<< "${netmask}"
    # convert netmask to binary
    netmask_binary="$(dec_to_bin "${netmask_part_a}").$(dec_to_bin "${netmask_part_b}").$(dec_to_bin "${netmask_part_c}").$(dec_to_bin "${netmask_part_d}")"
  # if only ipv4 and no cidr
  elif grep --extended-regexp --only-matching "${regex_ipv4}" <<< "${1}" &> /dev/null; then
    # if no netmask was specified keep the default value
    if [[ -z "${2}" ]]; then
      netmask="255.255.255.0"
    else
      netmask="${2}"
    fi

    IFS=.
    declare -a netmask_array
    # split netmask into parts and pass them into an array
    netmask_array=($(tr " " "\n" <<< "${netmask}"))
    
    # check if netmask is valid
    [[ ! "${NOCHECK}" ]] && check_dotted_quad_address "${netmask}"
    # if netmask first part is 0
    [[ "${netmask_array[0]}" -eq 0 ]] && echo -e "${dialog_no_valid_mask}" && show_usage_subnet && error_exit
    
    # iterate through netmask and validate
    for position in "${!netmask_array[@]}"; do
      case "${netmask_array[position]}" in
      255) ;; 254) ;; 252) ;; 248) ;; 240) ;;
      224) ;; 192) ;; 128) ;;   0) ;;
      *)
        echo -e "${dialog_no_valid_mask}"
        show_usage_subnet
        error_exit
      ;;
      esac
    done

    # pass netmask array values into variables for better ease
    netmask_part_a="${netmask_array[0]}"; netmask_part_b="${netmask_array[1]}"
    netmask_part_c="${netmask_array[2]}"; netmask_part_d="${netmask_array[3]}"

    # convert netmask to binary
    netmask_binary="$(dec_to_bin "${netmask_part_a}").$(dec_to_bin "${netmask_part_b}").$(dec_to_bin "${netmask_part_c}").$(dec_to_bin "${netmask_part_d}")"
    # convert netmask to cidr
    cidr=$(echo "${netmask_binary}" | grep --only-matching 1 | wc --lines)
  else
    show_usage_subnet
    error_exit
  fi

  # remove cidr from ip address
  ip=$(awk -F '/' '{print $1}' <<< "${ip}")

  # pass ip parts into multiple variables for future checks
  read -r ip_part_a ip_part_b ip_part_c ip_part_d <<< "${ip}"
  # convert ip to binary
  ip_binary="$(dec_to_bin "${ip_part_a}").$(dec_to_bin "${ip_part_b}").$(dec_to_bin "${ip_part_c}").$(dec_to_bin "${ip_part_d}")"

  # calculate wildcard in binary
  wildcard_binary=$(tr 01 10 <<< "${netmask_binary}") # inverse the address
  # pass wildcard parts into multiple variables for future checks
  read -r part_a part_b part_c part_d <<< "${wildcard_binary}"

  # convert wildcard to decimal
  wildcard="$(bin_to_dec "${part_a}").$(bin_to_dec "${part_b}").$(bin_to_dec "${part_c}").$(bin_to_dec "${part_d}")"

  # calculate network address by => parts of ip address and parts of netmask address
  network_address=$(( ip_part_a & netmask_part_a )).$(( ip_part_b & netmask_part_b )).$(( ip_part_c & netmask_part_c )).$(( ip_part_d & netmask_part_d ))
  # split network address into parts for better ease
  part_a=$(cut --delimiter='.' --fields=1 <<< "${network_address}"); part_b=$(cut --delimiter='.' --fields=2 <<< "${network_address}")
  part_c=$(cut --delimiter='.' --fields=3 <<< "${network_address}"); part_d=$(cut --delimiter='.' --fields=4 <<< "${network_address}")
  # convert network address to binary
  network_address_binary="$(dec_to_bin "${part_a}").$(dec_to_bin "${part_b}").$(dec_to_bin "${part_c}").$(dec_to_bin "${part_d}")"

  # calculate host bits
  host_bits=$(echo "${netmask_binary}" | grep --only-matching 0 | wc --lines) # count how many 0s are there in netmask binary

  # calculate first usable ip address
  part_d=$(( part_d + 1 )) # add 1 to the last octet of the network address
  host_minimum="${part_a}.${part_b}.${part_c}.${part_d}" # merge decimal parts
  host_minimum_binary=$(dec_to_bin "${part_a}").$(dec_to_bin "${part_b}").$(dec_to_bin "${part_c}").$(dec_to_bin "${part_d}") # convert to binary

  broadcast_address_binary="${ip_binary//.}" # remove dots and merge strings together
  broadcast_address_binary="${broadcast_address_binary:0:${#broadcast_address_binary}-${host_bits}}" # remove last bits, as many as host_bits are

  # append bits to trimmed binary
  bits=$(( 32 - host_bits ))
  until [[ "${bits}" -eq 32 ]]; do
    broadcast_address_binary+="1" # append a bit every loop
    let bits+=1
  done

  # put a dot every 8th character and remove last occurence of dot
  broadcast_address_binary=$(sed --expression="s/\(.\{8\}\)/\1./g" --expression="s/\(.*\)./\1 /" <<< "${broadcast_address_binary}")

  # split broadcast address binary into parts for better ease
  part_a=$(cut --delimiter='.' --fields=1 <<< "${broadcast_address_binary}"); part_b=$(cut --delimiter='.' --fields=2 <<< "${broadcast_address_binary}")
  part_c=$(cut --delimiter='.' --fields=3 <<< "${broadcast_address_binary}"); part_d=$(cut --delimiter='.' --fields=4 <<< "${broadcast_address_binary}")
  # convert broadcast address binary to decimal
  broadcast_address="$(bin_to_dec "${part_a}").$(bin_to_dec "${part_b}").$(bin_to_dec "${part_c}").$(bin_to_dec "${part_d}")"
  
  # calculate last usable ip address
  part_d=$(bin_to_dec "${part_d}") # convert to decimal in order to substract later
  part_d=$(( part_d - 1 )) # substract 1 from the last octet of the broadcast address
  part_d=$(dec_to_bin "${part_d}") # convert to binary
  host_maximum=$(bin_to_dec "${part_a}").$(bin_to_dec "${part_b}").$(bin_to_dec "${part_c}").$(bin_to_dec "${part_d}") # merge parts and convert them to decimals
  host_maximum_binary="${part_a}.${part_b}.${part_c}.${part_d}" # merge binary parts

  # maximum number of hosts
  hosts=$(( 2 ** ( 32 - cidr ) - 2 ))
  
  # classful addressing: leading bits checking
  ip_part_a=$(dec_to_bin "${ip_part_a}") # convert first octet to binary
  # find class by checking first 0-4 bits
  case "${ip_part_a}" in
     0*) class="A" ;;
    10*) class="B" ;;
   110*) class="C" ;;
  1110*) class="D" ;;
  1111*) class="E" ;;
  esac
  
  # rfc 1918 based
  ip_part_b=$(dec_to_bin "${ip_part_b}") # convert second octet to binary
  # describe the ip address by checking the first two octets
  case "${ip_part_a}:${ip_part_b}" in
  01111111:*) class_description="loopback" ;;
  00001010:*) class_description="private internet" ;;
  10101100:0001*) class_description="private internet" ;;
  11000000:10101000) class_description="private internet" ;;
  1110*:*) class_description="multicast" ;;
  1111*:*) class_description="experimental" ;;
  esac

  # describe ip address by checking the cidr 30-32 
  case "${cidr}" in
  30)
    class_description+=", glue network ptp link"
  ;;
  31)
    class_description+=", ptp link rfc 3021"
    hosts=2
    host_minimum="${network_address}"
    host_minimum_binary="${network_address_binary}"
    ip_part_a=$(bin_to_dec "${ip_part_a}")
    ip_part_b=$(bin_to_dec "${ip_part_b}")
    # calculates properly host range
    [[ $(( ip_part_d % 2 )) -eq 0 ]] \
      && ip_part_d=$(( ip_part_d + 1 )) \
      && host_maximum="${ip_part_a}.${ip_part_b}.${ip_part_c}.${ip_part_d}" \
      && host_maximum_binary=$(dec_to_bin "${ip_part_a}").$(dec_to_bin "${ip_part_b}").$(dec_to_bin "${ip_part_c}").$(dec_to_bin "${ip_part_d}") \
      || host_maximum="${ip}" \
      || host_maximum_binary="${ip_binary}"
  ;;
  32)
    class_description+=", hostroute"
    hosts=1 # number of hosts workaround
  ;;
  esac

  IFS=
  print_with_binary() {

    printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "address:" "${ip}" "${ip_binary}"
    printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "address (dec):" "$(dotted_quad_ip_to_decimal "${ip}")"
    printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "address (hex):" "$(dec_to_hex "$(dotted_quad_ip_to_decimal "${ip}")")"
    printf "%-16s${color_arr[4]}%-21s${color_arr[1]}%s${color_arr[0]}\n" "netmask:" "${netmask} = ${cidr}" "${netmask_binary}"
    printf "%-16s${color_arr[4]}%-21s${color_arr[1]}%s${color_arr[0]}\n" "netmask (hex):" "$(dec_to_hex "$(dotted_quad_ip_to_decimal "${netmask}")")"
    printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "wildcard:" "${wildcard}" "${wildcard_binary}"
    printf "=>\n"
    [[ "${cidr}" -le 31 ]] \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "network:" "${network_address}/${cidr}" "${network_address_binary}" \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "hostmin:" "${host_minimum}" "${host_minimum_binary}" \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "hostmax:" "${host_maximum}" "${host_maximum_binary}" \
      || printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "hostroute:" "${ip}" "${ip_binary}"
    [[ "${cidr}" -le 30 ]] \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "broadcast:" "${broadcast_address}" "${broadcast_address_binary}"
    printf "%-16s${color_arr[4]}%-21s${color_arr[5]}%s${color_arr[0]}%-22s${color_arr[4]}\n" "hosts/net:" "${hosts}" "class ${class}" " ${class_description}"
    echo -e "${color_arr[0]}" # revert COLOR back to normal
  }

  print_without_binary() {
    
    printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n"               "address:" "${ip}"
    printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "address (dec):" "$(dotted_quad_ip_to_decimal "${ip}")"
    printf "%-16s${color_arr[4]}%-21s${color_arr[3]}%s${color_arr[0]}\n" "address (hex):" "$(dec_to_hex "$(dotted_quad_ip_to_decimal "${ip}")")"
    printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n"               "netmask:" "${netmask} = ${cidr}"
    printf "%-16s${color_arr[4]}%-21s${color_arr[1]}%s${color_arr[0]}\n" "netmask (hex):" "$(dec_to_hex "$(dotted_quad_ip_to_decimal "${netmask}")")"
    printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n"               "wildcard:" "${wildcard}"
    printf "=>\n"
    [[ "${cidr}" -le 31 ]] \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n" "network:"   "${network_address}/${cidr}" \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n" "hostmin:"   "${host_minimum}" \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n" "hostmax:"   "${host_maximum}" \
      || printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n" "hostroute:" "${ip}"
    [[ "${cidr}" -le 30 ]] \
      && printf "%-16s${color_arr[4]}%-21s${color_arr[0]}\n"                           "broadcast:" "${broadcast_address}"
    printf "%-16s${color_arr[4]}%-21s${color_arr[5]}%s${color_arr[0]}%-22s${color_arr[4]}\n" "hosts/net:" "${hosts}" "class ${class}" " ${class_description}"
    echo -e "${color_arr[0]}" # revert COLOR back to normal
  }

  print_html_with_binary() {

    cat << EOF
      <!doctype html>
        <html>
          <head>
            <meta charset="utf-8"/>
            <title>ship.sh</title>
            <style>
              @import url(//fonts.googleapis.com/css?family=Source+Code+Pro);

              .ascii_art {
                font-size:   10pt;
                font-family: "Source Code Pro", Courier, monospace;
                white-space: pre
                color:       green;
              }

              .text {
                font-size:   13pt;
                font-family: "Source Code Pro", Courier, monospace;
                font-weight: light;
                color:       #f0f0f0;
              }

              .ip {
                font-size:   13pt;
                font-family: "Source Code Pro", Courier, monospace;
                font-weight: 800;
                color:       #2f888b;
              }

              .binary {
                font-size:   13pt;
                font-family: "Source Code Pro", Courier, monospace;
                font-weight: light;
                color:       #0d5a63;
              }

              #inlineParagraph {
                display:     inline;
              }

              html {
                position:    relative;
                min-height:  100%;
              }
              
              body {
                margin:           0 0 100px;
                padding:          25px;
                background-color: #000000;
              }
              
              footer {
                position:         absolute;
                left:             0;
                bottom:           0;
                height:           100px;
                width:            100%;
                overflow:         hidden;
                color:            #2f888b;
              }

              table {
                border-collapse: collapse;
                border:          1px solid black;
              }

              td {
                text-align:       left;
                padding-left:     7px;
                padding-right:    7px;
              }
            </style>
        </head>
        <body>
        <a href="https://github.com/xtonousou/ship"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/38ef81f8aca64bb9a64448d0d70f1308ef5341ab/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f6461726b626c75655f3132313632312e706e67" alt="fork me on github" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png"></a>
        <table>
        <tr>
          <td class="text">address:</td>
          <td class="ip">${ip}</td>
          <td class="binary">${ip_binary}</td>
        </tr> 
        <tr>
          <td class="text">address (dec):</td>
          <td class="ip">$(dotted_quad_ip_to_decimal "${ip}")</td>
        </tr>
        <tr>
          <td class="text">address (hex):</td>
          <td class="ip">$(dec_to_hex "$(dotted_quad_ip_to_decimal "${ip}")")</td>
        </tr>
        <tr>
          <td class="text">netmask:</td>
          <td class="ip">${netmask} = ${cidr}</td>
          <td class="binary">${netmask_binary}</td>
        </tr>
        <tr>
          <td class="text">netmask (hex):</td>
          <td class="ip">$(dec_to_hex "$(dotted_quad_ip_to_decimal "${netmask}")")</td>
        </tr>
        <tr>
          <td class="text">wildcard:</td>
          <td class="ip">${wildcard}</td>
          <td class="binary">${wildcard_binary}</td>
        </tr>
        <tr>
          <td class="text">=></td>
        </tr>
EOF
    [[ "${cidr}" -le 31 ]] \
      && cat << EOF
        <tr>
          <td class="text">network:</td>
          <td class="ip">${network_address}/${cidr}</td>
          <td class="binary">${network_address_binary}</td>
        </tr>
        <tr>
          <td class="text">hostmin:</td>
          <td class="ip">${host_minimum}</td>
          <td class="binary">${host_minimum_binary}</td>
        </tr>
        <tr>
          <td class="text">hostmax:</td>
          <td class="ip">${host_maximum}</td>
          <td class="binary">${host_maximum_binary}</td>
        </tr>
EOF
    [[ "${cidr}" -eq 32 ]] \
      && cat << EOF
        <tr>
          <td class="text">hostroute:</td>
          <td class="ip">${ip}</td>
          <td class="binary">${ip_binary}</td>
        </tr>
EOF
    [[ "${cidr}" -le 30 ]] \
      && cat << EOF
        <tr>
          <td class="text">broadcast:</td>
          <td class="ip">${broadcast_address}</td>
          <td class="binary">${broadcast_address_binary}</td>
        </tr>
EOF
    cat <<- EOF
      <tr>
        <td class="text">hosts/net:</td>
        <td class="ip">${hosts}</td>
        <td><p id="inlineParagraph" class="ip">class ${class}</p><p id="inlineparagraph" class="text">&nbsp;${class_description}</p></td>
      </tr>
      </table>
      </body>
      <footer>
      <p align="center">
        made with <3 by sotirios roussis (aka. xtonousou)<br/>
        contact information: <a href="mailto:xtonousou@gmail.com">xtonousou@gmail.com</a><br/>
      </p>
      </footer>
      </html>
EOF
  }

  print_html_without_binary() {

    cat << EOF
      <!doctype html>
        <html>
          <head>
            <meta charset="utf-8"/>
            <title>ship.sh</title>
            <style>
              @import url(//fonts.googleapis.com/css?family=Source+Code+Pro);

              .ascii_art {
                font-size:   10pt;
                font-family: "Source Code Pro", Courier, monospace;
                white-space: pre
                color:       green;
              }

              .text {
                font-size:   13pt;
                font-family: "Source Code Pro", Courier, monospace;
                font-weight: light;
                color:       #f0f0f0;
              }

              .ip {
                font-size:   13pt;
                font-family: "Source Code Pro", Courier, monospace;
                font-weight: 800;
                color:       #2f888b;
              }

              #inlineparagraph {
                display:     inline;
              }

              html {
                position:    relative;
                min-height:  100%;
              }
              
              body {
                margin:           0 0 100px;
                padding:          25px;
                background-color: #000000;
              }
              
              footer {
                position:         absolute;
                left:             0;
                bottom:           0;
                height:           100px;
                width:            100%;
                overflow:         hidden;
                color:            #2f888b;
              }

              table {
                border-collapse: collapse;
                border:          1px solid black;
              }

              td {
                text-align:       left;
                padding-left:     7px;
                padding-right:    7px;
              }
            </style>
        </head>
        <body>
        <a href="https://github.com/xtonousou/ship"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/38ef81f8aca64bb9a64448d0d70f1308ef5341ab/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f6461726b626c75655f3132313632312e706e67" alt="fork me on github" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png"></a>
        <table>
        <tr>
          <td class="text">address:</td>
          <td class="ip">${ip}</td>
        </tr> 
        <tr>
          <td class="text">address (dec):</td>
          <td class="ip">$(dotted_quad_ip_to_decimal "${ip}")</td>
        </tr>
        <tr>
          <td class="text">address (hex):</td>
          <td class="ip">$(dec_to_hex "$(dotted_quad_ip_to_decimal "${ip}")")</td>
        </tr>
        <tr>
          <td class="text">netmask:</td>
          <td class="ip">${netmask} = ${cidr}</td>
        </tr>
        <tr>
          <td class="text">netmask (hex):</td>
          <td class="ip">$(dec_to_hex "$(dotted_quad_ip_to_decimal "${netmask}")")</td>
        </tr>
        <tr>
          <td class="text">wildcard:</td>
          <td class="ip">${wildcard}</td>
        </tr>
        <tr>
          <td class="text">=></td>
        </tr>
EOF
    [[ "${cidr}" -le 31 ]] \
      && cat << EOF
        <tr>
          <td class="text">network:</td>
          <td class="ip">${network_address}/${cidr}</td>
        </tr>
        <tr>
          <td class="text">hostmin:</td>
          <td class="ip">${host_minimum}</td>
        </tr>
        <tr>
          <td class="text">hostmax:</td>
          <td class="ip">${host_maximum}</td>
        </tr>
EOF
    [[ "${cidr}" -eq 32 ]] \
      && cat << EOF
        <tr>
          <td class="text">hostroute:</td>
          <td class="ip">${ip}</td>
        </tr>
EOF
    [[ "${cidr}" -le 30 ]] \
      && cat << EOF
        <tr>
          <td class="text">broadcast:</td>
          <td class="ip">${broadcast_address}</td>
        </tr>
EOF
    cat <<- EOF
      <tr>
        <td class="text">hosts/net:</td>
        <td class="ip">${hosts}</td>
        <td><p id="inlineParagraph" class="ip">class ${class}</p><p id="inlineparagraph" class="text">&nbsp;${class_description}</p></td>
      </tr>
      </table>
      </body>
      <footer>
      <p align="center">
        made with <3 by sotirios roussis (aka. xtonousou)<br/>
        contact information: <a href="mailto:xtonousou@gmail.com">xtonousou@gmail.com</a><br/>
      </p>
      </footer>
      </html>
EOF
  }

  case "${nobinary}:${html}" in
  0:0) print_with_binary ;;
  0:1) print_html_with_binary ;;
  1:0) print_without_binary ;;
  1:1) print_html_without_binary ;;
  esac

  return 0
}

# extracts valid ipv4, ipv6 and mac addresses from urls.
show_ips_from_online_documents() {

  check_for_missing_args "no url was specified. ${dialog_aborting}" "${1}"

  local http_code document
  local temp_file_ipv4 temp_file_ipv6 temp_file_mac temp_file_html
  local is_temp_file_ipv4_empty is_temp_file_ipv6_empty is_temp_file_mac_empty

  temp_file_ipv4="/tmp/${script_name^^}.ipv4"
  temp_file_ipv6="/tmp/${script_name^^}.ipv6"
  temp_file_mac="/tmp/${script_name^^}.mac"
  temp_file_html="/tmp/${script_name^^}.html"

  touch "${temp_file_ipv4}" "${temp_file_ipv6}" "${temp_file_mac}" "${temp_file_html}"

  init_regexes

  for document in "${@}"; do
    [[ ! "${NOCHECK}" ]] && check_http_code "${document}"

    wget "${document}" -qo- >> "${temp_file_html}"

    grep --extended-regexp --only-matching "${regex_ipv4}" "${temp_file_html}" >> "${temp_file_ipv4}"
    grep --extended-regexp --only-matching "${regex_ipv6}" "${temp_file_html}" >> "${temp_file_ipv6}"
    grep --extended-regexp --only-matching "${regex_mac}" "${temp_file_html}" >> "${temp_file_mac}"
  done

  [[ -s "${temp_file_ipv4}" ]] && is_temp_file_ipv4_empty=0 || is_temp_file_ipv4_empty=1
  [[ -s "${temp_file_ipv6}" ]] && is_temp_file_ipv6_empty=0 || is_temp_file_ipv6_empty=1
  [[ -s "${temp_file_mac}" ]] && is_temp_file_mac_empty=0 || is_temp_file_mac_empty=1

  sort --version-sort --unique --output="${temp_file_ipv4}" "${temp_file_ipv4}"
  sort --version-sort --unique --output="${temp_file_ipv6}" "${temp_file_ipv6}"
  sort --version-sort --unique --output="${temp_file_mac}" "${temp_file_mac}"

  case "${is_temp_file_ipv4_empty}:${is_temp_file_ipv6_empty}:${is_temp_file_mac_empty}" in
  0:0:0) # ipv4, ipv6 and mac addresses
    paste "${temp_file_ipv4}" "${temp_file_ipv6}" "${temp_file_mac}" | \
      awk -F '\t' '{printf("%-15s │ %-39s │ %s\n", $1, tolower($2), tolower($3))}'
  ;;
  0:0:1) # only ipv4 and ipv6 addresses
    paste "${temp_file_ipv4}" "${temp_file_ipv6}" | \
      awk -F '\t' '{printf("%-15s │ %s\n", $1, tolower($2))}'
  ;;
  0:1:0) # only ipv4 and mac addresses
    paste "${temp_file_ipv4}" "${temp_file_mac}" | \
      awk -F '\t' '{printf("%-15s │ %s\n", $1, tolower($2))}'
  ;;
  0:1:1) # only ipv4 addresses
    paste "${temp_file_ipv4}" | \
      awk -F '\t' '{printf("%s\n", $1)}'
  ;;
  1:0:0) # only ipv6 and mac addresses
    paste "${temp_file_ipv6}" "${temp_file_mac}" | \
      awk -F '\t' '{printf("%-39s │ %s\n", tolower($1), tolower($2))}'
  ;;
  1:0:1) # only ipv6 addresses
    paste "${temp_file_ipv6}" | \
      awk -F '\t' '{printf("%s\n", tolower($1))}'
  ;;
  1:1:0) # only mac addresses
    paste "${temp_file_mac}" | \
      awk -F '\t' '{printf("%s\n", tolower($1))}'
  ;;
  1:1:1) # none
    error_exit "${dialog_no_valid_addresses}"
  ;;
  esac

  return 0
}

# prints script's version and author's info.
show_version() {

  echo -e "${color_arr[4]}"
  echo -e "   ▄▄▄▄▄    ▄  █ ▄█ █ ▄▄"
  echo -e "  █     ▀▄ █   █ ██ █   █ \t ${color_arr[0]}author .: ${color_arr[4]}${author} - xtonousou"
  echo -e "▄  ▀▀▀▀▄   ██▀▀█ ██ █▀▀▀ \t ${color_arr[0]}mail ...: ${color_arr[4]}${gmail}"
  echo -e " ▀▄▄▄▄▀    █   █ ▐█ █ \t\t ${color_arr[0]}github .: ${color_arr[4]}${github}"
  echo -e "              █   ▐  █ \t\t ${color_arr[0]}version : ${color_arr[4]}${version}"
  echo -e "             ▀        ▀"
  echo -e "${color_arr[0]}"

  return 0
}

# prints active network interfaces with their ipv4 address and cidr suffix.
show_ipv4_cidr() {

  local item
  declare -ra interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))
  declare -a ipv4_cidr_array
  
  for item in "${!interfaces_array[@]}"; do
    ipv4_cidr_array[item]=$(ip -4 address show dev "${interfaces_array[item]}" | awk -v family=inet '$0 ~ family {print $2}')
    echo "${interfaces_array[item]}" "${ipv4_cidr_array[item]}"
  done

  return 0
}

# prints active network interfaces with their ipv6 address and cidr suffix.
show_ipv6_cidr() {

  [[ ! "${NOCHECK}" ]] && check_ipv6

  local item
  declare -ra interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))
  declare -a ipv6_cidr_array

  for item in "${!interfaces_array[@]}"; do
    ipv6_cidr_array[item]=$(ip -6 address show dev "${interfaces_array[item]}" | awk -v family="inet6" 'tolower($0) ~ family {print $2}')
    echo "${interfaces_array[item]}" "${ipv6_cidr_array[item]}"
  done

  return 0
}

# prints all info and cidr suffix.
show_all_cidr() {

  [[ ! "${NOCHECK}" ]] && check_ipv6
  
  local mac_of driver_of gateway cidr item
  declare -ra interfaces_array=($(ip route | awk 'tolower($0) ~ /default/ {print $5}'))
  declare -a ipv4_cidr_array ipv6_cidr_array
  
  for item in "${!interfaces_array[@]}"; do
    ipv4_cidr_array[item]=$(ip -4 address show dev "${interfaces_array[item]}" | awk -v family=inet '$0 ~ family {print $2}')
    ipv6_cidr_array[item]=$(ip -6 address show dev "${interfaces_array[item]}" | awk -v family="inet6" 'tolower($0) ~ family {print $2}')
    [[ -f "/sys/class/net/${interfaces_array[item]}/phy80211/device/uevent" ]] \
      && driver_of=$(awk -F '=' 'tolower($0) ~ /driver/{print $2}' "/sys/class/net/${interfaces_array[item]}/phy80211/device/uevent") \
      || driver_of=$(awk -F '=' 'tolower($0) ~ /driver/{print $2}' "/sys/class/net/${interfaces_array[item]}/device/uevent")
    mac_of=$(awk '{print $0}' "/sys/class/net/${interfaces_array[item]}/address" 2> /dev/null)
    gateway=$(ip route | awk "/${interfaces_array[item]}/ && tolower(\$0) ~ /default/ {print \$3}")
    cidr=$(echo -n "${ipv4_cidr_array[item]}" | sed 's/^.*\//\//')
    echo "${interfaces_array[item]}" "${driver_of}" "${mac_of}" "${gateway}${cidr}" "${ipv4_cidr_array[item]}" "${ipv6_cidr_array[item]}"
  done

  return 0
}

# prints help message.
show_usage() {
  
  echo    " usage: ${script_name} [option] <argument/s>"
  echo -e "  ${script_name} ${color_arr[0]}-4 ${color_arr[0]}, ${color_arr[0]}--ipv4 ${color_arr[0]}          shows active interfaces with their ipv4 address"
  echo -e "  ${script_name} ${color_arr[0]}-6 ${color_arr[0]}, ${color_arr[0]}--ipv6 ${color_arr[0]}          shows active interfaces with their ipv6 address"
  echo -e "  ${script_name} ${color_arr[0]}-a ${color_arr[0]}, ${color_arr[0]}--all ${color_arr[0]}           shows all information"
  echo -e "  ${script_name} ${color_arr[0]}-A ${color_arr[0]}, ${color_arr[0]}--all-interfaces ${color_arr[0]}shows all available network interfaces"
  echo -e "  ${script_name} ${color_arr[0]}-c ${color_arr[0]}, ${color_arr[0]}--calculate ${color_arr[0]}<>   shows calculated ip information"
  echo -e "  ${script_name} ${color_arr[0]}-d ${color_arr[0]}, ${color_arr[0]}--driver ${color_arr[0]}        shows each active interface's driver"
  echo -e "  ${script_name} ${color_arr[0]}-e ${color_arr[0]}, ${color_arr[0]}--external ${color_arr[0]}      shows your external ip address"
  echo -e "  ${script_name} ${color_arr[0]}-e ${color_arr[0]}, ${color_arr[0]}--external ${color_arr[0]}<>    shows external ip addresses"
  echo -e "  ${script_name} ${color_arr[0]}-f ${color_arr[0]}, ${color_arr[0]}--find ${color_arr[0]}<>        shows valid ip and mac addresses found on file/s"
  echo -e "  ${script_name} ${color_arr[0]}-g ${color_arr[0]}, ${color_arr[0]}--gateway ${color_arr[0]}       shows gateway of online interfaces"
  echo -e "  ${script_name} ${color_arr[0]}-h ${color_arr[0]}, ${color_arr[0]}--help${color_arr[0]}           shows this help message"
  echo -e "  ${script_name} ${color_arr[1]}-H ${color_arr[0]}, ${color_arr[1]}--hosts ${color_arr[0]}         shows active hosts on network"
  echo -e "  ${script_name} ${color_arr[1]}-HM${color_arr[0]}, ${color_arr[1]}--hosts-mac ${color_arr[0]}     shows active hosts on network with their mac address"
  echo -e "  ${script_name} ${color_arr[0]}-i ${color_arr[0]}, ${color_arr[0]}--interfaces ${color_arr[0]}    shows active interfaces"
  echo -e "  ${script_name} ${color_arr[0]}-l ${color_arr[0]}, ${color_arr[0]}--list ${color_arr[0]}          shows a list of private and reserved ip addresses"
  echo -e "  ${script_name} ${color_arr[0]}-m ${color_arr[0]}, ${color_arr[0]}--mac ${color_arr[0]}           shows active interfaces with their mac address"
  echo -e "  ${script_name} ${color_arr[0]}-n ${color_arr[0]}, ${color_arr[0]}--neighbor ${color_arr[0]}      shows neighbor cache"
  echo -e "  ${script_name} ${color_arr[0]}-P ${color_arr[0]}, ${color_arr[0]}--port ${color_arr[0]}          shows a list of common ports"
  echo -e "  ${script_name} ${color_arr[1]}-P ${color_arr[0]}, ${color_arr[1]}--port ${color_arr[0]}<>        shows connections to a port per ip"
  echo -e "  ${script_name} ${color_arr[0]}-r ${color_arr[0]}, ${color_arr[0]}--route-ipv4 ${color_arr[0]}<>  shows the path to a network host using ipv4"
  echo -e "  ${script_name} ${color_arr[0]}-r6${color_arr[0]}, ${color_arr[0]}--route-ipv6 ${color_arr[0]}<>  shows the path to a network host using ipv6"
  echo -e "  ${script_name} ${color_arr[0]}-u ${color_arr[0]}, ${color_arr[0]}--url ${color_arr[0]}<>         shows valid ip and mac addresses found on website/s"
  echo -e "  ${script_name} ${color_arr[0]}-v ${color_arr[0]}, ${color_arr[0]}--version ${color_arr[0]}       shows the version of script"
  echo -e "  ${script_name} ${color_arr[2]}--cidr-4${color_arr[0]}, ${color_arr[2]}--cidr-ipv4 ${color_arr[0]}shows active interfaces with their ipv4 address and cidr"
  echo -e "  ${script_name} ${color_arr[2]}--cidr-6${color_arr[0]}, ${color_arr[2]}--cidr-ipv6 ${color_arr[0]}shows active interfaces with their ipv6 address and cidr"
  echo -e "  ${script_name} ${color_arr[2]}--cidr-a${color_arr[0]}, ${color_arr[2]}--cidr-all ${color_arr[0]} shows all information with cidr"
  echo -e "  ${script_name} ${color_arr[2]}--cidr-l${color_arr[0]}, ${color_arr[2]}--cidr-list ${color_arr[0]}shows a list of private and reserved ip addresses with cidr"

  return 0
}

# prints the right usage of ship -c | --calculate.
show_usage_ipcalc() {

  declare -ar string_format_arr=(
    " %s\n"
    "  %s ${color_arr[5]}%s${color_arr[0]}\n"
  )

  printf "${string_format_arr[0]}" "usage:"
  printf "${string_format_arr[1]}" "${script_name} -c, --calculate <options>" "192.168.0.1"
  printf "${string_format_arr[1]}" "${script_name} -c, --calculate <options>" "192.168.0.1/24"
  printf "${string_format_arr[1]}" "${script_name} -c, --calculate <options>" "192.168.0.1 255.255.255.0"
  printf "${string_format_arr[0]}" "options:"
  printf "${string_format_arr[1]}" "-b, --nobinary" "suppress the bitwise output"
  printf "${string_format_arr[1]}" "-h, --html" "display results as html"
  printf "${string_format_arr[1]}" "-s, --split" "split into networks of size n1, n2, n3 ${dialog_under_development}" #todo
  printf "${string_format_arr[1]}" "-r, --range" "deaggregate address range ${dialog_under_development}" #todo

  return 0
}

# starts ship.
sail() {
  
  [[ -z "${1}" ]] && error_exit "${dialog_error}"

  check_bash_version

  trap trap_handler INT &>/dev/null
  trap trap_handler SIGTSTP &>/dev/null
  trap mr_proper EXIT
  
  while :; do
    case "${1}" in
    "-4"|"--ipv4")
      check_connectivity "--local"
      show_ipv4
      break
    ;;
    "-6"|"--ipv6")
      check_connectivity "--local"
      show_ipv6
      break
    ;;
    "-a"|"--all")
      check_connectivity "--local"
      show_all
      break
    ;;
    "-A"|"--all-interfaces")
      show_all_interfaces
      break
    ;;
    "-c"|"--calculate")
      show_ipcalc "${@:2}"
      break
    ;;
    "-d"|"--driver")
      check_connectivity "--local"
      show_driver
      break
    ;;
    "-e"|"--external")
      check_connectivity "--internet"
      show_ip_from "${@:2}"
      shift 2
      break
    ;;
    "-f"|"--find")
      show_ips_from_file "${@:2}"
      break
    ;;
    "-g"|"--gateway")
      check_connectivity "--local"
      show_gateway
      break
    ;;
    "-h"|"--help")
      show_usage
      break
    ;;
    "-H"|"--hosts")
      check_connectivity "--local"
      show_live_hosts "--normal"
      break
    ;;
    "-HM"|"--hosts-mac")
      check_connectivity "--local"
      show_live_hosts "--mac"
      break
    ;;
    "-i"|"--interfaces")
      check_connectivity "--local"
      show_interfaces
      break
    ;;
    "-l"|"--list")
      show_bogon_ips "--normal"
      break
    ;;
    "-m"|"--mac")
      check_connectivity "--local"
      show_mac
      break
    ;;
    "-n"|"--neighbor")
      check_connectivity "--local"
      show_neighbor_cache
      break
    ;;
    "-P"|"--port")
      check_connectivity "--internet"
      show_port_connections "${2}"
      shift 2
      break
    ;;
    "-r"|"--route-ipv4")
      check_connectivity "--internet"
      show_next_hops "--ipv4" "${2}"
      shift 2
      break
    ;;
    "-r6"|"--route-ipv6")
      check_connectivity "--internet"
      show_next_hops "--ipv6" "${2}"
      shift 2
      break
    ;;
    "-u"|"--url")
      check_connectivity "--internet"
      show_ips_from_online_documents "${@:2}"
      break
    ;;
    "-v"|"--version")
      show_version
      break
    ;;
    "--cidr-4"|"--cidr-ipv4")
      check_connectivity "--local"
      show_ipv4_cidr
      break
    ;;
    "--cidr-6"|"--cidr-ipv6")
      check_connectivity "--local"
      show_ipv6_cidr
      break
    ;;
    "--cidr-a"|"--cidr-all")
      check_connectivity "--local"
      show_all_cidr
      break
    ;;
    "--cidr-l"|"--cidr-list")
      show_bogon_ips "--cidr"
      break
    ;;
    *)
      error_exit "${dialog_error}" "${1}"
    ;;
    esac
  done

  exit 0
}

sail "${1+${@}}"
