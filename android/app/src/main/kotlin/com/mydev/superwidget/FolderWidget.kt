package com.mydev.superwidget
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class FolderWidget : AppWidgetProvider() {
    companion object {
        fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
            val p = ctx.applicationContext.getSharedPreferences("sw_folder", Context.MODE_PRIVATE)
            val alpha=p.getInt("alpha",200); val r=p.getInt("r",15); val g=p.getInt("g",15); val b=p.getInt("b",15)
            val v = RemoteViews(ctx.packageName, R.layout.folder_widget)
            v.setInt(R.id.folder_root, "setBackgroundColor", (alpha shl 24) or (r shl 16) or (g shl 8) or b)
            
            val intent = Intent(ctx, FolderRemoteService::class.java).apply {
                putExtra("wid", id)
            }
            v.setRemoteAdapter(R.id.folder_grid, intent)
            
            val pi = PendingIntent.getBroadcast(ctx, id, Intent(ctx, FolderWidget::class.java).setAction("APP_LAUNCH"), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            v.setPendingIntentTemplate(R.id.folder_grid, pi)
            
            mgr.updateAppWidget(id, v)
        }
    }
    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) { ids.forEach { update(ctx, mgr, it) } }
    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == "APP_LAUNCH") {
            val pkg = intent.getStringExtra("pkg") ?: return
            ctx.packageManager.getLaunchIntentForPackage(pkg)?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                ctx.startActivity(it)
            }
        }
    }
}
