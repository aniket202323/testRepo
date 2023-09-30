CREATE TABLE [dbo].[ExtensionData] (
    [r_Key]   NVARCHAR (255) NOT NULL,
    [Data]    IMAGE          NULL,
    [Version] BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([r_Key] ASC)
);

