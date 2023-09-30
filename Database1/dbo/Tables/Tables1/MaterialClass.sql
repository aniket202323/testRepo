CREATE TABLE [dbo].[MaterialClass] (
    [MaterialClassName] NVARCHAR (200)   NOT NULL,
    [Id]                UNIQUEIDENTIFIER NULL,
    [Description]       NVARCHAR (255)   NULL,
    [Private]           BIT              NULL,
    [Version]           BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([MaterialClassName] ASC)
);


GO
ALTER TABLE [dbo].[MaterialClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialClass_Id]
    ON [dbo].[MaterialClass]([Id] ASC);

