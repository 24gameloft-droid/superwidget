package com.mydev.superwidget

import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotifService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if(sbn.isOngoing) return
        val extras=sbn.notification.extras
        val title=extras.getString("android.title")?:""
        val text=extras.getCharSequence("android.text")?.toString()?:""
        if(title.isEmpty()&&text.isEmpty()) return
        val p=getSharedPreferences("sw_notif",Context.MODE_PRIVATE)
        val allowed=p.getStringSet("allowed",emptySet())?:emptySet()
        if(allowed.isNotEmpty()&&!allowed.contains(sbn.packageName)) return
        if(!Settings.canDrawOverlays(this)) return
        val appName=try{packageManager.getApplicationLabel(packageManager.getApplicationInfo(sbn.packageName,0)).toString()}catch(e:Exception){sbn.packageName}
        OverlayService.show(this,appName,title,text,sbn.packageName)
    }
}
