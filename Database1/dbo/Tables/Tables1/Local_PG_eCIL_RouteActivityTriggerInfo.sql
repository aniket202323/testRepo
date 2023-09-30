CREATE TABLE [dbo].[Local_PG_eCIL_RouteActivityTriggerInfo] (
    [Trigger_Option_Id]        INT           IDENTITY (1, 1) NOT NULL,
    [Trigger_Option_Desc]      VARCHAR (50)  NOT NULL,
    [Trigger_Option_Long_Desc] VARCHAR (200) NULL,
    CONSTRAINT [PK_Local_PG_eCIL_RouteActivityTriggerInfo] PRIMARY KEY NONCLUSTERED ([Trigger_Option_Id] ASC)
);

