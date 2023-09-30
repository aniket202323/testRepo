CREATE TABLE [dbo].[WorkOrder_Event_Components] (
    [WO_Component_Id] INT IDENTITY (1, 1) NOT NULL,
    [Component_Id]    INT NULL,
    [BOM_Item_Id]     INT NULL,
    [Segment_Id]      INT NULL,
    [Work_Order_Id]   INT NULL,
    PRIMARY KEY CLUSTERED ([WO_Component_Id] ASC),
    FOREIGN KEY ([Component_Id]) REFERENCES [dbo].[Event_Components] ([Component_Id]) ON DELETE CASCADE,
    CONSTRAINT [WorkOrderEventComponents_UC_CompId_BOMItemId] UNIQUE NONCLUSTERED ([Component_Id] ASC, [BOM_Item_Id] ASC)
);

