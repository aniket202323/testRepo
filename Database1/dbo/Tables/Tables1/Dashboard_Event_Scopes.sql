CREATE TABLE [dbo].[Dashboard_Event_Scopes] (
    [Dashboard_Event_Scope_ID] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Event_Scope]    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Dashboard_Event_Scopes] PRIMARY KEY CLUSTERED ([Dashboard_Event_Scope_ID] ASC)
);

