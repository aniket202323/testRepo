CREATE TABLE [erp].[MappingSpecification] (
    [Id]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [Specification] NVARCHAR (MAX) NOT NULL,
    [Resource_Type] VARCHAR (255)  NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

