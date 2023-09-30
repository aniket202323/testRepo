CREATE TABLE [dbo].[Local_DDSWorkProcesses] (
    [DDSWorkProcessID] INT           IDENTITY (1, 1) NOT NULL,
    [WorkProcess]      NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Local_DDSWorkProcesses] PRIMARY KEY CLUSTERED ([DDSWorkProcessID] ASC)
);

