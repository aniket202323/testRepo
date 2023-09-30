CREATE TABLE [dbo].[Local_Index_Defrag] (
    [Row_ID]         BIGINT       IDENTITY (1, 1) NOT NULL,
    [ObjectName]     CHAR (255)   NULL,
    [ObjectId]       INT          NULL,
    [IndexName]      CHAR (255)   NULL,
    [IndexId]        INT          NULL,
    [Lvl]            INT          NULL,
    [CountPages]     INT          NULL,
    [CountRows]      INT          NULL,
    [MinRecSize]     INT          NULL,
    [MaxRecSize]     INT          NULL,
    [AvgRecSize]     INT          NULL,
    [ForRecCount]    INT          NULL,
    [Extents]        INT          NULL,
    [ExtentSwitches] INT          NULL,
    [AvgFreeBytes]   INT          NULL,
    [AvgPageDensity] INT          NULL,
    [ScanDensity]    DECIMAL (18) NULL,
    [BestCount]      INT          NULL,
    [ActualCount]    INT          NULL,
    [LogicalFrag]    DECIMAL (18) NULL,
    [ExtentFrag]     DECIMAL (18) NULL,
    [Current_Run]    DATETIME     DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([Row_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex-Current_Run]
    ON [dbo].[Local_Index_Defrag]([Current_Run] ASC);

