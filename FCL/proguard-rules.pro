# ============================================================
# FCL fordebug 激进优化 keep 规则（research-opt 分支，AI 辅助生成）
#
# 策略：启用 R8 收缩 + 优化，但**不重命名**（见末尾 -keepnames）。
# 原因：本项目存在多类按名访问——JNI FindClass/GetMethodID、Gson 反射、
# 外部渲染器插件按名实现 FCL API 接口。激进重命名的运行时风险远大于收益，
# 因此优化收益来自：无用代码删除 + 方法内联/字节码优化 + native -O3。
# 删除或放宽任何一条前，请先在真机验证功能完整性。
# ============================================================

# ---------- 通用属性 ----------
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ---------- Gson 反射序列化（HMCL 系模型类大量使用 @SerializedName） ----------
-keep class com.google.gson.annotations.SerializedName { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.internal.** { *; }

# ---------- kotlinx.serialization ----------
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}

# ---------- JNI：声明 native 方法的类不可移除/改名（pojavexec / bytehook / LWJGL natives） ----------
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
# JNI 侧按名 FindClass 访问的应用包（防御性整包保留）
-keep class com.tungsten.fcl.** { *; }
-keep class com.tungsten.fcllibrary.** { *; }
# LWJGL 预编译 natives 回调 Java 侧
-keep class org.lwjgl.** { *; }

# ---------- JNA（flite/TTS 等按名反射加载） ----------
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { *; }

# ---------- Serializable 字段名参与反射读写 ----------
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
    <fields>;
}

# ---------- 枚举 / Parcelable 标准规则 ----------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ---------- 第三方原始 jar/aar 无 consumer 规则，缺失类警告属预期 ----------
# slf4j-api 无绑定实现，LoggerFactory.bind() 运行时会自行降级（R8 缺类报错）
-dontwarn org.slf4j.impl.StaticLoggerBinder
-dontwarn org.slf4j.**
-dontwarn org.nanohttpd.**
-dontwarn org.jsoup.**
-dontwarn org.apache.commons.**
-dontwarn com.univocity.**
-dontwarn java.awt.**
-dontwarn javax.**
-dontwarn sun.awt.**
-dontwarn org.lwjgl.**
-dontwarn com.sun.jna.**
-dontwarn java.lang.foreign.**

# ---------- 总开关：允许 shrink + optimize，但禁止重命名 ----------
# （防止外部插件/JNI/配置文件中的类与成员名失配；崩溃堆栈保持可读）
-keepnames class * { *; }