CREATE TABLE [dbo].[ObjectAddress] (
    [Id]              UNIQUEIDENTIFIER NOT NULL,
    [Address]         NVARCHAR (255)   NULL,
    [ExtendedAddress] NVARCHAR (769)   NULL,
    [KeyString]       NVARCHAR (255)   NULL,
    [Pinned]          BIT              NULL,
    [Version]         BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
ALTER TABLE [dbo].[ObjectAddress] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_ObjectAddress_Address]
    ON [dbo].[ObjectAddress]([Address] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ObjectAddress_KeyString]
    ON [dbo].[ObjectAddress]([KeyString] ASC);

