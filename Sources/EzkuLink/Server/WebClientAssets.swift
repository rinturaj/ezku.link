import Foundation

public enum WebClientAssets {
    public static let htmlPage: String = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>ezku.link • Ultra Low Latency Mac Cast</title>
    <style>
        :root {
            --bg-color: #0d0e12;
            --panel-bg: rgba(22, 25, 35, 0.85);
            --accent: #007aff;
            --accent-glow: rgba(0, 122, 255, 0.4);
            --live-red: #ff3b30;
            --text: #f0f3f8;
            --text-secondary: #8e95a5;
            --border: rgba(255, 255, 255, 0.1);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            -webkit-user-select: none;
            user-select: none;
        }
        
        body {
            background-color: var(--bg-color);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Roboto, sans-serif;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        /* Top HUD Bar */
        .hud-bar {
            position: fixed;
            top: 16px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 100;
            display: flex;
            align-items: center;
            gap: 12px;
            background: var(--panel-bg);
            backdrop-filter: blur(24px) saturate(180%);
            -webkit-backdrop-filter: blur(24px) saturate(180%);
            padding: 8px 18px;
            border-radius: 9999px;
            border: 1px solid var(--border);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.45);
            transition: opacity 0.3s ease, transform 0.3s ease;
        }

        .hud-bar.hidden {
            opacity: 0;
            transform: translate(-50%, -20px);
            pointer-events: none;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 700;
            font-size: 14px;
            letter-spacing: -0.2px;
            color: #ffffff;
        }

        .live-dot {
            width: 9px;
            height: 9px;
            background-color: var(--live-red);
            border-radius: 50%;
            box-shadow: 0 0 10px var(--live-red);
            animation: pulse 1.6s infinite ease-in-out;
        }

        @keyframes pulse {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.3); opacity: 0.6; }
        }

        .divider {
            width: 1px;
            height: 16px;
            background: var(--border);
        }

        .stats-badge {
            font-size: 12px;
            font-weight: 500;
            color: var(--text-secondary);
            display: flex;
            gap: 8px;
            font-variant-numeric: tabular-nums;
        }

        .stat-item span {
            color: #30d158;
            font-weight: 600;
        }

        .hud-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: var(--text);
            padding: 5px 12px;
            border-radius: 9999px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .btn:hover {
            background: rgba(255, 255, 255, 0.18);
            transform: translateY(-1px);
        }

        .btn.active {
            background: var(--accent);
            border-color: var(--accent);
            color: #fff;
            box-shadow: 0 0 14px var(--accent-glow);
        }

        /* Canvas Viewport */
        .stage {
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #000000;
            position: relative;
        }

        #screenCanvas {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            display: block;
            box-shadow: 0 0 40px rgba(0, 0, 0, 0.8);
        }

        /* Loading / Reconnecting State */
        .overlay {
            position: absolute;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: rgba(13, 14, 18, 0.88);
            backdrop-filter: blur(12px);
            z-index: 50;
            transition: opacity 0.4s ease;
        }

        .overlay.hidden {
            opacity: 0;
            pointer-events: none;
        }

        .radar {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            border: 2px solid var(--accent);
            position: relative;
            margin-bottom: 24px;
        }

        .radar::after {
            content: '';
            position: absolute;
            inset: -8px;
            border-radius: 50%;
            border: 2px solid var(--accent-glow);
            animation: ripple 2s infinite ease-out;
        }

        @keyframes ripple {
            0% { transform: scale(0.7); opacity: 1; }
            100% { transform: scale(1.6); opacity: 0; }
        }

        .overlay-title {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .overlay-desc {
            font-size: 14px;
            color: var(--text-secondary);
        }
    </style>
</head>
<body>
    <!-- Top HUD Floating Controls -->
    <div class="hud-bar" id="hudBar">
        <div class="brand">
            <div class="live-dot"></div>
            <span>ezku.link</span>
        </div>
        
        <div class="divider"></div>
        
        <div class="stats-badge">
            <div class="stat-item"><span id="fpsDisplay">0</span> FPS</div>
            <div class="stat-item"><span id="latencyDisplay">0</span> ms</div>
        </div>
        
        <div class="divider"></div>
        
        <div class="hud-actions">
            <button class="btn" id="unmuteBtn" title="Toggle Sound">
                <span id="unmuteIcon">🔊</span> Unmute
            </button>
            <button class="btn" id="fullscreenBtn" title="Fullscreen (F)">
                <span>⛶</span> Fullscreen
            </button>
        </div>
    </div>

    <!-- Main Viewport Canvas -->
    <div class="stage">
        <canvas id="screenCanvas"></canvas>
        
        <div class="overlay" id="overlay">
            <div class="radar"></div>
            <div class="overlay-title" id="overlayStatus">Connecting to Mac...</div>
            <div class="overlay-desc">Ultra-low latency ScreenCaptureKit stream</div>
        </div>
    </div>

    <script>
        const canvas = document.getElementById('screenCanvas');
        const ctx = canvas.getContext('2d', { alpha: false, desynchronized: true });
        const overlay = document.getElementById('overlay');
        const overlayStatus = document.getElementById('overlayStatus');
        const fpsDisplay = document.getElementById('fpsDisplay');
        const latencyDisplay = document.getElementById('latencyDisplay');
        const unmuteBtn = document.getElementById('unmuteBtn');
        const fullscreenBtn = document.getElementById('fullscreenBtn');
        const hudBar = document.getElementById('hudBar');

        let ws = null;
        let audioCtx = null;
        let audioQueue = [];
        let isAudioPlaying = false;
        let isMuted = true;
        let isRendering = false;
        let pendingFrameBitmap = null;

        let frameCounter = 0;
        let lastFpsUpdate = performance.now();
        let mouseTimer = null;

        // Auto-hide HUD on idle
        document.addEventListener('mousemove', () => {
            hudBar.classList.remove('hidden');
            clearTimeout(mouseTimer);
            mouseTimer = setTimeout(() => {
                if (document.fullscreenElement) {
                    hudBar.classList.add('hidden');
                }
            }, 3000);
        });

        // Fullscreen Toggle
        fullscreenBtn.addEventListener('click', toggleFullscreen);
        document.addEventListener('keydown', (e) => {
            if (e.key === 'f' || e.key === 'F') toggleFullscreen();
            if (e.key === 'm' || e.key === 'M') toggleAudio();
        });

        function toggleFullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen().catch(() => {});
            } else {
                document.exitFullscreen().catch(() => {});
            }
        }

        // Audio System
        unmuteBtn.addEventListener('click', toggleAudio);
        function toggleAudio() {
            if (!audioCtx) {
                audioCtx = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 48000 });
            }
            if (audioCtx.state === 'suspended') {
                audioCtx.resume();
            }
            isMuted = !isMuted;
            if (!isMuted) {
                unmuteBtn.classList.add('active');
                unmuteBtn.innerHTML = '<span>🔊</span> Sound ON';
            } else {
                unmuteBtn.classList.remove('active');
                unmuteBtn.innerHTML = '<span>🔇</span> Unmute';
            }
        }

        function playAudioBuffer(int16Array) {
            if (isMuted || !audioCtx) return;
            const channels = 2;
            const length = int16Array.length / channels;
            if (length <= 0) return;
            
            const audioBuffer = audioCtx.createBuffer(channels, length, 48000);
            const leftChannel = audioBuffer.getChannelData(0);
            const rightChannel = audioBuffer.getChannelData(1);

            for (let i = 0; i < length; i++) {
                leftChannel[i] = int16Array[i * 2] / 32768.0;
                rightChannel[i] = int16Array[i * 2 + 1] / 32768.0;
            }

            const source = audioCtx.createBufferSource();
            source.buffer = audioBuffer;
            source.connect(audioCtx.destination);
            source.start();
        }

        let frameWatchdog = null;
        function resetWatchdog() {
            clearTimeout(frameWatchdog);
            frameWatchdog = setTimeout(() => {
                overlayStatus.innerText = 'Broadcast Paused • Waiting for Mac...';
                overlay.classList.remove('hidden');
            }, 3000);
        }

        // Connect WebSocket
        function connect() {
            const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${location.host}/stream`;
            
            overlayStatus.innerText = 'Connecting to Mac...';
            overlay.classList.remove('hidden');

            ws = new WebSocket(wsUrl);
            ws.binaryType = 'arraybuffer';

            ws.onopen = () => {
                overlayStatus.innerText = 'Connected to Mac • Waiting for broadcast...';
            };

            ws.onclose = () => {
                clearTimeout(frameWatchdog);
                overlayStatus.innerText = 'Reconnecting to Mac...';
                overlay.classList.remove('hidden');
                setTimeout(connect, 1500);
            };

            ws.onerror = () => {
                ws.close();
            };

            ws.onmessage = async (event) => {
                if (!(event.data instanceof ArrayBuffer)) return;
                const buffer = event.data;
                const view = new DataView(buffer);
                if (buffer.byteLength < 9) return;

                const packetType = view.getUint8(0);
                // Big-endian uint64 presentation timestamp ms
                const ptsHigh = view.getUint32(1);
                const ptsLow = view.getUint32(5);
                const ptsMs = (ptsHigh * 4294967296) + ptsLow;

                if (packetType === 1) {
                    // Video Frame received: hide overlay and reset stream watchdog
                    overlay.classList.add('hidden');
                    resetWatchdog();

                    const now = performance.now();
                    frameCounter++;
                    if (now - lastFpsUpdate >= 1000) {
                        fpsDisplay.innerText = Math.round((frameCounter * 1000) / (now - lastFpsUpdate));
                        frameCounter = 0;
                        lastFpsUpdate = now;
                    }

                    // Estimate network/encode transit latency
                    const serverTimeOffset = Date.now() - ptsMs;
                    if (serverTimeOffset >= 0 && serverTimeOffset < 10000) {
                        latencyDisplay.innerText = Math.min(999, Math.max(1, serverTimeOffset));
                    }

                    const jpegBytes = new Uint8Array(buffer, 9);
                    const blob = new Blob([jpegBytes], { type: 'image/jpeg' });
                    
                    try {
                        const bitmap = await createImageBitmap(blob);
                        if (pendingFrameBitmap) {
                            pendingFrameBitmap.close();
                        }
                        pendingFrameBitmap = bitmap;
                        requestRender();
                    } catch (e) {
                        // Frame decode error; drop frame gracefully
                    }
                } else if (packetType === 2) {
                    // Audio PCM Packet (Int16 stereo 48kHz)
                    if (!isMuted && audioCtx) {
                        const pcmData = new Int16Array(buffer, 9);
                        playAudioBuffer(pcmData);
                    }
                }
            };
        }

        function requestRender() {
            if (isRendering) return;
            isRendering = true;
            requestAnimationFrame(() => {
                isRendering = false;
                if (!pendingFrameBitmap) return;
                
                if (canvas.width !== pendingFrameBitmap.width || canvas.height !== pendingFrameBitmap.height) {
                    canvas.width = pendingFrameBitmap.width;
                    canvas.height = pendingFrameBitmap.height;
                }
                
                ctx.drawImage(pendingFrameBitmap, 0, 0);
                pendingFrameBitmap.close();
                pendingFrameBitmap = null;
            });
        }

        window.addEventListener('load', connect);
    </script>
</body>
</html>
"""

    public static let tvPage: String = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ezku.link TV Mode</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background-color: #000;
            color: #fff;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        #screenCanvas, #streamImg {
            width: 100vw;
            height: 100vh;
            object-fit: contain;
            display: block;
        }
        .tv-overlay {
            position: absolute;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: rgba(0,0,0,0.85);
            z-index: 10;
            transition: opacity 0.5s ease;
        }
        .tv-overlay.hidden { opacity: 0; pointer-events: none; }
        .tv-title { font-size: 38px; font-weight: 700; margin-bottom: 12px; }
        .tv-subtitle { font-size: 20px; color: #888; }
        .tv-hint {
            position: absolute;
            bottom: 30px;
            font-size: 16px;
            color: #666;
            background: rgba(255,255,255,0.08);
            padding: 8px 18px;
            border-radius: 20px;
        }
    </style>
</head>
<body>
    <canvas id="screenCanvas"></canvas>
    <img id="streamImg" style="display:none;" alt="ezku.link Stream" />
    
    <div class="tv-overlay" id="overlay">
        <div class="tv-title">ezku.link TV</div>
        <div class="tv-subtitle" id="status">Connecting to Mac...</div>
        <div class="tv-hint">Press [Enter] or [Play] on your TV remote to toggle audio</div>
    </div>

    <script>
        const canvas = document.getElementById('screenCanvas');
        const streamImg = document.getElementById('streamImg');
        const ctx = canvas.getContext('2d', { alpha: false, desynchronized: true });
        const overlay = document.getElementById('overlay');
        const statusText = document.getElementById('status');
        
        let ws = null;
        let audioCtx = null;
        let isMuted = false;
        let isRendering = false;
        let currentObjUrl = null;

        function initAudio() {
            if (!audioCtx) {
                audioCtx = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 48000 });
            }
            if (audioCtx.state === 'suspended') {
                audioCtx.resume();
            }
        }

        // TV Remote key events (Enter / OK / Play)
        window.addEventListener('keydown', (e) => {
            initAudio();
            if (e.keyCode === 13 || e.key === 'Enter') {
                isMuted = !isMuted;
            }
        });
        window.addEventListener('click', () => { initAudio(); });

        let tvWatchdog = null;
        function resetTVWatchdog() {
            clearTimeout(tvWatchdog);
            tvWatchdog = setTimeout(() => {
                statusText.innerText = 'Broadcast Paused • Waiting for Mac...';
                overlay.classList.remove('hidden');
            }, 3500);
        }

        function renderBitmap(bitmap) {
            if (canvas.width !== bitmap.width || canvas.height !== bitmap.height) {
                canvas.width = bitmap.width;
                canvas.height = bitmap.height;
            }
            ctx.drawImage(bitmap, 0, 0);
            bitmap.close();
        }

        function fallbackDrawImage(blob) {
            if (currentObjUrl) URL.revokeObjectURL(currentObjUrl);
            currentObjUrl = URL.createObjectURL(blob);
            const img = new Image();
            img.onload = () => {
                if (canvas.width !== img.naturalWidth || canvas.height !== img.naturalHeight) {
                    canvas.width = img.naturalWidth;
                    canvas.height = img.naturalHeight;
                }
                ctx.drawImage(img, 0, 0);
                URL.revokeObjectURL(currentObjUrl);
                currentObjUrl = null;
            };
            img.src = currentObjUrl;
        }

        function drawBlob(blob) {
            if (window.createImageBitmap) {
                createImageBitmap(blob).then(renderBitmap).catch(() => {
                    fallbackDrawImage(blob);
                });
            } else {
                fallbackDrawImage(blob);
            }
        }

        function switchToMJPEG() {
            canvas.style.display = 'none';
            streamImg.style.display = 'block';
            streamImg.src = '/stream.mjpg?t=' + Date.now();
            overlay.classList.add('hidden');
        }

        function connect() {
            const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${location.host}/stream`;
            
            try {
                ws = new WebSocket(wsUrl);
                ws.binaryType = 'arraybuffer';
            } catch (e) {
                switchToMJPEG();
                return;
            }

            ws.onopen = () => {
                statusText.innerText = 'Connected to Mac • Waiting for broadcast...';
            };

            ws.onclose = () => {
                clearTimeout(tvWatchdog);
                overlay.classList.remove('hidden');
                statusText.innerText = 'Reconnecting to Mac...';
                setTimeout(connect, 2000);
            };

            ws.onerror = () => {
                // If WebSocket errors out on TV browser, fallback to MJPEG
                switchToMJPEG();
            };

            ws.onmessage = async (event) => {
                if (!(event.data instanceof ArrayBuffer)) return;
                const buffer = event.data;
                const view = new DataView(buffer);
                if (buffer.byteLength < 9) return;

                const packetType = view.getUint8(0);

                if (packetType === 1) {
                    overlay.classList.add('hidden');
                    resetTVWatchdog();
                    const jpegBytes = new Uint8Array(buffer, 9);
                    const blob = new Blob([jpegBytes], { type: 'image/jpeg' });
                    drawBlob(blob);
                } else if (packetType === 2 && !isMuted && audioCtx) {
                    const pcmData = new Int16Array(buffer, 9);
                    const channels = 2;
                    const length = pcmData.length / channels;
                    if (length > 0) {
                        const audioBuf = audioCtx.createBuffer(channels, length, 48000);
                        const l = audioBuf.getChannelData(0);
                        const r = audioBuf.getChannelData(1);
                        for (let i = 0; i < length; i++) {
                            l[i] = pcmData[i * 2] / 32768.0;
                            r[i] = pcmData[i * 2 + 1] / 32768.0;
                        }
                        const src = audioCtx.createBufferSource();
                        src.buffer = audioBuf;
                        src.connect(audioCtx.destination);
                        src.start();
                    }
                }
            };
        }

        window.addEventListener('load', () => {
            connect();
            // Try auto-fullscreen for Smart TV browser
            if (document.documentElement.requestFullscreen) {
                document.documentElement.requestFullscreen().catch(() => {});
            }
        });
    </script>
</body>
</html>
"""

    public static let videoPage: String = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>ezku.link • Video Player</title>
    <style>
        :root {
            --bg-color: #000000;
            --accent: #007aff;
            --text: #ffffff;
            --text-secondary: rgba(255, 255, 255, 0.6);
            --panel: rgba(20, 20, 26, 0.85);
            --border: rgba(255, 255, 255, 0.12);
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background-color: var(--bg-color);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, sans-serif;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        #videoContainer {
            position: relative;
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #000;
        }
        video {
            width: 100%;
            height: 100%;
            object-fit: contain;
            outline: none;
        }
        .header-bar {
            position: absolute;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            align-items: center;
            gap: 12px;
            background: var(--panel);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            padding: 8px 20px;
            border-radius: 9999px;
            border: 1px solid var(--border);
            z-index: 10;
            transition: opacity 0.3s ease;
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
        }
        .header-bar.fade-out {
            opacity: 0;
            pointer-events: none;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: #30d158;
            box-shadow: 0 0 8px #30d158;
        }
        .title {
            font-size: 13px;
            font-weight: 600;
            letter-spacing: 0.2px;
        }
        .tag {
            font-size: 10px;
            font-weight: 700;
            padding: 2px 6px;
            background: rgba(0, 122, 255, 0.25);
            color: var(--accent);
            border-radius: 4px;
            text-transform: uppercase;
        }
        #errorOverlay {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            display: none;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: rgba(10, 10, 15, 0.95);
            z-index: 20;
            text-align: center;
            padding: 20px;
        }
        #errorOverlay.visible {
            display: flex;
        }
        .error-title {
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 8px;
        }
        .error-desc {
            font-size: 14px;
            color: var(--text-secondary);
            margin-bottom: 20px;
            max-width: 420px;
        }
        .retry-btn {
            background: var(--accent);
            color: #fff;
            border: none;
            padding: 10px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s ease, opacity 0.2s ease;
        }
        .retry-btn:hover {
            opacity: 0.9;
            transform: scale(1.02);
        }
    </style>
</head>
<body>
    <div id="videoContainer">
        <div class="header-bar" id="headerBar">
            <div class="status-dot"></div>
            <div class="title" id="videoTitle">ezku.link Video Player</div>
            <div class="tag">Direct 4K / HD</div>
        </div>

        <video id="player" controls autoplay playsinline preload="auto">
            <source src="/media/video" type="video/mp4">
            Your browser does not support HTML5 video streaming.
        </video>

        <div id="errorOverlay">
            <div class="error-title">No Video Currently Selected</div>
            <div class="error-desc">Please choose a video file in the ezku.link app on your Mac to start streaming directly to this screen.</div>
            <button class="retry-btn" onclick="retryVideo()">Reload Video</button>
        </div>
    </div>

    <script>
        const video = document.getElementById('player');
        const header = document.getElementById('headerBar');
        const errorOverlay = document.getElementById('errorOverlay');
        let hideTimer = null;

        function resetHeaderTimer() {
            header.classList.remove('fade-out');
            clearTimeout(hideTimer);
            hideTimer = setTimeout(() => {
                if (!video.paused) {
                    header.classList.add('fade-out');
                }
            }, 3000);
        }

        document.addEventListener('mousemove', resetHeaderTimer);
        document.addEventListener('touchstart', resetHeaderTimer);
        video.addEventListener('play', resetHeaderTimer);
        video.addEventListener('pause', () => header.classList.remove('fade-out'));

        video.addEventListener('error', (e) => {
            console.log("Video playback error or no video loaded:", e);
            errorOverlay.classList.add('visible');
        });

        video.addEventListener('loadeddata', () => {
            errorOverlay.classList.remove('visible');
            video.play().catch(() => {});
        });

        function retryVideo() {
            errorOverlay.classList.remove('visible');
            video.load();
            video.play().catch(() => {});
        }

        // TV / Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            switch(e.key) {
                case ' ':
                    if (video.paused) video.play(); else video.pause();
                    break;
                case 'ArrowRight':
                    video.currentTime = Math.min(video.duration, video.currentTime + 10);
                    break;
                case 'ArrowLeft':
                    video.currentTime = Math.max(0, video.currentTime - 10);
                    break;
                case 'f':
                case 'F':
                    if (document.fullscreenElement) {
                        document.exitFullscreen();
                    } else if (document.documentElement.requestFullscreen) {
                        document.documentElement.requestFullscreen();
                    }
                    break;
            }
        });
    </script>
</body>
</html>
"""
}

