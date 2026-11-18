import sys
import os
from pathlib import Path

# Add the smart_college_attendance package to sys.path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR / "smart_college_attendance"))

from app import app

if __name__ == "__main__":
    print("=" * 70)
    print(" SMART COLLEGE ATTENDANCE & AUTOMATIC WHATSAPP NOTIFICATION SYSTEM")
    print("=" * 70)
    print(" Server running on: http://localhost:5000")
    print(" Admin Login:       admin / Admin@123")
    print(" Teacher Login:     prof.smith / Teacher@123")
    print(" WhatsApp API:      Official Meta Cloud API (Simulation / Live mode)")
    print("=" * 70)
    app.run(host="0.0.0.0", port=5000, debug=True)
