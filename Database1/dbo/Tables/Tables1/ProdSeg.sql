CREATE TABLE [dbo].[ProdSeg] (
    [IsMaster]         BIT              NULL,
    [IsReusable]       BIT              DEFAULT ((1)) NULL,
    [Duration]         FLOAT (53)       NULL,
    [WorkType]         NVARCHAR (25)    NULL,
    [ProdSegId]        UNIQUEIDENTIFIER NOT NULL,
    [S95Id]            NVARCHAR (50)    NULL,
    [Description]      NVARCHAR (255)   NULL,
    [S95Type]          NVARCHAR (50)    NULL,
    [LastModifiedTime] DATETIME         NULL,
    [LastModifiedBy]   NVARCHAR (255)   NULL,
    [Version]          BIGINT           NULL,
    [IsVisible]        BIT              DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([ProdSegId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ProdSeg_LastModifiedTime]
    ON [dbo].[ProdSeg]([LastModifiedTime] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProdSeg_S95Id]
    ON [dbo].[ProdSeg]([S95Id] ASC);

