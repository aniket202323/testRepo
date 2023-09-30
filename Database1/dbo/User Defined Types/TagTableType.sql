CREATE TYPE [dbo].[TagTableType] AS TABLE (
    [Name]        NVARCHAR (400) NOT NULL,
    [Description] NVARCHAR (255) NULL,
    [DataType]    INT            NULL,
    PRIMARY KEY CLUSTERED ([Name] ASC));

