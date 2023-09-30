CREATE TABLE [dbo].[Alarm_SPC_Rule_Properties] (
    [Alarm_SPC_Rule_Property_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alarm_SPC_Rule_Id]            INT          NOT NULL,
    [Alarm_SPC_Rule_Property_Desc] CHAR (100)   NOT NULL,
    [Default_mValue]               VARCHAR (25) NULL,
    [Default_Value]                VARCHAR (25) NULL,
    [ED_Field_Type_Id]             INT          NOT NULL,
    [Field_Order]                  CHAR (10)    NOT NULL,
    CONSTRAINT [PK_Alarm_SPC_Rule_Properties] PRIMARY KEY NONCLUSTERED ([Alarm_SPC_Rule_Property_Id] ASC),
    CONSTRAINT [Alarm_SPC_Rule_Properties_FK_Alarm_SPC_Rules] FOREIGN KEY ([Alarm_SPC_Rule_Id]) REFERENCES [dbo].[Alarm_SPC_Rules] ([Alarm_SPC_Rule_Id]),
    CONSTRAINT [Alarm_SPC_Rule_Properties_FK_ED_FieldTypes] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id])
);

