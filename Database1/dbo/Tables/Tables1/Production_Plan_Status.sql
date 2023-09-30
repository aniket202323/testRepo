CREATE TABLE [dbo].[Production_Plan_Status] (
    [PPS_Id]           INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [From_PPStatus_Id] INT NOT NULL,
    [Parent_PP_Id]     INT NULL,
    [Path_Id]          INT NULL,
    [To_PPStatus_Id]   INT NOT NULL,
    CONSTRAINT [PK_Production_Plan_Status] PRIMARY KEY NONCLUSTERED ([PPS_Id] ASC),
    CONSTRAINT [FK_ProductionPlanStatus_ProductionPlanStatuses] FOREIGN KEY ([From_PPStatus_Id]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [FK_ProductionPlanStatus_ProductionPlanStatuses1] FOREIGN KEY ([To_PPStatus_Id]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [ProductionPlanStatus_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [ProductionPlanStatus_FK_PPId] FOREIGN KEY ([Parent_PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id])
);

