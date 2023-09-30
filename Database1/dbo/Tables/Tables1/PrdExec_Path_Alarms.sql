CREATE TABLE [dbo].[PrdExec_Path_Alarms] (
    [PEPA_Id]                  INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AP_Id]                    INT     CONSTRAINT [PrdExec_Path_Alarms_DF_APId] DEFAULT ((3)) NOT NULL,
    [Path_Id]                  INT     NOT NULL,
    [PEPAT_Id]                 INT     NOT NULL,
    [Threshold_Type_Selection] TINYINT NULL,
    [Threshold_Value]          REAL    NOT NULL,
    CONSTRAINT [PK_PrdExec_Path_Alarms] PRIMARY KEY NONCLUSTERED ([PEPA_Id] ASC),
    CONSTRAINT [PrdExec_Path_Alarms_FK_APId] FOREIGN KEY ([AP_Id]) REFERENCES [dbo].[Alarm_Priorities] ([AP_Id]),
    CONSTRAINT [PrdExec_Path_Alarms_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [PrdExec_Path_Alarms_FK_PEPATId] FOREIGN KEY ([PEPAT_Id]) REFERENCES [dbo].[PrdExec_Path_Alarm_Types] ([PEPAT_Id])
);

