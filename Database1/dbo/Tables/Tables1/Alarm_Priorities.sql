CREATE TABLE [dbo].[Alarm_Priorities] (
    [AP_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AP_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [AlarmPriorities_PK_APId] PRIMARY KEY NONCLUSTERED ([AP_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [AlarmPriorities_IDX_APDesc]
    ON [dbo].[Alarm_Priorities]([AP_Desc] ASC);

