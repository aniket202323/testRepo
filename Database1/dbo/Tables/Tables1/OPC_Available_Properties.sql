CREATE TABLE [dbo].[OPC_Available_Properties] (
    [OPC_Available_Properties_Id] INT NOT NULL,
    [OPC_Type_Id]                 INT NOT NULL,
    [Prop_Class_Id]               INT NOT NULL,
    [Prop_Id]                     INT NOT NULL,
    CONSTRAINT [PK_OPC_Available_Properties] PRIMARY KEY CLUSTERED ([OPC_Type_Id] ASC, [Prop_Id] ASC)
);

