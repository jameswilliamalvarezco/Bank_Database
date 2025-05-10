/*________________________________________________________________________________ Database ______________________________________________________________________________________________________________________*/
USE master; -- Makes sure that there's no other database selected and so that we can execute the code and create a new database. 

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'Bank') -- Drops the database if it exists.
	BEGIN
		ALTER DATABASE Bank SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE Bank
	END
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'Bank') -- Creates the database if it doesn't exist.
	BEGIN
		CREATE DATABASE [Bank]
	END
GO

/*________________________________________________________________________________ Schema ______________________________________________________________________________________________________________________*/

USE Bank; -- Makes sure to choose the new database we just created 
GO

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Users') -- Ensures that if the Schema doesn't exist, then it'll create the schemas, in this case 'Users' or 'Logs' and etc.
    EXEC('CREATE SCHEMA Users;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Security')
    EXEC('CREATE SCHEMA Security;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Bank')
    EXEC('CREATE SCHEMA Bank;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Finance')
    EXEC('CREATE SCHEMA Finance;');
GO

/*________________________________________________________________________________ Tables ______________________________________________________________________________________________________________________*/

CREATE TABLE Users.Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    SocialSecurityNumber NVARCHAR(13) NOT NULL UNIQUE,
    DateOfBirth DATE NOT NULL,
    Gender NCHAR(1) NOT NULL CHECK (Gender IN ('M', 'F', 'O')),
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    PostalCode NVARCHAR(10) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    Country NVARCHAR(60) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(10) NOT NULL CHECK (Status IN ('Active', 'Inactive', 'Blocked'))
);

CREATE TABLE Users.Alerts (
    AlertID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    AlertType NVARCHAR(50) NOT NULL,
    AlertMessage NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(10) NOT NULL CHECK (Status IN ('Read', 'Unread')),
    CONSTRAINT FK_Alerts_Customers FOREIGN KEY (CustomerID) REFERENCES Users.Customers(CustomerID) ON DELETE CASCADE
);

CREATE TABLE Bank.Branches (
    BranchID INT PRIMARY KEY IDENTITY(1,1),
    BranchManagerID INT NULL,
    BranchName NVARCHAR(100) NOT NULL,
    BranchAddress NVARCHAR(255) NOT NULL,
    BranchPhoneNumber NVARCHAR(20) NOT NULL
);

CREATE TABLE Users.Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    BranchID INT NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Position NVARCHAR(50) NOT NULL,
    Gender NCHAR(1) NOT NULL CHECK (Gender IN ('M', 'F', 'O')),
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    PostalCode NVARCHAR(10) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    EmploymentDate DATE NOT NULL DEFAULT GETDATE(),
    Salary DECIMAL(18,2) NOT NULL CHECK(Salary >= 0),
    CONSTRAINT FK_Employees_Branches FOREIGN KEY (BranchID) REFERENCES Bank.Branches(BranchID)
);

ALTER TABLE Bank.Branches -- Has to be added after Branches and Employees tables are created so that we can create these two tables.
	ADD CONSTRAINT FK_Branches_Employees FOREIGN KEY (BranchManagerID) REFERENCES Users.Employees(EmployeeID);

CREATE TABLE Bank.InterestRates (
	InterestRateID INT PRIMARY KEY IDENTITY(1,1),
	AccountType NVARCHAR(100) NOT NULL,
	InterestRate DECIMAL(5,2) NOT NULL,
	ValidFromDate DATE NOT NULL,
	ValidToDate DATE NULL
	);

CREATE TABLE Users.Accounts ( 
	AccountID INT PRIMARY KEY IDENTITY(1,1),
	CustomerID INT NOT NULL,
	BranchID INT NOT NULL,
	InterestRateID INT NOT NULL,
	AccountType NVARCHAR(30) NOT NULL,
	Balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
	Currency NVARCHAR(3) NOT NULL DEFAULT 'SEK',
    CONSTRAINT FK_Accounts_Customers FOREIGN KEY (CustomerID) REFERENCES Users.Customers(CustomerID),
    CONSTRAINT FK_Accounts_Branches FOREIGN KEY (BranchID) REFERENCES Bank.Branches(BranchID),
	CONSTRAINT FK_Accounts_InterestRates FOREIGN KEY (InterestRateID) REFERENCES Bank.InterestRates(InterestRateID)
	);

CREATE TABLE Bank.Cards (
	CardID INT PRIMARY KEY IDENTITY(1,1),
	AccountID INT NOT NULL,
	CardType NVARCHAR(20) NOT NULL,
	CardNumber NVARCHAR(16) NOT NULL UNIQUE,
	IssuedDate DATE NOT NULL,
	ExpiryYear SMALLINT NOT NULL,
	Status NVARCHAR(10) NOT NULL CHECK (Status IN ('Active', 'Blocked', 'Expired')),
	CONSTRAINT FK_Cards_Accounts FOREIGN KEY (AccountID) REFERENCES Users.Accounts(AccountID)
	);

CREATE TABLE Security.AuditLogs (
	AuditLogID INT PRIMARY KEY IDENTITY(1,1),
	EmployeeID INT NOT NULL,
	Action NVARCHAR(255) NOT NULL,
	Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
	AffectedTable NVARCHAR(255) NOT NULL,
	AffectedRowID INT NULL,
	OldValue NVARCHAR(MAX) NULL,
	NewValue NVARCHAR(MAX) NULL,
	CONSTRAINT FK_AuditLogs_Employees FOREIGN KEY (EmployeeID) REFERENCES Users.Employees(EmployeeID)
	);

CREATE TABLE Users.Dispositions (
	DipositionID INT PRIMARY KEY IDENTITY(1,1),
	CustomerID INT NOT NULL,
	AccountID INT NOT NULL,
	CardID INT NOT NULL,
	RelationshipType NVARCHAR(50) NOT NULL,
	DipositionDate DATETIME NOT NULL DEFAULT GETDATE(),
	CONSTRAINT FK_Dispositions_Customers FOREIGN KEY (CustomerID) REFERENCES Users.Customers(CustomerID),
	CONSTRAINT FK_Dispositions_Accounts FOREIGN KEY (AccountID) REFERENCES Users.Accounts(AccountID),
	CONSTRAINT FK_Dispositions_Cards FOREIGN KEY (CardID) REFERENCES Bank.Cards(CardID)
	);

CREATE TABLE Bank.Loans (
	LoanID INT PRIMARY KEY IDENTITY(1,1),
	CustomerID INT NOT NULL,
	InterestRateID INT NOT NULL,
	LoanType NVARCHAR(20) NOT NULL,
	LoanAmount DECIMAL(18,2) NOT NULL,
	LoanTerm NVARCHAR(10) NOT NULL,
	InterestRate DECIMAL(5,2) NOT NULL,
	LoanStartDate DATE NOT NULL,
	LoanEndDate DATE NOT NULL,
	MonthlyPayment DECIMAL(18,2) NOT NULL,
	Status NVARCHAR(10) NOT NULL CHECK (Status IN ('Active', 'Closed', 'Defaulted')),
	CONSTRAINT FK_Loans_Customers FOREIGN KEY (CustomerID) REFERENCES Users.Customers(CustomerID),
	CONSTRAINT FK_Loans_InterestRates FOREIGN KEY (InterestRateID) REFERENCES Bank.InterestRates(InterestRateID)
	);

CREATE TABLE Bank.LoanPayments (
	PaymentID INT PRIMARY KEY IDENTITY(1,1),
	LoanID INT NOT NULL,
	PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
	PaymentAmount DECIMAL(10,2) NOT NULL,
	RemainingBalance DECIMAL(10,2) NOT NULL,
	PaymentMethod NVARCHAR(20) NOT NULL CHECK (PaymentMethod IN ('Bank Transfer', 'Cash', 'Credit Card', 'Check', 'Other')),
	CONSTRAINT FK_LoanPayments_Loans FOREIGN KEY (LoanID) REFERENCES Bank.Loans(LoanID)
	);

CREATE TABLE Finance.Transactions (
	TransactionID INT PRIMARY KEY IDENTITY(1,1),
	AccountID INT NOT NULL,
	TransactionType NVARCHAR(20) NOT NULL CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Transfer')),
	Amount DECIMAL(18,2) NOT NULL,
	TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
	TransactionMethod NVARCHAR(50) NOT NULL CHECK (TransactionMethod IN ('Cash', 'Card', 'Online Banking', 'Wire Transfer', 'Mobile Payment')),
	Description NVARCHAR(MAX) NULL,
	CONSTRAINT FK_Transactions_Accounts FOREIGN KEY (AccountID) REFERENCES Users.Accounts(AccountID)
	);

CREATE TABLE Finance.TransactionLogs (
	LogID INT PRIMARY KEY IDENTITY(1,1),
	TransactionID INT NOT NULL,
	EmployeeID INT NOT NULL,
	LogMessage NVARCHAR(MAX) NOT NULL,
	LogTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
	CONSTRAINT FK_TransactionLogs_Transactions FOREIGN KEY (TransactionID) REFERENCES Finance.Transactions(TransactionID),
	CONSTRAINT FK_TransactionLogs_Employees FOREIGN KEY (EmployeeID) REFERENCES Users.Employees(EmployeeID)
	);

/*________________________________________________________________________________ Data Insertion ______________________________________________________________________________________________________________________*/

INSERT INTO Users.Customers
    (Name, SocialSecurityNumber, DateOfBirth, Gender, Email, PhoneNumber, Address, PostalCode, City, Country, Status)
VALUES
    ('Johan Svensson', '19880415-7845', '1988-04-15', 'M', 'johan.svensson@gmail.com', '+46738911234', 'Storgatan 12', '114 56', 'Stockholm', 'Sweden', 'Active'),
<<<<<<< HEAD
    ('Fatima Hussein', '19950610-4521', '1995-06-10', 'F', 'fatima.hussein@yahoo.com', '+46763224567', 'Bergsgatan 23', '211 12', 'Malm�', 'Iraq', 'Active'),
    ('Anders Karlsson', '20010821-9856', '2001-08-21', 'M', 'anders.karlsson@hotmail.com', '+46782347654', 'Linn�gatan 45', '413 04', 'G�teborg', 'Sweden', 'Inactive'),
    ('Sofia Zhang', '20050411-5673', '2005-04-11', 'F', 'sofia.zhang@gmail.com', '+46765438912', 'Kungsgatan 8', '753 20', 'Uppsala', 'China', 'Active'),
    ('Oskar Berg', '19991202-3456', '1999-12-02', 'M', 'oskar.berg@gmail.com', '+46734598761', 'Drottninggatan 30', '803 10', 'G�vle', 'Sweden', 'Blocked'),
    ('Lena Persson', '19830527-1234', '1983-05-27', 'F', 'lena.persson@gmail.com', '+46768765432', 'Huvudv�gen 5', '541 45', 'Sk�vde', 'Sweden', 'Active'),
    ('Ahmed Ali', '20020814-9872', '2002-08-14', 'M', 'ahmed.ali@gmail.com', '+46769876543', 'Roseng�rdsv�gen 6', '213 66', 'Malm�', 'Somalia', 'Inactive'),
    ('Emma Lindstr�m', '19970303-7654', '1997-03-03', 'F', 'emma.lindstrom@gmail.com', '+46765412389', 'Torsgatan 18', '411 03', 'G�teborg', 'Sweden', 'Blocked'),
    ('David Brown', '19900129-4321', '1990-01-29', 'M', 'david.brown@gmail.com', '+46768901234', 'Sveav�gen 60', '113 59', 'Stockholm', 'USA', 'Active'),
    ('Aliyah Mohamed', '20070930-6543', '2007-09-30', 'F', 'aliyah.mohamed@gmail.com', '+46769871234', 'Lantmannagatan 9', '214 50', 'Malm�', 'Eritrea', 'Inactive'),
    ('Elliot Larsson', '20100205-8765', '2010-02-05', 'O', 'elliot.larsson@gmail.com', '+46769876521', 'Vasagatan 3', '722 11', 'V�ster�s', 'Sweden', 'Active'),
    ('Isabella Rossi', '19920418-4323', '1992-04-18', 'F', 'isabella.rossi@gmail.com', '+46768904321', '�stra Hamngatan 4', '411 10', 'G�teborg', 'Italy', 'Blocked'),
    ('Kristian Nilsson', '20060317-5432', '2006-03-17', 'M', 'kristian.nilsson@gmail.com', '+46765498721', 'Brunnsgatan 19', '111 38', 'Stockholm', 'Sweden', 'Inactive'),
    ('Morgan Sj�berg', '19891224-3214', '1989-12-24', 'O', 'morgan.sjoberg@gmail.com', '+46769871239', 'Bj�rkv�gen 7', '632 20', 'Eskilstuna', 'Sweden', 'Active'),
    ('Amina Jafari', '20080812-6547', '2008-08-12', 'F', 'amina.jafari@gmail.com', '+46767890123', 'Kungs�ngsgatan 12', '753 20', 'Uppsala', 'Afghanistan', 'Blocked');
=======
    ('Fatima Hussein', '19950610-4521', '1995-06-10', 'F', 'fatima.hussein@yahoo.com', '+46763224567', 'Bergsgatan 23', '211 12', 'Malm�', 'Iraq', 'Active'),
    ('Anders Karlsson', '20010821-9856', '2001-08-21', 'M', 'anders.karlsson@hotmail.com', '+46782347654', 'Linn�gatan 45', '413 04', 'G�teborg', 'Sweden', 'Inactive'),
    ('Sofia Zhang', '20050411-5673', '2005-04-11', 'F', 'sofia.zhang@gmail.com', '+46765438912', 'Kungsgatan 8', '753 20', 'Uppsala', 'China', 'Active'),
    ('Oskar Berg', '19991202-3456', '1999-12-02', 'M', 'oskar.berg@gmail.com', '+46734598761', 'Drottninggatan 30', '803 10', 'G�vle', 'Sweden', 'Blocked'),
    ('Lena Persson', '19830527-1234', '1983-05-27', 'F', 'lena.persson@gmail.com', '+46768765432', 'Huvudv�gen 5', '541 45', 'Sk�vde', 'Sweden', 'Active'),
    ('Ahmed Ali', '20020814-9872', '2002-08-14', 'M', 'ahmed.ali@gmail.com', '+46769876543', 'Roseng�rdsv�gen 6', '213 66', 'Malm�', 'Somalia', 'Inactive'),
    ('Emma Lindstr�m', '19970303-7654', '1997-03-03', 'F', 'emma.lindstrom@gmail.com', '+46765412389', 'Torsgatan 18', '411 03', 'G�teborg', 'Sweden', 'Blocked'),
    ('David Brown', '19900129-4321', '1990-01-29', 'M', 'david.brown@gmail.com', '+46768901234', 'Sveav�gen 60', '113 59', 'Stockholm', 'USA', 'Active'),
    ('Aliyah Mohamed', '20070930-6543', '2007-09-30', 'F', 'aliyah.mohamed@gmail.com', '+46769871234', 'Lantmannagatan 9', '214 50', 'Malm�', 'Eritrea', 'Inactive'),
    ('Elliot Larsson', '20100205-8765', '2010-02-05', 'O', 'elliot.larsson@gmail.com', '+46769876521', 'Vasagatan 3', '722 11', 'V�ster�s', 'Sweden', 'Active'),
    ('Isabella Rossi', '19920418-4323', '1992-04-18', 'F', 'isabella.rossi@gmail.com', '+46768904321', '�stra Hamngatan 4', '411 10', 'G�teborg', 'Italy', 'Blocked'),
    ('Kristian Nilsson', '20060317-5432', '2006-03-17', 'M', 'kristian.nilsson@gmail.com', '+46765498721', 'Brunnsgatan 19', '111 38', 'Stockholm', 'Sweden', 'Inactive'),
    ('Morgan Sj�berg', '19891224-3214', '1989-12-24', 'O', 'morgan.sjoberg@gmail.com', '+46769871239', 'Bj�rkv�gen 7', '632 20', 'Eskilstuna', 'Sweden', 'Active'),
    ('Amina Jafari', '20080812-6547', '2008-08-12', 'F', 'amina.jafari@gmail.com', '+46767890123', 'Kungs�ngsgatan 12', '753 20', 'Uppsala', 'Afghanistan', 'Blocked');
>>>>>>> 03d82fead01c25affbf599bec294bf6307202670

INSERT INTO Users.Alerts
	(CustomerID, AlertType, AlertMessage, Status)
VALUES
	(1, 'Transaction Alert', 'A withdrawal of $500 was made from your account.', 'Read'),
	(2, 'Login Alert', 'Your account was accessed from a new device.', 'Unread'),
	(3, 'Low Balance Alert', 'Your account balance has dropped below $100.', 'Unread'),
	(4, 'Loan Payment Reminder', 'Your loan payment of $1,200 is due in 3 days.', 'Read'),
	(5, 'Credit Card Payment Due', 'Your credit card payment of $300 is due tomorrow.', 'Unread'),
	(6, 'Suspicious Activity', 'Unusual activity detected on your account. Please verify.', 'Read'),
	(7, 'Deposit Confirmation', 'A deposit of $2,000 has been made to your account.', 'Unread'),
	(8, 'Overdraft Warning', 'Your account is overdrawn. Immediate action required.', 'Read'),
	(9, 'Profile Update Alert', 'Your contact information was recently updated.', 'Unread'),
	(10, 'Interest Payment', 'Interest of $50 has been credited to your savings account.', 'Read');

INSERT INTO Bank.Branches
	(BranchName, BranchAddress, BranchPhoneNumber)
VALUES
	('Stockholm City Bank', 'Drottninggatan 15, 111 51 Stockholm', '+46 8 555 12345'),
<<<<<<< HEAD
	('G�teborg Finanscenter', 'Avenyn 32, 411 36 G�teborg', '+46 31 789 6789'),
	('Malm� Bank & Co.', 'Stortorget 7, 211 34 Malm�', '+46 40 222 4567');
=======
	('G�teborg Finanscenter', 'Avenyn 32, 411 36 G�teborg', '+46 31 789 6789'),
	('Malm� Bank & Co.', 'Stortorget 7, 211 34 Malm�', '+46 40 222 4567');
>>>>>>> 03d82fead01c25affbf599bec294bf6307202670

INSERT INTO Users.Employees
	(BranchID, Name, Position, Gender, Email, PhoneNumber, Address, PostalCode, City, Country, EmploymentDate, Salary)
VALUES
<<<<<<< HEAD
	(1, 'Erik Johansson', 'Branch Manager', 'M', 'erik.johansson@stockholmbank.se', '+46 70 123 4567', 'Sveav�gen 14', '111 57', 'Stockholm', 'Sweden', '2020-06-15', 65000.00),
	(1, 'Fatima Al-Hassan', 'Financial Advisor', 'F', 'fatima.alhassan@stockholmbank.se', '+46 70 234 5678', 'Kungsgatan 34', '111 48', 'Stockholm', 'Sweden', '2021-03-12', 48000.00),
	(1, 'Liam O�Connor', 'Loan Officer', 'M', 'liam.oconnor@stockholmbank.se', '+46 70 345 6789', 'Birger Jarlsgatan 21', '114 34', 'Stockholm', 'Ireland', '2022-07-01', 45000.00),
	(1, 'Chen Wei', 'Customer Service Representative', 'M', 'chen.wei@stockholmbank.se', '+46 70 456 7890', 'Hornsgatan 67', '118 49', 'Stockholm', 'China', '2023-05-23', 37000.00),
	(1, 'Sofia Bergstr�m', 'Accountant', 'F', 'sofia.bergstrom@stockholmbank.se', '+46 70 567 8901', 'Vasagatan 10', '111 20', 'Stockholm', 'Sweden', '2021-11-10', 52000.00),
	(2, 'Anders Lindqvist', 'Branch Manager', 'M', 'anders.lindqvist@gbgfinans.se', '+46 31 100 200', 'Kungsportsavenyn 45', '411 36', 'G�teborg', 'Sweden', '2019-09-20', 64000.00),
	(2, 'Aisha Njeri', 'Investment Analyst', 'F', 'aisha.njeri@gbgfinans.se', '+46 31 111 222', 'S�dra V�gen 12', '412 54', 'G�teborg', 'Kenya', '2020-12-01', 51000.00),
	(2, 'Johan Persson', 'Loan Officer', 'M', 'johan.persson@gbgfinans.se', '+46 31 122 333', 'Haga Nygata 9', '411 22', 'G�teborg', 'Sweden', '2023-04-15', 46000.00),
	(2, 'Maria Gonzalez', 'Financial Advisor', 'F', 'maria.gonzalez@gbgfinans.se', '+46 31 133 444', 'Viktoriagatan 6', '411 25', 'G�teborg', 'Spain', '2021-08-29', 49000.00),
	(2, 'Raj Patel', 'Customer Service Representative', 'M', 'raj.patel@gbgfinans.se', '+46 31 144 555', '�stra Hamngatan 22', '411 10', 'G�teborg', 'India', '2022-10-05', 36000.00),
	(3, 'Karin Svensson', 'Branch Manager', 'F', 'karin.svensson@malmobank.se', '+46 40 200 300', 'Gustav Adolfs torg 8', '211 39', 'Malm�', 'Sweden', '2018-05-14', 63000.00),
	(3, 'Omar El-Sayed', 'Loan Officer', 'M', 'omar.elsayed@malmobank.se', '+46 40 211 400', 'Davidshallsgatan 17', '211 45', 'Malm�', 'Egypt', '2021-02-10', 47000.00),
	(3, 'Emily Carter', 'Financial Advisor', 'F', 'emily.carter@malmobank.se', '+46 40 222 500', 'F�reningsgatan 32', '211 52', 'Malm�', 'USA', '2023-07-18', 49000.00),
	(3, 'Nguyen Hoang', 'Accountant', 'M', 'nguyen.hoang@malmobank.se', '+46 40 233 600', 'Dj�knegatan 4', '211 34', 'Malm�', 'Vietnam', '2020-09-22', 53000.00),
	(3, 'Anna M�ller', 'Customer Service Representative', 'F', 'anna.muller@malmobank.se', '+46 40 244 700', 'Skomakaregatan 3', '211 36', 'Malm�', 'Germany', '2022-12-01', 35000.00);

UPDATE Bank.Branches SET BranchManagerID ='11' WHERE BranchName = 'Malm� Bank & Co.';
UPDATE Bank.Branches SET BranchManagerID ='6' WHERE BranchName = 'G�teborg Finanscenter';
=======
	(1, 'Erik Johansson', 'Branch Manager', 'M', 'erik.johansson@stockholmbank.se', '+46 70 123 4567', 'Sveav�gen 14', '111 57', 'Stockholm', 'Sweden', '2020-06-15', 65000.00),
	(1, 'Fatima Al-Hassan', 'Financial Advisor', 'F', 'fatima.alhassan@stockholmbank.se', '+46 70 234 5678', 'Kungsgatan 34', '111 48', 'Stockholm', 'Sweden', '2021-03-12', 48000.00),
	(1, 'Liam O�Connor', 'Loan Officer', 'M', 'liam.oconnor@stockholmbank.se', '+46 70 345 6789', 'Birger Jarlsgatan 21', '114 34', 'Stockholm', 'Ireland', '2022-07-01', 45000.00),
	(1, 'Chen Wei', 'Customer Service Representative', 'M', 'chen.wei@stockholmbank.se', '+46 70 456 7890', 'Hornsgatan 67', '118 49', 'Stockholm', 'China', '2023-05-23', 37000.00),
	(1, 'Sofia Bergstr�m', 'Accountant', 'F', 'sofia.bergstrom@stockholmbank.se', '+46 70 567 8901', 'Vasagatan 10', '111 20', 'Stockholm', 'Sweden', '2021-11-10', 52000.00),
	(2, 'Anders Lindqvist', 'Branch Manager', 'M', 'anders.lindqvist@gbgfinans.se', '+46 31 100 200', 'Kungsportsavenyn 45', '411 36', 'G�teborg', 'Sweden', '2019-09-20', 64000.00),
	(2, 'Aisha Njeri', 'Investment Analyst', 'F', 'aisha.njeri@gbgfinans.se', '+46 31 111 222', 'S�dra V�gen 12', '412 54', 'G�teborg', 'Kenya', '2020-12-01', 51000.00),
	(2, 'Johan Persson', 'Loan Officer', 'M', 'johan.persson@gbgfinans.se', '+46 31 122 333', 'Haga Nygata 9', '411 22', 'G�teborg', 'Sweden', '2023-04-15', 46000.00),
	(2, 'Maria Gonzalez', 'Financial Advisor', 'F', 'maria.gonzalez@gbgfinans.se', '+46 31 133 444', 'Viktoriagatan 6', '411 25', 'G�teborg', 'Spain', '2021-08-29', 49000.00),
	(2, 'Raj Patel', 'Customer Service Representative', 'M', 'raj.patel@gbgfinans.se', '+46 31 144 555', '�stra Hamngatan 22', '411 10', 'G�teborg', 'India', '2022-10-05', 36000.00),
	(3, 'Karin Svensson', 'Branch Manager', 'F', 'karin.svensson@malmobank.se', '+46 40 200 300', 'Gustav Adolfs torg 8', '211 39', 'Malm�', 'Sweden', '2018-05-14', 63000.00),
	(3, 'Omar El-Sayed', 'Loan Officer', 'M', 'omar.elsayed@malmobank.se', '+46 40 211 400', 'Davidshallsgatan 17', '211 45', 'Malm�', 'Egypt', '2021-02-10', 47000.00),
	(3, 'Emily Carter', 'Financial Advisor', 'F', 'emily.carter@malmobank.se', '+46 40 222 500', 'F�reningsgatan 32', '211 52', 'Malm�', 'USA', '2023-07-18', 49000.00),
	(3, 'Nguyen Hoang', 'Accountant', 'M', 'nguyen.hoang@malmobank.se', '+46 40 233 600', 'Dj�knegatan 4', '211 34', 'Malm�', 'Vietnam', '2020-09-22', 53000.00),
	(3, 'Anna M�ller', 'Customer Service Representative', 'F', 'anna.muller@malmobank.se', '+46 40 244 700', 'Skomakaregatan 3', '211 36', 'Malm�', 'Germany', '2022-12-01', 35000.00);

UPDATE Bank.Branches SET BranchManagerID ='11' WHERE BranchName = 'Malm� Bank & Co.';
UPDATE Bank.Branches SET BranchManagerID ='6' WHERE BranchName = 'G�teborg Finanscenter';
>>>>>>> 03d82fead01c25affbf599bec294bf6307202670
UPDATE Bank.Branches SET BranchManagerID ='1' WHERE BranchName = 'Stockholm City Bank';

INSERT INTO Bank.InterestRates
	(AccountType, InterestRate, ValidFromDate, ValidToDate)
VALUES
    ('Savings Account', 1.50, '2024-01-01', '2025-12-31'),
    ('Fixed Deposit - 6 months', 2.25, '2024-01-01', '2024-06-30'),
    ('Fixed Deposit - 1 year', 2.75, '2024-01-01', '2024-12-31'),
    ('Fixed Deposit - 3 years', 3.25, '2024-01-01', '2026-12-31'),
    ('Fixed Deposit - 5 years', 3.75, '2024-01-01', '2028-12-31'),
    ('Checking Account', 0.10, '2024-01-01', '2026-12-31'),
    ('Business Account', 0.75, '2024-01-01', '2025-12-31'),
    ('Premium Savings Account', 2.00, '2024-01-01', '2026-06-30'),
    ('Youth Savings Account', 1.75, '2024-01-01', '2025-06-30'),
    ('Retirement Savings Account', 2.50, '2024-01-01', '2029-12-31'),
    ('Mortgage Loan', 4.50, '2024-01-01', '2026-12-31'),
    ('Personal Loan', 6.25, '2024-01-01', '2025-06-30'),
    ('Car Loan', 5.00, '2024-01-01', '2025-12-31'),
    ('Credit Card', 15.99, '2024-01-01', '2026-12-31');

INSERT INTO Users.Accounts
	(CustomerID, BranchID, InterestRateID, AccountType, Balance, Currency)
VALUES
	(1, 2, 1, 'Savings', 12500.00, 'SEK'),
	(2, 1, 2, 'Current', 4570.50, 'SEK'),
	(3, 3, 3, 'Fixed Deposit', 30000.00, 'SEK'),
	(4, 1, 2, 'Savings', 9800.00, 'SEK'),
	(5, 2, 1, 'Current', 2140.75, 'SEK'),
	(6, 3, 3, 'Savings', 15250.00, 'SEK'),
	(7, 1, 2, 'Fixed Deposit', 50000.00, 'SEK'),
	(8, 2, 1, 'Current', 6350.00, 'SEK'),
	(9, 3, 2, 'Savings', 8730.00, 'SEK'),
	(10, 1, 3, 'Fixed Deposit', 45000.00, 'SEK'),
	(11, 2, 2, 'Savings', 2760.00, 'SEK'),
	(12, 3, 1, 'Current', 3900.00, 'SEK'),
	(13, 1, 3, 'Savings', 7150.00, 'SEK'),
	(14, 2, 2, 'Current', 4870.00, 'SEK'),
	(15, 3, 1, 'Fixed Deposit', 100000.00, 'SEK');

INSERT INTO Bank.Cards
	(AccountID, CardType, CardNumber, IssuedDate, ExpiryYear, Status)
VALUES
    (1, 'Debit',  '4539123498761234', '2021-03-10', 2026, 'Active'),
    (1, 'Credit', '5243678912345678', '2020-07-15', 2025, 'Active'),
    (2, 'Debit',  '4765823471982345', '2021-06-11', 2026, 'Blocked'),
    (2, 'Credit', '5398123456239876', '2019-01-15', 2024, 'Expired'),
    (3, 'Debit',  '4029384712983471', '2022-08-05', 2027, 'Active'),
    (3, 'Credit', '5111222233334444', '2020-03-20', 2025, 'Active'),
    (4, 'Debit',  '4532987654321234', '2021-05-20', 2026, 'Active'),
    (4, 'Credit', '5533764499887766', '2019-09-10', 2024, 'Expired'),
    (5, 'Debit',  '4916987654329987', '2022-04-01', 2027, 'Blocked'),
    (5, 'Credit', '5432345676543210', '2021-07-14', 2026, 'Active'),
    (6, 'Debit',  '4029111166667777', '2023-02-18', 2028, 'Active'),
    (6, 'Credit', '5588776655443322', '2018-12-30', 2023, 'Expired'),
    (7, 'Debit',  '4111444433332222', '2021-06-12', 2026, 'Active'),
    (7, 'Credit', '5198765432101234', '2020-10-10', 2025, 'Blocked'),
    (8, 'Debit',  '4871234598765432', '2022-04-06', 2027, 'Active'),
    (8, 'Credit', '5333444422221111', '2019-08-18', 2024, 'Expired'),
    (9, 'Debit',  '4567456745674567', '2021-11-01', 2026, 'Active'),
    (9, 'Credit', '5100765432105678', '2020-01-01', 2025, 'Blocked'),
    (10, 'Debit', '4921888899991111', '2023-05-10', 2028, 'Active'),
    (10, 'Credit','5222666699994444', '2021-12-31', 2026, 'Active'),
    (11, 'Debit', '4599887766554433', '2022-09-09', 2027, 'Blocked'),
    (11, 'Credit','5377999988885555', '2020-06-06', 2025, 'Expired'),
    (12, 'Debit', '4899887733221100', '2021-10-10', 2026, 'Active'),
    (12, 'Credit','5344556677889911', '2019-04-04', 2024, 'Expired'),
    (13, 'Debit', '4022001111222233', '2023-03-15', 2028, 'Active'),
    (13, 'Credit','5533887766554433', '2021-07-21', 2026, 'Active'),
    (14, 'Debit', '4100123412345678', '2022-12-12', 2027, 'Active'),
    (14, 'Credit','5244000099998888', '2020-08-30', 2025, 'Blocked'),
    (15, 'Debit', '4677889900112233', '2023-01-01', 2028, 'Active'),
    (15, 'Credit','5377990011223344', '2021-11-11', 2026, 'Active');

INSERT INTO Security.AuditLogs
	(EmployeeID, Action, Timestamp, AffectedTable, AffectedRowID, OldValue, NewValue)
VALUES
	(6, 'UPDATE', '2025-04-05 10:23:45', 'Users.Customers', 12, 'Email: old@example.com', 'Email: new@example.com'),
	(2, 'INSERT', '2025-04-04 14:12:22', 'Finance.Accounts', 45, NULL, 'New record created'),
	(14, 'DELETE', '2025-04-06 09:00:00', 'Finance.Loans', 7, 'LoanID: 12, Amount: 10000', NULL),
	(1, 'UPDATE', '2025-04-03 12:44:55', 'Users.Customers', 33, 'Phone: +46 70 111 1111', 'Phone: +46 70 222 2222'),
	(12, 'INSERT', '2025-04-06 08:12:10', 'Bank.Transactions', 88, NULL, 'Initial transaction logged'),
	(3, 'UPDATE', '2025-04-04 13:55:00', 'Users.Employees', 6, 'Position: Analyst', 'Position: Senior Analyst'),
	(9, 'DELETE', '2025-04-02 17:30:45', 'Finance.Accounts', 92, 'Account closed', NULL),
	(7, 'UPDATE', '2025-04-06 09:25:00', 'Finance.Loans', 51, 'Old status: Active', 'New status: Inactive'),
	(15, 'INSERT', '2025-04-01 10:45:15', 'Users.Customers', 78, NULL, 'New customer created'),
	(4, 'UPDATE', '2025-04-05 11:30:00', 'Users.Employees', 10, 'Email: old@example.com', 'Email: new@example.com'),
	(11, 'INSERT', '2025-04-06 08:11:11', 'Bank.Transactions', 67, NULL, 'New record created'),
	(8, 'DELETE', '2025-04-03 17:03:20', 'Finance.Accounts', 58, 'Account closed', NULL),
	(10, 'UPDATE', '2025-04-04 16:30:10', 'Users.Customers', 99, 'Phone: +46 70 111 1111', 'Phone: +46 70 222 2222'),
	(5, 'INSERT', '2025-04-02 09:22:01', 'Finance.Accounts', 39, NULL, 'Initial transaction logged'),
	(13, 'DELETE', '2025-04-01 14:44:00', 'Finance.Loans', 29, 'LoanID: 12, Amount: 10000', NULL),
	(1, 'UPDATE', '2025-04-05 18:12:36', 'Users.Employees', 4, 'Salary: 50000', 'Salary: 55000'),
	(14, 'INSERT', '2025-04-04 07:19:33', 'Users.Customers', 57, NULL, 'New customer: test'),
<<<<<<< HEAD
	(9, 'UPDATE', '2025-04-06 09:35:00', 'Users.Customers', 51, 'Old branch: Stockholm', 'New branch: G�teborg'),
=======
	(9, 'UPDATE', '2025-04-06 09:35:00', 'Users.Customers', 51, 'Old branch: Stockholm', 'New branch: G�teborg'),
>>>>>>> 03d82fead01c25affbf599bec294bf6307202670
	(6, 'DELETE', '2025-04-03 13:41:09', 'Finance.Loans', 22, 'LoanID: 12, Amount: 10000', NULL),
	(7, 'INSERT', '2025-04-02 08:22:49', 'Bank.Transactions', 19, NULL, 'New record created'),
	(12, 'UPDATE', '2025-04-05 15:10:05', 'Users.Employees', 12, 'Email: old@example.com', 'Email: new@example.com'),
	(3, 'DELETE', '2025-04-01 11:11:11', 'Finance.Accounts', 89, 'Account closed', NULL),
	(5, 'INSERT', '2025-04-06 07:00:00', 'Users.Customers', 88, NULL, 'New customer: Maria Karlsson'),
	(8, 'UPDATE', '2025-04-05 09:33:27', 'Finance.Loans', 43, 'Interest Rate: 5.5%', 'Interest Rate: 4.9%'),
	(11, 'DELETE', '2025-04-02 10:10:10', 'Users.Employees', 15, 'Old status: Active', NULL);	

INSERT INTO Users.Dispositions 
	(CustomerID, AccountID, CardID, RelationshipType, DipositionDate) 
VALUES
	(1, 1, 1, 'Owner', '2023-01-15'),
	(2, 2, 2, 'Authorized User', '2023-03-10'),
	(3, 3, 3, 'Joint Holder', '2022-11-08'),
	(4, 4, 4, 'Owner', '2024-02-25'),
	(5, 5, 5, 'Power of Attorney', '2023-05-12'),
	(6, 6, 6, 'Authorized User', '2023-07-03'),
	(7, 7, 7, 'Owner', '2023-09-14'),
	(8, 8, 8, 'Joint Holder', '2022-12-29'),
	(9, 9, 9, 'Owner', '2023-10-20'),
	(10, 10, 10, 'Authorized User', '2024-01-05'),
	(11, 11, 11, 'Owner', '2023-06-18'),
	(12, 12, 12, 'Power of Attorney', '2023-04-09'),
	(13, 13, 13, 'Authorized User', '2023-08-23'),
	(14, 14, 14, 'Owner', '2022-10-31'),
	(15, 15, 15, 'Joint Holder', '2023-11-11');

INSERT INTO Bank.Loans
	(CustomerID, InterestRateID, LoanType, LoanAmount, LoanTerm, InterestRate, LoanStartDate, LoanEndDate, MonthlyPayment, Status)
VALUES
	(3, 2, 'Home', 350000.00, '240M', 3.25, '2020-05-15', '2040-05-15', 1916.42, 'Active'),
	(5, 1, 'Car', 25000.00, '60M', 4.10, '2021-03-10', '2026-03-10', 460.59, 'Closed'),
	(7, 4, 'Personal', 10000.00, '36M', 5.20, '2022-07-01', '2025-07-01', 300.21, 'Active'),
	(2, 3, 'Business', 150000.00, '120M', 4.75, '2020-01-20', '2030-01-20', 1570.36, 'Defaulted'),
	(1, 5, 'Education', 30000.00, '84M', 3.75, '2019-09-01', '2026-09-01', 408.33, 'Closed'),
	(9, 2, 'Car', 18000.00, '48M', 4.25, '2021-11-12', '2025-11-12', 407.12, 'Active'),
	(4, 1, 'Home', 420000.00, '360M', 3.00, '2018-06-01', '2048-06-01', 1772.07, 'Active'),
	(6, 3, 'Business', 200000.00, '180M', 4.95, '2022-01-15', '2037-01-15', 1580.89, 'Active'),
	(10, 5, 'Personal', 15000.00, '36M', 5.80, '2023-03-01', '2026-03-01', 454.63, 'Closed'),
	(8, 4, 'Education', 25000.00, '60M', 4.50, '2020-09-20', '2025-09-20', 466.65, 'Defaulted'),
	(2, 2, 'Car', 22000.00, '72M', 3.95, '2019-12-01', '2025-12-01', 341.87, 'Active'),
	(3, 3, 'Business', 120000.00, '84M', 5.10, '2021-08-10', '2028-08-10', 1691.22, 'Active'),
	(1, 5, 'Home', 275000.00, '180M', 3.75, '2018-02-01', '2033-02-01', 2002.34, 'Closed'),
	(6, 1, 'Education', 18000.00, '48M', 4.20, '2022-05-10', '2026-05-10', 408.97, 'Active'),
	(4, 2, 'Personal', 12000.00, '24M', 5.60, '2021-01-01', '2023-01-01', 530.75, 'Closed');

INSERT INTO Bank.LoanPayments
	(LoanID, PaymentDate, PaymentAmount, RemainingBalance, PaymentMethod)
VALUES
	(1, '2023-01-01 00:00:00', 684.67, 317694.83, 'Other'),
	(1, '2023-02-01 00:00:00', 1474.72, 316220.11, 'Check'),
	(2, '2023-01-01 00:00:00', 2486.49, 44384.04, 'Credit Card'),
	(2, '2023-01-30 00:00:00', 1992.55, 42391.50, 'Credit Card'),
	(2, '2023-02-27 00:00:00', 1558.33, 40833.17, 'Check'),
	(3, '2023-01-01 00:00:00', 1555.37, 95849.72, 'Cash'),
	(3, '2023-01-30 00:00:00', 1792.42, 94057.30, 'Bank Transfer'),
	(4, '2023-01-01 00:00:00', 2250.09, 146891.37, 'Check'),
	(5, '2023-01-01 00:00:00', 2353.44, 27646.48, 'Cash'),
	(5, '2023-01-30 00:00:00', 777.76, 26868.72, 'Bank Transfer'),
	(5, '2023-03-01 00:00:00', 1432.41, 25436.31, 'Other'),
	(5, '2023-03-31 00:00:00', 1583.95, 23852.36, 'Other'),
	(6, '2023-01-01 00:00:00', 2211.75, 157788.70, 'Bank Transfer'),
	(6, '2023-01-31 00:00:00', 1096.65, 156692.05, 'Cash'),
	(6, '2023-03-03 00:00:00', 1525.42, 155166.63, 'Bank Transfer'),
	(7, '2023-01-01 00:00:00', 567.96, 415432.89, 'Cash'),
	(8, '2023-01-01 00:00:00', 1061.19, 198799.99, 'Other'),
	(8, '2023-01-28 00:00:00', 2164.04, 196635.95, 'Bank Transfer'),
	(9, '2023-01-01 00:00:00', 1027.13, 13912.47, 'Bank Transfer'),
	(9, '2023-01-26 00:00:00', 2371.16, 11541.31, 'Credit Card'),
	(9, '2023-02-23 00:00:00', 2001.83, 9539.48, 'Bank Transfer'),
	(9, '2023-03-22 00:00:00', 818.92, 8720.56, 'Check'),
	(10, '2023-01-01 00:00:00', 2203.92, 22796.96, 'Check'),
	(10, '2023-01-27 00:00:00', 1111.66, 21685.30, 'Cash'),
	(10, '2023-02-24 00:00:00', 1549.18, 20136.12, 'Check'),
	(10, '2023-03-24 00:00:00', 881.84, 19254.28, 'Cash'),
	(11, '2023-01-01 00:00:00', 1241.86, 20758.21, 'Bank Transfer'),
	(11, '2023-01-31 00:00:00', 911.65, 19846.56, 'Credit Card'),
	(11, '2023-03-03 00:00:00', 879.98, 18966.58, 'Cash'),
	(12, '2023-01-01 00:00:00', 1607.51, 114962.75, 'Other'),
	(12, '2023-01-31 00:00:00', 2383.85, 112578.90, 'Other'),
	(12, '2023-03-04 00:00:00', 1795.29, 110783.61, 'Bank Transfer'),
	(13, '2023-01-01 00:00:00', 2456.15, 272543.49, 'Bank Transfer'),
	(13, '2023-01-28 00:00:00', 2327.94, 270215.55, 'Cash'),
	(13, '2023-02-26 00:00:00', 2262.57, 267952.98, 'Bank Transfer'),
	(13, '2023-03-27 00:00:00', 1476.45, 266476.53, 'Cash'),
	(14, '2023-01-01 00:00:00', 1634.79, 16365.21, 'Cash'),
	(15, '2023-01-01 00:00:00', 2175.01, 9809.65, 'Credit Card'),
	(15, '2023-01-29 00:00:00', 1542.38, 8267.27, 'Other'),
	(15, '2023-02-26 00:00:00', 1397.32, 6869.95, 'Check');

INSERT INTO Finance.Transactions
	(AccountID, TransactionType, Amount, TransactionDate, TransactionMethod, Description)
VALUES
	(1, 'Deposit', 3299.45, '2023-01-12 00:00:00', 'Wire Transfer', 'Salary Payment'),
	(2, 'Withdrawal', 550.20, '2023-02-10 00:00:00', 'Cash', 'ATM Withdrawal'),
	(3, 'Transfer', 1023.99, '2023-03-05 00:00:00', 'Mobile Payment', 'Utility Bill'),
	(4, 'Deposit', 4420.00, '2023-04-08 00:00:00', 'Online Banking', 'Freelance Payment'),
	(5, 'Withdrawal', 920.10, '2023-05-15 00:00:00', 'Card', 'Grocery Shopping'),
	(6, 'Deposit', 1500.00, '2023-06-20 00:00:00', 'Wire Transfer', 'Salary Payment'),
	(7, 'Transfer', 2100.50, '2023-07-14 00:00:00', 'Cash', 'Online Transfer'),
	(8, 'Deposit', 1850.75, '2023-08-02 00:00:00', 'Card', 'Freelance Payment'),
	(9, 'Withdrawal', 670.25, '2023-09-09 00:00:00', 'Cash', 'Mobile Recharge'),
	(10, 'Transfer', 3600.90, '2023-10-11 00:00:00', 'Wire Transfer', 'Loan Repayment'),
	(11, 'Deposit', 2750.30, '2023-11-05 00:00:00', 'Online Banking', 'Salary Payment'),
	(12, 'Withdrawal', 400.00, '2023-12-15 00:00:00', 'Card', 'Restaurant Bill'),
	(13, 'Deposit', 1980.10, '2023-01-23 00:00:00', 'Wire Transfer', 'Freelance Payment'),
	(14, 'Transfer', 3150.20, '2023-02-28 00:00:00', 'Mobile Payment', 'Utility Bill'),
	(15, 'Deposit', 2200.00, '2023-03-17 00:00:00', 'Cash', 'Salary Payment'),
	(3, 'Withdrawal', 300.00, '2023-04-21 00:00:00', 'Card', 'Grocery Shopping'),
	(4, 'Deposit', 4100.00, '2023-05-13 00:00:00', 'Wire Transfer', 'Freelance Payment'),
	(6, 'Transfer', 1450.60, '2023-06-30 00:00:00', 'Online Banking', 'Online Transfer'),
	(8, 'Deposit', 1650.00, '2023-07-18 00:00:00', 'Card', 'Salary Payment'),
	(9, 'Withdrawal', 770.50, '2023-08-25 00:00:00', 'Cash', 'ATM Withdrawal'),
	(11, 'Deposit', 3200.00, '2023-09-30 00:00:00', 'Wire Transfer', 'Freelance Payment'),
	(13, 'Transfer', 1800.00, '2023-10-22 00:00:00', 'Mobile Payment', 'Utility Bill'),
	(15, 'Deposit', 2000.00, '2023-11-19 00:00:00', 'Online Banking', 'Salary Payment'),
	(1, 'Withdrawal', 250.25, '2023-12-03 00:00:00', 'Card', 'Grocery Shopping'),
	(2, 'Deposit', 3900.40, '2023-01-10 00:00:00', 'Wire Transfer', 'Freelance Payment'),
	(5, 'Transfer', 2150.75, '2023-02-14 00:00:00', 'Mobile Payment', 'Online Transfer'),
	(7, 'Deposit', 1750.00, '2023-03-25 00:00:00', 'Cash', 'Salary Payment'),
	(10, 'Withdrawal', 900.60, '2023-04-30 00:00:00', 'Card', 'ATM Withdrawal'),
	(12, 'Transfer', 2650.40, '2023-05-20 00:00:00', 'Online Banking', 'Loan Repayment'),
	(14, 'Deposit', 3300.00, '2023-06-16 00:00:00', 'Wire Transfer', 'Freelance Payment');

INSERT INTO Finance.TransactionLogs
	(TransactionID, EmployeeID, LogMessage, LogTimestamp)
VALUES
	(1, 2, 'Verified deposit and updated balance.', '2023-01-12 09:34:12'),
	(2, 1, 'Processed ATM withdrawal request.', '2023-02-10 11:20:45'),
	(3, 3, 'Checked transfer routing details.', '2023-03-05 15:50:30'),
	(4, 2, 'Confirmed incoming salary deposit.', '2023-04-08 10:05:22'),
	(5, 1, 'Withdrawal flagged for large amount check.', '2023-05-15 13:14:10'),
	(6, 4, 'Approved scheduled deposit from employer.', '2023-06-20 08:00:00'),
	(7, 5, 'Initiated internal account transfer.', '2023-07-14 17:42:19'),
	(8, 3, 'Verified card payment method details.', '2023-08-02 12:18:44'),
	(9, 4, 'Cleared cash withdrawal at branch.', '2023-09-09 16:22:05'),
	(10, 2, 'Marked loan repayment as completed.', '2023-10-11 09:45:27'),
	(11, 1, 'Checked employer deposit credentials.', '2023-11-05 14:33:55'),
	(12, 3, 'Reviewed transaction history on card.', '2023-12-15 11:11:11'),
	(13, 2, 'Freelance income validated and cleared.', '2023-01-23 15:00:00'),
	(14, 5, 'Confirmed mobile transfer with code.', '2023-02-28 18:09:33'),
	(15, 4, 'Salary deposit posted successfully.', '2023-03-17 07:45:00');

PRINT 'The script was executed successfully without any errors!'

/* You can highlight one of these SELECT-statements to see what's in each table and click "Execute".
SELECT * FROM Users.Customers  
SELECT * FROM Users.Alerts  
SELECT * FROM Bank.Branches  
SELECT * FROM Users.Employees  
SELECT * FROM Bank.InterestRates  
SELECT * FROM Users.Accounts  
SELECT * FROM Bank.Cards  
SELECT * FROM Security.AuditLogs  
SELECT * FROM Users.Dispositions  
SELECT * FROM Bank.Loans  
SELECT * FROM Bank.LoanPayments  
SELECT * FROM Finance.Transactions  
SELECT * FROM Finance.TransactionLogs 
*/