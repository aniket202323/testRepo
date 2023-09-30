CREATE TABLE [dbo].[Event_Configuration_Properties] (
    [EC_Id]            INT            NOT NULL,
    [ED_Field_Prop_Id] INT            NOT NULL,
    [Value]            VARCHAR (1000) NULL,
    CONSTRAINT [EventConfProp_FK_FieldPropId] FOREIGN KEY ([ED_Field_Prop_Id]) REFERENCES [dbo].[ED_Field_Properties] ([ED_Field_Prop_Id]),
    CONSTRAINT [EventConfProp_UC_ECIdFieldPropId] UNIQUE NONCLUSTERED ([EC_Id] ASC, [ED_Field_Prop_Id] ASC)
);

