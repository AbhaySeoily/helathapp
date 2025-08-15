package com.example.stepcounter


import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.collections.ArrayList
import kotlin.collections.HashMap

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.usage.stats/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "hasUsagePermission" -> {
                            result.success(hasUsageStatsPermission())
                        }
                        "openUsageSettings" -> {
                            openUsageAccessSettings()
                            result.success(true)
                        }
                        "getUsageStats" -> {
                            result.success(getUsageStatsLast24h())
                        }
                        "getDailyTotals" -> {
                            val days = call.argument<Int>("days") ?: 7
                            result.success(getDailyTotals(days))
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val list = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            now - 1000 * 60,
            now
        )
        return list != null && list.isNotEmpty()
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    /** Last 24h per-app usage (non-system, >0) */
//    private fun getUsageStatsLast24h(): List<Map<String, Any>> {
//        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
//        val pm = packageManager
//
//        val end = System.currentTimeMillis()
//        val cal = Calendar.getInstance()
//        cal.timeInMillis = end
//        cal.add(Calendar.DAY_OF_YEAR, -1)
//        val start = cal.timeInMillis
//
//        val stats: List<UsageStats> = usm.queryUsageStats(
//            UsageStatsManager.INTERVAL_DAILY, start, end
//        ) ?: emptyList()
//
//        val out = ArrayList<Map<String, Any>>()
//
//        for (u in stats) {
//            try {
//                if (u.totalTimeInForeground <= 0) continue
//                val pkg = u.packageName
//                val ai = pm.getApplicationInfo(pkg, 0)
//
//                // skip system apps (optional)
//                if ((ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0) continue
//
//                val appName = pm.getApplicationLabel(ai).toString()
//
//                val map = hashMapOf<String, Any>(
//                    "packageName" to pkg,
//                    "appName" to appName,
//                    "totalTimeMs" to u.totalTimeInForeground, // long
//                    "lastTimeUsed" to u.lastTimeUsed // long
//                )
//                out.add(map)
//            } catch (e: PackageManager.NameNotFoundException) {
//                // ignore
//            }
//        }
//
//        // sort by usage desc
//        out.sortByDescending { (it["totalTimeMs"] as Number).toLong() }
//        return out
//    }
    /** Last 24h per-app usage (including system apps) */
    private fun getUsageStatsLast24h(): List<Map<String, Any>> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager

        val end = System.currentTimeMillis()
        val cal = Calendar.getInstance()
        cal.timeInMillis = end
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val start = cal.timeInMillis

        val stats: List<UsageStats> = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, start, end
        ) ?: emptyList()

        val out = ArrayList<Map<String, Any>>()

        for (u in stats) {
            if (u.totalTimeInForeground <= 0) continue
            val pkg = u.packageName
            val ai = try { pm.getApplicationInfo(pkg, 0) } catch (_: Exception) { null }
            val appName = if (ai != null) pm.getApplicationLabel(ai).toString() else pkg

            val map = hashMapOf<String, Any>(
                "packageName" to pkg,
                "appName" to appName,
                "totalTimeMs" to u.totalTimeInForeground,
                "lastTimeUsed" to u.lastTimeUsed
            )
            out.add(map)
        }

        out.sortByDescending { (it["totalTimeMs"] as Number).toLong() }
        return out
    }

    /** Daily totals for the last [days] (today included). */
//    private fun getDailyTotals(days: Int): List<Map<String, Any>> {
//        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
//        val pm = packageManager
//
//        val end = System.currentTimeMillis()
//        val calStart = Calendar.getInstance()
//        calStart.timeInMillis = end
//        calStart.set(Calendar.HOUR_OF_DAY, 0)
//        calStart.set(Calendar.MINUTE, 0)
//        calStart.set(Calendar.SECOND, 0)
//        calStart.set(Calendar.MILLISECOND, 0)
//        calStart.add(Calendar.DAY_OF_YEAR, -(days - 1))
//        val start = calStart.timeInMillis
//
//        val stats: List<UsageStats> = usm.queryUsageStats(
//            UsageStatsManager.INTERVAL_DAILY, start, end
//        ) ?: emptyList()
//
//        // group by "dayStart" (00:00 local) -> aggregate totals and top app
//        val totalsByDay = HashMap<Long, Long>()
//        val topByDay = HashMap<Long, Pair<String, Long>>() // name, ms
//
//        for (u in stats) {
//            if (u.totalTimeInForeground <= 0) continue
//
//            // derive bucket day start from firstTimeStamp
//            val c = Calendar.getInstance()
//            c.timeInMillis = u.firstTimeStamp
//            c.set(Calendar.HOUR_OF_DAY, 0)
//            c.set(Calendar.MINUTE, 0)
//            c.set(Calendar.SECOND, 0)
//            c.set(Calendar.MILLISECOND, 0)
//            val dayStart = c.timeInMillis
//
//            val ai = try { pm.getApplicationInfo(u.packageName, 0) } catch (_: Exception) { null }
//            val appName = if (ai != null) pm.getApplicationLabel(ai).toString() else u.packageName
//
//            val prev = totalsByDay[dayStart] ?: 0L
//            val newTotal = prev + u.totalTimeInForeground
//            totalsByDay[dayStart] = newTotal
//
//            val prevTop = topByDay[dayStart]
//            if (prevTop == null || u.totalTimeInForeground > prevTop.second) {
//                topByDay[dayStart] = Pair(appName, u.totalTimeInForeground)
//            }
//        }
//
//        val daysList = totalsByDay.keys.sorted()
//        val out = ArrayList<Map<String, Any>>()
//        for (d in daysList) {
//            val total = totalsByDay[d] ?: 0L
//            val top = topByDay[d]?.first ?: ""
//            val map = hashMapOf<String, Any>(
//                "dayStartMs" to d,
//                "totalTimeMs" to total,
//                "topAppName" to top
//            )
//            out.add(map)
//        }
//        return out
//    }

    /** Daily totals for the last [days] (today included). */
    private fun getDailyTotals(days: Int): List<Map<String, Any>> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager

        val now = Calendar.getInstance()
        val end = now.timeInMillis

        // start from midnight X days ago
        val calStart = Calendar.getInstance()
        calStart.set(Calendar.HOUR_OF_DAY, 0)
        calStart.set(Calendar.MINUTE, 0)
        calStart.set(Calendar.SECOND, 0)
        calStart.set(Calendar.MILLISECOND, 0)
        calStart.add(Calendar.DAY_OF_YEAR, -(days - 1))
        val start = calStart.timeInMillis

        val stats: List<UsageStats> = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, start, end
        ) ?: emptyList()

        // group by "dayStart" based on LAST usage time
        val totalsByDay = HashMap<Long, Long>()
        val topByDay = HashMap<Long, Pair<String, Long>>() // name, ms

        for (u in stats) {
            if (u.totalTimeInForeground <= 0) continue

            val c = Calendar.getInstance()
            c.timeInMillis = u.lastTimeUsed
            c.set(Calendar.HOUR_OF_DAY, 0)
            c.set(Calendar.MINUTE, 0)
            c.set(Calendar.SECOND, 0)
            c.set(Calendar.MILLISECOND, 0)
            val dayStart = c.timeInMillis

            // skip if outside requested range
            if (dayStart < start) continue

            val ai = try { pm.getApplicationInfo(u.packageName, 0) } catch (_: Exception) { null }
            val appName = if (ai != null) pm.getApplicationLabel(ai).toString() else u.packageName

            totalsByDay[dayStart] = (totalsByDay[dayStart] ?: 0L) + u.totalTimeInForeground

            val prevTop = topByDay[dayStart]
            if (prevTop == null || u.totalTimeInForeground > prevTop.second) {
                topByDay[dayStart] = Pair(appName, u.totalTimeInForeground)
            }
        }

        // ensure all days are represented, even with 0 usage
        val out = ArrayList<Map<String, Any>>()
        val temp = Calendar.getInstance()
        temp.timeInMillis = start
        for (i in 0 until days) {
            val dayStart = temp.timeInMillis
            val total = totalsByDay[dayStart] ?: 0L
            val top = topByDay[dayStart]?.first ?: ""
            out.add(
                hashMapOf(
                    "dayStartMs" to dayStart,
                    "totalTimeMs" to total,
                    "topAppName" to top
                )
            )
            temp.add(Calendar.DAY_OF_YEAR, 1)
        }
        return out
    }

}
