CREATE TABLE [dbo].[Dashboard_Users] (
    [Dashboard_User_ID] INT           IDENTITY (1, 1) NOT NULL,
    [Dashboard_Key]     VARCHAR (100) CONSTRAINT [DashboardUsers_DF_DashboardKey] DEFAULT ('invalid') NOT NULL,
    [SecurityLevel]     INT           CONSTRAINT [DashboardUsers_DF_SecurityLlevel] DEFAULT ((0)) NOT NULL,
    [User_ID]           INT           NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Users]
    ON [dbo].[Dashboard_Users]([Dashboard_User_ID] ASC);

