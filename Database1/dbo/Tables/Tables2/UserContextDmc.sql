CREATE TABLE [dbo].[UserContextDmc] (
    [UserId]          NVARCHAR (255) NOT NULL,
    [ComputerName]    NVARCHAR (255) NOT NULL,
    [UserContextData] IMAGE          NULL,
    [TimeStamp]       DATETIME       NULL,
    [Version]         BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC, [ComputerName] ASC)
);

