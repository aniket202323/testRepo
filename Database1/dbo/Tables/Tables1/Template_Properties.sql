CREATE TABLE [dbo].[Template_Properties] (
    [TP_Id]       INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Eng_Units]   [dbo].[Varchar_Eng_Units] NULL,
    [Template_Id] INT                       NOT NULL,
    [TP_Desc]     [dbo].[Varchar_Desc]      NOT NULL,
    [TP_Order]    SMALLINT                  NOT NULL,
    CONSTRAINT [TmpProp_PK_TPIdTmpId] PRIMARY KEY NONCLUSTERED ([TP_Id] ASC, [Template_Id] ASC)
);

