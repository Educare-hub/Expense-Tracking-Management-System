/* ===========================
   Clean, dependency-safe SQL Server migration
   Tested for SQL Server 2016+ (JSON support required)
   Note: This script will DROP certain objects if they exist to avoid FK/type conflicts.
   Back up data before running in production.
   =========================== */

SET NOCOUNT ON;
GO

/* ---------------------------
   Cleanup possibly conflicting objects (safe for dev; backup in prod!)
   --------------------------- */
PRINT 'Dropping potentially conflicting objects...';

DROP PROCEDURE IF EXISTS dbo.sp_refresh_mv_monthly_category_summary;
DROP VIEW IF EXISTS dbo.vw_account_transactions;
DROP TABLE IF EXISTS dbo.mv_monthly_category_summary;

-- Drop dependent objects first
DROP TABLE IF EXISTS dbo.expense_tags;
DROP TABLE IF EXISTS dbo.attachments;
DROP TABLE IF EXISTS dbo.audit_logs;
DROP TABLE IF EXISTS dbo.reconciliations;
DROP TABLE IF EXISTS dbo.budgets;
DROP TABLE IF EXISTS dbo.expenses;
DROP TABLE IF EXISTS dbo.recurring_expenses;
DROP TABLE IF EXISTS dbo.tags;
DROP TABLE IF EXISTS dbo.categories;
DROP TABLE IF EXISTS dbo.accounts;
DROP TABLE IF EXISTS dbo.payment_methods;
DROP TABLE IF EXISTS dbo.users;
DROP TABLE IF EXISTS dbo.companies;
DROP TABLE IF EXISTS dbo.exchange_rates;
GO

/* ---------------------------
   1) Tables — created in dependency-safe order
   --------------------------- */

-- Companies
CREATE TABLE dbo.companies (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  name NVARCHAR(400) NOT NULL,
  timezone NVARCHAR(100) NOT NULL DEFAULT(N'Africa/Nairobi'),
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Users
CREATE TABLE dbo.users (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  company_id UNIQUEIDENTIFIER NULL,
  name NVARCHAR(300) NOT NULL,
  email NVARCHAR(320) NULL,
  password_hash NVARCHAR(1000) NULL,
  role NVARCHAR(50) NOT NULL DEFAULT('user'),
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.users
  ADD CONSTRAINT FK_users_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE SET NULL;
GO
CREATE UNIQUE INDEX IX_users_email ON dbo.users (email) WHERE email IS NOT NULL;
GO

-- Payment methods
CREATE TABLE dbo.payment_methods (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(200) NOT NULL UNIQUE,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Accounts
CREATE TABLE dbo.accounts (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  company_id UNIQUEIDENTIFIER NOT NULL,
  name NVARCHAR(300) NOT NULL,
  type NVARCHAR(50) NOT NULL DEFAULT('bank'),
  currency CHAR(3) NOT NULL DEFAULT('KES'),
  balance DECIMAL(18,2) NULL DEFAULT(0),
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.accounts
  ADD CONSTRAINT FK_accounts_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE CASCADE;
GO

-- Categories
CREATE TABLE dbo.categories (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  company_id UNIQUEIDENTIFIER NOT NULL,
  name NVARCHAR(300) NOT NULL,
  parent_id BIGINT NULL,
  is_active BIT NOT NULL DEFAULT(1),
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.categories
  ADD CONSTRAINT FK_categories_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE CASCADE;
GO
ALTER TABLE dbo.categories
  ADD CONSTRAINT FK_categories_parent FOREIGN KEY (parent_id) REFERENCES dbo.categories(id) ON DELETE SET NULL;
GO
CREATE UNIQUE INDEX UQ_categories_company_name ON dbo.categories(company_id, name);
GO

-- Tags
CREATE TABLE dbo.tags (
  id BIGINT IDENTITY(1,1) PRIMARY KEY,
  company_id UNIQUEIDENTIFIER NOT NULL,
  name NVARCHAR(200) NOT NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.tags
  ADD CONSTRAINT FK_tags_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE CASCADE;
GO
CREATE UNIQUE INDEX UQ_tags_company_name ON dbo.tags(company_id, name);
GO

-- Recurring expenses
CREATE TABLE dbo.recurring_expenses (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  company_id UNIQUEIDENTIFIER NULL,
  user_id UNIQUEIDENTIFIER NULL,
  category_id BIGINT NULL,
  payment_method_id BIGINT NULL,
  descriptor NVARCHAR(500) NULL,
  amount DECIMAL(18,2) NOT NULL CHECK (amount >= 0),
  currency CHAR(3) NOT NULL DEFAULT('KES'),
  frequency NVARCHAR(50) NOT NULL,
  next_run DATETIME2(3) NULL,
  end_date DATE NULL,
  active BIT NOT NULL DEFAULT(1),
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.recurring_expenses
  ADD CONSTRAINT FK_recurring_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE SET NULL,
      CONSTRAINT FK_recurring_user FOREIGN KEY (user_id) REFERENCES dbo.users(id),
      CONSTRAINT FK_recurring_category FOREIGN KEY (category_id) REFERENCES dbo.categories(id),
      CONSTRAINT FK_recurring_payment FOREIGN KEY (payment_method_id) REFERENCES dbo.payment_methods(id);
GO

-- Expenses (core)
CREATE TABLE dbo.expenses (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  company_id UNIQUEIDENTIFIER NULL,
  user_id UNIQUEIDENTIFIER NOT NULL,
  account_id UNIQUEIDENTIFIER NULL,
  category_id BIGINT NULL,
  payment_method_id BIGINT NULL,
  recurrent_from UNIQUEIDENTIFIER NULL,
  vendor NVARCHAR(400) NULL,
  description NVARCHAR(MAX) NULL,
  amount DECIMAL(18,2) NOT NULL CHECK (amount >= 0),
  currency CHAR(3) NOT NULL DEFAULT('KES'),
  incurred_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  recorded_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  reconciled BIT NOT NULL DEFAULT(0),
  status NVARCHAR(50) NOT NULL DEFAULT('posted'),
  metadata NVARCHAR(MAX) NULL,
  deleted_at DATETIME2(3) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.expenses
  ADD CONSTRAINT FK_expenses_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE SET NULL,
      CONSTRAINT FK_expenses_user FOREIGN KEY (user_id) REFERENCES dbo.users(id),
      CONSTRAINT FK_expenses_account FOREIGN KEY (account_id) REFERENCES dbo.accounts(id),
      CONSTRAINT FK_expenses_category FOREIGN KEY (category_id) REFERENCES dbo.categories(id),
      CONSTRAINT FK_expenses_payment FOREIGN KEY (payment_method_id) REFERENCES dbo.payment_methods(id),
      CONSTRAINT FK_expenses_recurrent FOREIGN KEY (recurrent_from) REFERENCES dbo.recurring_expenses(id);
GO

-- Expense tags (many-to-many)
CREATE TABLE dbo.expense_tags (
  expense_id UNIQUEIDENTIFIER NOT NULL,
  tag_id BIGINT NOT NULL,
  CONSTRAINT PK_expense_tags PRIMARY KEY (expense_id, tag_id)
);
GO
ALTER TABLE dbo.expense_tags
  ADD CONSTRAINT FK_expense_tags_expense FOREIGN KEY (expense_id) REFERENCES dbo.expenses(id) ON DELETE CASCADE,
      CONSTRAINT FK_expense_tags_tag FOREIGN KEY (tag_id) REFERENCES dbo.tags(id) ON DELETE CASCADE;
GO

-- Attachments
CREATE TABLE dbo.attachments (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  expense_id UNIQUEIDENTIFIER NOT NULL,
  filename NVARCHAR(1000) NULL,
  mime_type NVARCHAR(200) NULL,
  storage_key NVARCHAR(2000) NOT NULL,
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.attachments
  ADD CONSTRAINT FK_attachments_expense FOREIGN KEY (expense_id) REFERENCES dbo.expenses(id) ON DELETE CASCADE;
GO

-- Budgets
CREATE TABLE dbo.budgets (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  company_id UNIQUEIDENTIFIER NOT NULL,
  category_id BIGINT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  amount DECIMAL(18,2) NOT NULL CHECK (amount >= 0),
  metadata NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.budgets
  ADD CONSTRAINT FK_budgets_company FOREIGN KEY (company_id) REFERENCES dbo.companies(id) ON DELETE CASCADE,
      CONSTRAINT FK_budgets_category FOREIGN KEY (category_id) REFERENCES dbo.categories(id),
      CONSTRAINT CHK_budgets_dates CHECK (start_date <= end_date);
GO

-- Reconciliations
CREATE TABLE dbo.reconciliations (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  account_id UNIQUEIDENTIFIER NOT NULL,
  reconciled_by UNIQUEIDENTIFIER NULL,
  period_start DATE NULL,
  period_end DATE NULL,
  notes NVARCHAR(MAX) NULL,
  created_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE dbo.reconciliations
  ADD CONSTRAINT FK_reconciliations_account FOREIGN KEY (account_id) REFERENCES dbo.accounts(id) ON DELETE CASCADE,
      CONSTRAINT FK_reconciliations_user FOREIGN KEY (reconciled_by) REFERENCES dbo.users(id);
GO

-- Audit logs
CREATE TABLE dbo.audit_logs (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  resource_type NVARCHAR(200) NOT NULL,
  resource_id UNIQUEIDENTIFIER NULL,
  resource_pk NVARCHAR(400) NULL,
  action NVARCHAR(50) NOT NULL,
  performed_by UNIQUEIDENTIFIER NULL,
  timestamp DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  diff NVARCHAR(MAX) NULL
);
GO
ALTER TABLE dbo.audit_logs
  ADD CONSTRAINT FK_audit_performed_by FOREIGN KEY (performed_by) REFERENCES dbo.users(id);
GO

-- Exchange rates (optional)
CREATE TABLE dbo.exchange_rates (
  id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
  base_currency CHAR(3) NOT NULL,
  target_currency CHAR(3) NOT NULL,
  rate DECIMAL(18,8) NOT NULL CHECK (rate > 0),
  fetched_at DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_exchange_rates UNIQUE (base_currency, target_currency, fetched_at)
);
GO

/* ---------------------------
   2) CHECK constraints to mimic enums (already applied inline where possible)
   Add missing check constraints explicitly
   --------------------------- */

ALTER TABLE dbo.users ADD CONSTRAINT CHK_users_role_allowed CHECK (role IN ('user','accountant','admin','owner'));
ALTER TABLE dbo.expenses ADD CONSTRAINT CHK_expenses_status_allowed CHECK (status IN ('posted','pending','void','refunded'));
ALTER TABLE dbo.accounts ADD CONSTRAINT CHK_accounts_type_allowed CHECK (type IN ('bank','cash','mpesa','wallet','card','other'));
ALTER TABLE dbo.recurring_expenses ADD CONSTRAINT CHK_recurring_frequency_allowed CHECK (frequency IN ('daily','weekly','monthly','quarterly','yearly'));
GO

/* ---------------------------
   3) Indexes for performance (create only if missing)
   --------------------------- */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_expenses_company_incurred' AND object_id = OBJECT_ID('dbo.expenses'))
  CREATE NONCLUSTERED INDEX IX_expenses_company_incurred ON dbo.expenses(company_id, incurred_at DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_expenses_user_incurred' AND object_id = OBJECT_ID('dbo.expenses'))
  CREATE NONCLUSTERED INDEX IX_expenses_user_incurred ON dbo.expenses(user_id, incurred_at DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_expenses_category' AND object_id = OBJECT_ID('dbo.expenses'))
  CREATE NONCLUSTERED INDEX IX_expenses_category ON dbo.expenses(category_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_expenses_account' AND object_id = OBJECT_ID('dbo.expenses'))
  CREATE NONCLUSTERED INDEX IX_expenses_account ON dbo.expenses(account_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_expenses_reconciled' AND object_id = OBJECT_ID('dbo.expenses'))
  CREATE NONCLUSTERED INDEX IX_expenses_reconciled ON dbo.expenses(reconciled);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_expenses_status' AND object_id = OBJECT_ID('dbo.expenses'))
  CREATE NONCLUSTERED INDEX IX_expenses_status ON dbo.expenses(status);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_accounts_company' AND object_id = OBJECT_ID('dbo.accounts'))
  CREATE NONCLUSTERED INDEX IX_accounts_company ON dbo.accounts(company_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_categories_company' AND object_id = OBJECT_ID('dbo.categories'))
  CREATE NONCLUSTERED INDEX IX_categories_company ON dbo.categories(company_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tags_company' AND object_id = OBJECT_ID('dbo.tags'))
  CREATE NONCLUSTERED INDEX IX_tags_company ON dbo.tags(company_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_attachments_expense' AND object_id = OBJECT_ID('dbo.attachments'))
  CREATE NONCLUSTERED INDEX IX_attachments_expense ON dbo.attachments(expense_id);
GO

/* ---------------------------
   4) updated_at triggers (per table)
   --------------------------- */

-- Helper: drop if exists then create triggers
IF OBJECT_ID('trg_companies_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_companies_set_updated_at;
GO
CREATE TRIGGER trg_companies_set_updated_at
ON dbo.companies
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE c
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.companies c
  INNER JOIN inserted i ON c.id = i.id;
END;
GO

IF OBJECT_ID('trg_users_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_users_set_updated_at;
GO
CREATE TRIGGER trg_users_set_updated_at
ON dbo.users
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE u
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.users u
  INNER JOIN inserted i ON u.id = i.id;
END;
GO

IF OBJECT_ID('trg_accounts_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_accounts_set_updated_at;
GO
CREATE TRIGGER trg_accounts_set_updated_at
ON dbo.accounts
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE a
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.accounts a
  INNER JOIN inserted i ON a.id = i.id;
END;
GO

IF OBJECT_ID('trg_categories_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_categories_set_updated_at;
GO
CREATE TRIGGER trg_categories_set_updated_at
ON dbo.categories
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE c
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.categories c
  INNER JOIN inserted i ON c.id = i.id;
END;
GO

IF OBJECT_ID('trg_recurring_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_recurring_set_updated_at;
GO
CREATE TRIGGER trg_recurring_set_updated_at
ON dbo.recurring_expenses
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE r
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.recurring_expenses r
  INNER JOIN inserted i ON r.id = i.id;
END;
GO

IF OBJECT_ID('trg_budgets_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_budgets_set_updated_at;
GO
CREATE TRIGGER trg_budgets_set_updated_at
ON dbo.budgets
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE b
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.budgets b
  INNER JOIN inserted i ON b.id = i.id;
END;
GO

IF OBJECT_ID('trg_expenses_set_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER trg_expenses_set_updated_at;
GO
CREATE TRIGGER trg_expenses_set_updated_at
ON dbo.expenses
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE e
  SET updated_at = SYSUTCDATETIME()
  FROM dbo.expenses e
  INNER JOIN inserted i ON e.id = i.id;
END;
GO

/* ---------------------------
   5) Audit triggers (generic pattern)
   --------------------------- */

USE ExpenseTrackerDB;
GO

-- Drop existing trigger if it already exists
IF OBJECT_ID('trg_audit_expenses', 'TR') IS NOT NULL
  DROP TRIGGER trg_audit_expenses;
GO

-- ? Create Trigger (Run this as a complete block)
CREATE TRIGGER trg_audit_expenses
ON dbo.expenses
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  -- Handle INSERT and UPDATE
  IF EXISTS (SELECT 1 FROM inserted)
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT
      'expenses',
      TRY_CAST(i.id AS UNIQUEIDENTIFIER),
      CASE WHEN d.id IS NULL THEN 'create' ELSE 'update' END,
      (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    LEFT JOIN deleted d ON i.id = d.id;
  END

  -- Handle DELETE
  IF EXISTS (SELECT 1 FROM deleted WHERE id NOT IN (SELECT id FROM inserted))
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT
      'expenses',
      TRY_CAST(d.id AS UNIQUEIDENTIFIER),
      'delete',
      (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
  END
END;
GO

USE ExpenseTrackerDB;
GO

/* ============================================
   FIXED AUDIT TRIGGERS (Accounts, Users, Companies)
   ============================================ */

-- ============= ACCOUNTS AUDIT TRIGGER ============
IF OBJECT_ID('trg_audit_accounts', 'TR') IS NOT NULL
  DROP TRIGGER trg_audit_accounts;
GO
CREATE TRIGGER trg_audit_accounts
ON dbo.accounts
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  -- Insert or Update
  IF EXISTS (SELECT 1 FROM inserted)
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT 
      'accounts',
      TRY_CAST(i.id AS UNIQUEIDENTIFIER),
      CASE WHEN d.id IS NULL THEN 'create' ELSE 'update' END,
      (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    LEFT JOIN deleted d ON i.id = d.id;
  END

  -- Delete
  IF EXISTS (SELECT 1 FROM deleted WHERE id NOT IN (SELECT id FROM inserted))
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT 
      'accounts',
      TRY_CAST(d.id AS UNIQUEIDENTIFIER),
      'delete',
      (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
  END
END;
GO

-- ============= USERS AUDIT TRIGGER ============
IF OBJECT_ID('trg_audit_users', 'TR') IS NOT NULL
  DROP TRIGGER trg_audit_users;
GO
CREATE TRIGGER trg_audit_users
ON dbo.users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM inserted)
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT 
      'users',
      TRY_CAST(i.id AS UNIQUEIDENTIFIER),
      CASE WHEN d.id IS NULL THEN 'create' ELSE 'update' END,
      (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    LEFT JOIN deleted d ON i.id = d.id;
  END

  IF EXISTS (SELECT 1 FROM deleted WHERE id NOT IN (SELECT id FROM inserted))
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT 
      'users',
      TRY_CAST(d.id AS UNIQUEIDENTIFIER),
      'delete',
      (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
  END
END;
GO

-- ============= COMPANIES AUDIT TRIGGER ============
IF OBJECT_ID('trg_audit_companies', 'TR') IS NOT NULL
  DROP TRIGGER trg_audit_companies;
GO
CREATE TRIGGER trg_audit_companies
ON dbo.companies
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (SELECT 1 FROM inserted)
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT 
      'companies',
      TRY_CAST(i.id AS UNIQUEIDENTIFIER),
      CASE WHEN d.id IS NULL THEN 'create' ELSE 'update' END,
      (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    LEFT JOIN deleted d ON i.id = d.id;
  END

  IF EXISTS (SELECT 1 FROM deleted WHERE id NOT IN (SELECT id FROM inserted))
  BEGIN
    INSERT INTO dbo.audit_logs(resource_type, resource_id, action, diff)
    SELECT 
      'companies',
      TRY_CAST(d.id AS UNIQUEIDENTIFIER),
      'delete',
      (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted d;
  END
END;
GO


/* ---------------------------
   6) Summary (materialized) table + refresh stored proc
   --------------------------- */

CREATE TABLE dbo.mv_monthly_category_summary (
  company_key NVARCHAR(100) NOT NULL,
  month_start DATE NOT NULL,
  category NVARCHAR(300) NOT NULL,
  currency CHAR(3) NOT NULL,
  total_amount DECIMAL(38,2) NOT NULL,
  txn_count INT NOT NULL,
  CONSTRAINT PK_mv_monthly_category_summary PRIMARY KEY (company_key, month_start, category, currency)
);
GO

CREATE PROCEDURE dbo.sp_refresh_mv_monthly_category_summary
AS
BEGIN
  SET NOCOUNT ON;
  TRUNCATE TABLE dbo.mv_monthly_category_summary;

  INSERT INTO dbo.mv_monthly_category_summary (company_key, month_start, category, currency, total_amount, txn_count)
  SELECT
    ISNULL(CONVERT(NVARCHAR(36), e.company_id), 'personal') AS company_key,
    DATEADD(month, DATEDIFF(month, 0, e.incurred_at), 0) AS month_start,
    ISNULL(c.name, 'Uncategorized') AS category,
    e.currency,
    SUM(e.amount) AS total_amount,
    COUNT(*) AS txn_count
  FROM dbo.expenses e
  LEFT JOIN dbo.categories c ON e.category_id = c.id
  WHERE e.deleted_at IS NULL
  GROUP BY ISNULL(CONVERT(NVARCHAR(36), e.company_id), 'personal'),
           DATEADD(month, DATEDIFF(month, 0, e.incurred_at), 0),
           ISNULL(c.name, 'Uncategorized'),
           e.currency;
END;
GO

/* ---------------------------
   7) Helpful view: running balances per account
   --------------------------- */

CREATE VIEW dbo.vw_account_transactions AS
SELECT
  e.account_id,
  e.incurred_at,
  e.id AS expense_id,
  e.description,
  e.amount,
  e.currency,
  SUM(e.amount) OVER (PARTITION BY e.account_id ORDER BY e.incurred_at, e.created_at
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM dbo.expenses e
WHERE e.deleted_at IS NULL;
GO

/* ---------------------------
   8) Seed some payment methods (idempotent)
   --------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.payment_methods WHERE name = 'Cash')
  INSERT INTO dbo.payment_methods (name) VALUES ('Cash');
IF NOT EXISTS (SELECT 1 FROM dbo.payment_methods WHERE name = 'Card')
  INSERT INTO dbo.payment_methods (name) VALUES ('Card');
IF NOT EXISTS (SELECT 1 FROM dbo.payment_methods WHERE name = 'MPESA')
  INSERT INTO dbo.payment_methods (name) VALUES ('MPESA');
IF NOT EXISTS (SELECT 1 FROM dbo.payment_methods WHERE name = 'Bank Transfer')
  INSERT INTO dbo.payment_methods (name) VALUES ('Bank Transfer');
IF NOT EXISTS (SELECT 1 FROM dbo.payment_methods WHERE name = 'Cheque')
  INSERT INTO dbo.payment_methods (name) VALUES ('Cheque');
IF NOT EXISTS (SELECT 1 FROM dbo.payment_methods WHERE name = 'Mobile Wallet')
  INSERT INTO dbo.payment_methods (name) VALUES ('Mobile Wallet');
GO

PRINT 'Migration script completed successfully.';
GO
SELECT @@SERVERNAME;