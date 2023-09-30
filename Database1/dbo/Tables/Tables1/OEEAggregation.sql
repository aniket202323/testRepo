CREATE TABLE [dbo].[OEEAggregation] (
    [OEEAggregation_Id]   BIGINT       IDENTITY (1, 1) NOT NULL,
    [ActualSpeed]         FLOAT (53)   NOT NULL,
    [AvailabilityOEE]     FLOAT (53)   NOT NULL,
    [Crew_Desc]           VARCHAR (50) NULL,
    [End_Time]            DATETIME     NOT NULL,
    [Entry_On]            DATETIME     NOT NULL,
    [GoodProduction]      FLOAT (53)   NOT NULL,
    [Granularity_Id]      INT          NOT NULL,
    [IdealSpeed]          FLOAT (53)   NOT NULL,
    [LoadingTime]         FLOAT (53)   NOT NULL,
    [Path_Id]             INT          NULL,
    [PercentOEE]          FLOAT (53)   NOT NULL,
    [PerformanceDowntime] FLOAT (53)   NOT NULL,
    [PerformanceOEE]      FLOAT (53)   NOT NULL,
    [PP_Id]               INT          NULL,
    [Prod_Id]             INT          NULL,
    [Pu_Id]               INT          NOT NULL,
    [QualityOEE]          FLOAT (53)   NOT NULL,
    [Reprocess_Record]    INT          CONSTRAINT [OEEAggregation_DF_Reprocess] DEFAULT ((0)) NOT NULL,
    [RunningTime]         FLOAT (53)   NOT NULL,
    [Shift_Desc]          VARCHAR (50) NULL,
    [Slice_Type_Id]       INT          NOT NULL,
    [Start_Time]          DATETIME     NOT NULL,
    [TargetProduction]    FLOAT (53)   NOT NULL,
    [TotalProduction]     FLOAT (53)   NOT NULL,
    [DowntimeA]           FLOAT (53)   NULL,
    [DowntimeP]           FLOAT (53)   NULL,
    [DowntimePL]          FLOAT (53)   NULL,
    [DowntimeQ]           FLOAT (53)   NULL,
    [NPT]                 FLOAT (53)   NULL,
    [IsNPT]               BIT          NULL,
    CONSTRAINT [OEEAggregation_PK_OEEAggregationId] PRIMARY KEY NONCLUSTERED ([OEEAggregation_Id] ASC),
    CONSTRAINT [OEEAggregation_FK_GranularityId] FOREIGN KEY ([Granularity_Id]) REFERENCES [dbo].[OEEAggregationGranularityLevel] ([Granularity_Id]),
    CONSTRAINT [OEEAggregation_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]) ON DELETE CASCADE,
    CONSTRAINT [OEEAggregation_FK_PPId] FOREIGN KEY ([PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id]) ON DELETE CASCADE,
    CONSTRAINT [OEEAggregation_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]) ON DELETE CASCADE,
    CONSTRAINT [OEEAggregation_FK_PUId] FOREIGN KEY ([Pu_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE CASCADE,
    CONSTRAINT [OEEAggregation_FK_PUIdSliceType] FOREIGN KEY ([Slice_Type_Id]) REFERENCES [dbo].[OEEAggregationSliceTypes] ([Slice_Type_Id])
);


GO
CREATE CLUSTERED INDEX [OEEAggregation_CIDX_PuIdGranStypeStEt]
    ON [dbo].[OEEAggregation]([Pu_Id] ASC, [Start_Time] ASC, [End_Time] ASC, [Granularity_Id] ASC, [Slice_Type_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [OEEAggregation_IDX_Reprocess]
    ON [dbo].[OEEAggregation]([Reprocess_Record] ASC, [Pu_Id] ASC);

