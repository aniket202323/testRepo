CREATE TABLE [dbo].[DB_Maintenance_Command_Types] (
    [DBMC_Type_Desc] VARCHAR (50) NOT NULL,
    [DBMC_Type_Id]   TINYINT      NOT NULL,
    CONSTRAINT [PK_DB_Maintenance_Command_Types_Id] PRIMARY KEY CLUSTERED ([DBMC_Type_Id] ASC),
    CONSTRAINT [IX_DB_Maintenance_Command_Types_Desc] UNIQUE NONCLUSTERED ([DBMC_Type_Desc] ASC)
);

