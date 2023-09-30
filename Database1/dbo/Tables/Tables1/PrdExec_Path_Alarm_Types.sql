CREATE TABLE [dbo].[PrdExec_Path_Alarm_Types] (
    [PEPAT_Id]            INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alarm_Type]          TINYINT                   NOT NULL,
    [PEPAT_Desc]          [dbo].[Varchar_Desc]      NOT NULL,
    [Threshold_Eng_Units] [dbo].[Varchar_Eng_Units] NULL,
    [Threshold_Type]      TINYINT                   NOT NULL,
    CONSTRAINT [PK_PrdExec_Path_Alarm_Types] PRIMARY KEY NONCLUSTERED ([PEPAT_Id] ASC)
);

