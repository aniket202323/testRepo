CREATE TABLE [dbo].[ED_Fields] (
    [ED_Field_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]       INT           NULL,
    [Default_Value]    TEXT          NULL,
    [Derived_From]     INT           NULL,
    [ED_Field_Type_Id] INT           NOT NULL,
    [ED_Model_Id]      INT           NOT NULL,
    [Field_Desc]       VARCHAR (100) NOT NULL,
    [Field_Order]      INT           NOT NULL,
    [Locked]           TINYINT       CONSTRAINT [DF_ED_Fields_Locked_0] DEFAULT ((0)) NOT NULL,
    [Max_Instances]    INT           CONSTRAINT [ED_Fields_DF_MaxInstances] DEFAULT ((1)) NOT NULL,
    [Optional]         TINYINT       CONSTRAINT [ED_Fields_DF_Optional] DEFAULT ((0)) NOT NULL,
    [Percision]        INT           NULL,
    [Use_Percision]    TINYINT       NULL,
    CONSTRAINT [ED_Fields_PK_FieldId] PRIMARY KEY CLUSTERED ([ED_Field_Id] ASC),
    CONSTRAINT [ED_Fields_FK_FieldTypeId] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [ED_Fields_FK_ModelId] FOREIGN KEY ([ED_Model_Id]) REFERENCES [dbo].[ED_Models] ([ED_Model_Id]),
    CONSTRAINT [ED_Fields_UC_Model_FldOrder] UNIQUE NONCLUSTERED ([ED_Model_Id] ASC, [Field_Order] ASC)
);

