CREATE TABLE [dbo].[comment_attachments] (
    [Att_Id]       INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Att_FileName] VARCHAR (200) NOT NULL,
    [Comment_Id]   INT           NOT NULL,
    [File_Content] VARCHAR (MAX) NOT NULL,
    [Mime_Type]    VARCHAR (50)  NOT NULL,
    [Modified_on]  DATETIME      CONSTRAINT [DF__comment_a__Modif__0ED9D1C1] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK__comment___34580B990CF1894F] PRIMARY KEY CLUSTERED ([Att_Id] ASC),
    CONSTRAINT [attachment_FK_CommentId] FOREIGN KEY ([Comment_Id]) REFERENCES [dbo].[Comments] ([Comment_Id]) ON DELETE CASCADE
);

