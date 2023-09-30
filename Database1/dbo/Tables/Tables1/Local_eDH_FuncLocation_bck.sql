CREATE TABLE [dbo].[Local_eDH_FuncLocation_bck] (
    [EquipmentDesc] NVARCHAR (255) NULL,
    [FLCode]        NCHAR (255)    NULL,
    [ParentFLId]    INT            NULL,
    [FLId]          INT            IDENTITY (1, 1) NOT NULL,
    [Enable]        BIT            NULL,
    [Level]         INT            NULL,
    [MasterUnitId]  INT            NULL
);

