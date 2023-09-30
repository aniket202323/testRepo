CREATE TABLE [dbo].[BinaryItem] (
    [ItemId]  UNIQUEIDENTIFIER NOT NULL,
    [Name]    NVARCHAR (1000)  NULL,
    [Data]    IMAGE            NULL,
    [Version] BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([ItemId] ASC)
);

