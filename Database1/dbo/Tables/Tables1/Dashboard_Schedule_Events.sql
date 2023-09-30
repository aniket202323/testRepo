CREATE TABLE [dbo].[Dashboard_Schedule_Events] (
    [Dashboard_Schedule_Event_ID] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Event_Scope_ID]    INT NOT NULL,
    [Dashboard_Event_Type_ID]     INT NOT NULL,
    [Dashboard_Schedule_ID]       INT NOT NULL,
    [PU_ID]                       INT NULL,
    [Var_ID]                      INT NULL,
    CONSTRAINT [PK_Dashboard_Schedule_Events] PRIMARY KEY CLUSTERED ([Dashboard_Schedule_Event_ID] ASC)
);

