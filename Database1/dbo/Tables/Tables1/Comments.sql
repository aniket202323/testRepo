CREATE TABLE [dbo].[Comments] (
    [Comment_Id]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment]        TEXT          NOT NULL,
    [Comment_Text]   TEXT          NULL,
    [CS_Id]          INT           NULL,
    [Entry_On]       DATETIME      NULL,
    [Extended_Info]  VARCHAR (255) NULL,
    [Modified_On]    DATETIME      NOT NULL,
    [NextComment_Id] INT           NULL,
    [ShouldDelete]   TINYINT       NULL,
    [TopOfChain_Id]  INT           NULL,
    [User_Id]        INT           NOT NULL,
    CONSTRAINT [PK___8__13] PRIMARY KEY CLUSTERED ([Comment_Id] ASC),
    CONSTRAINT [Comments_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE NONCLUSTERED INDEX [Comments_IDX_TopOfChain]
    ON [dbo].[Comments]([TopOfChain_Id] ASC);

