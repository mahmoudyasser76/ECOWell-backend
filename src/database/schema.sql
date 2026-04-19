-- ======================================================
-- EcoWell Final Database Schema (SQLite)
-- Version: 1.0
-- Includes: Auth, Profiles, Gamification, Marketplace, Admin, & Derived Queries
-- ======================================================

PRAGMA foreign_keys = ON;

---------------------------------------------------------
-- 1. Authentication & Users Module
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS Users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT 0,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token TEXT UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
);

---------------------------------------------------------
-- 2. Profiles & Gamification Core
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS Levels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level_number INTEGER UNIQUE NOT NULL,
    min_points INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS Profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER UNIQUE NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    language TEXT DEFAULT 'en',
    total_points INTEGER DEFAULT 0,
    level_id INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (level_id) REFERENCES Levels(id)
);

---------------------------------------------------------
-- 3. Gamification (Badges, Missions, Quizzes)
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS Badges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    condition_type TEXT
);

CREATE TABLE IF NOT EXISTS User_Badges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    badge_id INTEGER NOT NULL,
    unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES Badges(id)
);

CREATE TABLE IF NOT EXISTS Missions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    reward_points INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT 1
);

CREATE TABLE IF NOT EXISTS User_Missions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    mission_id INTEGER NOT NULL,
    status TEXT DEFAULT 'pending', 
    progress INTEGER DEFAULT 0,
    completed_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (mission_id) REFERENCES Missions(id)
);

CREATE TABLE IF NOT EXISTS Quizzes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    category TEXT,
    reward_points INTEGER DEFAULT 10
);

CREATE TABLE IF NOT EXISTS Questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quiz_id INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    correct_answer TEXT NOT NULL,
    options TEXT, -- JSON Format for options
    FOREIGN KEY (quiz_id) REFERENCES Quizzes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS User_Quiz_Results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    quiz_id INTEGER NOT NULL,
    score INTEGER,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES Quizzes(id) ON DELETE CASCADE
);

---------------------------------------------------------
-- 4. Scan System & Reports
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS Reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    result_summary TEXT, -- Short summary of AI results
    status TEXT CHECK(status IN ('pending', 'processed', 'failed')) DEFAULT 'pending', -- pending, processed, failed
    metadata TEXT, -- Full AI JSON results
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
);

---------------------------------------------------------
-- 5. Activity Tracking (History)
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS Actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_key TEXT UNIQUE NOT NULL,
    points_reward INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS User_Actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    action_id INTEGER NOT NULL,
    metadata TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (action_id) REFERENCES Actions(id)
);

---------------------------------------------------------
-- 6. Marketplace & Admin
---------------------------------------------------------
CREATE TABLE IF NOT EXISTS Products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    category_id INTEGER,
    description TEXT,
    image_url TEXT,
    external_link TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES Categories(id)
);

CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS Favorites (
    user_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Admins (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'editor'
);

CREATE TABLE IF NOT EXISTS Admin_Logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    admin_id INTEGER NOT NULL,
    action TEXT NOT NULL,
    entity_type TEXT,
    entity_id INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES Admins(id)
);

CREATE TABLE IF NOT EXISTS Notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
);

---------------------------------------------------------
-- 7. Performance Indexes
---------------------------------------------------------
CREATE INDEX idx_user_email ON Users(email);
CREATE INDEX idx_reports_user ON Reports(user_id);
CREATE INDEX idx_profile_points ON Profiles(total_points DESC);
CREATE INDEX idx_user_actions ON User_Actions(user_id);
CREATE INDEX idx_favorites_user ON Favorites(user_id);
CREATE INDEX idx_user_quiz_results ON User_Quiz_Results(user_id);
CREATE INDEX idx_user_badges ON User_Badges(user_id);
CREATE UNIQUE INDEX idx_user_badge_unique 
ON User_Badges(user_id, badge_id);
CREATE UNIQUE INDEX idx_user_mission_unique 
ON User_Missions(user_id, mission_id);

---------------------------------------------------------
-- 8. Derived Queries (Features without tables)
---------------------------------------------------------

-- [Leaderboard Query]
/*
SELECT 
    fname || ' ' || lname AS full_name,
    total_points,
    RANK() OVER (ORDER BY total_points DESC) as rank
FROM Profiles
JOIN Users ON Profiles.user_id = Users.id
LIMIT 10;
*/

-- [Admin Dashboard Stats Query]
-- SELECT (SELECT COUNT(*) FROM Users) as users, (SELECT COUNT(*) FROM Reports) as scans;

---------------------------------------------------------
-- 9. Initial Seed Data
---------------------------------------------------------
INSERT INTO Levels (level_number, min_points) VALUES (1, 0), (2, 100), (3, 300), (4, 600), (5, 1000);
INSERT INTO Actions (action_key, points_reward) VALUES ('SCAN_PRODUCT', 10), ('DAILY_LOGIN', 5), ('FINISH_QUIZ', 20), ('MISSION_COMPLETE', 50);