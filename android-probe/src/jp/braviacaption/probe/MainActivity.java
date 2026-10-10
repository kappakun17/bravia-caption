package jp.braviacaption.probe;
import android.app.*;
import android.content.*;
import android.media.projection.*;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.widget.*;

public class MainActivity extends Activity {
 private TextView status;
 public void onCreate(Bundle state) {
  super.onCreate(state);
  LinearLayout box = new LinearLayout(this); box.setOrientation(1); box.setPadding(48,32,48,32);
  TextView heading=new TextView(this); heading.setText("BRAVIA Caption · 実機検証\n音声は保存・送信しません。AI認識はまだ行いません。"); heading.setTextSize(22); box.addView(heading);
  status=new TextView(this); box.addView(status);
  add(box,"① 他のアプリの上に表示する許可",()->startActivity(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,Uri.parse("package:"+getPackageName()))));
  add(box,"② 仮字幕を表示（地デジへ戻って確認）",()->{if(checkOverlay())startForegroundService(new Intent(this,ProbeService.class).setAction("overlay"));});
  add(box,"③ 内部音声の測定を開始",()->{
   if(!checkOverlay())return;
   if(checkSelfPermission(android.Manifest.permission.RECORD_AUDIO)!=android.content.pm.PackageManager.PERMISSION_GRANTED){requestPermissions(new String[]{android.Manifest.permission.RECORD_AUDIO},9);status.setText("許可後に③をもう一度選んでください。");return;}
   MediaProjectionManager mgr=(MediaProjectionManager)getSystemService(MEDIA_PROJECTION_SERVICE);
   startActivityForResult(mgr.createScreenCaptureIntent(),10);
  });
  add(box,"停止・字幕を消す",()->{stopService(new Intent(this,ProbeService.class));status.setText("停止しました。");});
  setContentView(box);
 }
 private boolean checkOverlay(){if(!Settings.canDrawOverlays(this)){status.setText("先に①の表示許可を有効にしてください。");return false;}return true;}
 private void add(LinearLayout box,String label,Runnable action){Button b=new Button(this);b.setText(label);b.setOnClickListener(v->action.run());box.addView(b);}
 protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==10&&result==RESULT_OK&&data!=null){startForegroundService(new Intent(this,ProbeService.class).setAction("audio").putExtra("result",result).putExtra("projection",data));status.setText("測定開始。地デジへ戻り、画面下の音声レベルを確認してください。");}}
}
