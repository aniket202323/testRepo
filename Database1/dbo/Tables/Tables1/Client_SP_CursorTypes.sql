CREATE TABLE [dbo].[Client_SP_CursorTypes] (
    [CursorType_Id]    TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CursorType_Desc]  [dbo].[Varchar_Desc] NOT NULL,
    [CursorType_Value] SMALLINT             NOT NULL,
    CONSTRAINT [CliSPCurTypes_PK_CurTypeId] PRIMARY KEY NONCLUSTERED ([CursorType_Id] ASC),
    CONSTRAINT [CliSPCurTypes_UC_CurTypeValue] UNIQUE NONCLUSTERED ([CursorType_Value] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CliSPCurTypes_IDX_CurTypeDesc]
    ON [dbo].[Client_SP_CursorTypes]([CursorType_Desc] ASC);

