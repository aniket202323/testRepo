CREATE TABLE [dbo].[SpecEquipment_EquipmentSpec_SegReq] (
    [SpecEquipment_EquipmentSpec_SegReqId] UNIQUEIDENTIFIER NOT NULL,
    [SpecificationType]                    NVARCHAR (255)   NULL,
    [Version]                              BIGINT           NULL,
    [EquipmentClassName]                   NVARCHAR (200)   NULL,
    [EquipmentId]                          UNIQUEIDENTIFIER NULL,
    [EquipmentSpec_SegReqId]               UNIQUEIDENTIFIER NULL,
    [SegReqId]                             UNIQUEIDENTIFIER NULL,
    [WorkRequestId]                        UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([SpecEquipment_EquipmentSpec_SegReqId] ASC),
    CONSTRAINT [SpecEquipment_EquipmentSpec_SegReq_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId]),
    CONSTRAINT [SpecEquipment_EquipmentSpec_SegReq_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE,
    CONSTRAINT [SpecEquipment_EquipmentSpec_SegReq_EquipmentSpec_SegReq_Relation1] FOREIGN KEY ([EquipmentSpec_SegReqId], [SegReqId], [WorkRequestId]) REFERENCES [dbo].[EquipmentSpec_SegReq] ([EquipmentSpec_SegReqId], [SegReqId], [WorkRequestId])
);


GO
ALTER TABLE [dbo].[SpecEquipment_EquipmentSpec_SegReq] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_SegReq_EquipmentClassName]
    ON [dbo].[SpecEquipment_EquipmentSpec_SegReq]([EquipmentClassName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_SegReq_EquipmentId]
    ON [dbo].[SpecEquipment_EquipmentSpec_SegReq]([EquipmentId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_SpecEquipment_EquipmentSpec_SegReq_EquipmentSpec_SegReqId_SegReqId_WorkRequestId]
    ON [dbo].[SpecEquipment_EquipmentSpec_SegReq]([EquipmentSpec_SegReqId] ASC, [SegReqId] ASC, [WorkRequestId] ASC);

