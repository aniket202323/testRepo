CREATE TABLE [dbo].[Dashboard_User_Security_Table] (
    [Dashboard_User_Security_Table_ID] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [security_level]                   INT NOT NULL,
    [user_id]                          INT NOT NULL,
    CONSTRAINT [PK_Dashboard_User_Security_Table] PRIMARY KEY CLUSTERED ([Dashboard_User_Security_Table_ID] ASC)
);

