CREATE TABLE [dbo].[DB_Maintenance_Commands] (
    [Actual_Duration]    INT            NULL,
    [Command]            VARCHAR (2000) NULL,
    [Command_Override]   VARCHAR (2000) NULL,
    [DBMC_Desc]          VARCHAR (100)  NOT NULL,
    [DBMC_Group]         INT            NULL,
    [DBMC_Group_Order]   INT            NULL,
    [DBMC_Id]            INT            NOT NULL,
    [DBMC_Severity_Id]   TINYINT        NOT NULL,
    [DBMC_Type_Id]       TINYINT        NOT NULL,
    [Entry_On]           DATETIME       NOT NULL,
    [Estimated_Duration] INT            NULL,
    [Executed_On]        DATETIME       NULL,
    [Object_Name]        VARCHAR (100)  NULL,
    [Pending_Check]      TINYINT        CONSTRAINT [DF__DB_Mainte__Pendi__1FEE83D3] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_DB_Maintenance_Commands] PRIMARY KEY NONCLUSTERED ([DBMC_Id] ASC),
    CONSTRAINT [FK_DB_Maintenance_Commands_DB_Maintenance_Command_Severity] FOREIGN KEY ([DBMC_Severity_Id]) REFERENCES [dbo].[DB_Maintenance_Command_Severity] ([DBMC_Severity_Id]),
    CONSTRAINT [FK_DB_Maintenance_Commands_DB_Maintenance_Command_Types] FOREIGN KEY ([DBMC_Type_Id]) REFERENCES [dbo].[DB_Maintenance_Command_Types] ([DBMC_Type_Id]),
    CONSTRAINT [IX_DB_Maintenance_Commands_Desc] UNIQUE NONCLUSTERED ([DBMC_Desc] ASC)
);


GO
CREATE CLUSTERED INDEX [IX_DB_Maintenance_Commands_Group_Order]
    ON [dbo].[DB_Maintenance_Commands]([DBMC_Group] ASC, [DBMC_Group_Order] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DB_Maintenance_Commands_ExecOnTypeNamePending]
    ON [dbo].[DB_Maintenance_Commands]([Executed_On] ASC, [DBMC_Type_Id] ASC, [Object_Name] ASC, [Pending_Check] ASC);

