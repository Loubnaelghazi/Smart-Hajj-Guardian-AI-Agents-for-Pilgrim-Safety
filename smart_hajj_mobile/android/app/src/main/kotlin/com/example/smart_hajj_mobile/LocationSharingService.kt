package com.example.smart_hajj_mobile

import android.Manifest
import android.app.*
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.*
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.*
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** User-started location sharing; no boot receiver, sticky restart or SOS. */
class LocationSharingService : Service(), LocationListener {
    companion object {
        const val CHANNEL = "guardian_location"
        const val NOTICE = 2401
        @Volatile var running = false
        @Volatile var phone = ""
        @Volatile var message = "Background sharing stopped."
        @Volatile var receipt: String? = null
        var active: LocationSharingService? = null
    }
    private lateinit var locations: LocationManager
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    @Volatile private var stopped = false
    private var baseUrl = ""
    private var arabic = false
    fun updateLanguage(language: String) {
        arabic = language == "ar"
        getSystemService(NotificationManager::class.java).notify(NOTICE, sharingNotification())
    }
    private fun sharingNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, if (arabic) "مشاركة الموقع" else "Location sharing", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 1, Intent(this, LocationSharingService::class.java).setAction("STOP"), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        return builder.setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle(if (arabic) "حارس الحاج · مشاركة الموقع" else "Hajj Guardian location sharing")
            .setContentText(if (arabic) "تتم مشاركة موقعك مع وكالتك أثناء هذه الجلسة." else "Sharing with your agency while this session is active.")
            .setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null, if (arabic) "إيقاف المشاركة" else "Stop sharing", stop).build()).build()
    }
    private var latest: Location? = null
    private var lastAttempt = 0L
    private val tick = object : Runnable {
        override fun run() {
            if (stopped) return
            val fix = latest
            if (fix == null || SystemClock.elapsedRealtimeNanos() - fix.elapsedRealtimeNanos > 120_000_000_000L) {
                message = "Waiting for a fresh GPS fix. Check phone location services."
            } else if (SystemClock.elapsedRealtime() - lastAttempt >= 30000) upload(fix)
            handler.postDelayed(this, 5000)
        }
    }

    override fun onBind(intent: Intent?) = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") { stopSelf(); return START_NOT_STICKY }
        if (running) return START_NOT_STICKY
        phone = intent?.getStringExtra("phone") ?: ""
        baseUrl = intent?.getStringExtra("baseUrl")?.trimEnd('/') ?: ""
        if (phone.isBlank() || baseUrl.isBlank()) { stopSelf(); return START_NOT_STICKY }
        arabic = intent?.getStringExtra("language") == "ar"
        val notification = sharingNotification()
        try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(NOTICE, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            else startForeground(NOTICE, notification)
            locations = getSystemService(LocationManager::class.java)
            val precise = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            val approximate = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            if (!precise && !approximate) throw SecurityException("Location permission required")
            if (precise && locations.allProviders.contains(LocationManager.GPS_PROVIDER)) locations.requestLocationUpdates(LocationManager.GPS_PROVIDER, 10000, 0f, this, Looper.getMainLooper())
            if (locations.allProviders.contains(LocationManager.NETWORK_PROVIDER)) locations.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 10000, 0f, this, Looper.getMainLooper())
            active = this
            running = true; message = "Background sharing active. Waiting for GPS…"; receipt = null
            handler.post(tick)
        } catch (e: Exception) { message = "Cannot start location sharing. Check location permission and services."; stopSelf() }
        return START_NOT_STICKY
    }

    override fun onLocationChanged(location: Location) {
        if (stopped) return
        if (latest == null || location.elapsedRealtimeNanos > latest!!.elapsedRealtimeNanos) latest = Location(location)
        if (SystemClock.elapsedRealtime() - lastAttempt >= 30000) upload(location)
    }
    override fun onProviderDisabled(provider: String) { message = "Location provider unavailable. Waiting for a fresh fix." }
    override fun onProviderEnabled(provider: String) {}
    @Deprecated("Legacy callback") override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    private fun upload(fix: Location) {
        if (stopped || fix.accuracy <= 0 || SystemClock.elapsedRealtimeNanos() - fix.elapsedRealtimeNanos > 120_000_000_000L || !busy.compareAndSet(false, true)) return
        lastAttempt = SystemClock.elapsedRealtime()
        val currentPhone = phone
        executor.execute {
            try {
                val network = getSystemService(ConnectivityManager::class.java)
                val caps = network.getNetworkCapabilities(network.activeNetwork)
                val connection = when {
                    caps == null -> "none"
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                    else -> "other"
                }
                val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
                val body = JSONObject().put("phone_number", currentPhone).put("latitude", fix.latitude).put("longitude", fix.longitude)
                    .put("accuracy_m", fix.accuracy.toDouble()).put("measured_at", formatter.format(Date(fix.time)))
                    .put("mocked", if (Build.VERSION.SDK_INT >= 31) fix.isMock else fix.isFromMockProvider)
                    .put("connection", JSONArray().put(connection))
                if (stopped) return@execute
                val response = post("/api/mobile/observations", body)
                if (stopped) return@execute
                receipt = response.toString()
                message = "GPS received by your agency. Background sharing active."
                val area = response.optJSONObject("safe_area")
                if (area != null && !stopped) {
                    try {
                        post("/api/guardian/analyze", JSONObject().put("phone_number", currentPhone).put("safe_area", area))
                    } catch (e: Exception) { if (!stopped) message = "GPS received; safety check unavailable. Sharing continues." }
                }
            } catch (e: Exception) {
                if (!stopped) message = "GPS upload not confirmed. Retrying with a fresh fix; check connection."
            } finally { busy.set(false) }
        }
    }

    private fun post(path: String, body: JSONObject): JSONObject {
        val connection = URL(baseUrl + path).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"; connection.connectTimeout = 10000; connection.readTimeout = 90000
            connection.doOutput = true; connection.setRequestProperty("Content-Type", "application/json")
            connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            if (connection.responseCode !in 200..299) throw IllegalStateException("Upload not accepted")
            return JSONObject(connection.inputStream.bufferedReader().use { it.readText() })
        } finally { connection.disconnect() }
    }

    override fun onDestroy() {
        active = null
        stopped = true; running = false; phone = ""; receipt = null
        message = "Background sharing stopped."
        handler.removeCallbacksAndMessages(null)
        if (::locations.isInitialized) locations.removeUpdates(this)
        executor.shutdownNow()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
