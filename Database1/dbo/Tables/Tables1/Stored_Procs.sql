CREATE TABLE [dbo].[Stored_Procs] (
    [SP_Id]            INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Avg_Exec_Time]    INT                       NULL,
    [Comment_Id]       INT                       NULL,
    [Error_Count]      INT                       NULL,
    [Last_Change_Date] DATETIME                  NULL,
    [Max_Exec_Time]    INT                       NULL,
    [Min_Exec_Time]    INT                       NULL,
    [ResultSet]        BIT                       CONSTRAINT [StoredProcs_DF_ResultSet] DEFAULT ((0)) NOT NULL,
    [SP_Desc]          [dbo].[Varchar_Desc]      NOT NULL,
    [SP_Long_Desc]     [dbo].[Varchar_Long_Desc] NULL,
    [SP_Name]          VARCHAR (30)              NOT NULL,
    [Times_Run]        INT                       NULL,
    [Version]          DECIMAL (3)               NOT NULL,
    CONSTRAINT [SPs_PK_SPId] PRIMARY KEY NONCLUSTERED ([SP_Id] ASC)
);

