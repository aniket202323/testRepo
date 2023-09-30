CREATE TABLE [PR_EquipmentProvisioning].[EquipmentProvisioning] (
    [CommandId]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [Command]               TINYINT        NOT NULL,
    [EquipmentName]         NVARCHAR (50)  NOT NULL,
    [EquipmentClassName]    NVARCHAR (200) NULL,
    [EquipmentType]         NVARCHAR (50)  NULL,
    [EquipmentDescription]  NVARCHAR (255) NULL,
    [PropertyName]          NVARCHAR (255) NULL,
    [PropertyDataType]      INT            NULL,
    [PropertyValue]         NVARCHAR (255) NULL,
    [PropertyUnitOfMeasure] NVARCHAR (50)  NULL,
    [PropertyDescription]   NVARCHAR (255) NULL,
    [HistorianServerName]   NVARCHAR (255) NULL,
    [Parent1]               NVARCHAR (50)  NULL,
    [Parent2]               NVARCHAR (50)  NULL,
    [Parent3]               NVARCHAR (50)  NULL,
    [Parent4]               NVARCHAR (50)  NULL,
    [Parent5]               NVARCHAR (50)  NULL,
    [Parent6]               NVARCHAR (50)  NULL,
    [Parent7]               NVARCHAR (50)  NULL,
    [Parent8]               NVARCHAR (50)  NULL,
    [Parent9]               NVARCHAR (50)  NULL,
    CONSTRAINT [PK_EquipmentProvisioning] PRIMARY KEY CLUSTERED ([CommandId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EquipmentProvisioning_Command]
    ON [PR_EquipmentProvisioning].[EquipmentProvisioning]([Command] ASC);

