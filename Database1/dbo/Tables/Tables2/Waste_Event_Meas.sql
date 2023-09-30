CREATE TABLE [dbo].[Waste_Event_Meas] (
    [WEMT_Id]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Conversion]       REAL          NULL,
    [Conversion_Spec]  INT           NULL,
    [PU_Id]            INT           NOT NULL,
    [WEMT_Name_Global] VARCHAR (100) NULL,
    [WEMT_Name_Local]  VARCHAR (100) NOT NULL,
    [WEMT_Name]        AS            (case when (@@options&(512))=(0) then isnull([WEMT_Name_Global],[WEMT_Name_Local]) else [WEMT_Name_Local] end),
    CONSTRAINT [WEvent_Meas_PK_WEMTId] PRIMARY KEY CLUSTERED ([WEMT_Id] ASC),
    CONSTRAINT [WEvent_Meas_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [WEvent_Meas_IDX_PUId]
    ON [dbo].[Waste_Event_Meas]([PU_Id] ASC);

