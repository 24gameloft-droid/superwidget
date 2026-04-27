package com.mydev.superwidget
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import java.io.File

class PhotoWidget : AppWidgetProvider() {
    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            val v = RemoteViews(ctx.packageName, R.layout.photo_widget)
            val path = ctx.getSharedPreferences("sw_photo", Context.MODE_PRIVATE).getString("path_$id", null)
            if (path != null && File(path).exists()) {
                v.setImageViewBitmap(R.id.photo_img, BitmapFactory.decodeFile(path))
                v.setViewVisibility(R.id.photo_img, View.VISIBLE)
            }
            mgr.updateAppWidget(id, v)
        }
    }
}
