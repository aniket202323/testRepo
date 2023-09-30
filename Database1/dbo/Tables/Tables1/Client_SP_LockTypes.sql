CREATE TABLE [dbo].[Client_SP_LockTypes] (
    [LockType_Id]    TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [LockType_Desc]  [dbo].[Varchar_Desc] NOT NULL,
    [LockType_Value] SMALLINT             NOT NULL,
    CONSTRAINT [CliSPLTypes_PK_LockTypeId] PRIMARY KEY NONCLUSTERED ([LockType_Id] ASC),
    CONSTRAINT [CliSPLTypes_UC_LockTypeValue] UNIQUE NONCLUSTERED ([LockType_Value] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CliSPLTypes_IDX_LockTypeDesc]
    ON [dbo].[Client_SP_LockTypes]([LockType_Desc] ASC);

