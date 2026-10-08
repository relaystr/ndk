package relaystr.ndk

import java.io.File
import java.nio.file.Files
import java.util.concurrent.TimeUnit
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class UpdateApkCacheTest {
    @Test
    fun prunesOnlyExpiredUpdateApks() {
        val directory = Files.createTempDirectory("ndk-updates-test").toFile()
        try {
            val now = System.currentTimeMillis()
            val cutoff = now - TimeUnit.DAYS.toMillis(1)
            fun file(name: String, modified: Long): File = File(directory, name).apply {
                writeText("apk")
                assertTrue(setLastModified(modified))
            }
            val expired = file("update-expired.apk", cutoff - 1)
            val recent = file("update-recent.apk", now)
            val boundary = file("update-boundary.apk", cutoff)
            val unrelated = file("other.apk", cutoff - 1)
            val otherExtension = file("update-other.txt", cutoff - 1)
            val nested = File(directory, "update-directory.apk").apply {
                mkdir()
                setLastModified(cutoff - 1)
            }

            pruneUpdateApks(directory, now)

            assertFalse(expired.exists())
            listOf(recent, boundary, unrelated, otherExtension, nested).forEach {
                assertTrue(it.exists(), "Should retain ${it.name}")
            }
            pruneUpdateApks(File(directory, "missing"), now)
        } finally {
            directory.deleteRecursively()
        }
    }
}
