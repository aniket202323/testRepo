CREATE TABLE [dbo].[GlobalVariable] (
    [Name]    NVARCHAR (255) NOT NULL,
    [Value]   SQL_VARIANT    NULL,
    [Version] BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Name] ASC)
);

