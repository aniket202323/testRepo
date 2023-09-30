CREATE TABLE [dbo].[Local_eDH_FuncLocation] (
    [EquipmentDesc]     NVARCHAR (255) NULL,
    [FLCode]            NCHAR (100)    NULL,
    [ParentFLId]        INT            NULL,
    [FLId]              INT            IDENTITY (1, 1) NOT NULL,
    [Enable]            BIT            CONSTRAINT [enableDef] DEFAULT ((1)) NULL,
    [Level]             INT            NULL,
    [MasterUnitId]      INT            NULL,
    [EquipmentId]       INT            NULL,
    [ParentEquipmentId] INT            NULL,
    [CILSystemId]       INT            NULL,
    CONSTRAINT [PK_Local_eDH_FuncLocation_1] PRIMARY KEY CLUSTERED ([FLId] ASC),
    FOREIGN KEY ([CILSystemId]) REFERENCES [dbo].[Local_eDH_CILSystems] ([CILSystemId]),
    FOREIGN KEY ([ParentFLId]) REFERENCES [dbo].[Local_eDH_FuncLocation] ([FLId])
);

