CREATE TABLE [dbo].[ProductOptionContent] (
    [ContentVersion]            NVARCHAR (255)   NOT NULL,
    [PackageCode]               UNIQUEIDENTIFIER NULL,
    [Name]                      NVARCHAR (255)   NULL,
    [DefinesServiceData]        BIT              NULL,
    [DefinesDeploymentTemplate] BIT              NULL,
    [IsPartialContent]          BIT              NULL,
    [Version]                   BIGINT           NULL,
    [ProductOptionId]           UNIQUEIDENTIFIER NOT NULL,
    [ContentFileId]             UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProductOptionId] ASC, [ContentVersion] ASC),
    CONSTRAINT [ProductOptionContent_ProductOption_Relation1] FOREIGN KEY ([ProductOptionId]) REFERENCES [dbo].[ProductOption] ([Id]),
    CONSTRAINT [ProductOptionContent_ProductOptionContentFile_Relation1] FOREIGN KEY ([ContentFileId]) REFERENCES [dbo].[ProductOptionContentFile] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_ProductOptionContent_ContentFileId]
    ON [dbo].[ProductOptionContent]([ContentFileId] ASC);

