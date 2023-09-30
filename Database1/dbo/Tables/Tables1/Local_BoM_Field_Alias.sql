CREATE TABLE [dbo].[Local_BoM_Field_Alias] (
    [AliasId]   INT           IDENTITY (1, 1) NOT NULL,
    [TableName] VARCHAR (255) NOT NULL,
    [FieldName] VARCHAR (50)  NOT NULL,
    [InputName] VARCHAR (255) NOT NULL,
    [Alias]     VARCHAR (255) NOT NULL,
    CONSTRAINT [LocalBoMFieldAlias_PK_AliasId] PRIMARY KEY CLUSTERED ([AliasId] ASC),
    CONSTRAINT [UQ_Local_BoM_FieldAlias] UNIQUE NONCLUSTERED ([TableName] ASC, [FieldName] ASC, [InputName] ASC)
);

