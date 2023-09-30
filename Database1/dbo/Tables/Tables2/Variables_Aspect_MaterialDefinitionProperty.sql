CREATE TABLE [dbo].[Variables_Aspect_MaterialDefinitionProperty] (
    [Variables_Aspect_MaterialDefinitionPropertyPkId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                                         BIGINT           NULL,
    [Var_Id]                                          INT              NULL,
    [Origin2MaterialClassName]                        NVARCHAR (200)   NULL,
    [Origin2PropertyName]                             NVARCHAR (200)   NULL,
    [Origin1MaterialDefinitionId]                     UNIQUEIDENTIFIER NULL,
    [Origin1Name]                                     NVARCHAR (255)   NULL,
    PRIMARY KEY CLUSTERED ([Variables_Aspect_MaterialDefinitionPropertyPkId] ASC),
    CONSTRAINT [Variables_Aspect_MaterialDefinitionProperty_Property_MaterialClass_Relation1] FOREIGN KEY ([Origin2MaterialClassName], [Origin2PropertyName]) REFERENCES [dbo].[Property_MaterialClass] ([MaterialClassName], [PropertyName]) ON UPDATE CASCADE,
    CONSTRAINT [Variables_Aspect_MaterialDefinitionProperty_Property_MaterialDefinition_MaterialClass_Relation1] FOREIGN KEY ([Origin1MaterialDefinitionId], [Origin1Name]) REFERENCES [dbo].[Property_MaterialDefinition_MaterialClass] ([MaterialDefinitionId], [Name]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_1512439522]
    ON [dbo].[Variables_Aspect_MaterialDefinitionProperty]([Origin2MaterialClassName] ASC, [Origin2PropertyName] ASC, [Origin1MaterialDefinitionId] ASC, [Origin1Name] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Variables_Aspect_MaterialDefinitionProperty_Var_Id]
    ON [dbo].[Variables_Aspect_MaterialDefinitionProperty]([Var_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Variables_Aspect_MaterialDefinitionProperty_Origin2MaterialClassName_Origin2PropertyName]
    ON [dbo].[Variables_Aspect_MaterialDefinitionProperty]([Origin2MaterialClassName] ASC, [Origin2PropertyName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Variables_Aspect_MaterialDefinitionProperty_Origin1MaterialDefinitionId_Origin1Name]
    ON [dbo].[Variables_Aspect_MaterialDefinitionProperty]([Origin1MaterialDefinitionId] ASC, [Origin1Name] ASC);

