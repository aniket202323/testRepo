CREATE TABLE [dbo].[Products_Aspect_MaterialDefinition] (
    [Products_Aspect_MaterialDefinitionPkId] UNIQUEIDENTIFIER NOT NULL,
    [Version]                                BIGINT           NULL,
    [Prod_Id]                                INT              NULL,
    [Origin2MaterialClassName]               NVARCHAR (200)   NULL,
    [Origin1MaterialDefinitionId]            UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Products_Aspect_MaterialDefinitionPkId] ASC),
    CONSTRAINT [Products_Aspect_MaterialDefinition_MaterialClass_Relation1] FOREIGN KEY ([Origin2MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE,
    CONSTRAINT [Products_Aspect_MaterialDefinition_MaterialDefinition_Relation1] FOREIGN KEY ([Origin1MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId]) ON UPDATE CASCADE,
    CONSTRAINT [Products_Aspect_MaterialDefinition_Products_Base_Relation1] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE SET NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_Aspect_MaterialDefinition_Prod_Id]
    ON [dbo].[Products_Aspect_MaterialDefinition]([Prod_Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Products_Aspect_MaterialDefinition_Origin2MaterialClassName_Origin1MaterialDefinitionId]
    ON [dbo].[Products_Aspect_MaterialDefinition]([Origin2MaterialClassName] ASC, [Origin1MaterialDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Products_Aspect_MaterialDefinition_Prod_Id]
    ON [dbo].[Products_Aspect_MaterialDefinition]([Prod_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Products_Aspect_MaterialDefinition_Origin2MaterialClassName]
    ON [dbo].[Products_Aspect_MaterialDefinition]([Origin2MaterialClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Products_Aspect_MaterialDefinition_Origin1MaterialDefinitionId]
    ON [dbo].[Products_Aspect_MaterialDefinition]([Origin1MaterialDefinitionId] ASC);

