CREATE TABLE [dbo].[Local_PG_MOQ_ChangeLog_Application] (
    [PFApp_Id]    INT            IDENTITY (1, 1) NOT NULL,
    [Application] VARCHAR (1000) NOT NULL,
    CONSTRAINT [LocalPGMOQChangeLogApplication_PK_PFAppId] PRIMARY KEY CLUSTERED ([PFApp_Id] ASC),
    CONSTRAINT [LocalPGMOQChangeLogApplication_UQ_Application] UNIQUE NONCLUSTERED ([Application] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMOQChangeLogApplication_IDX_Application]
    ON [dbo].[Local_PG_MOQ_ChangeLog_Application]([Application] ASC);

