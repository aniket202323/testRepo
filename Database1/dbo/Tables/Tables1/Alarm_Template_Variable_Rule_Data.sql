CREATE TABLE [dbo].[Alarm_Template_Variable_Rule_Data] (
    [ATVRD_Id]               INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alarm_Variable_Rule_Id] INT NOT NULL,
    [AP_Id]                  INT NULL,
    [AT_Id]                  INT NOT NULL,
    CONSTRAINT [PK_Alarm_Template_Variable_Rule_Data] PRIMARY KEY NONCLUSTERED ([ATVRD_Id] ASC),
    CONSTRAINT [Alarm_Template_Variable_Rule_Data_FK_Alarm_Templates] FOREIGN KEY ([AT_Id]) REFERENCES [dbo].[Alarm_Templates] ([AT_Id]),
    CONSTRAINT [Alarm_Template_Variable_Rule_Data_FK_Alarm_Variable_Rules] FOREIGN KEY ([Alarm_Variable_Rule_Id]) REFERENCES [dbo].[Alarm_Variable_Rules] ([Alarm_Variable_Rule_Id]),
    CONSTRAINT [Alarm_Template_Variable_Rule_Data_FK_APId] FOREIGN KEY ([AP_Id]) REFERENCES [dbo].[Alarm_Priorities] ([AP_Id])
);

