CREATE TABLE [dbo].[UrlRedirection] (
    [Id]                UNIQUEIDENTIFIER NOT NULL,
    [SourceUrl]         NVARCHAR (255)   NULL,
    [ExtendedSourceUrl] NVARCHAR (769)   NULL,
    [ForwardToUrl]      NVARCHAR (1024)  NULL,
    [OwnerHint]         NVARCHAR (1024)  NULL,
    [Version]           BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_UrlRedirection_SourceUrl]
    ON [dbo].[UrlRedirection]([SourceUrl] ASC);

