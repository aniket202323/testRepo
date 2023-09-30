CREATE TABLE [dbo].[OPC_Property] (
    [HDA_Prop_Id]      [dbo].[Varchar_Value] NOT NULL,
    [Prop_Data_Type]   INT                   NOT NULL,
    [Prop_Description] VARCHAR (50)          NOT NULL,
    [Prop_Id]          INT                   NOT NULL,
    [Prop_Name]        VARCHAR (50)          NOT NULL,
    [Writeable]        INT                   CONSTRAINT [DF_OPC_Property_Writeable] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_OPC_Property] PRIMARY KEY CLUSTERED ([Prop_Id] ASC)
);

