CREATE TABLE [dbo].[SpecMaterial_MaterialSpec_SegReq] (
    [SpecMaterial_MaterialSpec_SegReqId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                  NVARCHAR (255)   NULL,
    [Version]                            BIGINT           NULL,
    [MaterialDefinitionId]               UNIQUEIDENTIFIER NULL,
    [MaterialClassName]                  NVARCHAR (200)   NULL,
    [MaterialLotId]                      UNIQUEIDENTIFIER NULL,
    [MaterialSublotId]                   UNIQUEIDENTIFIER NULL,
    [MaterialSpec_SegReqId]              UNIQUEIDENTIFIER NULL,
    [SegReqId]                           UNIQUEIDENTIFIER NULL,
    [WorkRequestId]                      UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecMaterial_MaterialSpec_SegReqId] ASC),
    CONSTRAINT [SpecMaterial_MaterialSpec_SegReq_MaterialClass_Relation1] FOREIGN KEY ([MaterialClassName]) REFERENCES [dbo].[MaterialClass] ([MaterialClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecMaterial_MaterialSpec_SegReq_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_SegReq_MaterialLot_Relation1] FOREIGN KEY ([MaterialLotId]) REFERENCES [dbo].[MaterialLot] ([MaterialLotId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_SegReq_MaterialSpec_SegReq_Relation1] FOREIGN KEY ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[MaterialSpec_SegReq] ([MaterialSpec_SegReqId], [SegReqId], [WorkRequestId]),
    CONSTRAINT [SpecMaterial_MaterialSpec_SegReq_MaterialSublot_Relation1] FOREIGN KEY ([MaterialSublotId]) REFERENCES [dbo].[MaterialSublot] ([MaterialSublotId])
);


GO
ALTER TABLE [dbo].[SpecMaterial_MaterialSpec_SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_SegReq_MaterialDefinitionId]
    ON [dbo].[SpecMaterial_MaterialSpec_SegReq]([MaterialDefinitionId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_SegReq_MaterialClassName]
    ON [dbo].[SpecMaterial_MaterialSpec_SegReq]([MaterialClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_SegReq_MaterialLotId]
    ON [dbo].[SpecMaterial_MaterialSpec_SegReq]([MaterialLotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_SegReq_MaterialSublotId]
    ON [dbo].[SpecMaterial_MaterialSpec_SegReq]([MaterialSublotId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecMaterial_MaterialSpec_SegReq_MaterialSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[SpecMaterial_MaterialSpec_SegReq]([MaterialSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);

