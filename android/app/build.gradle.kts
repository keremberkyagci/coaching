// Gerekli sınıfların import edildiği blok.
import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.Project
import kotlin.io.path.exists

// Bu dosyanın en üstünde sadece eklentiler (plugins) tanımlanmalıdır.
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase eklentisi. Proje seviyesindeki build.gradle ile versiyonu uyumlu olmalıdır.
    id("com.google.gms.google-services")
}

// local.properties dosyasından Flutter versiyon bilgilerini okumak için
// kullanılan yardımcı fonksiyon. Bu blokta bir değişiklik gerekmez.
fun localProperties(key: String, project: Project): String {
    val properties = Properties()
    val localPropertiesFile = project.rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
    }
    return properties.getProperty(key, "")
}

// Android'e özel tüm yapılandırmalar bu blok içinde yer alır.
android {
    // Uygulamanızın paket adı. google-services.json dosyanızdaki paket adıyla eşleşmelidir.
    namespace = "com.example.focus_app_v2_final"

    // İsteğiniz doğrultusunda compileSdk 36'ya ayarlandı.
    // 36, Android 15'in geliştirici önizlemesini temsil eder. Genellikle 34 (Android 14) daha stabil bir seçimdir
    // ancak projeniz gerektiriyorsa 36 kullanılabilir.
    compileSdk = 36

    // Java versiyonu uyumluluğu için gerekli blok.
    // Bu, "source value 8 is obsolete" uyarısını giderir ve "java 1,8" standardını sağlar.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // Kotlin derleyicisine, Java 1.8 ile uyumlu bytecode üretmesini söyler.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }

    // Kotlin kaynak dosyalarının nerede olduğunu belirtir. Standart yapı.
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.focus_app_v2_final"
        minSdk = flutter.minSdkVersion // Modern Flutter için 23 iyi bir başlangıç noktasıdır.
        // targetSdk de compileSdk ile aynı olmalıdır. İsteğiniz doğrultusunda 36'ya güncellendi.
        targetSdk = 36
        versionCode = (localProperties("flutter.versionCode", project).takeIf { it.isNotEmpty() } ?: "1").toInt()
        versionName = localProperties("flutter.versionName", project).takeIf { it.isNotEmpty() } ?: "1.0"

        // 65K metod limitini aşan büyük uygulamalar için MultiDex desteğini etkinleştirir.
        multiDexEnabled = true
    }

    // Yayın (Release) modu için imzalama yapılandırmaları burada yapılır.
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Flutter eklentisinin, projenin kök dizinini bulmasını sağlar.
flutter {
    source = "../.."
}

// Uygulamanızın bağımlılıkları (kullandığı kütüphaneler).
dependencies {
    // Firebase "Bill of Materials" (BOM), tüm Firebase paketlerinin uyumlu versiyonlarını yönetir.
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // BOM kullanıldığı için, bu paketlerin versiyonlarını belirtmeye gerek yoktur.
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // Kotlin standart kütüphanesi.
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.23")

    // MultiDex desteği için gerekli kütüphane.
    implementation("androidx.multidex:multidex:2.0.1")
}

