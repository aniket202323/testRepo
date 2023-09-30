CREATE TABLE [dbo].[Local_Event_Starts] (
    [ES_Id]        INT          IDENTITY (1, 1) NOT NULL,
    [EC_Id]        INT          NOT NULL,
    [Start_Time]   DATETIME     NOT NULL,
    [End_Time]     DATETIME     NULL,
    [Entry_On]     DATETIME     NOT NULL,
    [Event_Num]    VARCHAR (30) NULL,
    [Event_Status] INT          NOT NULL,
    [Rate]         REAL         NULL,
    CONSTRAINT [PK_Local_Event_Starts] PRIMARY KEY NONCLUSTERED ([ES_Id] ASC),
    CONSTRAINT [IX_EC_Id_Start_Time] UNIQUE CLUSTERED ([EC_Id] ASC, [Start_Time] ASC)
);

