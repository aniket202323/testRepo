CREATE TABLE [dbo].[Dashboard_Session] (
    [Dashboard_Session_ID]         INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Session_Start_Date] DATETIME NOT NULL,
    [Dashboard_User_ID]            INT      NOT NULL,
    CONSTRAINT [PK_Dashboard_Session] PRIMARY KEY NONCLUSTERED ([Dashboard_Session_ID] ASC, [Dashboard_User_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Session]
    ON [dbo].[Dashboard_Session]([Dashboard_Session_ID] ASC);

