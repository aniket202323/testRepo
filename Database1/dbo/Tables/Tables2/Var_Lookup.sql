CREATE TABLE [dbo].[Var_Lookup] (
    [VL_Id]         INT           IDENTITY (1, 1) NOT NULL,
    [Ext_Int_Key_1] INT           NULL,
    [Ext_Int_Key_2] INT           NULL,
    [Ext_Int_Key_3] INT           NULL,
    [Ext_Str_Key_1] VARCHAR (255) NULL,
    [Ext_Str_Key_2] VARCHAR (255) NULL,
    [Ext_Str_Key_3] VARCHAR (255) NULL,
    [Var_Id]        INT           NULL
);

