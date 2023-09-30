CREATE TABLE [dbo].[Local_PG_Schedule_Display] (
    [SD_ID]            INT           IDENTITY (1, 1) NOT NULL,
    [Sheet_id]         INT           NOT NULL,
    [Sheet_desc]       VARCHAR (50)  NULL,
    [Sheet_Group_desc] VARCHAR (50)  NULL,
    [Comment_text]     VARCHAR (250) NOT NULL,
    [Type]             VARCHAR (25)  NOT NULL,
    [Day_period]       INT           NOT NULL,
    [Time_Day]         VARCHAR (5)   NOT NULL,
    [Begin_Year]       VARCHAR (10)  NULL,
    [LastTime]         DATETIME      NULL,
    [NextTime]         DATETIME      NULL
);

