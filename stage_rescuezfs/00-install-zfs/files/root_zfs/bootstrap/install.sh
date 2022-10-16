#! /bin/bash -e

export BASE_DIR=`dirname $(readlink -f "${BASH_SOURCE[0]}")`

${BASE_DIR}/install_d0.sh && \
${BASE_DIR}/install_s0.sh && \
${BASE_DIR}/install_s1.sh && \
${BASE_DIR}/install_s2.sh
