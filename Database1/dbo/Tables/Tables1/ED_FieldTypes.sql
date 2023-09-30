CREATE TABLE [dbo].[ED_FieldTypes] (
    [ED_Field_Type_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Extension]             VARCHAR (10)  NULL,
    [Field_Type_Desc]       VARCHAR (100) NOT NULL,
    [Prefix]                VARCHAR (25)  NULL,
    [SP_Lookup]             TINYINT       CONSTRAINT [ED_FieldTypes_DF_SP_Lookup] DEFAULT ((0)) NOT NULL,
    [Store_Id]              TINYINT       NOT NULL,
    [User_Defined_Property] TINYINT       NULL,
    CONSTRAINT [ED_FieldTypes_PK_FieldTypeId] PRIMARY KEY CLUSTERED ([ED_Field_Type_Id] ASC)
);

