CREATE TABLE [dbo].[Security_Operations] (
    [Security_Operation_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AL_Id1]                  INT                  NULL,
    [AL_Id2]                  INT                  NULL,
    [AL_Id3]                  INT                  NULL,
    [AL_Id4]                  INT                  NULL,
    [AL_Id5]                  INT                  NULL,
    [Security_Item_Id1]       INT                  NULL,
    [Security_Item_Id2]       INT                  NULL,
    [Security_Item_Id3]       INT                  NULL,
    [Security_Item_Id4]       INT                  NULL,
    [Security_Item_Id5]       INT                  NULL,
    [Security_Operation_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [SecOper_PK_SecOperId] PRIMARY KEY NONCLUSTERED ([Security_Operation_Id] ASC),
    CONSTRAINT [SecOper_UC_SecOperDesc] UNIQUE NONCLUSTERED ([Security_Operation_Desc] ASC)
);

