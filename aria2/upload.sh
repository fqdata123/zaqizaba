#!/usr/bin/env bash
#
# https://github.com/P3TERX/aria2.conf
# File name：upload.sh
# Description: Use Rclone to upload files after Aria2 download is complete
# Version: 3.1
#
# Copyright (c) 2018-2021 P3TERX <https://p3terx.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

CHECK_CORE_FILE() {
    CORE_FILE="$(dirname $0)/core"
    if [[ -f "${CORE_FILE}" ]]; then
        . "${CORE_FILE}"
    else
        echo && echo "!!! core file does not exist !!!"
        exit 1
    fi
}

#CHECK_RCLONE() {
#    [[ $# -eq 0 ]] && {
#        echo && echo -e "Checking RCLONE connection ..."
#        rclone mkdir "${DRIVE_NAME}:${DRIVE_DIR}/P3TERX.COM"
#        if [[ $? -eq 0 ]]; then
#            rclone rmdir "${DRIVE_NAME}:${DRIVE_DIR}/P3TERX.COM"
#            echo
#            echo -e "${LIGHT_GREEN_FONT_PREFIX}success${FONT_COLOR_SUFFIX}"
#            exit 0
#        else
#            echo
#            echo -e "${RED_FONT_PREFIX}failure${FONT_COLOR_SUFFIX}"
#            exit 1
#        fi
#   }
#}

TASK_INFO() {
    echo -e "
-------------------------- [${YELLOW_FONT_PREFIX}Task Infomation${FONT_COLOR_SUFFIX}] --------------------------
${LIGHT_PURPLE_FONT_PREFIX}Task GID:${FONT_COLOR_SUFFIX} ${TASK_GID}
${LIGHT_PURPLE_FONT_PREFIX}Number of Files:${FONT_COLOR_SUFFIX} ${FILE_NUM}
${LIGHT_PURPLE_FONT_PREFIX}First File Path:${FONT_COLOR_SUFFIX} ${FILE_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Task File Name:${FONT_COLOR_SUFFIX} ${TASK_FILE_NAME}
${LIGHT_PURPLE_FONT_PREFIX}Task Path:${FONT_COLOR_SUFFIX} ${TASK_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Aria2 Download Directory:${FONT_COLOR_SUFFIX} ${ARIA2_DOWNLOAD_DIR}
${LIGHT_PURPLE_FONT_PREFIX}Custom Download Directory:${FONT_COLOR_SUFFIX} ${DOWNLOAD_DIR}
${LIGHT_PURPLE_FONT_PREFIX}Local Path:${FONT_COLOR_SUFFIX} ${LOCAL_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Remote Path:${FONT_COLOR_SUFFIX} ${REMOTE_PATH}
${LIGHT_PURPLE_FONT_PREFIX}.aria2 File Path:${FONT_COLOR_SUFFIX} ${DOT_ARIA2_FILE}
-------------------------- [${YELLOW_FONT_PREFIX}Task Infomation${FONT_COLOR_SUFFIX}] --------------------------
"
}

OUTPUT_UPLOAD_LOG() {
    LOG="${UPLOAD_LOG}"
    LOG_PATH="${UPLOAD_LOG_PATH}"
    OUTPUT_LOG
}
#修改文件名
CHANGE_NAME(){
    TARGET_FILE_BASE=$(basename "${1}")
    TARGET_FILE_EXTENSION="${1##*.}"
    if [[ "$TARGET_FILE_BASE" == "$TARGET_FILE_EXTENSION" ]]; then
        # This fixes the case where the target file has no extension
        TARGET_FILE_EXTENSION=''
    fi
    MIME=`file -b --mime-type ${1}`
    EXT=$(grep "${MIME}" "/usr/local/aria2/custommime.types" | sed '/^#/ d' | grep -m 1 "${MIME}" | awk '{print $2}')
    if [[ "${EXT}" == "" ]]; then
        mv "${1}" "${1%.*}${2}.${TARGET_FILE_EXTENSION}"
        echo ${1%.*}${2}.${TARGET_FILE_EXTENSION}
    else
        mv "${1}" "${1%.*}${2}.${EXT}"
        echo ${1%.*}${2}.${EXT}
    fi
}
#遍历文件夹
TRAVFOLDER(){
    FLIST=$(ls $1)
    cd $1
    for f in $FLIST
    do
        if test -d $f
        then
            TRAVFOLDER $f $2
            CHANGE_NAME $f $2
        else
            CHANGE_NAME $f $2
        fi
    done
}

DEFINITION_PATH() {
    NAMEWITHTIME=$(TZ=Asia/Shanghai date "+%H%M%S")
    PATHWITHYEAR=$(TZ=Asia/Shanghai date "+%Y")
    PATHWITHMONTH=$(TZ=Asia/Shanghai date "+%m")
    PATHWITHDAY=$(TZ=Asia/Shanghai date "+%d")
    if [[ -f "${TASK_PATH}" ]]; then
        LOCAL_PATH=$(CHANGE_NAME "${TASK_PATH}" "${NAMEWITHTIME}")
        REMOTE_PATH="${DRIVE_DIR}/${PATHWITHYEAR}/${PATHWITHMONTH}/${PATHWITHDAY}${DEST_PATH_SUFFIX%/*}"
    else
        KEEPPATH=$(pwd)
        TRAVFOLDER ${TASK_PATH} ${NAMEWITHTIME}
        LOCAL_PATH="${TASK_PATH}"
        REMOTE_PATH="${DRIVE_DIR}/${PATHWITHYEAR}/${PATHWITHMONTH}/${PATHWITHDAY}${DEST_PATH_SUFFIX}"
        cd ${KEEPPATH}
    fi
}

#LOAD_RCLONE_ENV() {
#    RCLONE_ENV_FILE="${ARIA2_CONF_DIR}/rclone.env"
#    [[ -f ${RCLONE_ENV_FILE} ]] && export $(grep -Ev "^#|^$" ${RCLONE_ENV_FILE} | xargs -0)
#}

UPLOAD_FILE() {
    echo -e "$(DATE_TIME) ${INFO} Start upload files..."
    TASK_INFO
    RETRY=0
    RETRY_NUM=3
    while [ ${RETRY} -le ${RETRY_NUM} ]; do
        [ ${RETRY} != 0 ] && (
            echo
            echo -e "$(DATE_TIME) ${ERROR} Upload failed! Retry ${RETRY}/${RETRY_NUM} ..."
            echo
        )
        /usr/local/OneDriveUploader/OneDriveUploader -c "/usr/local/OneDriveUploader/auth.json" -t "3" -b "20" -s "${LOCAL_PATH}" -r "${REMOTE_PATH}" -skip
        UPLOAD_EXIT_CODE=$?
        if [ ${UPLOAD_EXIT_CODE} -eq 0 ]; then
            UPLOAD_LOG="$(DATE_TIME) ${INFO} Upload done: ${LOCAL_PATH} -> ${REMOTE_PATH}"
            OUTPUT_UPLOAD_LOG
            rm -rf "${LOCAL_PATH}"
            DELETE_EMPTY_DIR
            break
        else
            RETRY=$((${RETRY} + 1))
            [ ${RETRY} -gt ${RETRY_NUM} ] && (
                echo
                UPLOAD_LOG="$(DATE_TIME) ${ERROR} Upload failed: ${LOCAL_PATH}"
                OUTPUT_UPLOAD_LOG
            )
            sleep 3
        fi
    done
}

CHECK_CORE_FILE "$@"
CHECK_SCRIPT_CONF
#CHECK_RCLONE "$@"
CHECK_FILE_NUM
GET_TASK_INFO
GET_DOWNLOAD_DIR
CONVERSION_PATH
DEFINITION_PATH
CLEAN_UP
#LOAD_RCLONE_ENV
UPLOAD_FILE
php /usr/share/nginx/html/onedrive/one.php cache:refresh
exit 0
