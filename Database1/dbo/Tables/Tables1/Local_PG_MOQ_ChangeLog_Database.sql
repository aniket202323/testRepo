CREATE TABLE [dbo].[Local_PG_MOQ_ChangeLog_Database] (
    [PFdB_Id]    INT           IDENTITY (1, 1) NOT NULL,
    [PFDBServer] VARCHAR (100) NOT NULL,
    [PFDatabase] VARCHAR (100) NOT NULL,
    CONSTRAINT [LocalPGMOQChangeLogDatabase_PK_PFdBId] PRIMARY KEY CLUSTERED ([PFdB_Id] ASC),
    CONSTRAINT [LocalPGMOQChangeLogDatabase_UQ_PFDBServerPFDatabase] UNIQUE NONCLUSTERED ([PFDBServer] ASC, [PFDatabase] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMOQChangeLogDatabase_IDX_PFDBServer]
    ON [dbo].[Local_PG_MOQ_ChangeLog_Database]([PFDBServer] ASC);


GO
CREATE NONCLUSTERED INDEX [LocalPGMOQChangeLogDatabase_IDX_PFDatabase]
    ON [dbo].[Local_PG_MOQ_ChangeLog_Database]([PFDatabase] ASC);

