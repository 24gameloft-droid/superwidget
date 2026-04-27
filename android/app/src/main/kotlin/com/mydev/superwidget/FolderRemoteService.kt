package com.mydev.superwidget
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class FolderRemoteService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent) = Factory(applicationContext, intent.getIntExtra("wid", -1))
}

class Factory(private val ctx: Context, private val wid: Int) : RemoteViewsService.RemoteViewsFactory {
    private val pkgs = mutableListOf<String>()
    override fun onCreate() { load() }
    override fun onDataSetChanged() { load() }
    override fun onDestroy() { pkgs.clear() }
    private fun load() {
        pkgs.clear()
        try {
            val p = ctx.getSharedPreferences("sw_folder", Context.MODE_PRIVATE)
            val folders = JSONArray(p.getString("folders", "[]"))
            val fidx = p.getInt("wid_$wid", 0)
            if (folders.length() > 0) {
                val apps = folders.getJSONObject(if(fidx < folders.length()) fidx else 0).optJSONArray("apps")
                if (apps != null) for (i in 0 until apps.length()) pkgs.add(apps.getString(i))
            }
        } catch(e: Exception) {}
    }
    override fun getCount() = pkgs.size
    override fun getLoadingView() = null
    override fun getViewTypeCount() = 1
    override fun getItemId(p: Int) = p.toLong()
    override fun hasStableIds() = true
    override fun getViewAt(pos: Int): RemoteViews {
        val rv = RemoteViews(ctx.packageName, R.layout.folder_item)
        if (pos >= pkgs.size) return rv
        try {
            val icon = ctx.packageManager.getApplicationIcon(pkgs[pos])
            rv.setImageViewBitmap(R.id.item_icon, toBmp(icon))
            rv.setOnClickFillInIntent(R.id.item_root, Intent().putExtra("pkg", pkgs[pos]))
        } catch(e: Exception) {}
        return rv
    }
    private fun toBmp(d: Drawable): Bitmap {
        if (d is BitmapDrawable) return d.bitmap
        val b = Bitmap.createBitmap(128, 128, Bitmap.Config.ARGB_8888)
        val c = Canvas(b); d.setBounds(0, 0, 128, 128); d.draw(c); return b
    }
}
