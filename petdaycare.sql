-- ============================================================
--  Pet Daycare & Boarding Management System
--  Database Schema — All 11 Tables
--  Run this in phpMyAdmin or MySQL CLI
-- ============================================================

CREATE DATABASE IF NOT EXISTS petdaycare;
USE petdaycare;

-- 1. USERS (login credentials + role)
CREATE TABLE users (
    user_id     INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    role        ENUM('admin','staff','owner') NOT NULL,
    phone       VARCHAR(20),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. OWNERS (extended profile for pet owners)
CREATE TABLE owners (
    owner_id                 INT AUTO_INCREMENT PRIMARY KEY,
    user_id                  INT NOT NULL UNIQUE,
    address                  TEXT,
    emergency_contact_name   VARCHAR(100),
    emergency_contact_phone  VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 3. STAFF (extended profile for staff members)
CREATE TABLE staff (
    staff_id                 INT AUTO_INCREMENT PRIMARY KEY,
    user_id                  INT NOT NULL UNIQUE,
    designation              VARCHAR(100),
    shift                    ENUM('morning','evening','night') DEFAULT 'morning',
    assigned_kennel_section  VARCHAR(50),
    joining_date             DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 4. PETS (each pet belongs to one owner)
CREATE TABLE pets (
    pet_id        INT AUTO_INCREMENT PRIMARY KEY,
    owner_id      INT NOT NULL,
    name          VARCHAR(100) NOT NULL,
    species       VARCHAR(50)  NOT NULL,
    breed         VARCHAR(100),
    age           INT,
    weight        DECIMAL(5,2),
    gender        ENUM('male','female') DEFAULT 'male',
    medical_notes TEXT,
    vet_name      VARCHAR(100),
    vet_phone     VARCHAR(20),
    profile_photo VARCHAR(255),
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES owners(owner_id) ON DELETE CASCADE
);

-- 5. VACCINATIONS (vaccine records per pet)
CREATE TABLE vaccinations (
    vaccination_id   INT AUTO_INCREMENT PRIMARY KEY,
    pet_id           INT NOT NULL,
    vaccine_name     VARCHAR(100) NOT NULL,
    date_given       DATE NOT NULL,
    next_due_date    DATE NOT NULL,
    administered_by  VARCHAR(100),
    certificate_file VARCHAR(255),
    FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE
);

-- 6. KENNELS (physical kennel inventory)
CREATE TABLE kennels (
    kennel_id       INT AUTO_INCREMENT PRIMARY KEY,
    kennel_number   VARCHAR(20) NOT NULL UNIQUE,
    size_type       ENUM('small','medium','large') NOT NULL,
    capacity        INT DEFAULT 1,
    rate_per_night  DECIMAL(8,2) NOT NULL,
    daycare_rate    DECIMAL(8,2) NOT NULL,
    status          ENUM('available','occupied','maintenance') DEFAULT 'available',
    description     TEXT
);

-- 7. BOOKINGS (core table — every reservation)
CREATE TABLE bookings (
    booking_id           INT AUTO_INCREMENT PRIMARY KEY,
    pet_id               INT NOT NULL,
    kennel_id            INT NOT NULL,
    owner_id             INT NOT NULL,
    assigned_staff_id    INT,
    booking_type         ENUM('daycare','boarding') NOT NULL,
    check_in_date        DATE NOT NULL,
    check_out_date       DATE NOT NULL,
    actual_check_in      DATETIME,
    actual_check_out     DATETIME,
    status               ENUM('pending','confirmed','checked_in','checked_out','cancelled') DEFAULT 'pending',
    special_instructions TEXT,
    created_at           DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pet_id)            REFERENCES pets(pet_id),
    FOREIGN KEY (kennel_id)         REFERENCES kennels(kennel_id),
    FOREIGN KEY (owner_id)          REFERENCES owners(owner_id),
    FOREIGN KEY (assigned_staff_id) REFERENCES staff(staff_id)
);

-- 8. HEALTH LOGS (daily staff log per pet per stay)
CREATE TABLE health_logs (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    booking_id   INT NOT NULL,
    staff_id     INT NOT NULL,
    log_date     DATE NOT NULL,
    food_eaten   VARCHAR(200),
    appetite     ENUM('good','fair','poor') DEFAULT 'good',
    behavior     VARCHAR(200),
    health_notes TEXT,
    activity_done TEXT,
    photo_path   VARCHAR(255),
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id)   REFERENCES staff(staff_id)
);

-- 9. GROOMING SERVICES (catalog of grooming options)
CREATE TABLE grooming_services (
    service_id       INT AUTO_INCREMENT PRIMARY KEY,
    service_name     VARCHAR(100) NOT NULL,
    price            DECIMAL(8,2) NOT NULL,
    duration_minutes INT DEFAULT 60,
    description      TEXT,
    is_active        TINYINT(1) DEFAULT 1
);

-- 10. GROOMING BOOKINGS (grooming added to a booking)
CREATE TABLE grooming_bookings (
    grooming_booking_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id          INT NOT NULL,
    service_id          INT NOT NULL,
    scheduled_time      DATETIME,
    staff_id            INT,
    status              ENUM('scheduled','in_progress','completed','cancelled') DEFAULT 'scheduled',
    notes               TEXT,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES grooming_services(service_id),
    FOREIGN KEY (staff_id)   REFERENCES staff(staff_id)
);

-- 11. INVOICES (auto-generated at checkout)
CREATE TABLE invoices (
    invoice_id      INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL UNIQUE,
    owner_id        INT NOT NULL,
    nights_count    INT DEFAULT 0,
    boarding_fee    DECIMAL(10,2) DEFAULT 0,
    daycare_fee     DECIMAL(10,2) DEFAULT 0,
    grooming_fee    DECIMAL(10,2) DEFAULT 0,
    extra_charges   DECIMAL(10,2) DEFAULT 0,
    total_amount    DECIMAL(10,2) NOT NULL,
    generated_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_status  ENUM('unpaid','paid','partial') DEFAULT 'unpaid',
    payment_method  VARCHAR(50),
    paid_at         DATETIME,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (owner_id)   REFERENCES owners(owner_id)
);

-- ============================================================
--  SAMPLE DATA — for testing and demo purposes
-- ============================================================

-- Admin user (password: admin123)
INSERT INTO users (name, email, password, role, phone) VALUES
('Admin User',   'admin@petdaycare.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', '0300-0000001'),
('Sara Khan',    'staff@petdaycare.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'staff', '0300-0000002'),
('Ahmed Ali',    'owner@petdaycare.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'owner', '0300-0000003');

INSERT INTO owners (user_id, address, emergency_contact_name, emergency_contact_phone) VALUES
(3, 'House 12, Block B, Karachi', 'Bilal Ali', '0321-9876543');

INSERT INTO staff (user_id, designation, shift, assigned_kennel_section, joining_date) VALUES
(2, 'Senior Caretaker', 'morning', 'Section A', '2024-01-15');

INSERT INTO kennels (kennel_number, size_type, rate_per_night, daycare_rate, status) VALUES
('A1', 'small',  800.00,  400.00, 'available'),
('A2', 'small',  800.00,  400.00, 'available'),
('B1', 'medium', 1200.00, 600.00, 'available'),
('B2', 'medium', 1200.00, 600.00, 'available'),
('C1', 'large',  1800.00, 900.00, 'available');

INSERT INTO grooming_services (service_name, price, duration_minutes, description) VALUES
('Basic Bath & Dry',     500.00,  45, 'Shampoo, blow dry, and brush'),
('Full Groom',          1200.00,  90, 'Bath, haircut, nail trim, ear clean'),
('Nail Trim Only',       200.00,  15, 'Quick nail clipping'),
('Teeth Cleaning',       300.00,  20, 'Brush and dental rinse');

INSERT INTO pets (owner_id, name, species, breed, age, weight, gender, medical_notes, vet_name, vet_phone) VALUES
(1, 'Bruno', 'Dog', 'Labrador', 3, 28.5, 'male', 'Allergic to chicken-based food', 'Dr. Imran', '0321-1234567');

INSERT INTO vaccinations (pet_id, vaccine_name, date_given, next_due_date, administered_by) VALUES
(1, 'Rabies',    '2024-06-01', '2025-06-01', 'Dr. Imran'),
(1, 'Distemper', '2024-06-01', '2025-06-01', 'Dr. Imran');
