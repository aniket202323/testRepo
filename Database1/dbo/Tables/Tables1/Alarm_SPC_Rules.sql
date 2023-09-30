CREATE TABLE [dbo].[Alarm_SPC_Rules] (
    [Alarm_SPC_Rule_Desc] VARCHAR (100) NOT NULL,
    [Alarm_SPC_Rule_Id]   INT           NOT NULL,
    CONSTRAINT [PK_Alarm_SPC_Rules] PRIMARY KEY NONCLUSTERED ([Alarm_SPC_Rule_Id] ASC)
);

