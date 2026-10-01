package com.m_imran.maktabat_sheikh_abdul_salam_al_rustami

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.util.Calendar

internal object DailyReminders {
    private const val preferencesName = "daily_reminders"
    private const val enabledKey = "enabled"
    private const val initializedKey = "initialized"
    private const val lastOpenedKey = "last_opened_day"
    private const val channelId = "daily_invitation"
    private const val alarmAction = "com.shaikhrustami.maktabat.DAILY_REMINDER"
    private val hours = intArrayOf(10, 17)

    private fun preferences(context: Context) =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    fun isInitialized(context: Context): Boolean = preferences(context).getBoolean(initializedKey, false)

    fun isEnabled(context: Context): Boolean = preferences(context).getBoolean(enabledKey, false)

    fun canNotify(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false
        return context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
    }

    fun markOpened(context: Context) {
        if (isEnabled(context)) {
            preferences(context).edit().putInt(lastOpenedKey, today()).apply()
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        hours.forEach(manager::cancel)
    }

    fun setEnabled(context: Context, enabled: Boolean) {
        preferences(context).edit()
            .putBoolean(initializedKey, true)
            .putBoolean(enabledKey, enabled)
            .apply()
        if (enabled) {
            markOpened(context)
            createChannel(context)
            scheduleAll(context)
        } else {
            preferences(context).edit().remove(lastOpenedKey).apply()
            hours.forEach { hour ->
                pendingIntent(context, hour, PendingIntent.FLAG_NO_CREATE)?.let {
                    context.getSystemService(AlarmManager::class.java).cancel(it)
                    it.cancel()
                }
                context.getSystemService(NotificationManager::class.java).cancel(hour)
            }
        }
    }

    fun scheduleAll(context: Context) {
        if (isEnabled(context)) hours.forEach { schedule(context, it) }
    }

    fun schedule(context: Context, hour: Int) {
        if (!isEnabled(context) || hour !in hours) return
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        val intent = pendingIntent(context, hour, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
        context.getSystemService(AlarmManager::class.java)
            .setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, intent)
    }

    fun showIfUnopened(context: Context, hour: Int) {
        if (!isEnabled(context) || !canNotify(context) ||
            preferences(context).getInt(lastOpenedKey, -1) == today()
        ) return
        createChannel(context)
        val message = if (hour == 10) {
            "آج چند لمحے قرآن و سنت کے علم کے لیے نکالیں۔ ایک کتاب پڑھیں یا درس سنیں۔"
        } else {
            "آج مطالعہ یا ایک درس کے لیے وقت نکالیں۔ علمِ دین سے دل کو تازہ کریں۔"
        }
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            context, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, channelId)
        } else {
            Notification.Builder(context).setPriority(Notification.PRIORITY_DEFAULT)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_reminder)
            .setContentTitle("آج کا دعوتی پیغام")
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build()
        context.getSystemService(NotificationManager::class.java).notify(hour, notification)
    }

    private fun today(): Int = Calendar.getInstance().let {
        it.get(Calendar.YEAR) * 1000 + it.get(Calendar.DAY_OF_YEAR)
    }

    private fun pendingIntent(context: Context, hour: Int, flag: Int): PendingIntent? {
        val intent = Intent(context, DailyReminderReceiver::class.java).apply {
            action = alarmAction
            putExtra("hour", hour)
        }
        return PendingIntent.getBroadcast(context, hour, intent, flag or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val channel = NotificationChannel(
            channelId, "دعوتی یاد دہانیاں", NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = "ایپ نہ کھلنے والے دن صبح 10 اور شام 5 بجے یاد دہانی" }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}

class DailyReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.shaikhrustami.maktabat.DAILY_REMINDER") {
            val hour = intent.getIntExtra("hour", -1)
            if (hour == 10 || hour == 17) {
                try {
                    DailyReminders.showIfUnopened(context, hour)
                } finally {
                    DailyReminders.schedule(context, hour)
                }
            }
        } else if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED
        ) {
            DailyReminders.scheduleAll(context)
        }
    }
}
