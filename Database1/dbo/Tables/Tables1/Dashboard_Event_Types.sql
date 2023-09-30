CREATE TABLE [dbo].[Dashboard_Event_Types] (
    [Dashboard_Event_Type_ID] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_Event_Type]    VARCHAR (100) NOT NULL,
    [Unit_Level_Event]        BIT           NOT NULL,
    [Variable_Level_Event]    BIT           NOT NULL,
    CONSTRAINT [PK_Dashboard_Event_Types] PRIMARY KEY CLUSTERED ([Dashboard_Event_Type_ID] ASC)
);

