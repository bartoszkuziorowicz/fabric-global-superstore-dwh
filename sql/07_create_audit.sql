CREATE TABLE audit.LoadAudit
(
    LoadID BIGINT IDENTITY NOT NULL,
    StartTime DATETIME2(0) NOT NULL,
    EndTime DATETIME2(0),
    Status VARCHAR(20)
);
