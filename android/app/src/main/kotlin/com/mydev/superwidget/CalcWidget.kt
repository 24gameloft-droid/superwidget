package com.mydev.superwidget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class CalcWidget : AppWidgetProvider() {
    companion object {
        const val ACTION="com.mydev.superwidget.CALC_BTN"
        const val PREFS="sw_calc"

        fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
            val cp=ctx.applicationContext.getSharedPreferences("sw_notif",Context.MODE_PRIVATE)
            val r=cp.getInt("cr",15);val g=cp.getInt("cg",15);val b=cp.getInt("cb",26);val a=cp.getInt("ca",204)
            val p=ctx.applicationContext.getSharedPreferences(PREFS,Context.MODE_PRIVATE)
            val display=p.getString("display_$id","0")?:"0"
            val v=RemoteViews(ctx.packageName,R.layout.calc_widget)
            v.setInt(R.id.calc_root,"setBackgroundColor",(a shl 24)or(r shl 16)or(g shl 8)or b)
            v.setTextViewText(R.id.calc_display,display)
            val btns=mapOf(R.id.b0 to "0",R.id.b1 to "1",R.id.b2 to "2",R.id.b3 to "3",R.id.b4 to "4",R.id.b5 to "5",R.id.b6 to "6",R.id.b7 to "7",R.id.b8 to "8",R.id.b9 to "9",R.id.b_dot to ".",R.id.b_add to "+",R.id.b_sub to "-",R.id.b_mul to "*",R.id.b_div to "/",R.id.b_eq to "=",R.id.b_clear to "C",R.id.b_pm to "±",R.id.b_pct to "%")
            for((btnId,btnVal)in btns){val pi=PendingIntent.getBroadcast(ctx,id*100+btnId,Intent(ctx,CalcWidget::class.java).setAction(ACTION).putExtra("wid",id).putExtra("btn",btnVal),PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE);v.setOnClickPendingIntent(btnId,pi)}
            mgr.updateAppWidget(id,v)
        }
    }

    override fun onUpdate(ctx:Context,mgr:AppWidgetManager,ids:IntArray){ids.forEach{update(ctx,mgr,it)}}

    override fun onReceive(ctx:Context,intent:Intent){
        super.onReceive(ctx,intent)
        if(intent.action==ACTION){
            val id=intent.getIntExtra("wid",-1);if(id==-1)return
            val btn=intent.getStringExtra("btn")?:return
            val p=ctx.applicationContext.getSharedPreferences(PREFS,Context.MODE_PRIVATE)
            var display=p.getString("display_$id","0")?:"0"
            var op1=p.getString("op1_$id","")?:""
            var opr=p.getString("opr_$id","")?:""
            var newE=p.getBoolean("new_$id",false)
            when(btn){
                "C"->{display="0";op1="";opr="";newE=false}
                "="->{if(opr.isNotEmpty()&&op1.isNotEmpty()){val n1=op1.toDoubleOrNull()?:0.0;val n2=display.toDoubleOrNull()?:0.0;val res=when(opr){"+"->(n1+n2);"-"->(n1-n2);"*"->(n1*n2);"/"->(if(n2!=0.0)n1/n2 else Double.NaN);else->n2};display=if(res==res.toLong().toDouble())res.toLong().toString() else "%.8f".format(res).trimEnd('0').trimEnd('.');op1="";opr="";newE=true}}
                "+","-","*","/"->{ op1=display;opr=btn;newE=true}
                "±"->{display=if(display.startsWith("-"))display.substring(1) else "-$display"}
                "%"->{val n=display.toDoubleOrNull()?:0.0;display=(n/100).toString()}
                "."->{if(!display.contains("."))display="$display."}
                else->{display=if(display=="0"||newE)btn else "$display$btn";newE=false}
            }
            p.edit().putString("display_$id",display).putString("op1_$id",op1).putString("opr_$id",opr).putBoolean("new_$id",newE).apply()
            update(ctx,AppWidgetManager.getInstance(ctx),id)
        }
    }
}
