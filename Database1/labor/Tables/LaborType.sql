CREATE TABLE [labor].[LaborType] (
    [Id]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [Name]      NVARCHAR (100)     NOT NULL,
    [CreatedOn] DATETIMEOFFSET (7) NOT NULL,
    [CreatedBy] NVARCHAR (100)     NOT NULL,
    CONSTRAINT [LaborType_pk] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [LaborType_uk_name] UNIQUE NONCLUSTERED ([Name] ASC)
);

