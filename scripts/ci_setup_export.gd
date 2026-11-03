@tool
extends EditorScript

func _run() -> void:
    var settings := EditorInterface.get_editor_settings()
    var java_home := OS.get_environment("JAVA_HOME")
    var android_home := OS.get_environment("ANDROID_HOME")
    if android_home.is_empty():
        android_home = OS.get_environment("ANDROID_SDK_ROOT")
    settings.set_setting("export/android/java_sdk_path", java_home)
    settings.set_setting("export/android/android_sdk_path", android_home)
    settings.set_setting("export/android/debug_keystore", OS.get_environment("JU_DEBUG_KEYSTORE"))
    settings.set_setting("export/android/debug_keystore_user", "androiddebugkey")
    settings.set_setting("export/android/debug_keystore_password", OS.get_environment("JU_DEBUG_KEYSTORE_PASSWORD"))
    settings.save()
    print("JU CI Android export settings configured.")
