CREATE TABLE [dbo].[OPC_ResultSet_Map] (
    [OPC_ResultSet_Map_Id] INT NOT NULL,
    [OPC_Type_Id]          INT NOT NULL,
    [Prop_Id]              INT NOT NULL,
    [Time_Col]             INT NULL,
    [Time_Row]             INT NULL,
    [Value_Col]            INT NOT NULL,
    [Value_Row]            INT NOT NULL,
    CONSTRAINT [PK_OPC_ResultSet_Map] PRIMARY KEY CLUSTERED ([OPC_Type_Id] ASC, [Prop_Id] ASC)
);

