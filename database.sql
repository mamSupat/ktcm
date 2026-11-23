
CREATE DATABASE IF NOT EXISTS hr_evaluation CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hr_evaluation;
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS evidence, assessment_scores, self_details, self_scores, committee_assignments, assessments, duties, indicators, topics, rounds, users;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE users(
 id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50) UNIQUE NOT NULL,
 password_hash CHAR(161) NOT NULL, fullname VARCHAR(150) NOT NULL,
 role ENUM('admin','employee','committee') NOT NULL, active TINYINT DEFAULT 1,
 must_change_password TINYINT DEFAULT 0, email VARCHAR(150), phone VARCHAR(30),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE rounds(
 id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(150) NOT NULL,
 start_date DATE NULL, end_date DATE NULL, status ENUM('draft','open','closed') DEFAULT 'open'
);
CREATE TABLE topics(
 id INT AUTO_INCREMENT PRIMARY KEY, round_id INT NOT NULL, name VARCHAR(200) NOT NULL,
 FOREIGN KEY(round_id) REFERENCES rounds(id) ON DELETE CASCADE
);
CREATE TABLE indicators(
 id INT AUTO_INCREMENT PRIMARY KEY, topic_id INT NOT NULL, name VARCHAR(200) NOT NULL,
 description TEXT, weight DECIMAL(6,2) DEFAULT 1, max_score DECIMAL(6,2) DEFAULT 4,
 eval_type ENUM('scale','yesno') DEFAULT 'scale', evidence_hint VARCHAR(255),
 level1 TEXT, level2 TEXT, level3 TEXT, level4 TEXT,
 FOREIGN KEY(topic_id) REFERENCES topics(id) ON DELETE CASCADE
);
CREATE TABLE duties(
 id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, round_id INT NOT NULL,
 title VARCHAR(200) NOT NULL, description TEXT,
 status ENUM('pending','submitted','evaluated') DEFAULT 'pending',
 submitted_at DATETIME NULL,
 FOREIGN KEY(user_id) REFERENCES users(id), FOREIGN KEY(round_id) REFERENCES rounds(id)
);
CREATE TABLE committee_assignments(
 id INT AUTO_INCREMENT PRIMARY KEY, duty_id INT NOT NULL, committee_id INT NOT NULL,
 committee_role ENUM('chair','member') DEFAULT 'member',
 status ENUM('pending','draft','submitted') DEFAULT 'pending',
 signature LONGTEXT NULL, signed_at DATETIME NULL,
 UNIQUE KEY uq_assignment(duty_id,committee_id),
 FOREIGN KEY(duty_id) REFERENCES duties(id) ON DELETE CASCADE,
 FOREIGN KEY(committee_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE self_scores(
 id INT AUTO_INCREMENT PRIMARY KEY, duty_id INT NOT NULL, indicator_id INT NOT NULL,
 score DECIMAL(6,2) NOT NULL DEFAULT 0, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 UNIQUE KEY uq_self(duty_id,indicator_id),
 FOREIGN KEY(duty_id) REFERENCES duties(id) ON DELETE CASCADE,
 FOREIGN KEY(indicator_id) REFERENCES indicators(id) ON DELETE CASCADE
);
CREATE TABLE self_details(
 id INT AUTO_INCREMENT PRIMARY KEY, self_score_id INT NOT NULL, detail TEXT NOT NULL,
 FOREIGN KEY(self_score_id) REFERENCES self_scores(id) ON DELETE CASCADE
);
CREATE TABLE assessments(
 id INT AUTO_INCREMENT PRIMARY KEY, assignment_id INT NOT NULL UNIQUE,
 total_score DECIMAL(8,2) DEFAULT 0, comment TEXT,
 status ENUM('draft','submitted') DEFAULT 'draft',
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 FOREIGN KEY(assignment_id) REFERENCES committee_assignments(id) ON DELETE CASCADE
);
CREATE TABLE assessment_scores(
 id INT AUTO_INCREMENT PRIMARY KEY, assessment_id INT NOT NULL, indicator_id INT NOT NULL,
 score DECIMAL(6,2) NOT NULL, comment TEXT,
 UNIQUE KEY uq_assessment_indicator(assessment_id,indicator_id),
 FOREIGN KEY(assessment_id) REFERENCES assessments(id) ON DELETE CASCADE,
 FOREIGN KEY(indicator_id) REFERENCES indicators(id) ON DELETE CASCADE
);
CREATE TABLE evidence(
 id INT AUTO_INCREMENT PRIMARY KEY, duty_id INT NOT NULL, user_id INT NOT NULL,
 indicator_id INT NULL, filename VARCHAR(255), file_path VARCHAR(500), mime_type VARCHAR(100),
 url TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(duty_id) REFERENCES duties(id) ON DELETE CASCADE,
 FOREIGN KEY(user_id) REFERENCES users(id),
 FOREIGN KEY(indicator_id) REFERENCES indicators(id) ON DELETE SET NULL
);
