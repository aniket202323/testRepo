CREATE TABLE [dbo].[Mapping_Types] (
    [MappingTypeId]       BIGINT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DataSourceTableName] NVARCHAR (50) NOT NULL,
    [Mapping_Desc]        NVARCHAR (50) NOT NULL,
    CONSTRAINT [MappingTypes_PK_MappingTypeId] PRIMARY KEY CLUSTERED ([MappingTypeId] ASC),
    CONSTRAINT [MappingTypes_UC_MappingDesc] UNIQUE NONCLUSTERED ([Mapping_Desc] ASC)
);

