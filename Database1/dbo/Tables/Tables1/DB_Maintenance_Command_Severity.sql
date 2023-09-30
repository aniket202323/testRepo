CREATE TABLE [dbo].[DB_Maintenance_Command_Severity] (
    [DBMC_Severity_Desc] VARCHAR (50) NOT NULL,
    [DBMC_Severity_Id]   TINYINT      NOT NULL,
    CONSTRAINT [PK_DB_Maintenance_Command_Severity_Id] PRIMARY KEY CLUSTERED ([DBMC_Severity_Id] ASC),
    CONSTRAINT [IX_DB_Maintenance_Command_Severity_Desc] UNIQUE NONCLUSTERED ([DBMC_Severity_Desc] ASC)
);

