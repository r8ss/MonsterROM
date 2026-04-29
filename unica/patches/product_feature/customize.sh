#!/bin/bash

# Função para encontrar o arquivo smali dinamicamente
find_smali_file() {
    local apk_path="$1"
    local file_name="$2"
    find "$APKTOOL_DIR/$apk_path" -name "$file_name" | sed "s|$APKTOOL_DIR/||"
}

if [[ "$SOURCE_AUTO_BRIGHTNESS_TYPE" != "$TARGET_AUTO_BRIGHTNESS_TYPE" && "$TARGET_AUTO_BRIGHTNESS_TYPE" != "4" ]]; then
    LOG_STEP_IN "- Applying auto brightness type patches"

    DECODE_APK "system" "system/framework/services.jar"
    DECODE_APK "system" "system/framework/ssrm.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

    # Busca dinâmica para evitar erro de No Such File
    FTP_PMU=$(find_smali_file "system/framework/services.jar" "PowerManagerUtil.smali")
    FTP_PRE=$(find_smali_file "system/framework/ssrm.jar" "PreMonitor.smali")
    FTP_RUNE=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "Rune.smali")

    for f in $FTP_PMU $FTP_PRE $FTP_RUNE; do
        if [ -f "$APKTOOL_DIR/$f" ]; then
            sed -i "s/\"$SOURCE_AUTO_BRIGHTNESS_TYPE\"/\"$TARGET_AUTO_BRIGHTNESS_TYPE\"/g" "$APKTOOL_DIR/$f"
        fi
    done

    # HEX_PATCH removido para One UI 8.0/Android 16 devido a mudanca na assinatura binaria
    LOG "- Skipping HEX_PATCH for libsensorservice.so (Incompatible with Android 16)"
    
    LOG_STEP_OUT
fi

DECODE_APK "system" "system/framework/framework.jar"

if [[ "$TARGET_HFR_SEAMLESS_BRT" == "none" && "$TARGET_HFR_SEAMLESS_LUX" == "none" ]]; then
     # Comentado devido a erro de contexto na One UI 8.0 (Android 16)
     # APPLY_PATCH "system" "system/framework/framework.jar" "$SRC_DIR/unica/patches/product_feature/hfr/framework.jar/0001-Remove-brightness-threshold-values.patch"
     LOG "- Skipping HFR threshold patch (Incompatible context in Android 16)"
else
    FTP_RR=$(find_smali_file "system/framework/framework.jar" "RefreshRateConfig.smali")
    for f in $FTP_RR; do
        if [ -f "$APKTOOL_DIR/$f" ]; then
            sed -i "s/\"$SOURCE_HFR_SEAMLESS_BRT\"/\"$TARGET_HFR_SEAMLESS_BRT\"/g" "$APKTOOL_DIR/$f"
            sed -i "s/\"$SOURCE_HFR_SEAMLESS_LUX\"/\"$TARGET_HFR_SEAMLESS_LUX\"/g" "$APKTOOL_DIR/$f"
        fi
    done
fi

if [[ "$SOURCE_HFR_MODE" != "$TARGET_HFR_MODE" ]]; then
    LOG_STEP_IN "- Applying HFR_MODE patches"

    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/framework/gamemanager.jar"
    DECODE_APK "system" "system/framework/secinputdev-service.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
    DECODE_APK "system" "system/priv-app/SettingsProvider/SettingsProvider.apk"
    DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

    FTP_HFR="
    $(find_smali_file "system/framework/framework.jar" "RefreshRateConfig.smali")
    $(find_smali_file "system/framework/framework.jar" "CoreRune.smali")
    $(find_smali_file "system/framework/gamemanager.jar" "GameManagerService.smali")
    $(find_smali_file "system/framework/secinputdev-service.jar" "SemInputDeviceManagerService.smali")
    $(find_smali_file "system/framework/secinputdev-service.jar" "SemInputFeatures.smali")
    $(find_smali_file "system/framework/secinputdev-service.jar" "SemInputFeaturesExtra.smali")
    $(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "SecDisplayUtils.smali")
    $(find_smali_file "system/priv-app/SettingsProvider/SettingsProvider.apk" "DatabaseHelper.smali")
    $(find_smali_file "system_ext/priv-app/SystemUI/SystemUI.apk" "LsRune.smali")
    "

    for f in $FTP_HFR; do
        if [ -f "$APKTOOL_DIR/$f" ]; then
            sed -i "s/\"$SOURCE_HFR_MODE\"/\"$TARGET_HFR_MODE\"/g" "$APKTOOL_DIR/$f"
        fi
    done
    LOG_STEP_OUT
fi

if [[ "$SOURCE_HFR_SUPPORTED_REFRESH_RATE" != "$TARGET_HFR_SUPPORTED_REFRESH_RATE" ]]; then
    LOG_STEP_IN "- Applying HFR_SUPPORTED_REFRESH_RATE patches"
    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

    FTP_HSR="
    $(find_smali_file "system/framework/framework.jar" "RefreshRateConfig.smali")
    $(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "SecDisplayUtils.smali")
    "
    for f in $FTP_HSR; do
        if [ -f "$APKTOOL_DIR/$f" ]; then
            if [[ "$TARGET_HFR_SUPPORTED_REFRESH_RATE" != "none" ]]; then
                sed -i "s/\"$SOURCE_HFR_SUPPORTED_REFRESH_RATE\"/\"$TARGET_HFR_SUPPORTED_REFRESH_RATE\"/g" "$APKTOOL_DIR/$f"
            else
                sed -i "s/\"$SOURCE_HFR_SUPPORTED_REFRESH_RATE\"/\"\"/g" "$APKTOOL_DIR/$f"
            fi
        fi
    done
    LOG_STEP_OUT
fi

if [[ "$SOURCE_HFR_DEFAULT_REFRESH_RATE" != "$TARGET_HFR_DEFAULT_REFRESH_RATE" ]]; then
    LOG_STEP_IN "- Applying HFR_DEFAULT_REFRESH_RATE patches"
    DECODE_APK "system" "system/framework/framework.jar"
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
    DECODE_APK "system" "system/priv-app/SettingsProvider/SettingsProvider.apk"

    FTP_HDR="
    $(find_smali_file "system/framework/framework.jar" "RefreshRateConfig.smali")
    $(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "SecDisplayUtils.smali")
    $(find_smali_file "system/priv-app/SettingsProvider/SettingsProvider.apk" "DatabaseHelper.smali")
    "
    for f in $FTP_HDR; do
        if [ -f "$APKTOOL_DIR/$f" ]; then
            sed -i "s/\"$SOURCE_HFR_DEFAULT_REFRESH_RATE\"/\"$TARGET_HFR_DEFAULT_REFRESH_RATE\"/g" "$APKTOOL_DIR/$f"
        fi
    done
    LOG_STEP_OUT
fi

if [[ "$TARGET_DISPLAY_CUTOUT_TYPE" == "right" ]]; then
    LOG_STEP_IN "- Applying right cutout patch"
    APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$SRC_DIR/unica/patches/product_feature/cutout/SystemUI.apk/0001-Add-right-cutout-support.patch"
    LOG_STEP_OUT
fi

if [[ "$SOURCE_DVFS_CONFIG_NAME" != "$TARGET_DVFS_CONFIG_NAME" ]]; then
    LOG_STEP_IN "- Applying DVFS patches"
    DECODE_APK "system" "system/framework/ssrm.jar"
    FTP_DVFS=$(find_smali_file "system/framework/ssrm.jar" "Feature.smali")
    for f in $FTP_DVFS; do
        if [ -f "$APKTOOL_DIR/$f" ]; then
            sed -i "s/\"$SOURCE_DVFS_CONFIG_NAME\"/\"$TARGET_DVFS_CONFIG_NAME\"/g" "$APKTOOL_DIR/$f"
        fi
    done
    LOG_STEP_OUT
fi
