CREATE TABLE [dbo].[ED_Field_Properties] (
    [ED_Field_Prop_Id] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Default_Value]    VARCHAR (1000) NULL,
    [ED_Field_Type_Id] INT            NOT NULL,
    [ED_Model_Id]      INT            NOT NULL,
    [Field_Desc]       VARCHAR (255)  NOT NULL,
    [Locked]           BIT            NOT NULL,
    [Optional]         BIT            NOT NULL,
    CONSTRAINT [EDFieldProp_PK_FieldPropId] PRIMARY KEY CLUSTERED ([ED_Field_Prop_Id] ASC),
    CONSTRAINT [EDFieldProp_FK_EDFieldTypeId] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [EDFieldProp_FK_EDModelId] FOREIGN KEY ([ED_Model_Id]) REFERENCES [dbo].[ED_Models] ([ED_Model_Id]),
    CONSTRAINT [EDFieldProp_UC_ModelFieldDesc] UNIQUE NONCLUSTERED ([ED_Model_Id] ASC, [Field_Desc] ASC)
);

