package com.mydev.superwidget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class PhotoWidget : AppWidgetProvider() {
    companion object {
        const val ACTION = "com.mydev.superwidget.PHOTO_NEXT"
        const val PREFS = "sw_photo"

        fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
            val p = ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val arr = try { JSONArray(p.getString("photos","[]")) } catch(e:Exception){ JSONArray() }
            val idx = p.getInt("idx",0)
            val v = RemoteViews(ctx.packageName, R.layout.photo_widget)
            if (arr.length() > 0) {
                v.setViewVisibility(R.id.photo_hint, View.GONE)
                v.setViewVisibility(R.id.photo_img, View.VISIBLE)
                try {
                    val uri = Uri.parse(arr.getString(idx % arr.length()))
                    val bmp = ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it) }
                    if (bmp != null) v.setImageViewBitmap(R.id.photo_img, bmp)
                    else { v.setViewVisibility(R.id.photo_hint, View.VISIBLE); v.setViewVisibility(R.id.photo_img, View.GONE) }
                } catch(e:Exception){ v.setViewVisibility(R.id.photo_hint, View.VISIBLE); v.setViewVisibility(R.id.photo_img, View.GONE) }
            } else {
                v.setViewVisibility(R.id.photo_hint, View.VISIBLE)
                v.setViewVisibility(R.id.photo_img, View.GONE)
            }
            val pi = PendingIntent.getBroadcast(ctx, id, Intent(ctx, PhotoWidget::class.java).setAction(ACTION), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            v.setOnClickPendingIntent(R.id.photo_root, pi)
            mgr.updateAppWidget(id, v)
        }

        fun schedule(ctx: Context) {
            val pi = PendingIntent.getBroadcast(ctx, 9001, Intent(ctx, PhotoWidget::class.java).setAction(ACTION), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            (ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager).setRepeating(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 300000L, 300000L, pi)
        }
    }

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) { ids.forEach { update(ctx, mgr, it) }; schedule(ctx) }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == ACTION) {
            val p = ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val arr = try { JSONArray(p.getString("photos","[]")) } catch(e:Exception){ JSONArray() }
            if (arr.length() > 0) p.edit().putInt("idx",(p.getInt("idx",0)+1)%arr.length()).apply()
            val mgr = AppWidgetManager.getInstance(ctx)
            mgr.getAppWidgetIds(ComponentName(ctx, PhotoWidget::class.java)).forEach { update(ctx, mgr, it) }
        }
    }
}
