package relaystr.ndk

import java.io.File
import java.util.concurrent.TimeUnit

internal fun pruneUpdateApks(directory: File, now: Long = System.currentTimeMillis()) {
    // The installer reads the shared APK asynchronously. Keep recent downloads,
    // and prune abandoned/successful installs on startup or the next download.
    val cutoff = now - TimeUnit.DAYS.toMillis(1)
    directory.listFiles()?.forEach { file ->
        if (file.isFile && file.name.startsWith("update-") &&
            file.extension == "apk" && file.lastModified() < cutoff) {
            file.delete()
        }
    }
}
