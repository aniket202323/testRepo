CREATE TABLE [dbo].[Client_Connection_Module_Data] (
    [Client_Connection_Id] INT     NOT NULL,
    [Counter]              INT     CONSTRAINT [Client_Connection_Module_Data_DF_Counter] DEFAULT ((1)) NOT NULL,
    [Module_Id]            TINYINT NOT NULL,
    CONSTRAINT [Client_Connection_Module_Data_PK] PRIMARY KEY CLUSTERED ([Client_Connection_Id] ASC, [Module_Id] ASC),
    CONSTRAINT [Client_Connection_Module_Data_FK_Modules] FOREIGN KEY ([Module_Id]) REFERENCES [dbo].[Modules] ([Module_Id])
);

