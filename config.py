import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

class Config:
    """Base application configuration."""
    SECRET_KEY = os.getenv("SECRET_KEY", "fallback-secret-key-change-in-production")
    
    # Database Settings
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "mysql+pymysql://root:@localhost:3306/smart_attendance?charset=utf8mb4"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_recycle": 280,
        "pool_pre_ping": True,
    }

    # Security & Session Settings
    WTF_CSRF_ENABLED = True
    WTF_CSRF_TIME_LIMIT = None  # Persistent token for session
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    PERMANENT_SESSION_LIFETIME = 86400  # 24 hours

    # Meta WhatsApp Business Cloud API Settings
    WHATSAPP_API_URL = os.getenv("WHATSAPP_API_URL", "https://graph.facebook.com/v19.0").rstrip("/")
    WHATSAPP_PHONE_NUMBER_ID = os.getenv("WHATSAPP_PHONE_NUMBER_ID", "")
    WHATSAPP_BUSINESS_ACCOUNT_ID = os.getenv("WHATSAPP_BUSINESS_ACCOUNT_ID", "")
    WHATSAPP_ACCESS_TOKEN = os.getenv("WHATSAPP_ACCESS_TOKEN", "")
    WHATSAPP_TEMPLATE_NAME = os.getenv("WHATSAPP_TEMPLATE_NAME", "student_absent_notification")
    WHATSAPP_LANGUAGE_CODE = os.getenv("WHATSAPP_LANGUAGE_CODE", "en_US")
    WHATSAPP_SIMULATION_MODE = os.getenv("WHATSAPP_SIMULATION_MODE", "True").lower() in ("true", "1", "yes")

    # College Branding Information
    COLLEGE_NAME = os.getenv("COLLEGE_NAME", "Apex Institute of Technology & Management")
    COLLEGE_TAGLINE = os.getenv("COLLEGE_TAGLINE", "Excellence in Engineering & Innovation")
    COLLEGE_EMAIL = os.getenv("COLLEGE_EMAIL", "attendance@apex-tech.edu")
    COLLEGE_PHONE = os.getenv("COLLEGE_PHONE", "+91 11 2345 6789")

    # Reports Storage
    REPORTS_DIR = BASE_DIR / "reports"
