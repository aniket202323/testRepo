CREATE TABLE [dbo].[Waste_Event_Type] (
    [WET_Id]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ReadOnly]        BIT           CONSTRAINT [WEvent_Type_DF_ReadOnly] DEFAULT ((0)) NOT NULL,
    [WET_Name_Global] VARCHAR (100) NULL,
    [WET_Name_Local]  VARCHAR (100) NOT NULL,
    [WET_Name]        AS            (case when (@@options&(512))=(0) then isnull([WET_Name_Global],[WET_Name_Local]) else [WET_Name_Local] end),
    CONSTRAINT [WEvent_Type_PK_WETId] PRIMARY KEY CLUSTERED ([WET_Id] ASC),
    CONSTRAINT [WasteEventType_UC_NameLocal] UNIQUE NONCLUSTERED ([WET_Name_Local] ASC)
);

