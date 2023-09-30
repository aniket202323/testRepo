CREATE TABLE [dbo].[ProductOptionContentFile] (
    [Id]      UNIQUEIDENTIFIER NOT NULL,
    [ZipFile] IMAGE            NULL,
    [Version] BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

