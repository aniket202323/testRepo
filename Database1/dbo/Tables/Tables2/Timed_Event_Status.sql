CREATE TABLE [dbo].[Timed_Event_Status] (
    [TEStatus_Id]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PU_Id]                INT           NOT NULL,
    [TEStatus_Value]       VARCHAR (25)  NOT NULL,
    [TEStatus_Name_Global] VARCHAR (100) NULL,
    [TEStatus_Name_Local]  VARCHAR (100) NOT NULL,
    [TEStatus_Name]        AS            (case when (@@options&(512))=(0) then isnull([TEStatus_Name_Global],[TEStatus_Name_Local]) else [TEStatus_Name_Local] end),
    CONSTRAINT [TEvent_Status_PK_TEStatusId] PRIMARY KEY CLUSTERED ([TEStatus_Id] ASC),
    CONSTRAINT [TEvent_Status_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [TEvent_Status_UC_PUIdValue] UNIQUE NONCLUSTERED ([PU_Id] ASC, [TEStatus_Value] ASC)
);

