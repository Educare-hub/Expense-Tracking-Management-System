<<<<<<< HEAD
-- ===========================================================
-- EXPENSE TRACKER DATABASE SETUP (CLEAN VERSION)
-- ===========================================================

-- 🔁 Drop existing database if it already exists
IF DB_ID('ExpenseTrackerDB') IS NOT NULL
BEGIN
    ALTER DATABASE ExpenseTrackerDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExpenseTrackerDB;
END
GO

-- 1️⃣ Create the database fresh
CREATE DATABASE ExpenseTrackerDB;
GO

USE ExpenseTrackerDB;
GO

-- ===========================================================
-- 2️⃣ USERS TABLE
=======
﻿
-- EXPENSE TRACKER DATABASE SETUP (CLEAN VERSION)

-- ===========================================================
-- USERS TABLE
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
-- ===========================================================
CREATE TABLE Users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'User',
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
GO

<<<<<<< HEAD
-- ===========================================================
-- 3️⃣ REGISTRATION TABLE (NEW)
-- ===========================================================
CREATE TABLE Registration (
    reg_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    registered_at DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY (user_id) REFERENCES Users(id)
        ON DELETE CASCADE
);
GO

-- ===========================================================
-- 4️⃣ CATEGORIES TABLE
=======
---- ===========================================================
----REGISTRATION TABLE (NEW)
---- ===========================================================
--CREATE TABLE Registration (
--    reg_id INT IDENTITY(1,1) PRIMARY KEY,
--    user_id INT NOT NULL,
--    username VARCHAR(100) NOT NULL,
--    email VARCHAR(255) NOT NULL,
--    registered_at DATETIME2 DEFAULT SYSDATETIME(),
--    FOREIGN KEY (user_id) REFERENCES Users(id)
--        ON DELETE CASCADE
--);
--GO

-- ===========================================================
-- ⿤ CATEGORIES TABLE
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
-- ===========================================================
CREATE TABLE Categories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
<<<<<<< HEAD
    user_id INT NULL, m
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    FOREIGN KEY (user_id) REFERENCES Users(id)
        ON DELETE SET NULL
=======
    user_id INT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(id)
        ON DELETE CASCADE
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
        ON UPDATE CASCADE
);
GO

<<<<<<< HEAD
-- ===========================================================
-- 5️⃣ EXPENSES TABLE
=======

-- ===========================================================
-- ⿥ EXPENSES TABLE
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
-- ===========================================================
CREATE TABLE Expenses (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NULL,
    amount DECIMAL(18,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    note NVARCHAR(1000) NULL,
    is_recurring BIT DEFAULT 0,
    recurring_interval VARCHAR(50) NULL,
    expense_date DATE NOT NULL,
<<<<<<< HEAD
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    updated_at DATETIME2 DEFAULT SYSDATETIME(),
=======
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
    FOREIGN KEY (user_id) REFERENCES Users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(id)
        ON DELETE SET NULL
);
<<<<<<< HEAD
GO

-- ===========================================================
-- 6️⃣ SAMPLE DATA (OPTIONAL FOR TESTING)
=======

-- ===========================================================
-- ⿦ SAMPLE DATA (OPTIONAL FOR TESTING)
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
-- ===========================================================

INSERT INTO Users (username, email, password_hash, role)
VALUES
('Admin User', 'admin@example.com', 'hashed_password_here', 'Admin'),
('John Doe', 'john@example.com', 'hashed_password_here', 'User');
<<<<<<< HEAD
GO

INSERT INTO Registration (user_id, username, email)
SELECT id, username, email FROM Users;
GO

INSERT INTO Categories (name, user_id)
VALUES
('Food', NULL),
('Transport', NULL),
('Utilities', NULL),
('Entertainment', NULL);
GO
=======


--INSERT INTO Registration (user_id, username, email)
--SELECT id, username, email FROM Users;
--GO

INSERT INTO Categories (name, user_id)
VALUES
('Food', 1),
('Transport', 1),
('Utilities', 2),
('Entertainment', 2);

>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)

INSERT INTO Expenses (user_id, category_id, amount, currency, note, expense_date)
VALUES
(2, 1, 1200.00, 'KES', 'Groceries at supermarket', '2025-10-25'),
(2, 2, 300.00, 'KES', 'Matatu fare', '2025-10-26');
<<<<<<< HEAD
GO

-- ===========================================================
-- 7️⃣ TEST QUERIES
-- ===========================================================

SELECT * FROM Users;
SELECT * FROM Registration;
SELECT * FROM Categories;
SELECT * FROM Expenses;
GO
=======


-- ===========================================================
--  TEST QUERIES
-- ===========================================================

SELECT * FROM Users;
SELECT * FROM Categories;
SELECT * FROM Expenses;
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)

SELECT e.id, e.amount, e.currency, e.note, e.expense_date, c.name AS category
FROM Expenses e
LEFT JOIN Categories c ON e.category_id = c.id
<<<<<<< HEAD
WHERE e.user_id = 2;
GO
=======
WHERE e.user_id = 2;
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
