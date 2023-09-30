CREATE TABLE [dbo].[Alarm_Variable_Rules] (
    [Alarm_Variable_Rule_Desc] VARCHAR (100) NOT NULL,
    [Alarm_Variable_Rule_Id]   INT           NOT NULL,
    CONSTRAINT [PK_Alarm_Variable_Rules] PRIMARY KEY NONCLUSTERED ([Alarm_Variable_Rule_Id] ASC)
);

