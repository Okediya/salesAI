from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from backend.app.core.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def init_db():
    Base.metadata.create_all(bind=engine)
    if "sqlite" in settings.DATABASE_URL:
        import sqlite3
        db_path = settings.DATABASE_URL.replace("sqlite:///", "").replace("sqlite://", "")
        if db_path.startswith("./"):
            db_path = db_path[2:]
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # Check products columns
            cursor.execute("PRAGMA table_info(products)")
            prod_cols = [r[1] for r in cursor.fetchall()]
            if "knowledge_base" not in prod_cols:
                cursor.execute("ALTER TABLE products ADD COLUMN knowledge_base TEXT")
            if "image_features" not in prod_cols:
                cursor.execute("ALTER TABLE products ADD COLUMN image_features TEXT")
            if "telegram_handle" not in prod_cols:
                cursor.execute("ALTER TABLE products ADD COLUMN telegram_handle VARCHAR(255)")
            if "telegram_bot_token" not in prod_cols:
                cursor.execute("ALTER TABLE products ADD COLUMN telegram_bot_token VARCHAR(255)")
            if "website_last_synced" not in prod_cols:
                cursor.execute("ALTER TABLE products ADD COLUMN website_last_synced DATETIME")

            # Check leads columns
            cursor.execute("PRAGMA table_info(leads)")
            lead_cols = [r[1] for r in cursor.fetchall()]
            if "telegram_handle" not in lead_cols:
                cursor.execute("ALTER TABLE leads ADD COLUMN telegram_handle VARCHAR(255)")

            conn.commit()
            conn.close()
        except Exception as e:
            print(f"Auto-migration note: {e}")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

