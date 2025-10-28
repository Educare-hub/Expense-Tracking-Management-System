
-- EXPENSE TRACKER DATABASE SETUP (CLEAN VERSION)

-- ===========================================================
-- USERS TABLE
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
-- ===========================================================
CREATE TABLE Categories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    user_id INT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- ===========================================================
-- ⿥ EXPENSES TABLE
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
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(id)
);

-- ===========================================================
-- ⿦ SAMPLE DATA (OPTIONAL FOR TESTING)
-- ===========================================================

INSERT INTO Users (username, email, password_hash, role)
VALUES
('Admin User', 'admin@example.com', 'hashed_password_here', 'Admin'),
('John Doe', 'john@example.com', 'hashed_password_here', 'User');


--INSERT INTO Registration (user_id, username, email)
--SELECT id, username, email FROM Users;
--GO

INSERT INTO Categories (name, user_id)
VALUES
('Food', 1),
('Transport', 1),
('Utilities', 2),
('Entertainment', 2);


INSERT INTO Expenses (user_id, category_id, amount, currency, note, expense_date)
VALUES
(2, 1, 1200.00, 'KES', 'Groceries at supermarket', '2025-10-25'),
(2, 2, 300.00, 'KES', 'Matatu fare', '2025-10-26');


-- ===========================================================
--  TEST QUERIES
-- ===========================================================

SELECT * FROM Users;
SELECT * FROM Categories;
SELECT * FROM Expenses;

SELECT e.id, e.amount, e.currency, e.note, e.expense_date, c.name AS category
FROM Expenses e
LEFT JOIN Categories c ON e.category_id = c.id
WHERE e.user_id = 2;
