CREATE TABLE [dbo].[Local_PE_Log_Details] (
    [LogDetail_Id] INT            IDENTITY (1, 1) NOT NULL,
    [Log_Id]       INT            NOT NULL,
    [Detail_Key]   NVARCHAR (MAX) NOT NULL,
    [Detail_Value] NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_Local_PE_Log_Details] PRIMARY KEY CLUSTERED ([LogDetail_Id] ASC),
    CONSTRAINT [FK_Local_PE_Log_Details_Local_PE_Logs] FOREIGN KEY ([Log_Id]) REFERENCES [dbo].[Local_PE_Logs] ([Log_Id])
);

