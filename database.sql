-- ==============================================================================
-- Smart College Attendance & Automatic WhatsApp Notification System
-- Database Schema & Initial Seed Data
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS `smart_attendance` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `smart_attendance`;

-- Disable foreign key checks during creation
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------------------------
-- 1. Table: users
-- Stores authentication credentials and role assignments for Admins & Teachers
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(80) NOT NULL UNIQUE,
    `email` VARCHAR(120) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('admin', 'teacher') NOT NULL DEFAULT 'teacher',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_role` (`role`),
    INDEX `idx_users_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 2. Table: courses
-- Academic departments/programs (e.g., Computer Science, Mechanical Eng)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `courses`;
CREATE TABLE `courses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `course_name` VARCHAR(150) NOT NULL,
    `course_code` VARCHAR(50) NOT NULL UNIQUE,
    `description` TEXT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_course_code` (`course_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 3. Table: classes
-- Cohort / Year / Section belonging to a specific Course
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `classes`;
CREATE TABLE `classes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `class_name` VARCHAR(100) NOT NULL,
    `course_id` INT NOT NULL,
    `section` VARCHAR(20) NOT NULL DEFAULT 'A',
    `academic_year` VARCHAR(30) NOT NULL DEFAULT '2026-2027',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_classes_course` FOREIGN KEY (`course_id`) 
        REFERENCES `courses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY `uq_class_section_year` (`course_id`, `class_name`, `section`, `academic_year`),
    INDEX `idx_class_course` (`course_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 4. Table: subjects
-- Subjects/Modules taught in the institution
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `subjects`;
CREATE TABLE `subjects` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `subject_name` VARCHAR(150) NOT NULL,
    `subject_code` VARCHAR(50) NOT NULL UNIQUE,
    `course_id` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_subjects_course` FOREIGN KEY (`course_id`) 
        REFERENCES `courses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX `idx_subject_code` (`subject_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 5. Table: teachers
-- Teacher profile linked to user account
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `teachers`;
CREATE TABLE `teachers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL UNIQUE,
    `employee_id` VARCHAR(50) NOT NULL UNIQUE,
    `full_name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(120) NOT NULL UNIQUE,
    `phone` VARCHAR(25) NOT NULL,
    `department` VARCHAR(100) NOT NULL,
    `qualification` VARCHAR(100) NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_teachers_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX `idx_teacher_emp_id` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 6. Table: teacher_assignments
-- Defines which classes and subjects each teacher is authorized to teach
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `teacher_assignments`;
CREATE TABLE `teacher_assignments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `teacher_id` INT NOT NULL,
    `class_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `academic_year` VARCHAR(30) NOT NULL DEFAULT '2026-2027',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_assignment_teacher` FOREIGN KEY (`teacher_id`) 
        REFERENCES `teachers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_assignment_class` FOREIGN KEY (`class_id`) 
        REFERENCES `classes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_assignment_subject` FOREIGN KEY (`subject_id`) 
        REFERENCES `subjects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY `uq_teacher_class_subject` (`teacher_id`, `class_id`, `subject_id`, `academic_year`),
    INDEX `idx_assignment_lookup` (`teacher_id`, `class_id`, `subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 7. Table: students
-- Complete student records including parent details and WhatsApp consent
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `students`;
CREATE TABLE `students` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `student_id_code` VARCHAR(50) NOT NULL UNIQUE,
    `full_name` VARCHAR(150) NOT NULL,
    `roll_number` VARCHAR(50) NOT NULL,
    `course_id` INT NOT NULL,
    `class_id` INT NOT NULL,
    `parent_name` VARCHAR(150) NOT NULL,
    `parent_phone` VARCHAR(25) NOT NULL,
    `whatsapp_consent` BOOLEAN NOT NULL DEFAULT TRUE,
    `admission_date` DATE NOT NULL,
    `status` ENUM('Active', 'Inactive', 'Suspended') NOT NULL DEFAULT 'Active',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_students_course` FOREIGN KEY (`course_id`) 
        REFERENCES `courses` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_students_class` FOREIGN KEY (`class_id`) 
        REFERENCES `classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY `uq_class_roll_number` (`class_id`, `roll_number`),
    INDEX `idx_students_roll` (`roll_number`),
    INDEX `idx_students_class` (`class_id`),
    INDEX `idx_students_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 8. Table: attendance
-- Daily attendance marked per student, class session, and subject
-- Rule: Only ONE record per student/class/subject/date
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `attendance`;
CREATE TABLE `attendance` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT NOT NULL,
    `class_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `teacher_id` INT NOT NULL,
    `attendance_date` DATE NOT NULL,
    `status` ENUM('PRESENT', 'ABSENT', 'LATE') NOT NULL DEFAULT 'PRESENT',
    `remarks` VARCHAR(255) NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) 
        REFERENCES `students` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_att_class` FOREIGN KEY (`class_id`) 
        REFERENCES `classes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_att_subject` FOREIGN KEY (`subject_id`) 
        REFERENCES `subjects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_att_teacher` FOREIGN KEY (`teacher_id`) 
        REFERENCES `teachers` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY `uq_student_session_attendance` (`student_id`, `class_id`, `subject_id`, `attendance_date`),
    INDEX `idx_att_date_class_subject` (`attendance_date`, `class_id`, `subject_id`),
    INDEX `idx_att_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 9. Table: whatsapp_logs
-- Audit trail of all WhatsApp notification dispatches via Meta Cloud API
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `whatsapp_logs`;
CREATE TABLE `whatsapp_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `attendance_id` INT NULL,
    `student_id` INT NOT NULL,
    `recipient_phone` VARCHAR(25) NOT NULL,
    `parent_name` VARCHAR(150) NOT NULL,
    `template_name` VARCHAR(100) NOT NULL,
    `message_id` VARCHAR(150) NULL,
    `status` ENUM('SENT', 'FAILED', 'SKIPPED') NOT NULL DEFAULT 'SENT',
    `request_payload` MEDIUMTEXT NULL,
    `response_payload` MEDIUMTEXT NULL,
    `error_message` TEXT NULL,
    `retry_count` INT NOT NULL DEFAULT 0,
    `sent_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_wlog_attendance` FOREIGN KEY (`attendance_id`) 
        REFERENCES `attendance` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_wlog_student` FOREIGN KEY (`student_id`) 
        REFERENCES `students` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX `idx_wlog_student_sent` (`student_id`, `sent_at`),
    INDEX `idx_wlog_status` (`status`),
    INDEX `idx_wlog_recipient` (`recipient_phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 10. Table: audit_logs
-- Comprehensive administrative audit log for security & compliance
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL,
    `username` VARCHAR(80) NULL,
    `role` VARCHAR(20) NULL,
    `action` VARCHAR(100) NOT NULL,
    `details` TEXT NULL,
    `ip_address` VARCHAR(50) NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX `idx_audit_action` (`action`),
    INDEX `idx_audit_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================================
-- INITIAL SEED DATA
-- Default Admin Account: admin / Admin@123
-- Sample Teachers: prof.smith / Teacher@123, dr.sharma / Teacher@123
-- ==============================================================================

-- 1. Insert Default Users
INSERT INTO `users` (`id`, `username`, `email`, `password_hash`, `role`, `is_active`) VALUES
(1, 'admin', 'admin@apex-tech.edu', 'scrypt:32768:8:1$5N18XBWccrPwLzya$aee069f7afef8874595d22a1e6c703af55972c4e4337bebefd49730122bf40c347b3d212e36306694677bd03a00a3c5ed5253579cf0be70b5cd9245699515e97', 'admin', 1),
(2, 'prof.smith', 'alex.smith@apex-tech.edu', 'scrypt:32768:8:1$ImGRfyfuFs7gAo3a$5cc692f59f859fe5f66388213194edcb25985dda77036e98498d0268fd7dc5f7229ead3642851c9a02dcf7044df3607b0404a454a2554946ae537628db994ea6', 'teacher', 1),
(3, 'dr.sharma', 'priya.sharma@apex-tech.edu', 'scrypt:32768:8:1$ImGRfyfuFs7gAo3a$5cc692f59f859fe5f66388213194edcb25985dda77036e98498d0268fd7dc5f7229ead3642851c9a02dcf7044df3607b0404a454a2554946ae537628db994ea6', 'teacher', 1);

-- 2. Insert Courses
INSERT INTO `courses` (`id`, `course_name`, `course_code`, `description`) VALUES
(1, 'Bachelor of Technology in Computer Science', 'BTECH-CSE', 'Four-year undergraduate program focusing on computing systems and algorithms.'),
(2, 'Bachelor of Technology in Information Technology', 'BTECH-IT', 'Undergraduate degree covering software engineering, networking, and cloud systems.'),
(3, 'Bachelor of Business Administration', 'BBA', 'Management program focusing on business analytics and digital leadership.');

-- 3. Insert Classes
INSERT INTO `classes` (`id`, `class_name`, `course_id`, `section`, `academic_year`) VALUES
(1, 'B.Tech CSE - 3rd Year', 1, 'A', '2026-2027'),
(2, 'B.Tech CSE - 3rd Year', 1, 'B', '2026-2027'),
(3, 'B.Tech IT - 2nd Year', 2, 'A', '2026-2027'),
(4, 'BBA - 1st Year', 3, 'A', '2026-2027');

-- 4. Insert Subjects
INSERT INTO `subjects` (`id`, `subject_name`, `subject_code`, `course_id`) VALUES
(1, 'Database Management Systems', 'CS301', 1),
(2, 'Operating Systems', 'CS302', 1),
(3, 'Web Technologies', 'CS303', 1),
(4, 'Data Structures & Algorithms', 'IT201', 2),
(5, 'Computer Networks', 'IT202', 2),
(6, 'Principles of Management', 'BBA101', 3);

-- 5. Insert Teacher Profiles
INSERT INTO `teachers` (`id`, `user_id`, `employee_id`, `full_name`, `email`, `phone`, `department`, `qualification`) VALUES
(1, 2, 'EMP-T-101', 'Prof. Alex Smith', 'alex.smith@apex-tech.edu', '+919876543210', 'Computer Science & Engineering', 'M.Tech CSE, Ph.D. Scholar'),
(2, 3, 'EMP-T-102', 'Dr. Priya Sharma', 'priya.sharma@apex-tech.edu', '+919876543211', 'Computer Science & Engineering', 'Ph.D. in Computer Science');

-- 6. Insert Teacher Class & Subject Assignments
INSERT INTO `teacher_assignments` (`id`, `teacher_id`, `class_id`, `subject_id`, `academic_year`) VALUES
(1, 1, 1, 1, '2026-2027'), -- Prof. Smith teaches DBMS to CSE 3rd Year (Sec A)
(2, 1, 1, 2, '2026-2027'), -- Prof. Smith teaches OS to CSE 3rd Year (Sec A)
(3, 2, 1, 3, '2026-2027'), -- Dr. Sharma teaches Web Tech to CSE 3rd Year (Sec A)
(4, 2, 2, 1, '2026-2027'); -- Dr. Sharma teaches DBMS to CSE 3rd Year (Sec B)

-- 7. Insert Sample Students
INSERT INTO `students` (`id`, `student_id_code`, `full_name`, `roll_number`, `course_id`, `class_id`, `parent_name`, `parent_phone`, `whatsapp_consent`, `admission_date`, `status`) VALUES
(1, 'STU-2026-001', 'Aarav Patel', 'CSE-001', 1, 1, 'Rajesh Patel', '+919876500001', 1, '2024-08-01', 'Active'),
(2, 'STU-2026-002', 'Diya Sengupta', 'CSE-002', 1, 1, 'Anirban Sengupta', '+919876500002', 1, '2024-08-01', 'Active'),
(3, 'STU-2026-003', 'Rohan Verma', 'CSE-003', 1, 1, 'Sunil Verma', '+919876500003', 1, '2024-08-01', 'Active'),
(4, 'STU-2026-004', 'Ananya Iyer', 'CSE-004', 1, 1, 'K. Venkat Iyer', '+919876500004', 1, '2024-08-01', 'Active'),
(5, 'STU-2026-005', 'Kabir Mehta', 'CSE-005', 1, 1, 'Vikram Mehta', '+919876500005', 0, '2024-08-01', 'Active'), -- No WhatsApp Consent
(6, 'STU-2026-006', 'Sneha Kulkarni', 'CSE-006', 1, 1, 'Suresh Kulkarni', '+919876500006', 1, '2024-08-01', 'Active'),
(7, 'STU-2026-007', 'Arjun Nair', 'CSE-007', 1, 1, 'Gopal Nair', '+919876500007', 1, '2024-08-01', 'Active'),
(8, 'STU-2026-008', 'Meera Rao', 'CSE-008', 1, 1, 'Nagaraj Rao', '+919876500008', 1, '2024-08-01', 'Active'),
(9, 'STU-2026-009', 'Aditya Singh', 'CSE-009', 1, 1, 'Harish Singh', '+919876500009', 1, '2024-08-01', 'Active'),
(10, 'STU-2026-010', 'Tanvi Joshi', 'CSE-010', 1, 1, 'Milind Joshi', '+919876500010', 1, '2024-08-01', 'Active'),
-- Students for Section B
(11, 'STU-2026-011', 'Devansh Reddy', 'CSE-B-001', 1, 2, 'Ramesh Reddy', '+919876500011', 1, '2024-08-01', 'Active'),
(12, 'STU-2026-012', 'Ishita Bansal', 'CSE-B-002', 1, 2, 'Pawan Bansal', '+919876500012', 1, '2024-08-01', 'Active');

-- 8. Sample Attendance Records for Previous Session (to immediately show reports & stats)
INSERT INTO `attendance` (`id`, `student_id`, `class_id`, `subject_id`, `teacher_id`, `attendance_date`, `status`, `remarks`) VALUES
(1, 1, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time'),
(2, 2, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time'),
(3, 3, 1, 1, 1, '2026-11-17', 'ABSENT', 'Informed absence'),
(4, 4, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time'),
(5, 5, 1, 1, 1, '2026-11-17', 'ABSENT', 'Unexcused'),
(6, 6, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time'),
(7, 7, 1, 1, 1, '2026-11-17', 'ABSENT', 'Sick leave'),
(8, 8, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time'),
(9, 9, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time'),
(10, 10, 1, 1, 1, '2026-11-17', 'PRESENT', 'On time');

-- 9. Sample WhatsApp Notification Logs
INSERT INTO `whatsapp_logs` (`id`, `attendance_id`, `student_id`, `recipient_phone`, `parent_name`, `template_name`, `message_id`, `status`, `request_payload`, `response_payload`, `error_message`, `retry_count`, `sent_at`) VALUES
(1, 3, 3, '+919876500003', 'Sunil Verma', 'student_absent_notification', 'wamid.HBgLOTE5ODc2NTAwMDAzFQIAERgSMzNFREVDMDAwMDAwMDAwMDBBAA==', 'SENT', '{"to": "919876500003", "type": "template", "template": {"name": "student_absent_notification"}}', '{"messaging_product": "whatsapp", "contacts": [{"input": "919876500003", "wa_id": "919876500003"}], "messages": [{"id": "wamid.HBgLOTE5ODc2NTAwMDAzFQIAERgSMzNFREVDMDAwMDAwMDAwMDBBAA=="}]}', NULL, 0, '2026-11-17 09:30:15'),
(2, 5, 5, '+919876500005', 'Vikram Mehta', 'student_absent_notification', NULL, 'SKIPPED', '{"student_id": 5, "parent": "Vikram Mehta"}', NULL, 'Notification skipped: Parent has not opted in for WhatsApp notifications (whatsapp_consent = False)', 0, '2026-11-17 09:30:15'),
(3, 7, 7, '+919876500007', 'Gopal Nair', 'student_absent_notification', 'wamid.HBgLOTE5ODc2NTAwMDA3FQIAERgSMzNFREVDMDAwMDAwMDAwMDBCBA==', 'SENT', '{"to": "919876500007", "type": "template", "template": {"name": "student_absent_notification"}}', '{"messaging_product": "whatsapp", "contacts": [{"input": "919876500007", "wa_id": "919876500007"}], "messages": [{"id": "wamid.HBgLOTE5ODc2NTAwMDA3FQIAERgSMzNFREVDMDAwMDAwMDAwMDBCBA=="}]}', NULL, 0, '2026-11-17 09:30:16');

-- 10. Sample Audit Log
INSERT INTO `audit_logs` (`user_id`, `username`, `role`, `action`, `details`, `ip_address`) VALUES
(1, 'admin', 'admin', 'SYSTEM_INITIALIZATION', 'System tables and initial master data seeded successfully.', '127.0.0.1'),
(2, 'prof.smith', 'teacher', 'SUBMIT_ATTENDANCE', 'Submitted attendance for B.Tech CSE - 3rd Year (Sec A) - Subject: CS301 (Date: 2026-11-17). Present: 7, Absent: 3.', '127.0.0.1');
