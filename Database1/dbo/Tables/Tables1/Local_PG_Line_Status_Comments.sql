CREATE TABLE [dbo].[Local_PG_Line_Status_Comments] (
    [Comment_Id]         INT            IDENTITY (1, 1) NOT NULL,
    [Status_Schedule_Id] INT            NOT NULL,
    [User_Id]            INT            NOT NULL,
    [Entered_On]         DATETIME       NOT NULL,
    [Start_DateTime]     DATETIME       NULL,
    [End_DateTime]       DATETIME       NULL,
    [Line_Status_Id]     INT            NOT NULL,
    [Unit_Id]            INT            NOT NULL,
    [Comment_Text]       NVARCHAR (510) NULL
);

