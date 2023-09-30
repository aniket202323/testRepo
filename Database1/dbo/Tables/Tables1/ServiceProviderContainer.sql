CREATE TABLE [dbo].[ServiceProviderContainer] (
    [r_Order]           INT              NULL,
    [Version]           BIGINT           NULL,
    [ContainerId]       INT              NOT NULL,
    [ServiceProviderId] UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ContainerId] ASC, [ServiceProviderId] ASC),
    CONSTRAINT [ServiceProviderContainer_ServiceContainer_Relation1] FOREIGN KEY ([ContainerId]) REFERENCES [dbo].[ServiceContainer] ([Id]),
    CONSTRAINT [ServiceProviderContainer_ServiceProvider_Relation1] FOREIGN KEY ([ServiceProviderId]) REFERENCES [dbo].[ServiceProvider] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_ServiceProviderContainer_ServiceProviderId]
    ON [dbo].[ServiceProviderContainer]([ServiceProviderId] ASC);

