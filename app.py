import os
from datetime import datetime, date
from flask import Flask, render_template, redirect, url_for, flash, request
from flask_login import LoginManager, current_user
from flask_wtf.csrf import CSRFProtect

from config import Config
from models import db, User, Teacher, Student, Course, ClassModel, Subject, TeacherAssignment, Attendance, WhatsAppLog, AuditLog

csrf = CSRFProtect()
login_manager = LoginManager()

def create_app(config_class=Config):
    """Application factory for the Smart College Attendance System."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize Extensions
    db.init_app(app)
    csrf.init_app(app)
    
    login_manager.init_app(app)
    login_manager.login_view = "auth.login"
    login_manager.login_message = "Please authenticate to access this institutional resource."
    login_manager.login_message_category = "warning"

    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    # Register Blueprints
    from routes import auth_bp, admin_bp, teacher_bp, reports_bp, api_bp
    app.register_blueprint(auth_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(teacher_bp)
    app.register_blueprint(reports_bp)
    app.register_blueprint(api_bp)

    # Root Route
    @app.route("/")
    def index():
        if current_user.is_authenticated:
            if current_user.is_admin:
                return redirect(url_for("admin.dashboard"))
            return redirect(url_for("teacher.dashboard"))
        return redirect(url_for("auth.login"))

    # Global Context Processors
    @app.context_processor
    def inject_global_template_vars():
        return {
            "current_year": datetime.utcnow().year,
            "college_name": app.config.get("COLLEGE_NAME", "Apex Institute of Technology & Management"),
            "college_tagline": app.config.get("COLLEGE_TAGLINE", "Smart Attendance System")
        }

    # Error Handlers
    @app.errorhandler(403)
    def forbidden_error(error):
        return render_template("base.html", error_title="403 Forbidden", error_message="You do not possess the required permissions to access this endpoint."), 403

    @app.errorhandler(404)
    def not_found_error(error):
        return render_template("base.html", error_title="404 Not Found", error_message="The requested academic resource or page could not be located."), 404

    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return render_template("base.html", error_title="500 Internal Error", error_message="An unexpected server error occurred. The incident has been recorded."), 500

    # Custom CLI Command: init-db
    @app.cli.command("init-db")
    def init_db_command():
        """Creates all database tables."""
        with app.app_context():
            db.create_all()
            print("Successfully initialized all database tables.")

    # Custom CLI Command: seed-db
    @app.cli.command("seed-db")
    def seed_db_command():
        """Populates database with initial academic master data."""
        with app.app_context():
            from werkzeug.security import generate_password_hash
            db.create_all()

            # 1. Admin
            if not User.query.filter_by(username="admin").first():
                admin = User(
                    username="admin",
                    email="admin@apex-tech.edu",
                    role="admin",
                    is_active=True
                )
                admin.set_password("Admin@123")
                db.session.add(admin)

            # 2. Teacher 1
            user_smith = User.query.filter_by(username="prof.smith").first()
            if not user_smith:
                user_smith = User(
                    username="prof.smith",
                    email="alex.smith@apex-tech.edu",
                    role="teacher",
                    is_active=True
                )
                user_smith.set_password("Teacher@123")
                db.session.add(user_smith)
                db.session.flush()

                teacher_smith = Teacher(
                    user_id=user_smith.id,
                    employee_id="EMP-T-101",
                    full_name="Prof. Alex Smith",
                    email="alex.smith@apex-tech.edu",
                    phone="+919876543210",
                    department="Computer Science & Engineering",
                    qualification="M.Tech CSE, Ph.D. Scholar"
                )
                db.session.add(teacher_smith)

            # 3. Courses
            c1 = Course.query.filter_by(course_code="BTECH-CSE").first()
            if not c1:
                c1 = Course(course_name="Bachelor of Technology in Computer Science", course_code="BTECH-CSE")
                db.session.add(c1)
                db.session.flush()

            # 4. Classes
            cl1 = ClassModel.query.filter_by(class_name="B.Tech CSE - 3rd Year", section="A").first()
            if not cl1:
                cl1 = ClassModel(class_name="B.Tech CSE - 3rd Year", course_id=c1.id, section="A", academic_year="2026-2027")
                db.session.add(cl1)
                db.session.flush()

            # 5. Subjects
            s1 = Subject.query.filter_by(subject_code="CS301").first()
            if not s1:
                s1 = Subject(subject_name="Database Management Systems", subject_code="CS301", course_id=c1.id)
                db.session.add(s1)
                db.session.flush()

            # 6. Assign Teacher
            t_smith = Teacher.query.filter_by(employee_id="EMP-T-101").first()
            if t_smith and cl1 and s1:
                if not TeacherAssignment.query.filter_by(teacher_id=t_smith.id, class_id=cl1.id, subject_id=s1.id).first():
                    assign = TeacherAssignment(teacher_id=t_smith.id, class_id=cl1.id, subject_id=s1.id, academic_year="2026-2027")
                    db.session.add(assign)

            db.session.commit()
            print("Database successfully seeded with default master data.")

    return app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
