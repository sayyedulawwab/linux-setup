#  utils.sh

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

########################################
# Globals
########################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

LOG_FILE="/var/log/arch-install.log"

########################################
# Logging
########################################
mkdir -p /var/log
exec > >(tee -a "$LOG_FILE") 2>&1

########################################
# Helpers
########################################
confirm() {
  read -rp "$1 [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

info() {
  echo -e "${GREEN}${BOLD}==>${NC} $1"
}

warn() {
  echo -e "${YELLOW}${BOLD}WARNING:${NC} $1"
}

error() {
  echo -e "${RED}${BOLD}ERROR:${NC} $1"
  exit 1
}