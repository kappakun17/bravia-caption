package jp.braviacaption.probe;
import android.app.*;
import android.content.*;
import android.media.*;
import android.media.projection.*;
import android.os.*;
import android.graphics.Color;
import android.view.*;
import android.widget.TextView;
import java.util.Locale;

public class ProbeService extends Service {
 private final Handler ui=new Handler(Looper.getMainLooper());
 private WindowManager windows; private TextView caption;
 private AudioRecord recorder; private MediaProjection projection;
 private volatile boolean reading; private Thread worker;
 public IBinder onBind(Intent i){return null;}
 public void onCreate(){super.onCreate();NotificationManager nm=(NotificationManager)getSystemService(NOTIFICATION_SERVICE);nm.createNotificationChannel(new NotificationChannel("probe","字幕検証",NotificationManager.IMPORTANCE_LOW));startForeground(1,new Notification.Builder(this,"probe").setSmallIcon(android.R.drawable.ic_media_play).setContentTitle("BRAVIA字幕検証中").setContentText("停止は検証アプリから").build());}
 public int onStartCommand(Intent intent,int flags,int id){
  if(intent==null){stopSelf();return START_NOT_STICKY;}
  try {
   if(caption==null){caption=new TextView(this);caption.setTextSize(26);caption.setTextColor(Color.WHITE);caption.setBackgroundColor(0xDD000000);caption.setPadding(24,12,24,12);caption.setGravity(Gravity.CENTER);windows=(WindowManager)getSystemService(WINDOW_SERVICE);WindowManager.LayoutParams p=new WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT,WindowManager.LayoutParams.WRAP_CONTENT,WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE|WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,android.graphics.PixelFormat.TRANSLUCENT);p.gravity=Gravity.BOTTOM;p.y=60;windows.addView(caption,p);}
   if("audio".equals(intent.getAction())) {
    if(reading){caption.setText("既に測定中です。再測定は停止してから開始してください。");return START_NOT_STICKY;}
    MediaProjectionManager mgr=(MediaProjectionManager)getSystemService(MEDIA_PROJECTION_SERVICE);
    projection=mgr.getMediaProjection(intent.getIntExtra("result",Activity.RESULT_CANCELED),intent.getParcelableExtra("projection"));
    projection.registerCallback(new MediaProjection.Callback(){public void onStop(){stopSelf();}},ui);
    AudioPlaybackCaptureConfiguration cfg=new AudioPlaybackCaptureConfiguration.Builder(projection).addMatchingUsage(AudioAttributes.USAGE_MEDIA).addMatchingUsage(AudioAttributes.USAGE_GAME).addMatchingUsage(AudioAttributes.USAGE_UNKNOWN).build();
    int size=Math.max(16000,AudioRecord.getMinBufferSize(16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT));
    recorder=new AudioRecord.Builder().setAudioFormat(new AudioFormat.Builder().setSampleRate(16000).setChannelMask(AudioFormat.CHANNEL_IN_MONO).setEncoding(AudioFormat.ENCODING_PCM_16BIT).build()).setBufferSizeInBytes(size).setAudioPlaybackCaptureConfig(cfg).build();
    if(recorder.getState()!=AudioRecord.STATE_INITIALIZED)throw new IllegalStateException("AudioRecord初期化失敗");
    recorder.startRecording();reading=true;worker=new Thread(()->measure());worker.start();
   } else if(!reading)caption.setText("仮字幕：地デジ画面でこの文字が見えるか確認してください");
  }catch(Exception e){if(caption!=null)caption.setText("検証エラー: "+e.getClass().getSimpleName()+" "+e.getMessage());android.util.Log.e("CaptionProbe","probe failed",e);}
  return START_NOT_STICKY;
 }
 private void measure(){
  short[] samples=new short[1600];long total=0,nonzero=0;long begin=SystemClock.elapsedRealtime(),last=begin;double energy=0;long window=0;int peak=0;
  while(reading){int n=recorder.read(samples,0,samples.length);if(n<0){ui.post(()->{if(caption!=null)caption.setText("音声readエラー: "+n);});break;}for(int k=0;k<n;k++){int v=samples[k];if(v!=0)nonzero++;peak=Math.max(peak,Math.abs(v));energy+=(double)v*v;window++;}total+=n;long now=SystemClock.elapsedRealtime();if(now-last>=1000){double db=window>0&&energy>0?20*Math.log10(Math.sqrt(energy/window)/32768.0):-120;String line=String.format(Locale.US,"内部音声 %ds | RMS %.1f dBFS | peak %d | 非ゼロ %d / %d\n無音が続いても取得不可とは未確定。地デジ→YouTubeで比較してください。",(now-begin)/1000,db,peak,nonzero,total);ui.post(()->{if(caption!=null)caption.setText(line);});last=now;energy=0;window=0;peak=0;}}
 }
 public void onDestroy(){reading=false;if(recorder!=null){try{recorder.stop();}catch(Exception ignored){}if(worker!=null)try{worker.join(1500);}catch(InterruptedException e){Thread.currentThread().interrupt();}recorder.release();}if(projection!=null)projection.stop();if(caption!=null){windows.removeView(caption);caption=null;}super.onDestroy();}
}
