
import subprocess
import time
import sys
import os

def run_backend():
    print("🚀 Starting FastAPI Backend...")
    return subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"],
        cwd=os.getcwd(),
        shell=True
    )

def run_flutter():
    print("📱 Starting Flutter Frontend (Chrome)...")
    flutter_path = os.path.join(os.getcwd(), "flutter_app", "hackathon_2")
    return subprocess.Popen(
        ["flutter", "run", "-d", "chrome"],
        cwd=flutter_path,
        shell=True
    )

if __name__ == "__main__":
    backend_proc = None
    flutter_proc = None
    
    try:
        # 1. Start Backend
        backend_proc = run_backend()
        
        # Give backend a moment to warm up
        time.sleep(3)
        
        # 2. Start Flutter
        flutter_proc = run_flutter()
        
        print("\n✅ Both services are launching!")
        print("Backend: http://localhost:8000")
        print("Frontend: launching in Chrome...")
        print("\nPress Ctrl+C to stop both services.")
        
        # Keep the script alive
        while True:
            time.sleep(1)
            
            # Check if processes are still running
            if backend_proc.poll() is not None:
                print("❌ Backend stopped unexpectedly.")
                break
            if flutter_proc.poll() is not None:
                print("❌ Flutter stopped unexpectedly.")
                break
                
    except KeyboardInterrupt:
        print("\n🛑 Stopping services...")
    finally:
        if backend_proc:
            backend_proc.terminate()
        if flutter_proc:
            flutter_proc.terminate()
        print("👋 Done.")
