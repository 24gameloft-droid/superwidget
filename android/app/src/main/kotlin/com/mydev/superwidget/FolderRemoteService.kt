package com.mydev.superwidget

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class FolderRemoteService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent) =
        Factory(applicationContext, intent.getIntExtra("wid", -1), intent.getIntExtra("cols", 4))
}

class Factory(
    private val ctx: Context,
    private val wid: Int,
    private val cols: Int
) : RemoteViewsService.RemoteViewsFactory {

    private val pkgs = mutableListOf<String>()

    override fun onCreate() { load() }
    override fun onDataSetChanged() { load() }
    override fun onDestroy() { pkgs.clear() }

    private fun load() {
        pkgs.clear()
        try {
            val p = ctx.getSharedPreferences("sw_folder", Context.MODE_PRIVATE)
            val folders = JSONArray(p.getString("folders", "[]") ?: "[]")
            val fidx = p.getInt("wid_$wid", 0)
            if (folders.length() > 0) {
                val apps = folders
                    .getJSONObject(if (fidx < folders.length()) fidx else 0)
                    .optJSONArray("apps") ?: JSONArray()
                for (i in 0 until apps.length()) pkgs.add(apps.getString(i))
            }
        } catch (e: Exception) {}
    }

    // عدد الصفوف = ceil(pkgs.size / cols)
    override fun getCount(): Int = if (pkgs.isEmpty()) 0 else (pkgs.size + cols - 1) / cols
    override fun getLoadingView() = null
    override fun getViewTypeCount() = 1
    override fun getItemId(pos: Int) = pos.toLong()
    override fun hasStableIds() = true

    override fun getViewAt(pos: Int): RemoteViews {
        val rv = RemoteViews(ctx.packageName, R.layout.folder_row)
        val iconIds = listOf(R.id.icon0, R.id.icon1, R.id.icon2, R.id.icon3)
        val cellIds = listOf(R.id.cell0, R.id.cell1, R.id.cell2, R.id.cell3)

        for (col in 0 until 4) {
            val appIdx = pos * cols + col
            if (col < cols && appIdx < pkgs.size) {
                rv.setViewVisibility(cellIds[col], View.VISIBLE)
                try {
                    rv.setImageViewBitmap(iconIds[col], toBmp(ctx.packageManager.getApplicationIcon(pkgs[appIdx])))
                } catch (e: Exception) {
                    rv.setImageViewResource(iconIds[col], android.R.drawable.sym_def_app_icon)
                }
                rv.setOnClickFillInIntent(cellIds[col], Intent().putExtra("pkg", pkgs[appIdx]))
            } else {
                rv.setViewVisibility(cellIds[col], View.INVISIBLE)
            }
        }
        return rv
    }

    private fun toBmp(d: Drawable): Bitmap {
        if (d is BitmapDrawable && d.bitmap != null) return d.bitmap
        val w = if (d.intrinsicWidth > 0) d.intrinsicWidth else 96
        val h = if (d.intrinsicHeight > 0) d.intrinsicHeight else 96
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        d.setBounds(0, 0, w, h); d.draw(Canvas(bmp)); return bmp
    }
}
