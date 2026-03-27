#!/bin/bash
set -e
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Run as root. You're running as $(whoami)"
  exit 1
fi


cat <<'EOF'
Ubuntu
.__  .__                                                   ___.                  __                      .___
|  | |  | _____    _____ _____        ____ ______ ______   \_ |__ _____    ____ |  | __ ____   ____    __| _/
|  | |  | \__  \  /     \\__  \     _/ ___\\____ \\____ \   | __ \\__  \ _/ ___\|  |/ // __ \ /    \  / __ | 
|  |_|  |__/ __ \|  Y Y  \/ __ \_   \  \___|  |_> >  |_> >  | \_\ \/ __ \\  \___|    <\  ___/|   |  \/ /_/ | 
|____/____(____  /__|_|  (____  / /\ \___  >   __/|   __/   |___  (____  /\___  >__|_ \\___  >___|  /\____ | 
               \/      \/     \/  \/     \/|__|   |__|          \/     \/     \/     \/    \/     \/      \/ 
___.                  __            __                                                                       
\_ |__   ____   _____/  |_  _______/  |_____________  ______    
 | __ \ /  _ \ /  _ \   __\/  ___/\   __\_  __ \__  \ \____ \   v0.93
 | \_\ (  <_> |  <_> )  |  \___ \  |  |  |  | \// __ \|  |_> >  Installs: update|upgrade, llama.cpp,
 |___  /\____/ \____/|__| /____  > |__|  |__|  (____  /   __/             LLM models (gpt-oss,nemotron),
     \/                        \/                   \/|__|                tailscale, startup scritps.
							 
CTRL+C to abort now. Will commence in 5 seconds.
EOF
sleep 5

echo "[INFO] Updating system"
apt-get -y update
apt-get -y upgrade

echo "[INFO] Installing stuff.."
apt-get -y install age aria2 cmake curl duf emacs-nox git libssl-dev htop nvtop pv python3-pip python3.12-venv ripgrep unzip wget zip zlib1g-dev

echo "[INFO] Install tailscale..."
## tailscale login
## tailscale ip -4
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
apt-get -y update
apt-get -y install tailscale

echo "[INFO] Installing model.."
mkdir -vp /root/llm-models
cd /root/llm-models

BASE="https://huggingface.co/unsloth/NVIDIA-Nemotron-3-Super-120B-A12B-GGUF/resolve/main/UD-Q4_K_XL"
echo "[INFO] nemotoron..."
if [ ! -f ./NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00001-of-00003.gguf ]; then
     aria2c -x 16 -s 16 -c -o "NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00001-of-00003.gguf" "${BASE}/NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00001-of-00003.gguf"
fi
if [ ! -f ./NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00002-of-00003.gguf ]; then
     aria2c -x 16 -s 16 -c -o "NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00002-of-00003.gguf" "${BASE}/NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00002-of-00003.gguf"
fi
if [ ! -f ./NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00003-of-00003.gguf ]; then
     aria2c -x 16 -s 16 -c -o "NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00003-of-00003.gguf" "${BASE}/NVIDIA-Nemotron-3-Super-120B-A12B-UD-Q4_K_XL-00003-of-00003.gguf"
fi

echo "[INFO] gpt-oss 120b..."
if [ ! -f ./gpt-oss-120b-F16.gguf ]; then
    aria2c -x 16 -s 16 -c -o "gpt-oss-120b-F16.gguf" "https://huggingface.co/unsloth/gpt-oss-120b-GGUF/resolve/main/gpt-oss-120b-F16.gguf"
fi

echo "[INFO] qwen 3.5 35B and 120B..."
BASE="https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF/resolve/main"
if [ ! -f Qwen3.5-35B-A3B-UD-Q8_K_XL.gguf ]; then
    aria2c -x 16 -s 16 -c -o "Qwen3.5-35B-A3B-UD-Q8_K_XL.gguf" "${BASE}/Qwen3.5-35B-A3B-UD-Q8_K_XL.gguf"
fi
if [ ! -f qwen3.5-35B-mmproj-BF16.gguf ]; then
    aria2c -x 16 -s 16 -c -o "mmproj-BF16.gguf" "${BASE}/mmproj-BF16.gguf"
    mv -v mmproj-BF16.gguf Qwen3.5-35B-mmproj-BF16.gguf
fi
if [ ! -f qwen3.5-35B-mmproj-F32.gguf ]; then
    aria2c -x 16 -s 16 -c -o "mmproj-F32.gguf" "${BASE}/mmproj-F32.gguf"
    mv -v mmproj-F32.gguf Qwen3.5-35B-mmproj-F32.gguf
fi

echo "[INFO] Writing /root/models.config"
if [ ! -f /root/models.config ]; then
    #cat models.config | zstd --ultra -22 | base64 -w0
    echo "KLUv/QSILQsAxtA4FBD9Su++bVaVglEj7dc2glVVVQDgMgAyADIAX45t4CgC+T1tAL3TtGgQ6xv1f13XsOOYNtzTjF8gJI8E+XUdf1tOQQBAAimA47WmTzynCMf1eNJCQERCCq8tvKq2wNcpPebtP+3R/faolkDiHIhy7mv9dbsEzpu2RxZeWeBo5Wj8keNnn4iJy/ar7lMJMn2K+4r2p6u6PG2gT/muPxzTdvyeMDgAQC+o6aoKkWDTMYoGwLIgSZMkivXZmJbf91E2RvlMocBnPoPi6ZIjfA5A4zDPcsC2PX61Hl10GAaAgYpjGJQzIEDGGLKxG3dQtBkAYg8OJMABbEgDFIAN2DACAAAJyYBawEE4MRkAYFJcRaDduhizCaxZcL9oYyAcU/iAgeBBZy68cAV5sAsP+GEA2NA/If3y4/MwxpUjELbEZRIxyiUEXfbscLxXCgQ+cXgJgl8EDMB9GMccVJXcym1PA+8JWyZ/oA==" | base64 -d | ztsd -d -o /root/models.config
fi

#BASE="https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF/resolve/main"
#if [ ! -f Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003.gguf ]; then
#    aria2c -x 16 -s 16 -c -o "Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003.gguf" "${BASE}/UD-Q4_K_XL/Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003#.gguf"
#fi
#if [ ! -f Qwen3.5-122B-A10B-UD-Q4_K_XL-00002-of-00003.gguf ]; then
#    aria2c -x 16 -s 16 -c -o "Qwen3.5-122B-A10B-UD-Q4_K_XL-00002-of-00003.gguf" "${BASE}/UD-Q4_K_XL/Qwen3.5-122B-A10B-UD-Q4_K_XL-00002-of-00003#.gguf"
#fi
#if [ ! -f Qwen3.5-122B-A10B-UD-Q4_K_XL-00003-of-00003.gguf ]; then
#    aria2c -x 16 -s 16 -c -o "Qwen3.5-122B-A10B-UD-Q4_K_XL-00003-of-00003.gguf" "${BASE}/UD-Q4_K_XL/Qwen3.5-122B-A10B-UD-Q4_K_XL-00003-of-00003#.gguf"
#fi
#if [ ! -f qwen3.5-120B-mmproj-BF16.gguf ]; then
#    aria2c -x 16 -s 16 -c -o "mmproj-BF16.gguf" "${BASE}/mmproj-BF16.gguf"
#    mv -v mmproj-BF16.gguf qwen3.5-120B-mmproj-BF16.gguf
#fi

echo "[INFO] writing llama.cpp builder.."
echo "KLUv/QSIXQUAYkkfGVDXA08QwkMqUkFQ1Oge9ignHdLwNZNY8AGFnvp739bSMDHz1tsgZO+Uk/RSyau9tjz/oQhJmGmhnKdpmHfrWq9y5Z1qEk9Yd/6La404T6PysBgPTncd5nTLd3pnK7QmjFpPQ2J5b+xy3tGv/Y43hPS9oxzEOFnFzVYRCAIQIBAYofP2l8q6A7oWuM1YpG63QfULeFuO8QwUzABJY7MXq3tbKxB8g9MDfSYNOA==" | base64 -d | zstd -d -o /root/build-llamacpp.sh
chmod +x /root/build-llamacpp.sh
/root/build-llamacpp.sh

echo "[INFO] writing runner.."
echo "KLUv/QSIzQgAdtE1HyBzdfCPSURb3pW2kp9ZAf4KBGF7h812SBbEBxgKcDwtACsALQDtup6jm+oFsgZBULOM0PVnS/gn4Xvz8UqkAXFQ2mc1MWO8b66sqs4SSWiJAIF/EjZ1PYEX1jyUYxrdJYxcIzMJ34z/meSqv2itmae4PbO/mL5/fhgwEK+akkXXNUE9J41OTXLCWrlujBDT+2py3e4djdVvhsT+ggXBJY7LecobynWd5WIMjBHau85q95J0eHxyf3jHWQ9e5Jyg5sr02hqZmtYu4ZLinr2EQLyzr3uKwwEYIBASAePWAxemdrDtHADNrJof6xCtOc72jvtWVwQMvZwx0kQBw2LFuIDZuNbmgHT9D8fjAr+o3lYAwrFcBQrgELna" | base64 -d | zstd -d -o /root/run-llama-server.sh
chmod +x /root/run-llama-server.sh


cat <<'EOF'
   ___________   ____ _____ _/  |_    ________ __   ____  ____  ____   ______ ______
  / ___\_  __ \_/ __ \\__  \\   __\  /  ___/  |  \_/ ___\/ ___\/ __ \ /  ___//  ___/
 / /_/  >  | \/\  ___/ / __ \|  |    \___ \|  |  /\  \__\  \__\  ___/ \___ \ \___ \ 
 \___  /|__|    \___  >____  /__|   /____  >____/  \___  >___  >___  >____  >____  >
/_____/             \/     \/            \/            \/    \/    \/     \/     \/ 

Next steps:
- reboot
- re-login
- run /root/run-llama-server.sh
  (will login to tailscale, and start llama.cpp at tailnet IP)

EOF



##
##./llama-server  --models-preset /root/models.config --models-max 1 -ngl 100 --host 0.0.0.0

