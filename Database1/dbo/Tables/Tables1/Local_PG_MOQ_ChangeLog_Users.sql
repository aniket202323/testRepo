CREATE TABLE [dbo].[Local_PG_MOQ_ChangeLog_Users] (
    [PFUser_Id] INT            IDENTITY (1, 1) NOT NULL,
    [Username]  VARCHAR (1000) NOT NULL,
    CONSTRAINT [LocalPGMOQChangeLogUsers_PK_PFUserId] PRIMARY KEY CLUSTERED ([PFUser_Id] ASC),
    CONSTRAINT [LocalPGMOQChangeLogUsers_UQ_Username] UNIQUE NONCLUSTERED ([Username] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMOQChangeLogUsers_IDX_Username]
    ON [dbo].[Local_PG_MOQ_ChangeLog_Users]([Username] ASC);

