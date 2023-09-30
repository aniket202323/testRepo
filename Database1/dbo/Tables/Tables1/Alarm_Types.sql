CREATE TABLE [dbo].[Alarm_Types] (
    [Alarm_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alarm_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Alarm_Types_PK_AlarmTypeId] PRIMARY KEY NONCLUSTERED ([Alarm_Type_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [AlarmTypes_IDX_Desc]
    ON [dbo].[Alarm_Types]([Alarm_Type_Desc] ASC);

