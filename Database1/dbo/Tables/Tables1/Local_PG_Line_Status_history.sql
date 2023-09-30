CREATE TABLE [dbo].[Local_PG_Line_Status_history] (
    [Status_History_Id]  INT          IDENTITY (1, 1) NOT NULL,
    [Status_Schedule_Id] INT          NULL,
    [Start_DateTime]     DATETIME     NOT NULL,
    [Line_Status_Id]     INT          NOT NULL,
    [Update_Status]      VARCHAR (50) NOT NULL,
    [Unit_Id]            INT          NOT NULL,
    [End_DateTime]       DATETIME     NULL,
    [User_ID]            INT          NULL,
    [Modified_DateTime]  DATETIME     NULL
);

