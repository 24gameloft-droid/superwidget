package com.mydev.superwidget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import org.json.JSONArray

class FolderWidget : AppWidgetProvider() {
    companion object {
        fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
            val p = ctx.applicationContext.getSharedPreferences("sw_folder", Context.MODE_PRIVATE)
            val alpha = p.getInt("alpha", 200)
            val r = p.getInt("r", 26); val g = p.getInt("g", 26); val b = p.getInt("b", 46)
            val cols = p.getInt("cols", 4)

            val v = RemoteViews(ctx.packageName, R.layout.folder_widget)
            v.setInt(R.id.folder_root, "setBackgroundColor", (alpha shl 24) or (r shl 16) or (g shl 8) or b)

            try {
                val folders = JSONArray(p.getString("folders", "[]") ?: "[]")
                val fidx = p.getInt("wid_$id", 0)
                if (folders.length() > 0)
                    v.setTextViewText(
                        R.id.folder_name,
                        folders.getJSONObject(if (fidx < folders.length()) fidx else 0).optString("name", "Folder")
                    )
            } catch (e: Exception) {}

            val svcIntent = Intent(ctx, FolderRemoteService::class.java)
                .putExtra("wid", id)
                .putExtra("cols", cols)
            v.setRemoteAdapter(R.id.folder_list, svcIntent)

            val pi = PendingIntent.getBroadcast(
                ctx, id,
                Intent(ctx, FolderWidget::class.java).setAction("com.mydev.superwidget.APP_LAUNCH"),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            v.setPendingIntentTemplate(R.id.folder_list, pi)

            mgr.updateAppWidget(id, v)
            mgr.notifyAppWidgetViewDataChanged(id, R.id.folder_list)
        }
    }

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(ctx, mgr, it) }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == "com.mydev.superwidget.APP_LAUNCH") {
            val pkg = intent.getStringExtra("pkg") ?: return
            ctx.packageManager.getLaunchIntentForPackage(pkg)?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                ctx.startActivity(it)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(ctx: Context, mgr: AppWidgetManager, id: Int, opts: Bundle) {
        update(ctx, mgr, id)
    }
}
