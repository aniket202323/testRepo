CREATE TABLE [dbo].[PrdExec_Path_Status_Detail] (
    [PPSD_Id]                    INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AutoPromoteFrom_PPStatusId] INT     NULL,
    [AutoPromoteTo_PPStatusId]   INT     NULL,
    [How_Many]                   INT     NULL,
    [Path_Id]                    INT     NOT NULL,
    [PP_Status_Id]               INT     NOT NULL,
    [Sort_Order]                 TINYINT NULL,
    [SortWith_PPStatusId]        INT     NULL,
    CONSTRAINT [PK_PrdExec_Path_Status_Detail] PRIMARY KEY NONCLUSTERED ([PPSD_Id] ASC),
    CONSTRAINT [PrdExec_Path_Status_Detail_FK_AutoPromoteFrom_PPStatusId] FOREIGN KEY ([AutoPromoteFrom_PPStatusId]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [PrdExec_Path_Status_Detail_FK_AutoPromoteTo_PPStatusId] FOREIGN KEY ([AutoPromoteTo_PPStatusId]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [PrdExec_Path_Status_Detail_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [PrdExec_Path_Status_Detail_FK_PPStatusId] FOREIGN KEY ([PP_Status_Id]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [PrdExec_Path_Status_Detail_FK_SortWithPPStatusId] FOREIGN KEY ([SortWith_PPStatusId]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id])
);


GO
CREATE NONCLUSTERED INDEX [PPSDetail_IDX_PathIdPPStatusId]
    ON [dbo].[PrdExec_Path_Status_Detail]([Path_Id] ASC, [PP_Status_Id] ASC);

