CREATE TABLE [dbo].[Production_Plan_Alarms] (
    [PPA_Id]                   INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AP_Id]                    INT     CONSTRAINT [Production_Plan_Alarms_DF_APId] DEFAULT ((3)) NOT NULL,
    [PEPAT_Id]                 INT     NOT NULL,
    [PP_Id]                    INT     NOT NULL,
    [Threshold_Type_Selection] TINYINT NULL,
    [Threshold_Value]          REAL    NOT NULL,
    CONSTRAINT [PK_Production_Plan_Alarms] PRIMARY KEY NONCLUSTERED ([PPA_Id] ASC),
    CONSTRAINT [Production_Plan_Alarms_FK_APId] FOREIGN KEY ([AP_Id]) REFERENCES [dbo].[Alarm_Priorities] ([AP_Id]),
    CONSTRAINT [Production_Plan_Alarms_FK_PEPATId] FOREIGN KEY ([PEPAT_Id]) REFERENCES [dbo].[PrdExec_Path_Alarm_Types] ([PEPAT_Id]),
    CONSTRAINT [Production_Plan_Alarms_FK_PPId] FOREIGN KEY ([PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id])
);

