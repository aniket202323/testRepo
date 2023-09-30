CREATE TABLE [dbo].[Waste_n_Timed_Comments] (
    [WTC_Id]           INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment]          TEXT     NULL,
    [Comment_Text]     TEXT     NULL,
    [TimeStamp]        DATETIME NULL,
    [User_Id]          INT      NULL,
    [WTC_Source_Id]    INT      NOT NULL,
    [WTC_Type]         TINYINT  NOT NULL,
    [Processed]        TINYINT  NULL,
    [Convert_WTC_Type] TINYINT  NULL,
    CONSTRAINT [WTComments_PK_WTCId] PRIMARY KEY NONCLUSTERED ([WTC_Id] ASC, [WTC_Type] ASC)
);


GO
CREATE NONCLUSTERED INDEX [WTComments_IDX_WTCSourceId]
    ON [dbo].[Waste_n_Timed_Comments]([WTC_Source_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [WTComments_IDX_WTCSourceIdType]
    ON [dbo].[Waste_n_Timed_Comments]([WTC_Source_Id] ASC, [WTC_Type] ASC);

