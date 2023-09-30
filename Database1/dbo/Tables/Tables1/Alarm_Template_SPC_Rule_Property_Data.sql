CREATE TABLE [dbo].[Alarm_Template_SPC_Rule_Property_Data] (
    [Alarm_SPC_Rule_Property_Id] INT          NOT NULL,
    [ATSRD_Id]                   INT          NOT NULL,
    [mValue]                     INT          NULL,
    [Value]                      VARCHAR (25) NOT NULL,
    CONSTRAINT [PK_Alarm_Template_SPC_Rule_Property_Data] PRIMARY KEY NONCLUSTERED ([ATSRD_Id] ASC),
    CONSTRAINT [Alarm_Template_SPC_Rule_Data_FK_Alarm_SPC_Rule_Properties] FOREIGN KEY ([Alarm_SPC_Rule_Property_Id]) REFERENCES [dbo].[Alarm_SPC_Rule_Properties] ([Alarm_SPC_Rule_Property_Id]),
    CONSTRAINT [Alarm_Template_SPC_Rule_Property_Data_FK_Rule_Data] FOREIGN KEY ([ATSRD_Id]) REFERENCES [dbo].[Alarm_Template_SPC_Rule_Data] ([ATSRD_Id])
);

