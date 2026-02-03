
import subprocess
import time
import sys
import os

def run_flask():
    print("🚀 Starting Flask App (Frontend + Backend)...")
    # Using sys.executable to ensure we use the same python environment
    return subprocess.Popen(
        [sys.executable, "flask_app.py"],
        cwd=os.getcwd()
    )

if __name__ == "__main__":
    flask_proc = None
    
    try:
        # 1. Start Flask
        flask_proc = run_flask()
        
        print("\n✅ InstaSpace AI is now running!")
        print("URL: http://localhost:8000")
        print("\nPress Ctrl+C to stop the service.")
        
        # Keep the script alive
        while True:
            time.sleep(1)
            
            # Check if process is still running
            if flask_proc.poll() is not None:
                print("❌ Flask app stopped unexpectedly.")
                break
                
    except KeyboardInterrupt:
        print("\n🛑 Stopping service...")
    finally:
        if flask_proc:
            flask_proc.terminate()
        print("👋 Done.")
