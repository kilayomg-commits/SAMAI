package pe.samai.samai

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity: requerido por local_auth (huella / rostro).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // FLAG_SECURE: oculta el contenido en "Recientes" e impide capturas de
        // pantalla, para proteger los registros emocionales.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
    }
}
